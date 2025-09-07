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
    @State private var fileURL: URL? = nil
    
    var body: some Scene {
        WindowGroup {
            ContentView(fileURL: $fileURL)
                .onAppear {
                    fileURL = appDelegate.url
                }
        }
        .defaultSize(width: 500, height: 375)
    }
}
class AppDelegate: NSObject, NSApplicationDelegate {
    var url: URL?
    
    func application(_ application: NSApplication, open urls: [URL]) {
        url = urls.first
    }
}
