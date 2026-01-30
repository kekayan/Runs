import SwiftUI

struct SettingsView: View {
    @State private var appState: AppState
    @State private var searchText = ""
    
    init(appState: AppState) {
        self._appState = State(initialValue: appState)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)

                Text("Settings")
                    .font(.title2.weight(.semibold))

                Spacer()
            }
            .padding()
            .background(.ultraThinMaterial)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Authentication Section
                    AuthenticationSection(appState: appState)

                    if appState.isAuthenticated {
                        Divider()

                        // Repository Selection Section
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Repositories", systemImage: "folder.badge.gearshape")
                                .font(.headline)

                            Text("Select repositories to monitor")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            // Search field
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.secondary)

                                TextField("Search repositories", text: $searchText)
                                    .textFieldStyle(.plain)

                                if !searchText.isEmpty {
                                    Button(action: { searchText = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(8)
                            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))

                            // Repository list
                            if appState.repositories.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "tray")
                                        .font(.largeTitle)
                                        .foregroundStyle(.secondary)

                                    Text("No repositories found")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 32)
                            } else {
                                VStack(spacing: 4) {
                                    ForEach(filteredRepositories) { repo in
                                        RepositoryRow(
                                            repository: repo,
                                            isSelected: appState.isRepositorySelected(repo.id)
                                        ) {
                                            appState.toggleRepositorySelection(repo.id)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)

                                if filteredRepositories.isEmpty {
                                    Text("No repositories match '\(searchText)'")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                }
                            }

                            if appState.selectedRepositoryIDs.count > 0 {
                                Text("\(appState.selectedRepositoryIDs.count) repository(ies) selected")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 4)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 600, height: 500)
    }

    private var filteredRepositories: [Repository] {
        if searchText.isEmpty {
            return appState.repositories
        } else {
            return appState.repositories.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.fullName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

struct RepositoryRow: View {
    let repository: Repository
    let isSelected: Bool
    let onToggle: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .font(.system(size: 16))

                VStack(alignment: .leading, spacing: 2) {
                    Text(repository.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)

                    Text(repository.fullName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if repository.isPrivate {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.primary.opacity(0.05) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    SettingsView(appState: AppState())
}
