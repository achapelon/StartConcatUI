//
//  SplitUIApp.swift
//  SplitUI
//
//  Created by Anthony Chapelon on 15/08/2025.
//

import SwiftUI

class FileOpener: ObservableObject {
    @Published var url: URL? = nil
}

@main
struct SplitConcatUIApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var fileOpener = FileOpener()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(fileOpener)
                .onAppear {
                    appDelegate.fileOpener = fileOpener
                }
        }
        .defaultSize(width: 500, height: 375)
    }
}
class AppDelegate: NSObject, NSApplicationDelegate {
    weak var fileOpener: FileOpener?
    
    func application(_ application: NSApplication, open urls: [URL]) {
        fileOpener?.url = urls.first
    }
}
