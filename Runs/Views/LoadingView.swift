import SwiftUI

struct LoadingView: View {
    var message: String = "Loading..."

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(0.8)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    LoadingView()
        .frame(width: 350, height: 400)
}

#Preview("Custom Message") {
    LoadingView(message: "Fetching workflow runs...")
        .frame(width: 350, height: 400)
}
