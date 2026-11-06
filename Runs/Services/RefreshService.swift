import os
import Foundation

/// Runs a refresh closure on a fixed interval until stopped.
@MainActor
class RefreshService {
    private var loop: Task<Void, Never>?
    private let interval: TimeInterval

    init(interval: TimeInterval = 300) {
        self.interval = interval
    }

    var isRunning: Bool { loop != nil }

    func start(_ refresh: @escaping @MainActor () async -> Void) {
        stop()
        loop = Task { [interval] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled else { break }
                await refresh()
            }
        }
        Log.app.debug("Auto-refresh started (\(self.interval)s)")
    }

    func stop() {
        loop?.cancel()
        loop = nil
    }
}
