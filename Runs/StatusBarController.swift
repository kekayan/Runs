import Cocoa
import SwiftUI

class StatusBarController: NSObject, NSPopoverDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var appState: AppState
    private var refreshService: RefreshService
    private var eventMonitor: EventMonitor?
    
    init(appState: AppState, refreshService: RefreshService) {
        self.appState = appState
        self.refreshService = refreshService
        super.init()
        setupStatusBar()
    }
    
    private func setupStatusBar() {
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let button = statusItem?.button else {
            print("ERROR: Failed to create status bar button")
            return
        }
        
        // Set the status bar icon with template rendering for proper dark mode support
        if let image = NSImage(systemSymbolName: "bolt.circle", accessibilityDescription: "Runs") {
            image.size = NSSize(width: 18, height: 18)
            image.isTemplate = true
            button.image = image
        }
        button.imagePosition = .imageOnly
        button.action = #selector(togglePopover)
        button.target = self
        button.toolTip = "Runs"
        
        print("Status bar item created successfully")
        
        // Create popover with default appearance for vibrant colors
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 350, height: 450)
        popover?.behavior = .transient
        popover?.delegate = self
        
        // Set the content view controller with SwiftUI
        let contentView = MenuBarContentView(appState: appState)
        
        let hostingController = NSHostingController(rootView: contentView)
        popover?.contentViewController = hostingController
        
        // Setup event monitor to close popover when clicking outside
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let strongSelf = self, strongSelf.popover?.isShown == true {
                strongSelf.closePopover()
            }
        }
    }
    
    @objc private func togglePopover() {
        if let popover = popover, popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }
    
    private func showPopover() {
        guard let button = statusItem?.button else { return }
        
        // Setup OAuth callback
        AppDelegate.shared?.setURLCallback { [weak self] url in
            Task {
                await self?.appState.handleOAuthCallback(url)
                
                // Start auto-refresh after successful login
                if self?.appState.isAuthenticated == true {
                    self?.refreshService.start {
                        await self?.appState.refreshRuns()
                    }
                }
            }
        }
        
        // Start auto-refresh if already authenticated
        if appState.isAuthenticated {
            refreshService.start {
                await self.appState.refreshRuns()
            }
        }
        
        popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        eventMonitor?.start()
    }
    
    private func closePopover() {
        popover?.close()
        eventMonitor?.stop()
    }
    
    func popoverDidClose(_ notification: Notification) {
        eventMonitor?.stop()
    }
}

// Event monitor to detect clicks outside the popover
class EventMonitor: NSObject {
    private var monitor: Any?
    private let mask: NSEvent.EventTypeMask
    private let handler: (NSEvent?) -> Void
    
    init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent?) -> Void) {
        self.mask = mask
        self.handler = handler
    }
    
    deinit {
        stop()
    }
    
    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
    }
    
    func stop() {
        if monitor != nil {
            NSEvent.removeMonitor(monitor!)
            monitor = nil
        }
    }
}
