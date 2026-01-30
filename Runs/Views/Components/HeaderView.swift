import SwiftUI
import AppKit

struct MenuBarHeaderView: View {
    let isRefreshing: Bool
    let isAuthenticated: Bool
    let onRefresh: () -> Void
    let onSettings: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bolt.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(.blue)

            Text("GitHub Actions")
                .font(.headline)

            Spacer()

            // Refresh button
            HeaderIconButton(
                icon: "arrow.clockwise",
                isDisabled: isRefreshing || !isAuthenticated,
                rotation: isRefreshing ? 360 : 0,
                action: onRefresh
            )
            .help("Refresh runs")

            // Settings button
            HeaderIconButton(
                icon: "gearshape",
                action: onSettings
            )
            .help("Settings")

            // Quit button
            HeaderIconButton(
                icon: "xmark.circle",
                action: { NSApplication.shared.terminate(nil) }
            )
            .help("Quit")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}

struct HeaderIconButton: View {
    let icon: String
    var isDisabled: Bool = false
    var rotation: Double = 0
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(isDisabled ? .tertiary : (isHovered ? .primary : .secondary))
                .rotationEffect(.degrees(rotation))
                .frame(width: 20, height: 20)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
            if hovering && !isDisabled {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
