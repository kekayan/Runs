import Foundation
import Observation

@Observable
class AppState {
    // MARK: - State Properties
    var authToken: String?
    var currentUser: GitHubUser?
    var repositories: [Repository] = []
    var selectedRepositoryIDs: Set<Int> = []
    var workflowRuns: [WorkflowRun] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var lastRefreshDate: Date?

    // MARK: - Services
    private let authService = AuthService.shared
    private let githubService = GitHubService.shared
    private let keychainManager = KeychainManager.shared

    // MARK: - Biometric Settings
    var useBiometricAuthentication: Bool {
        get { KeychainManager.shared.isBiometricEnabled() }
        set { 
            // Save preference will be handled when saving token
        }
    }

    // MARK: - Initialization
    init() {
        loadSavedState()
    }

    // MARK: - Authentication Methods

    func login() {
        authService.startOAuthFlow()
    }

    func logout() {
        // Clear token from Keychain
        try? keychainManager.deleteToken()

        // Clear state
        authToken = nil
        currentUser = nil
        repositories = []
        workflowRuns = []
        selectedRepositoryIDs = []
        errorMessage = nil
        lastRefreshDate = nil

        // Clear saved settings
        AppSettings.clear()
    }

    func handleOAuthCallback(_ url: URL) async {
        do {
            isLoading = true
            errorMessage = nil

            // Exchange code for token
            let token = try await authService.handleCallback(url: url)

            // Save token to Keychain (with biometric if enabled)
            try keychainManager.saveToken(token, useBiometric: useBiometricAuthentication)
            await MainActor.run {
                self.authToken = token
            }

            // Fetch user info
            currentUser = try await githubService.fetchUser(token: token)

            // Load repositories
            await loadRepositories()

            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Login failed: \(error.localizedDescription)"
            print("OAuth callback error: \(error)")
        }
    }

    // MARK: - Data Loading Methods

    func loadSavedState() {
        // Load token from Keychain (with biometric if enabled)
        Task {
            do {
                let requireBiometric = keychainManager.isBiometricEnabled() && keychainManager.canUseBiometricAuthentication()
                let token = try await keychainManager.getToken(requireBiometric: requireBiometric)
                
                if let token = token {
                    await MainActor.run {
                        self.authToken = token
                    }
                    // Load user and repositories
                    await loadInitialData()
                }
            } catch {
                print("Failed to load token: \(error)")
                await MainActor.run {
                    self.errorMessage = "Authentication required"
                }
            }
        }

        // Load settings
        let settings = AppSettings.load()
        selectedRepositoryIDs = settings.selectedRepositoryIDs
    }
    
    func authenticateWithBiometric() async -> Bool {
        guard keychainManager.isBiometricEnabled() else { return true }
        guard keychainManager.canUseBiometricAuthentication() else { return true }
        
        do {
            let token = try await keychainManager.getToken(
                requireBiometric: true,
                reason: "Authenticate to access GitHub Actions"
            )
            if let token = token {
                await MainActor.run {
                    self.authToken = token
                }
                return true
            }
            return false
        } catch {
            await MainActor.run {
                self.errorMessage = "Biometric authentication failed"
            }
            return false
        }
    }

    func loadInitialData() async {
        guard let token = authToken else { return }

        do {
            isLoading = true
            errorMessage = nil

            // Load user info
            currentUser = try await githubService.fetchUser(token: token)

            // Load repositories
            await loadRepositories()

            // Load workflow runs if repositories are selected
            if !selectedRepositoryIDs.isEmpty {
                await refreshRuns()
            }

            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to load data: \(error.localizedDescription)"

            // If unauthorized, clear token
            if case APIError.unauthorized = error {
                logout()
            }
        }
    }

    func loadRepositories() async {
        guard let token = authToken else { return }

        do {
            repositories = try await githubService.fetchRepositories(token: token)
        } catch {
            errorMessage = "Failed to load repositories: \(error.localizedDescription)"
            print("Error loading repositories: \(error)")
        }
    }

    func refreshRuns() async {
        guard let token = authToken else { return }
        guard !selectedRepositoryIDs.isEmpty else {
            workflowRuns = []
            return
        }

        do {
            isLoading = true
            errorMessage = nil

            workflowRuns = try await githubService.fetchLatestRunsForSelectedRepos(
                selectedIDs: selectedRepositoryIDs,
                allRepos: repositories,
                token: token
            )

            // Limit to max runs to display
            if workflowRuns.count > GitHubConstants.maxRunsToDisplay {
                workflowRuns = Array(workflowRuns.prefix(GitHubConstants.maxRunsToDisplay))
            }

            lastRefreshDate = Date()
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to refresh runs: \(error.localizedDescription)"
            print("Error refreshing runs: \(error)")

            // If unauthorized, clear token
            if case APIError.unauthorized = error {
                logout()
            }
        }
    }

    // MARK: - Repository Selection Methods

    func toggleRepositorySelection(_ id: Int) {
        if selectedRepositoryIDs.contains(id) {
            selectedRepositoryIDs.remove(id)
        } else {
            selectedRepositoryIDs.insert(id)
        }
        saveSettings()

        // Refresh runs when selection changes
        Task {
            await refreshRuns()
        }
    }

    func isRepositorySelected(_ id: Int) -> Bool {
        selectedRepositoryIDs.contains(id)
    }

    // MARK: - Settings Persistence

    private func saveSettings() {
        let settings = AppSettings(selectedRepositoryIDs: selectedRepositoryIDs)
        settings.save()
    }

    // MARK: - Computed Properties

    var isAuthenticated: Bool {
        authToken != nil && currentUser != nil
    }

    var selectedRepositories: [Repository] {
        repositories.filter { selectedRepositoryIDs.contains($0.id) }
    }
}
