import SwiftUI

struct MenuBarContentView: View {
    @State private var appState: AppState
    @State private var isRefreshing = false
    
    init(appState: AppState) {
        self._appState = State(initialValue: appState)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            MenuBarHeaderView(
                isRefreshing: isRefreshing,
                isAuthenticated: appState.isAuthenticated,
                onRefresh: refresh,
                onSettings: {
                    // Open settings window via AppDelegate
                    if let delegate = AppDelegate.shared {
                        let settingsWindow = NSWindow(
                            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
                            styleMask: [.titled, .closable, .miniaturizable],
                            backing: .buffered,
                            defer: false
                        )
                        settingsWindow.title = "Settings"
                        settingsWindow.contentViewController = NSHostingController(
                            rootView: SettingsView(appState: delegate.getAppState())
                        )
                        settingsWindow.makeKeyAndOrderFront(nil)
                        NSApp.activate(ignoringOtherApps: true)
                    }
                }
            )

            Divider()

            // Content
            ZStack {
                if !appState.isAuthenticated {
                    EmptyStateView(type: .notAuthenticated)
                } else if appState.selectedRepositoryIDs.isEmpty {
                    EmptyStateView(type: .noRepositoriesSelected)
                } else if appState.workflowRuns.isEmpty && !appState.isLoading {
                    EmptyStateView(type: .noRuns)
                } else {
                    ScrollView {
                        GlassEffectContainer(spacing: 12) {
                            LazyVStack(spacing: 0) {
                                ForEach(appState.workflowRuns) { run in
                                    RunRowView(run: run)

                                    if run.id != appState.workflowRuns.last?.id {
                                        Divider()
                                            .padding(.leading, 56)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .scrollIndicators(.hidden)
                }

                // Loading overlay
                if appState.isLoading {
                    ZStack {
                        Rectangle()
                            .fill(.ultraThinMaterial)

                        LoadingView(message: "Fetching runs...")
                    }
                    .transition(.opacity)
                }
            }

            // Error banner
            if let error = appState.errorMessage {
                VStack(spacing: 0) {
                    Divider()

                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.orange.opacity(0.2))

                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .font(.caption)

                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.primary)
                                .lineLimit(2)

                            Spacer()

                            Button(action: { appState.errorMessage = nil }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .glassEffect(.regular.tint(.orange), in: .rect(cornerRadius: 6))
                }
            }

            Divider()

            // Footer
            HStack(spacing: 8) {
                if let lastRefresh = appState.lastRefreshDate {
                    Text("Updated \(lastRefresh.relativeTime())")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                if let user = appState.currentUser {
                    HStack(spacing: 4) {
                        Image(systemName: "person.circle.fill")
                            .font(.caption2)
                        Text(user.login)
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
        }
        .frame(width: 350, height: 450)
    }

    private func refresh() {
        guard !isRefreshing else { return }

        withAnimation(.linear(duration: 0.5)) {
            isRefreshing = true
        }

        Task {
            await appState.refreshRuns()

            try? await Task.sleep(nanoseconds: 500_000_000) // Minimum 0.5s for UX

            withAnimation {
                isRefreshing = false
            }
        }
    }
}

// Triangle shape for menu bar pointer
#Preview {
    MenuBarContentView(appState: AppState())
}
