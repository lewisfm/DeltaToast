//
//  DeltaToastApp.swift
//  DeltaToast
//
//  Created by Lewis McClelland on 8/12/25.
//

import SwiftUI
import os
import Observation

let logger = Logger(subsystem: "me.lewismcclelland.DeltaToast", category: "DeltaToast")

@main
struct DeltaToastApp: App {
    @NSApplicationDelegateAdaptor(DTAppDelegate.self) var delegate
    @Environment(\.openSettings) var openSettings
    @State private var settings = DTSettings.shared
    
    init() {
        delegate.openSettings = openSettings
    }

    var body: some Scene {
        Settings {
            DTSettingsView()
        }
        .onChange(of: settings.windowSharingType) {
            delegate.setWindowSharingType(settings.windowSharingType)
        }
    }
}

@MainActor
class DTAppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var shouldReopenTriggerSettings = false
    var openSettings: OpenSettingsAction?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
#if DEBUG
        NSApp.setActivationPolicy(.regular)
#endif
        
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
        
        setWindowSharingType(DTSettings.shared.windowSharingType)
        
        if let screen = window.screen ?? NSScreen.main {
            window.setFrame(screen.visibleFrame, display: true, animate: false)
        }
        
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.shouldReopenTriggerSettings = true
        }
    }
    
    func setWindowSharingType(_ type: NSWindow.SharingType) {
        window.sharingType = type
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if shouldReopenTriggerSettings {
            self.openSettings?()
        }
        return false
    }
}
