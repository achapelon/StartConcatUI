//
//  SplitView.swift
//  SplitUI
//
//  Created by Anthony Chapelon on 16/08/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct ConcatView: View {
    @StateObject private var progress: Progress = Progress()
    @Binding var fileURL: URL?
    
    @State private var destFolder: URL?
    @State private var destFilename: String = ""
    @State private var destFilesize: UInt64 = 0
    @State private var files: [URL] = []
    @State private var showTermination: Bool = false
    @State private var showConfirmation: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            FileField(url: $fileURL)
                .onAppear {
                    parseSourceUrl(at: fileURL)
                }
                .onChange(of: fileURL) {
                    parseSourceUrl(at: fileURL)
                }
            FilesizeCatField(filesize: $destFilesize)
            FileField(label: "Folder destination", url: $destFolder)
                .onChange(of: destFolder) {
                    if let url = fileURL, destFolder == nil {
                        destFolder = url.deletingLastPathComponent()
                        return
                    }
                    if let url = destFolder, !url.hasDirectoryPath {
                        destFolder = url.deletingLastPathComponent()
                    }
                }

            Text("Destination file: \(destFilename)")
            FileListView(files: $files)
            Spacer()
            if progress.isRunning {
                ProgressView(value: progress.value)
                    .progressViewStyle(LinearProgressViewStyle())
                    .disabled(progress.value == 0.0)
                Text(progress.message)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, -10)
            }
            Button(progress.isRunning ? "Cancel" : "Concatenate") {
                if progress.isRunning {
                    progress.terminateProcess()
                } else {
                    guard let destFolder = destFolder else { return }
                    let file = destFolder.appending(path: destFilename)
                    if (FileManager.default.fileExists(atPath: file.path)) {
                        showConfirmation = true
                        return
                    }
                    startConcat()
                }
            }
            .confirmationDialog("Overwrite existing files?", isPresented: $showConfirmation) {
                Button("Overwrite", role: .destructive) {
                    removeDestinationFile()
                    startConcat()
                }
                .keyboardShortcut(.defaultAction)
                Button("Cancel", role: .cancel) { }
            }
            .alert(progress.isFinished ? "Finished" : "Canceled", isPresented: $showTermination) {
                Button("OK") {
                    // Remove temporary file on Cancel
                    if (!progress.isFinished) {
                        removeDestinationFile()
                    }
                }
            } message: {
                Text(progress.isFinished ? "The file has been concatenated successfully." : "The concatenation has been canceled.")
            }
            .buttonStyle(.borderedProminent)
            .disabled(fileURL == nil || destFilename.isEmpty || destFolder == nil)
            .padding(.top, 10)

        }
        .padding()
    }
    
    func removeDestinationFile() {
        guard let destFolder = destFolder else { return }
        let file = destFolder.appending(path: destFilename)
        try? FileManager.default.removeItem(at: file)
    }
    
    func cancel() {
        progress.terminateProcess()
        showTermination = true
    }
    
    func startConcat() {
        guard let destFolder = destFolder else { return }
            
        let destination = destFolder.appendingPathComponent(destFilename)
        
        progress.setProcessConcat(sources: files, destination: destination)
        progress.runProcess()
        
        guard let process = progress.process else { return }
        DispatchQueue.global(qos: .background).async {
            while process.isRunning {
                progress.update()
                Thread.sleep(forTimeInterval: 0.2) // vérification toutes les 0.2 secondes
            }
            progress.update()
            // Fin du traitement
            DispatchQueue.main.async {
                progress.terminateProcess()
                let soundName: NSSound.Name = progress.isFinished ? "Glass" : "Sosumi"
                NSSound(named: soundName)?.play()
                showTermination = true
            }
        }
    }
    
    func parseSourceUrl(at url: URL?) {
        guard var url = url else { return }
        let ext = url.pathExtension
        if ext == "split" {
            url = url.deletingPathExtension()
        }
        url = url.deletingPathExtension()
        destFilename = url.lastPathComponent
        destFolder = url.deletingLastPathComponent()
        
        var files = FileManager.contentsOfDirectory(atPath: destFolder!.path, matching: destFilename)
        files = files.filter { ($0 as NSString).lastPathComponent != destFilename }
        self.files = files.map { URL(filePath: $0) }
        destFilesize = 0
        files.forEach { file in
            destFilesize += FileManager.filesize(forPath: file)
        }
    }
}

struct FilesizeCatField: View {
    @Binding var filesize: UInt64
    var body: some View {
        Text("File size: \(FilesizeFormatter.string(fromByteCount: filesize))")
    }
}



#Preview {
    @Previewable @State var fileURL: URL? = URL(fileURLWithPath: "/Users/achapelon/Downloads/Cyberpunk.2077.v2.3.dmg.0.part0.split")
    ConcatView(fileURL: $fileURL)
}
