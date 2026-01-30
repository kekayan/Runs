import SwiftUI

struct AuthenticationSection: View {
    @State private var appState: AppState
    
    init(appState: AppState) {
        self._appState = State(initialValue: appState)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Authentication", systemImage: "person.circle")
                .font(.headline)

            if appState.isAuthenticated {
                authenticatedView
            } else {
                unauthenticatedView
            }
        }
    }

    @ViewBuilder
    private var authenticatedView: some View {
        if let user = appState.currentUser {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.green.opacity(0.15))

                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Logged in as \(user.login)")
                            .font(.subheadline.weight(.medium))

                        if let name = user.name {
                            Text(name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Button("Logout") {
                        appState.logout()
                    }
                    .buttonStyle(.glass)
                    .controlSize(.small)
                }
                .padding()
            }
            .glassEffect(.regular.tint(.green), in: .rect(cornerRadius: 8))
        }
    }

    private var unauthenticatedView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.blue.opacity(0.15))

            VStack(alignment: .leading, spacing: 12) {
                Text("Connect your GitHub account to monitor workflow runs")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button(action: { appState.login() }) {
                    HStack {
                        Image(systemName: "person.badge.key")
                        Text("Login with GitHub")
                    }
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
            }
            .padding()
        }
        .glassEffect(.regular.tint(.blue), in: .rect(cornerRadius: 8))
    }
}
