//
//  ContentView.swift
//  SplitUI
//
//  Created by Anthony Chapelon on 15/08/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var fileOpener: FileOpener
    @State var fileURL: URL?
    
    var body: some View {
        Group {
            if let url = fileURL {
                let ext = url.pathExtension
                if ext == "split" {
                    ConcatView(fileURL: $fileURL)
                } else {
                    SplitView(fileURL: $fileURL)
                }
            } else {
                Dropzone(text: "Drag and drop a file here", fileURL: $fileURL)
            }
        }
        .onChange(of: fileOpener.url) {
            if fileURL != nil { return }
            fileURL = fileOpener.url
        }
    }
}

#Preview {
    ContentView()
}
