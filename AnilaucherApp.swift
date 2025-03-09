import SwiftUI
import AppKit
import HotKey

@main
struct AnilauncherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: CustomWindowController?
    var statusItem: NSStatusItem?
    var hotKey: HotKey?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the status bar item
        setupStatusBar()
        
        // Set up the global hotkey
        setupHotKey()
        
        // Create and configure the window controller
        windowController = CustomWindowController()
        
        // Set up the content view
        let contentView = ContentView()
        let hostingView = NSHostingView(rootView: contentView)
        windowController?.window?.contentView = hostingView
        
        // Adjust content insets to reduce extra space
        if let window = windowController?.window {
            window.contentView?.setFrameOrigin(NSPoint(x: 0, y: 0))
            hostingView.setFrameOrigin(NSPoint(x: 0, y: 0))
        }
        
        // Add the anime character
        windowController?.setupFloatingCharacter()
        
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Set up observer for when an action is executed
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hideWindowAfterAction),
            name: NSNotification.Name("ActionExecuted"),
            object: nil
        )
        
        
    }
    
    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Use an image instead of text
            button.image = NSImage(named: NSImage.Name("StatusBarButtonImage"))
            // If you don't have a custom image, use a system symbol
            if button.image == nil {
                button.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: nil)
            }
            button.action = #selector(toggleWindow)
            button.target = self
        }
        
        // Create menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu
        
        // Right-click shows menu, left-click toggles window
        if let button = statusItem?.button {
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    func setupHotKey() {
        hotKey = HotKey(key: .space, modifiers: [.option])
        hotKey?.keyDownHandler = { [weak self] in
            self?.toggleWindow()
        }
    }
    
    @objc func toggleWindow() {
        if let window = windowController?.window {
            if window.isVisible {
                hideWindow()
            } else {
                showWindow()
            }
        }
    }
    
    func showWindow() {
        windowController?.window?.center()
        windowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Focus the search field when window appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(name: NSNotification.Name("FocusSearchField"), object: nil)
        }
    }
    
    func hideWindow() {
        windowController?.window?.orderOut(nil)
    }
    
    @objc func hideWindowAfterAction() {
        hideWindow()
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}
