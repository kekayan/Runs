import SwiftUI

@main
struct RunsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Settings window
        Window("Settings", id: "settings") {
            SettingsView(appState: appDelegate.getAppState())
        }
        .defaultSize(width: 600, height: 500)
        .windowResizability(.contentSize)
        .keyboardShortcut(",", modifiers: .command)
    }
}
