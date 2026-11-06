import os
import Foundation
import Observation
import AppKit

@MainActor
@Observable
class AppState {
    // MARK: - State
    private(set) var authToken: String?
    private(set) var currentUser: GitHubUser?
    private(set) var repositories: [Repository] = []
    private(set) var selectedRepositoryIDs: Set<Int> = []
    private(set) var workflowRuns: [WorkflowRun] = []
    private(set) var isLoading = false
    var errorMessage: String?
    private(set) var lastRefreshDate: Date?

    /// Shown while the user approves the sign-in on github.com.
    private(set) var pendingDeviceCode: AuthService.DeviceCode?
    private(set) var isSigningIn = false
    private(set) var useBiometricAuthentication = false

    // MARK: - Services
    private let authService = AuthService.shared
    private let githubService = GitHubService.shared
    private let keychainManager = KeychainManager.shared
    private let apiClient = GitHubAPIClient.shared
    private let refreshService = RefreshService()
    private var signInTask: Task<Void, Never>?
    private var refreshTask: Task<Void, Never>?

    private static let staleAfter: TimeInterval = 60

    init() {
        selectedRepositoryIDs = AppSettings.load().selectedRepositoryIDs
        useBiometricAuthentication = keychainManager.isBiometricEnabled()
        Task { await loadSavedToken() }
    }

    var isAuthenticated: Bool { authToken != nil && currentUser != nil }

    var selectedRepositories: [Repository] {
        repositories.filter { selectedRepositoryIDs.contains($0.id) }
    }

    // MARK: - Sign in (Device Flow)

    func login() {
        signInTask?.cancel()
        errorMessage = nil
        isSigningIn = true
        signInTask = Task {
            defer {
                isSigningIn = false
                pendingDeviceCode = nil
            }
            do {
                let code = try await authService.requestDeviceCode()
                pendingDeviceCode = code
                copyUserCode()
                NSWorkspace.shared.open(code.verificationURL)

                let token = try await authService.pollForToken(code)
                try keychainManager.saveToken(token, useBiometric: false)
                useBiometricAuthentication = false
                authToken = token
                await loadInitialData()
            } catch is CancellationError {
                // User cancelled
            } catch {
                Log.auth.error("Sign-in failed: \(error.localizedDescription, privacy: .public)")
                errorMessage = "Login failed: \(error.localizedDescription)"
            }
        }
    }

    func cancelLogin() {
        signInTask?.cancel()
        signInTask = nil
    }

    func copyUserCode() {
        guard let code = pendingDeviceCode?.userCode else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
    }

    func logout() {
        try? keychainManager.deleteToken()
        clearSession()
        useBiometricAuthentication = false
        errorMessage = nil
    }

    /// Drops in-memory credentials and data. Repository selection is kept so
    /// signing back in restores it.
    private func clearSession() {
        refreshService.stop()
        refreshTask?.cancel()
        apiClient.clearCache()
        authToken = nil
        currentUser = nil
        repositories = []
        workflowRuns = []
        lastRefreshDate = nil
    }

    // MARK: - Biometrics

    func setBiometricProtection(_ enabled: Bool) {
        guard let token = authToken else { return }
        do {
            try keychainManager.saveToken(token, useBiometric: enabled)
            useBiometricAuthentication = enabled
        } catch {
            errorMessage = "Couldn't update biometric protection: \(error.localizedDescription)"
            // Make sure the token is still stored somewhere usable.
            try? keychainManager.saveToken(token, useBiometric: useBiometricAuthentication)
        }
    }

    // MARK: - Loading

    private func loadSavedToken() async {
        do {
            guard let token = try await keychainManager.getToken(reason: "unlock your GitHub token") else { return }
            authToken = token
            await loadInitialData()
        } catch {
            Log.keychain.error("Couldn't load token: \(error.localizedDescription, privacy: .public)")
            errorMessage = "Couldn't unlock your GitHub token. Open the menu to try again."
        }
    }

    /// Retry unlocking (e.g. after a cancelled Touch ID prompt).
    func unlockIfNeeded() {
        guard authToken == nil, !isSigningIn else { return }
        Task { await loadSavedToken() }
    }

    func loadInitialData() async {
        guard let token = authToken else { return }
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil

        do {
            currentUser = try await githubService.fetchUser(token: token)
            await loadRepositories()
            await performRefresh()
            refreshService.start { [weak self] in await self?.refreshRuns() }
        } catch {
            await handle(error, context: "Failed to load data")
        }
    }

    func loadRepositories() async {
        guard let token = authToken else { return }
        do {
            repositories = try await githubService.fetchRepositories(token: token)
        } catch {
            await handle(error, context: "Failed to load repositories")
        }
    }

    /// Refreshes runs, coalescing with any refresh already in flight.
    func refreshRuns() async {
        if let refreshTask {
            await refreshTask.value
            return
        }
        let task = Task { await performRefresh() }
        refreshTask = task
        await task.value
        refreshTask = nil
    }

    /// Called when the popover opens: refresh if the data is stale.
    func refreshIfStale() {
        guard isAuthenticated else {
            unlockIfNeeded()
            return
        }
        if let last = lastRefreshDate, Date().timeIntervalSince(last) < Self.staleAfter { return }
        Task { await refreshRuns() }
    }

    private func performRefresh() async {
        guard let token = authToken else { return }
        guard !selectedRepositories.isEmpty else {
            workflowRuns = []
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await githubService.fetchLatestRuns(for: selectedRepositories, token: token)
            workflowRuns = Array(result.runs.prefix(GitHubConstants.maxRunsToDisplay))
            lastRefreshDate = Date()

            if result.failures.isEmpty {
                errorMessage = nil
            } else {
                let names = result.failures.map(\.repository.name).joined(separator: ", ")
                errorMessage = "Couldn't load runs for \(names)"
            }
        } catch is CancellationError {
        } catch {
            await handle(error, context: "Failed to refresh runs")
        }
    }

    /// A 401 can be transient; confirm the token is really rejected before signing out.
    private func handle(_ error: Error, context: String) async {
        if case APIError.unauthorized = error, let token = authToken {
            do {
                _ = try await githubService.fetchUser(token: token)
                errorMessage = "\(context): \(error.localizedDescription)"
            } catch APIError.unauthorized {
                Log.auth.notice("Token rejected by GitHub; signing out")
                try? keychainManager.deleteToken()
                clearSession()
                errorMessage = APIError.unauthorized.localizedDescription
            } catch {
                errorMessage = "\(context): \(error.localizedDescription)"
            }
            return
        }
        Log.app.error("\(context, privacy: .public): \(error.localizedDescription, privacy: .public)")
        errorMessage = "\(context): \(error.localizedDescription)"
    }

    // MARK: - Repository selection

    func toggleRepositorySelection(_ id: Int) {
        if selectedRepositoryIDs.contains(id) {
            selectedRepositoryIDs.remove(id)
        } else {
            selectedRepositoryIDs.insert(id)
        }
        AppSettings(selectedRepositoryIDs: selectedRepositoryIDs).save()
        Task { await refreshRuns() }
    }

    func isRepositorySelected(_ id: Int) -> Bool {
        selectedRepositoryIDs.contains(id)
    }
}
