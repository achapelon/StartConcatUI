//
//  SplitView.swift
//  SplitUI
//
//  Created by Anthony Chapelon on 16/08/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct SplitView: View {
    @EnvironmentObject private var model: SplitConcatModel

    @StateObject private var progress: SplitConcatProgress = SplitConcatProgress()

    @State private var showTermination: Bool = false
    @State private var showConfirmation: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            parameters

            Spacer()

            SplitConcatProgressView(progress: progress)
            
            startCancelButton
        }
        .padding()
    }

    private func startCancelAction() {
        if progress.isRunning { // Cancel button
            progress.terminateProcess()
        } else { // Start Button
            guard let configuration = model.splitConfiguration else { return }
            let files = FileManager.splitParts(
                atPath: configuration.destinationFolder.path,
                templateFilename: configuration.templateFilename
            )
            if !files.isEmpty {
                showConfirmation = true
                return
            }
            startSplit()
        }
    }
    
    private var overwriteConfirmation: some View {
        HStack {
            Button("Overwrite", role: .destructive) {
                        guard let configuration = model.splitConfiguration else { return }
                        FileManager.removeSplitParts(
                            atPath: configuration.destinationFolder.path,
                            templateFilename: configuration.templateFilename
                        )
                        startSplit()
                    }
                    Button("Cancel", role: .cancel) { }
                        .keyboardShortcut(.defaultAction)
        }
        
    }
    
    private var finishedAlert: some View {
        Button("OK") {
            // Rename files with extension on Finish, or remove temporary files on Cancel.
            guard let configuration = model.splitConfiguration else { return }
            if progress.isFinished {
                FileManager.appendPathExtensionToSplitParts(
                    "split",
                    atPath: configuration.destinationFolder.path,
                    templateFilename: configuration.templateFilename
                )
            } else {
                FileManager.removeSplitParts(
                    atPath: configuration.destinationFolder.path,
                    templateFilename: configuration.templateFilename
                )
            }
        }
    }
    
    private var startCancelButton: some View {
        Button(action: startCancelAction) {
            Text(progress.isRunning ? "Cancel" : "Split")
                .frame(width: 100)
        }
        .confirmationDialog("Overwrite existing files?", isPresented: $showConfirmation) {
            overwriteConfirmation
        }
        .alert(progress.isFinished ? "Finished" : "Canceled", isPresented: $showTermination) {
            finishedAlert
        } message: {
            Text(progress.isFinished ? "The file has been split successfully." : "The split has been canceled.")
        }
        .controlSize(.extraLarge)
        .buttonStyle(.borderedProminent)
        .disabled(model.splitConfiguration == nil)
    }
    
    private var parameters: some View {
        VStack(alignment: .leading, spacing: 12) {
            FileField(url: $model.sourceURL)
            FilesizeField(url: $model.sourceURL)
            FileField(label: "Destination folder", url: destinationFolderBinding)
            ChunckCountField(
                chunkCount: chunkCountBinding,
                estimatedChunkSize: model.splitConfiguration?.estimatedChunkSize ?? 0
            )
        }
    }
    
    private var destinationFolderBinding: Binding<URL?> {
        Binding {
            model.splitConfiguration?.destinationFolder
        } set: { newValue in
            guard let newValue else { return }
            updateSplitConfiguration { configuration in
                configuration.destinationFolder = newValue.hasDirectoryPath ? newValue : newValue.deletingLastPathComponent()
            }
        }
    }

    private var chunkCountBinding: Binding<Int> {
        Binding {
            model.splitConfiguration?.chunkCount ?? 2
        } set: { newValue in
            updateSplitConfiguration { configuration in
                configuration.chunkCount = min(max(newValue, 2), 99)
            }
        }
    }

    private func updateSplitConfiguration(_ update: (inout SplitConfiguration) -> Void) {
        guard var configuration = model.splitConfiguration else { return }
        update(&configuration)
        model.splitConfiguration = configuration
    }

    func cancel() {
        progress.terminateProcess()
        showTermination = true
    }

    func startSplit() {
        guard let configuration = model.splitConfiguration else { return }

        progress.setProcessSplit(
            source: configuration.sourceURL,
            destination: configuration.destinationURL,
            chunkCount: configuration.chunkCount
        )
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

    struct ChunckCountField: View {
        @Binding var chunkCount: Int
        let estimatedChunkSize: UInt64

        var body: some View {
            HStack {
                Text("Chunk count:")
                TextField("", value: $chunkCount, format: .number)
                    .frame(width: 38)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .multilineTextAlignment(.center)
                Stepper("", value: $chunkCount, in: 2...99)
                    .frame(width: 0)
                    .padding(.trailing, 10)
                Text("Size of each part: \(FilesizeFormatter.string(fromByteCount: estimatedChunkSize))")
            }
        }
    }
}



#Preview {
    SplitView()
        .environmentObject(SplitConcatModel(sourceURL: URL(fileURLWithPath: "/Users/achapelon/Downloads/GlobalProtect_Linux_6-2-9-c4.tar")))
}
