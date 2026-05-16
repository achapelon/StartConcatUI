//
//  ListView.swift
//  SplitUI
//
//  Created by Anthony Chapelon on 31/08/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct FileListView: View {
    @Binding var files: [URL]
    @State private var selection: URL?
    @State private var isImporterPresented: Bool = false
    @State private var isDropTargeted: Bool = false
    
    var cornerRadius: CGFloat = 12
    
    var body: some View {
        partsList
            .safeAreaInset(edge: .bottom, spacing: 0) {
                listToolbar
            }
    }

    private var partsList: some View {
        List {
            ForEach(files, id: \.self) { file in
                fileRow(for: file)
            }
            .onMove { source, destination in
                files.move(fromOffsets: source, toOffset: destination)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentShape(Rectangle())
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
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.blue, lineWidth: 2)
                    .padding(1)
            }
        }
        .onDrop(
            of: [UTType.fileURL.identifier],
            isTargeted: $isDropTargeted,
            perform: handleDrop
        )
    }

    private func fileRow(for file: URL) -> some View {
        let isSelected = selection == file
        let textColor: Color = isSelected ? .white : .gray
        let fileSize = FilesizeFormatter.string(fromFileURL: file)

        return HStack(alignment: .center) {
            Image(iconForFile: file.path)
                .resizable()
                .frame(width: 24, height: 24)
            Text(file.lastPathComponent)
                .foregroundColor(textColor)
            Text("(\(fileSize))")
                .foregroundColor(textColor)
            Spacer()
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .background(rowBackground(isSelected: isSelected))
        .onTapGesture { selection = file }
    }

    private func rowBackground(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(isSelected ? Color.accentColor : Color.clear)
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
                        appendFiles(urls)
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
    
    private func appendFiles(_ urls: [URL]) {
        files.append(contentsOf: urls.filter { !$0.hasDirectoryPath })
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        let fileProviders = providers.filter { provider in
            provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier)
        }

        guard !fileProviders.isEmpty else { return false }

        for provider in fileProviders {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                guard error == nil,
                      let data = item as? Data,
                      let droppedURL = URL(dataRepresentation: data, relativeTo: nil),
                      !droppedURL.hasDirectoryPath else {
                    return
                }

                DispatchQueue.main.async {
                    appendFiles([droppedURL])
                }
            }
        }

        return true
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
