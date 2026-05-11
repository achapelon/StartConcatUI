//
//  SplitUIApp.swift
//  SplitUI
//
//  Created by Anthony Chapelon on 15/08/2025.
//

import SwiftUI

@main
struct SplitConcatUIApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 500, height: 375)
        .handlesExternalEvents(matching: []) // ✅ WindowGroup n'intercepte plus rien
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var openedWindows: [NSWindow] = []
    
    func application(_ application: NSApplication, open urls: [URL]) {
        guard !urls.isEmpty else { return }
        open(urls)
    }
    
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        openedWindows.removeAll { $0 == window }
    }
    
    private func open(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        for url in urls {
            openWindow(for: url)
        }
    }
    
    private func openWindow(for url: URL) {
        let rootView = ContentView(fileURL: url)
        let window = NSWindow(contentViewController: NSHostingController(rootView: rootView))
        window.title = url.lastPathComponent
        window.setContentSize(NSSize(width: 500, height: 375))
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.isReleasedWhenClosed = false
        window.delegate = self
        
        if openedWindows.isEmpty {
            window.center() // première fenêtre centrée
        } else {
            // Décaler par rapport à la dernière fenêtre ouverte
            let last = openedWindows.last!
            let origin = last.frame.origin
            window.setFrameOrigin(NSPoint(
                x: origin.x + 30,
                y: origin.y - 30  // y inversé sur macOS — moins = plus bas
            ))
        }
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        openedWindows.append(window)
    }
}
