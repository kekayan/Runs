import Foundation
import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?

    private var urlCallback: ((URL) -> Void)?
    private var pendingURL: URL?
    private var statusBarController: StatusBarController?
    private var appState = AppState()
    private var refreshService = RefreshService()

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self

        // Set activation policy to accessory (menu bar app) - MUST be first
        NSApp.setActivationPolicy(.accessory)

        // Register for URL events (OAuth callback)
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )

        // Setup status bar
        statusBarController = StatusBarController(appState: appState, refreshService: refreshService)

        print("AppDelegate initialized and registered for URL events")
    }

    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: urlString) else {
            print("Invalid URL in event")
            return
        }

        print("Received URL event: \(url)")

        // If callback is set, call it immediately
        if let callback = urlCallback {
            callback(url)
        } else {
            // Otherwise, store for later
            print("No callback set yet, storing URL for later")
            pendingURL = url
        }
    }

    func setURLCallback(_ callback: @escaping (URL) -> Void) {
        print("Setting URL callback")
        self.urlCallback = callback

        // If we have a pending URL, process it now
        if let pending = pendingURL {
            print("Processing pending URL: \(pending)")
            callback(pending)
            pendingURL = nil
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup if needed
        NSAppleEventManager.shared().removeEventHandler(
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }
    
    func getAppState() -> AppState {
        return appState
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep app running when settings window is closed
        return false
    }
}
