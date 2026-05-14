//
//  SplitView.swift
//  SplitUI
//
//  Created by Anthony Chapelon on 16/08/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct ConcatView: View {
    @EnvironmentObject private var model: SplitConcatModel

    @StateObject private var progress: SplitConcatProgress = SplitConcatProgress()
    @State private var showTermination: Bool = false
    @State private var showConfirmation: Bool = false

    var body: some View {
        VStack {
            parameters
                .padding(.bottom, 16)
            
            Spacer()
            
            SplitConcatProgressView(progress: progress)
            
            startCancelButton
        }
        .padding()
    }

    private func startCancelAction() {
        if progress.isRunning {
            progress.terminateProcess()
        } else {
            guard let configuration = model.concatConfiguration else { return }
            if FileManager.default.fileExists(atPath: configuration.destinationURL.path) {
                showConfirmation = true
                return
            }
            startConcat()
        }
    }
    
    private var overwriteConfirmation: some View {
        HStack {
            Button("Overwrite", role: .destructive) {
                removeDestinationFile()
                startConcat()
            }
            Button("Cancel", role: .cancel) { }
                .keyboardShortcut(.defaultAction)
        }
    }
    
    private var finishedAlert: some View {
        Button("OK") {
            // Remove temporary file on Cancel.
            if !progress.isFinished {
                removeDestinationFile()
            }
        }
    }
    private var startCancelButton: some View {
        Button(action: startCancelAction) {
            Text(progress.isRunning ? "Cancel" : "Concatenate")
                .frame(width: 100)
        }
        .confirmationDialog("Overwrite existing file?", isPresented: $showConfirmation) {
            overwriteConfirmation
        }
        .alert(progress.isFinished ? "Finished" : "Canceled", isPresented: $showTermination) {
            finishedAlert
        } message: {
            Text(progress.isFinished ? "The file has been concatenated successfully." : "The concatenation has been canceled.")
        }
        .controlSize(.extraLarge)
        .buttonStyle(.borderedProminent)
        .disabled(model.concatConfiguration == nil)
    }
    
    private var parameters: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let configuration = model.concatConfiguration {
                FileListView(files: partURLsBinding)
                FilesizeCatField(filesize: configuration.destinationFileSize)
                FileField(label: "Folder destination", url: destinationFolderBinding)
                Text("Destination file: \(configuration.destinationFilename)")
            }
        }
    }
    
    private var destinationFolderBinding: Binding<URL?> {
        Binding {
            model.concatConfiguration?.destinationFolder
        } set: { newValue in
            guard let newValue else { return }
            updateConcatConfiguration { configuration in
                configuration.destinationFolder = newValue.hasDirectoryPath ? newValue : newValue.deletingLastPathComponent()
            }
        }
    }

    private var partURLsBinding: Binding<[URL]> {
        Binding {
            model.concatConfiguration?.partURLs ?? []
        } set: { newValue in
            updateConcatConfiguration { configuration in
                configuration.partURLs = newValue
                configuration.destinationFileSize = newValue.reduce(0) { partialResult, url in
                    partialResult + FileManager.filesize(for: url)
                }
            }
        }
    }

    private func updateConcatConfiguration(_ update: (inout ConcatConfiguration) -> Void) {
        guard var configuration = model.concatConfiguration else { return }
        update(&configuration)
        model.concatConfiguration = configuration
    }

    func removeDestinationFile() {
        guard let configuration = model.concatConfiguration else { return }
        try? FileManager.default.removeItem(at: configuration.destinationURL)
    }

    func cancel() {
        progress.terminateProcess()
        showTermination = true
    }

    func startConcat() {
        guard let configuration = model.concatConfiguration else { return }

        progress.setProcessConcat(sources: configuration.partURLs, destination: configuration.destinationURL)
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

struct FilesizeCatField: View {
    let filesize: UInt64

    var body: some View {
        Text("File size: \(FilesizeFormatter.string(fromByteCount: filesize))")
    }
}

#Preview {
    ConcatView()
        .environmentObject(SplitConcatModel(sourceURL: URL(fileURLWithPath: "/Users/achapelon/Desktop/1684331401931.jpeg.part0.split")))
}
