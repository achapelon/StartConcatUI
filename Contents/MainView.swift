//
//  ContentView.swift
//  SplitUI
//
//  Created by Anthony Chapelon on 15/08/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct MainView: View {
    @EnvironmentObject private var model: SplitConcatModel
    
    var body: some View {
        Group {
            switch model.operation {
            case .concat:
                SplitConcatView(operation: .concat)
            case .split:
                SplitConcatView(operation: .split)
            case nil:
                Dropzone("Drag and drop a file here")
            }
        }
        .onChange(of: model.sourceURL) {
            // Mise à jour dynamique du titre de la fenêtre
            NSApp.mainWindow?.title = model.windowTitle
        }
    }
}

#Preview {
    MainView()
        .environmentObject(SplitConcatModel())
}
