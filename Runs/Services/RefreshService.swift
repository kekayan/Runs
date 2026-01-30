import Foundation
import Combine

class RefreshService {
    private var timer: Timer?
    private let interval: TimeInterval
    private var refreshTask: (() async -> Void)?

    init(interval: TimeInterval = GitHubConstants.refreshInterval) {
        self.interval = interval
    }

    // Start auto-refresh timer
    func start(refreshTask: @escaping () async -> Void) {
        self.refreshTask = refreshTask
        stop() // Stop any existing timer

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task {
                await self.refreshTask?()
            }
        }

        // Ensure timer runs even when menu is open
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }

        print("Auto-refresh started with interval: \(interval) seconds")
    }

    // Stop auto-refresh timer
    func stop() {
        timer?.invalidate()
        timer = nil
        print("Auto-refresh stopped")
    }

    // Check if timer is running
    var isRunning: Bool {
        timer != nil
    }

    deinit {
        stop()
    }
}
