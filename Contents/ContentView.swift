//
//  ContentView.swift
//  SplitUI
//
//  Created by Anthony Chapelon on 15/08/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Binding var fileURL: URL?
    
    var body: some View {
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
}

#Preview {
    ContentView(fileURL: .constant(nil))
}
