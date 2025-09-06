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
    
    var body: some View {
        VStack(spacing: 0) {
            List(files, id: \.self, selection: $selection) { file in
                HStack (alignment: .center) {
                    Image(iconForFile: file.path)
                    Text(file.lastPathComponent)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 2)
            }
            .listStyle(PlainListStyle())
            .scrollContentBackground(.hidden)
            .background(
                Color(white: 0.95)
                    .clipShape(
                        RoundedCornersShape(radius: 8, corners: [.topLeft, .topRight])
                    )
            )
            
            Divider()
              
            HStack {
                Button(action: {isImporterPresented = true}) {
                    Image(systemName: "plus")
                        .font(.system(size: 12))
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
                        .font(.system(size: 12))
                }
                .buttonStyle(BorderlessButtonStyle())
                Spacer()
            }
            .padding(5.5)
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2))
                .background(Color.gray.opacity(0.1).cornerRadius(8))
        )
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
}
