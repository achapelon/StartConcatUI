//
//  ListView.swift
//  SplitUI
//
//  Created by Anthony Chapelon on 31/08/2025.
//

import SwiftUI

struct FileListView: View {
    @Binding var files: [URL]
    @State private var selection: URL?
    @State private var isImporterPresented: Bool = false
    
    var cornerRadius: CGFloat = 12
    
    var body: some View {
        partsList
            .safeAreaInset(edge: .bottom, spacing: 0) {
                listToolbar
            }
    }

    private var partsList: some View {
        List(files, id: \.self, selection: $selection) { file in
            HStack {
                Image(iconForFile: file.path)
                    .resizable()
                    .frame(width: 24, height: 24)
                Text(file.lastPathComponent)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 2)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(
            Color(white: 0.97)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: cornerRadius,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: cornerRadius
                    )
                )
        )
    }
    
    private var listToolbar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                Button(action: {isImporterPresented = true}) {
                    Image(systemName: "plus")
                        .font(.system(size: 11))
                        .bold(true)
                }
                .buttonStyle(BorderlessButtonStyle())
                .fileImporter(
                    isPresented: $isImporterPresented,
                    allowedContentTypes: [.item],
                    allowsMultipleSelection: true
                ) { result in
                    switch result {
                    case .success(let urls):
                        self.files.append(contentsOf: urls)
                    case .failure(let error):
                        print("Error: \(error)")
                    }
                }
                
                Divider()
                    .frame(height: 14)
                
                Button(action: remove) {
                    Image(systemName: "minus")
                        .font(.system(size: 11))
                }
                .buttonStyle(BorderlessButtonStyle())
                
                Divider()
                    .frame(height: 14)
                
                Text("\(files.count) parts")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(5.5)
            .background(
                Color(white: 0.94)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: cornerRadius,
                            bottomTrailingRadius: cornerRadius,
                            topTrailingRadius: 0
                        )
                    )
            )
        }
    }
    
    func remove() {
        if let selected = selection, let index = files.firstIndex(of: selected) {
            files.remove(at: index)
            selection = nil
        }
    }
}

#Preview {
    @Previewable @State var files: [URL] = [
        URL(filePath: "/path/to/file1.txt"),
        URL(filePath: "/path/to/file2.txt")
    ]
    FileListView(files: $files)
        .padding()
}
