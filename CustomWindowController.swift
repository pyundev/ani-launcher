import SwiftUI
import AppKit

class CustomWindowController: NSWindowController, NSWindowDelegate {
    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 200), // Start with full height
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // Set up window appearance
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor(white: 0.2, alpha: 0.9)
        window.hasShadow = true
        window.level = .floating
        window.center()
        window.isOpaque = false
        
        // Eliminate title bar space
        if let titlebarController = window.standardWindowButton(.closeButton)?.superview {
            titlebarController.isHidden = true
        }
        
        // Rounded corners
        window.appearance = NSAppearance(named: .darkAqua)
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = 15
        window.contentView?.layer?.masksToBounds = true
        
        // Important: Allow key events to reach the text field
        window.acceptsMouseMovedEvents = true
        window.makeFirstResponder(nil)
        
        super.init(window: window)
        window.delegate = self
        
        let escape = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // ESC key
                self?.window?.orderOut(nil)
                return nil // Consume the event
            }
            return event
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func windowWillClose(_ notification: Notification) {
        NSApp.hide(nil)
    }
    
    // Make sure we can properly interact with the window
    func windowDidBecomeKey(_ notification: Notification) {
        window?.makeFirstResponder(window?.contentView)
    }
    
    func setupFloatingCharacter() {
        let imageView = NSImageView()
        imageView.image = NSImage(named: "anime-girl")
        
        // Position the character to the right side of the search bar
        let characterSize = CGSize(width: 180, height: 200)
        let xPosition: CGFloat = window!.frame.width - characterSize.width + 20
        let yPosition: CGFloat = window!.frame.height - characterSize.height + 10
        
        imageView.frame = NSRect(x: xPosition, y: yPosition, width: characterSize.width, height: characterSize.height)
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.wantsLayer = true
        
        window?.contentView?.addSubview(imageView)
    }
}
