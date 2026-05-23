//
//  File.swift
//  SplitUI
//
//  Created by Anthony Chapelon on 19/08/2025.
//

import SwiftUI
import UniformTypeIdentifiers

class FilesizeFormatter {
    static var formatter: ByteCountFormatter {
        let formatter = ByteCountFormatter()
        formatter.allowsNonnumericFormatting = false // Affiche toujours le chiffre
        return formatter
    }
    
    static func string(fromByteCount byteCount: UInt64) -> String {
        return formatter.string(fromByteCount: Int64(byteCount))
    }
    
    static func string(fromFileURL fileURL: URL) -> String {
        let filesize = FileManager.filesize(for: fileURL)
        return formatter.string(fromByteCount: Int64(filesize))
    }
}

extension FileManager {
    static func filesize(for url: URL) -> UInt64 {
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: url.path)
            return attr[.size] as? UInt64 ?? 0
        } catch {
            return 0
        }
    }
    
    static func filesize(forPath path: String) -> UInt64 {
        return filesize(for: URL(fileURLWithPath: path))
    }

    static func isDirectory(_ url: URL) -> Bool {
        if let values = try? url.resourceValues(forKeys: [.isDirectoryKey]),
           let isDirectory = values.isDirectory {
            return isDirectory
        }

        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    static func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]? = nil , options mask: FileManager.DirectoryEnumerationOptions = []) -> [URL] {
        let fileUrls = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: keys, options: mask)
        return fileUrls ?? []
    }
    
    static func contentsOfDirectory(atPath path: String, matching name: String? = nil) -> [String] {
        let files = try? FileManager.default.contentsOfDirectory(atPath: path)
        guard let name = name else { return files ?? [] }
        return files?.filter { $0.hasPrefix(name) }
            .map { (path as NSString).appendingPathComponent($0) } ?? []
    }
    
    static func splitParts(atPath path: String, templateFilename: String) -> [String] {
        let files = try? FileManager.default.contentsOfDirectory(atPath: path)
        return files?.filter { isSplitPartFilename($0, templateFilename: templateFilename) }
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
            .map { (path as NSString).appendingPathComponent($0) } ?? []
    }
    
    static func removeSplitParts(atPath path: String, templateFilename: String) {
        let files = splitParts(atPath: path, templateFilename: templateFilename)
        for file in files {
            try? FileManager.default.removeItem(atPath: file)
        }
    }
    
    static func appendPathExtensionToSplitParts(_ ext: String, atPath path: String, templateFilename: String) {
        let files = splitParts(atPath: path, templateFilename: templateFilename)
        for file in files {
            guard let newPath = (file as NSString).appendingPathExtension(ext) else { continue }
            try? FileManager.default.moveItem(atPath: file, toPath: newPath)
        }
    }
    
    private static func isSplitPartFilename(_ filename: String, templateFilename: String) -> Bool {
        guard filename.hasPrefix(templateFilename) else { return false }
        var suffix = String(filename.dropFirst(templateFilename.count))
        if suffix.hasPrefix(".part") && suffix.hasSuffix(".split")  {
            suffix.removeFirst(".part".count)
            suffix.removeLast(".split".count)
        }
        return !suffix.isEmpty && suffix.allSatisfy { $0.isNumber }
    }
    
    static func escapePath(_ path: String) -> String {
        let pattern = #"([ '\"])"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: path.utf16.count)
        // Remplacer chaque caractère trouvé par \caractere
        return regex.stringByReplacingMatches(in: path, options: [], range: range, withTemplate: #"\\$1"#)
    }
}

struct FileField: View {
    @State private var isTargeted = false
    @State var label: String
    @State private var isImporterPresented: Bool = false
    @Binding var url: URL?
    
    init(_ url: Binding<URL?>, label: String = "File") {
        self._url = url
        self.label = label
    }
    
    var body: some View {
        HStack {
                Text("\(label):")
                    .frame(height: 22)
                ZStack {
                    TextField("", text: .constant(""))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(true)

                    HStack(spacing: 8) {
                        fileView
                        
                        Spacer()
                        
                        fileActionButtons
                    } // HStack
                    //.padding(.vertical, 2)
                    .padding(.horizontal, 8)
                    //.frame(height: 20)
                } // ZStack
                .overlay {
                    if isTargeted {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.accentColor, lineWidth: 2)
                            .padding(1)
                    }
                }
                .onDrop(
                    of: [UTType.fileURL.identifier],
                    isTargeted: $isTargeted,
                    perform: handleDrop
                )
        } // HStack
    } // View
    
    private var fileActionButtons: some View {
        HStack(spacing: 8) {
            if let url = url {
                Button(action: {isImporterPresented = true}) {
                    let imageName = FileManager.isDirectory(url) ? "folder.fill" : "doc.fill"
                    Image(systemName: imageName)
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                }
                .fileImporter(
                    isPresented: $isImporterPresented,
                    allowedContentTypes: FileManager.isDirectory(url) ? [.folder] : [.item],
                    allowsMultipleSelection: false
                ) { result in
                    switch result {
                    case .success(let urls):
                        self.url = urls.first
                    case .failure(let error):
                        print("Erreur : \(error.localizedDescription)")
                    }
                }
                .buttonStyle(PlainButtonStyle())
                Button(action: {self.url = nil}) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var fileView: some View {
        HStack(spacing: 8) {
            if let url = url {
                Image(iconForFile: url.path)
                    .resizable()
                    .frame(width: 16, height: 16)
                // File name
                Text(url.lastPathComponent)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundColor(.primary)
            }
        }
    }
    
    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        let fileProviders = providers.filter { provider in
            provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier)
        }

        guard !fileProviders.isEmpty else { return false }

        if let provider = providers.first {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                if let data = item as? Data,
                   let droppedURL = URL(dataRepresentation: data, relativeTo: nil) {
                    DispatchQueue.main.async {
                        self.url = droppedURL
                    }
                }
            }
            return true
        }
        return false
    }
    
} // Struct

struct TemplateFilenameField: View {
    @Binding var value: String
    var label: String = "Template filename"
    
    var body: some View {
        HStack {
            Text("\(label):")
            TextField("", text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct FilesizeField: View {
    @Binding var url: URL?
    
    init(_ url: Binding<URL?>) {
        self._url = url
    }
    var body: some View {
        if let url = url {
            Text("File size: \(FilesizeFormatter.string(fromFileURL: url))")
        }
    }
}

#Preview {
    @Previewable @State var fileURL: URL? = URL(fileURLWithPath: "/Volumes/Data/Cyberpunk.2077.v2.3.dmg")
    @Previewable @State var templateFilename: String = "Cyberpunk.2077.v2.3.dmg"
    VStack(alignment: .leading, spacing: 12) {
        FileField($fileURL)
        FilesizeField($fileURL)
        TemplateFilenameField(value: $templateFilename)
    }
    .padding()

 }
