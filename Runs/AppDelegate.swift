import os
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?

    let appState = AppState()
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        NSApp.setActivationPolicy(.accessory)
        statusBarController = StatusBarController(appState: appState)
        Log.app.info("Launched")
    }

    func getAppState() -> AppState { appState }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false // Keep running in the menu bar when Settings closes
    }
}
