import SwiftUI

struct EmptyStateView: View {
    enum EmptyStateType {
        case noRepositoriesSelected
        case noRuns
        case notAuthenticated

        var icon: String {
            switch self {
            case .noRepositoriesSelected: return "folder.badge.plus"
            case .noRuns: return "tray"
            case .notAuthenticated: return "person.crop.circle.badge.exclamationmark"
            }
        }

        var title: String {
            switch self {
            case .noRepositoriesSelected: return "No Repositories Selected"
            case .noRuns: return "No Recent Runs"
            case .notAuthenticated: return "Not Logged In"
            }
        }

        var message: String {
            switch self {
            case .noRepositoriesSelected:
                return "Open settings to select repositories to monitor"
            case .noRuns:
                return "No workflow runs found for selected repositories"
            case .notAuthenticated:
                return "Please log in with GitHub to view your workflow runs"
            }
        }
    }

    let type: EmptyStateType

    var body: some View {
        VStack(spacing: 20) {
            // Icon with glass effect
            ZStack {
                Circle()
                    .fill(.quaternary.opacity(0.5))

                Image(systemName: type.icon)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 80, height: 80)
            .glassEffect(.regular, in: .circle)

            VStack(spacing: 8) {
                Text(type.title)
                    .font(.headline.weight(.semibold))

                Text(type.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(40)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial.opacity(0.5))
        }
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview("No Repositories") {
    EmptyStateView(type: .noRepositoriesSelected)
        .frame(width: 350, height: 400)
}

#Preview("No Runs") {
    EmptyStateView(type: .noRuns)
        .frame(width: 350, height: 400)
}

#Preview("Not Authenticated") {
    EmptyStateView(type: .notAuthenticated)
        .frame(width: 350, height: 400)
}
