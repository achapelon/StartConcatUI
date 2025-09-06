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
    
    static func removeItems(atPath path: String, matching name: String? = nil) {
        let files = contentsOfDirectory(atPath: path, matching: name)
        for file in files {
            try? FileManager.default.removeItem(atPath: file)
        }
    }
    
    static func appendingPathExtensionToItems(extension ext: String, atPath path: String, matching name: String? = nil) {
        let files = contentsOfDirectory(atPath: path, matching: name)
        for file in files {
            let newPath = (file as NSString).appendingPathExtension(ext) ?? ""
            try? FileManager.default.moveItem(atPath: file, toPath: newPath)
        }
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
    @State var label: String = "File"
    @State private var text: String = ""
    @State private var isImporterPresented: Bool = false
    @Binding var url: URL?
    
    var body: some View {
        HStack {
            if let url = url {
                Text("\(label):")
                    .frame(height: 22)
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.accentColor, lineWidth: 2)
                        .opacity(isTargeted ? 1 : 0)
                        .frame(height: 22)
                    TextField("", text: $text)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(true)
                    //.focusable(false)
                    HStack(spacing: 8) {
                        // File icon
                        Image(iconForFile: url.path)
                            .resizable()
                            .frame(width: 16, height: 16)
                        // File name
                        Text(url.lastPathComponent)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .foregroundColor(.primary)
                        
                        // Action button
                        Spacer()
                        Button(action: {isImporterPresented = true}) {
                            Image(systemName: "doc.fill")
                                .foregroundColor(.gray)
                                .font(.system(size: 14))
                        }
                        .fileImporter(
                            isPresented: $isImporterPresented,
                            allowedContentTypes: [.item],
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
                    } // HStack
                    .padding(.vertical, 2)
                    .padding(.horizontal, 8)
                    .frame(height: 20)
                } // ZStack
                .onDrop(
                    of: [UTType.fileURL.identifier],
                    isTargeted: $isTargeted
                ) { providers in
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
            } // if url
        } // HStack
    } // View
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
    var body: some View {
        if let url = url {
            Text("File size: \(FilesizeFormatter.string(fromFileURL: url))")
        }
        
    }
}

#Preview {
    @Previewable @State var fileURL: URL? = URL(fileURLWithPath: "/Volumes/Data/Cyberpunk.2077.v2.3.dmg")
    @Previewable @State var templateFilename: String = "Cyberpunk.2077.v2.3.dmg"
    FileField(url: $fileURL)
    FilesizeField(url: $fileURL)
    TemplateFilenameField(value: $templateFilename)
}
