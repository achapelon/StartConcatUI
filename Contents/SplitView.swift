//
//  SplitView.swift
//  SplitUI
//
//  Created by Anthony Chapelon on 16/08/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct SplitView: View {
    @StateObject private var progress: Progress = Progress()
    @Binding var fileURL: URL?
    
    @State private var destFolder: URL?
    @State private var templateFilename: String = ""
    @State private var chunkCount: Int = 2
    @State private var suffixLength: Int = 1
    @State private var overwrite: Bool = true
    @State private var numericSuffix: Bool = true
    @State private var showTermination: Bool = false
    @State private var showConfirmation: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            FileField(url: $fileURL)
            FilesizeField(url: $fileURL)
            FileField(label: "Folder destination", url: $destFolder)
                .onAppear {
                    if let url = fileURL {
                        destFolder = url.deletingLastPathComponent()
                        templateFilename = url.lastPathComponent + ".part"
                    }
                }
                .onChange(of: destFolder) {
                    if let url = fileURL, destFolder == nil {
                        destFolder = url.deletingLastPathComponent()
                        return
                    }
                    if let url = destFolder, !url.hasDirectoryPath {
                        destFolder = url.deletingLastPathComponent()
                    }
                }
                .onChange(of: fileURL) {
                    if let url = fileURL {
                        destFolder = url.deletingLastPathComponent()
                        templateFilename = url.lastPathComponent + ".part"
                    }
                }
            ChunckCountField(url:$fileURL, value: $chunkCount)
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
            Button(progress.isRunning ? "Cancel" : "Split") {
                if progress.isRunning {
                    progress.terminateProcess()
                } else {
                    guard let destFolder = destFolder else { return }
                    let files = FileManager.contentsOfDirectory(atPath: destFolder.path, matching: templateFilename)
                    if (files.count > 0) {
                        showConfirmation = true
                        return
                    }
                    startSplit()
                }
            }
            .confirmationDialog("Overwrite existing files?", isPresented: $showConfirmation) {
                Button("Overwrite", role: .destructive) {
                    guard let destFolder = destFolder else { return }
                    FileManager.removeItems(atPath: destFolder.path, matching: templateFilename)
                    startSplit()
                }
                .keyboardShortcut(.defaultAction)
                Button("Cancel", role: .cancel) { }
            }
            .alert(progress.isFinished ? "Finished" : "Canceled", isPresented: $showTermination) {
                Button("OK") {
                    // Rename files with extension on Finish
                    // Remove temporary files on Cancel
                    if (progress.isFinished) {
                        FileManager.appendingPathExtensionToItems(extension: "split", atPath: destFolder!.path, matching: templateFilename)
                    } else {
                        FileManager.removeItems(atPath: destFolder!.path, matching: templateFilename)
                    }
                }
            } message: {
                Text(progress.isFinished ? "The file has been split successfully." : "The split has been canceled.")
            }
            .buttonStyle(.borderedProminent)
            .disabled(fileURL == nil || templateFilename.isEmpty || destFolder == nil)
            .padding(.top, 10)

        }
        .padding()
    }
    
    func cancel() {
        progress.terminateProcess()
        showTermination = true
    }
    
    func startSplit() {
        guard let url = fileURL else { return }
        guard let destFolder = destFolder else { return }
            
        let destination = destFolder.appendingPathComponent(templateFilename)
        
        progress.setProcessSplit(source: url, destination: destination, chunkCount: chunkCount)
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
}

struct ChunckCountField: View {
    @Binding var url: URL?
    @Binding var value: Int
    var body: some View {
        HStack {
            if let url = url {
                Text("Chunk count:")
                TextField("", value: $value, format: .number)
                    .frame(width: 38)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .multilineTextAlignment(.center)
                Stepper("", value: $value, in: 2...99)
                    .frame(width: 0)
                    .padding(.trailing, 10)
                let filesize = FileManager.filesize(for: url)
                let size: UInt64 = filesize/UInt64(value)
                Text("Size of each file: \(FilesizeFormatter.string(fromByteCount:size))")
            }
        }
    }
}

#Preview {
    @Previewable @State var fileURL: URL? = URL(fileURLWithPath: "/Users/achapelon/Downloads/GlobalProtect_Linux_6-2-9-c4.tar")
    SplitView(fileURL: $fileURL)
}
