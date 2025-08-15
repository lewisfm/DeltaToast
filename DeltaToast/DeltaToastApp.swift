//
//  DeltaToastApp.swift
//  DeltaToast
//
//  Created by Lewis McClelland on 8/12/25.
//

import SwiftUI

@main
struct DeltaToastApp: App {
    @NSApplicationDelegateAdaptor(DTAppDelegate.self) var delegate
    @Environment(\.openSettings) var openSettings
    
    init() {
        delegate.openSettings = openSettings
    }

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class DTAppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var shouldReopenTriggerSettings = false
    var openSettings: OpenSettingsAction?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // set content to custom View
        let contentView = ContentView()
        window.contentView = NSHostingView(rootView: contentView)
        
        window.isOpaque = false
        window.backgroundColor = .clear
        
        window.ignoresMouseEvents = true
        window.level = .statusBar
        window.collectionBehavior = [.canJoinAllSpaces, .transient]
        
        if let screen = window.screen ?? NSScreen.main {
            window.setFrame(screen.visibleFrame, display: true, animate: false)
        }
        
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        
        DispatchQueue.main.async {
            self.shouldReopenTriggerSettings = true
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
//        @Environment(\.openSettings) var openSettings
        
        if shouldReopenTriggerSettings {
            print("reopen")
            self.openSettings?()
//            openSettings()
        }
        return false
    }
}
