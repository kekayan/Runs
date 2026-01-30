import SwiftUI
import AppKit

struct RunRowView: View {
    let run: WorkflowRun
    @State private var showCopiedFeedback = false
    @State private var isHovered = false

    var body: some View {
        Button(action: copyRunURL) {
            HStack(spacing: 12) {
                // Status icon
                ZStack {
                    Circle()
                        .fill(run.statusColor)

                    Image(systemName: run.statusIcon)
                        .foregroundStyle(.white)
                        .font(.system(size: 14, weight: .bold))
                }
                .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 4) {
                    // Repository name
                    Text(run.repository.name)
                        .font(.system(.body, design: .default, weight: .medium))
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        // Commit SHA with Liquid Glass
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.quaternary)

                            Text(run.shortCommitSha)
                                .font(.system(.caption, design: .monospaced, weight: .semibold))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                        }
                        .fixedSize()
                        .glassEffect(.regular, in: .rect(cornerRadius: 4))

                        Text("•")
                            .foregroundStyle(.tertiary)

                        // Relative time
                        Text(run.createdAt.relativeTime())
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if showCopiedFeedback {
                            Text("•")
                                .foregroundStyle(.tertiary)

                            ZStack {
                                Capsule()
                                    .fill(.green.opacity(0.25))

                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption2)
                                    Text("Copied!")
                                        .font(.caption.weight(.semibold))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                            }
                            .fixedSize()
                            .glassEffect(.regular.tint(.green), in: .capsule)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                }

                Spacer()

                // Status badge
                ZStack {
                    Capsule()
                        .fill(run.statusColor)

                    Text(run.displayStatus)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                }
                .fixedSize()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.primary.opacity(0.05) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }

    private func copyRunURL() {
        NSPasteboard.general.clearContents()

        // For successful jobs, copy the 5-char hash
        // For failed/in-progress jobs, copy the run link
        let contentToCopy: String
        if run.status == .completed && run.conclusion == .success {
            contentToCopy = run.shortCommitSha
        } else {
            contentToCopy = run.htmlUrl
        }

        NSPasteboard.general.setString(contentToCopy, forType: .string)

        // Show feedback
        withAnimation(.spring(response: 0.3)) {
            showCopiedFeedback = true
        }

        // Hide feedback after 2 seconds
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation(.spring(response: 0.3)) {
                showCopiedFeedback = false
            }
        }
    }
}
