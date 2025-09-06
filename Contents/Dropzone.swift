//
//  DropZone.swift
//  SplitUI
//
//  Created by Anthony Chapelon on 16/08/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct Dropzone: View {
    @State private var isTargeted = false
    @State private var isImporterPresented = false
    var text: String = "Drag a file here"
    @Binding var fileURL: URL?
    
    var body: some View {
        ZStack {
            Text(text)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            Button(action: {isImporterPresented = true}) {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [10]))
                    .foregroundColor(isTargeted ? .blue : .gray)
                    .background(Color.gray.opacity(0.06))
                
            }
            .buttonStyle(PlainButtonStyle())
            .fileImporter(
                isPresented: $isImporterPresented,
                allowedContentTypes: [.item],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    self.fileURL = urls.first
                case .failure(let error):
                    print("Erreur : \(error.localizedDescription)")
                }
            }

        }
        .contentShape(Rectangle())
        .onDrop(
            of: [UTType.fileURL.identifier],
            isTargeted: $isTargeted
        ) { providers in
            if let provider = providers.first {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                    if let data = item as? Data,
                       let droppedURL = URL(dataRepresentation: data, relativeTo: nil) {
                        if droppedURL.hasDirectoryPath {
                            return
                        }
                        DispatchQueue.main.async {
                            self.fileURL = droppedURL
                        }
                    }
                }
                return true
            }
            return false
        }
        .padding()
    }
}

#Preview {
    @Previewable @State var fileURL: URL? = URL(fileURLWithPath: "/Users/achapelon/Downloads/GlobalProtect_Linux_6-2-9-c4.tar")
    Dropzone(fileURL: $fileURL)
}
