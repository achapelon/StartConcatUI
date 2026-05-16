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
    @State private var progress: SplitConcatProgress = SplitConcatProgress()
    
    var body: some View {
        VStack(spacing: 12) {
            ParametersView()

            Spacer()

            SplitConcatProgressView(progress: progress)
            
            ActionButtonView(progress: progress)
        }
        .padding()
    }

    private struct ParametersView: View {
        @EnvironmentObject private var model: SplitConcatModel

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                FileField(url: $model.sourceURL)
                FilesizeField(url: $model.sourceURL)
                FileField(label: "Destination folder", url: destinationFolderBinding)
                ChunkCountField(
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
    }

    private struct ActionButtonView: View {
        @State var progress: SplitConcatProgress
        @EnvironmentObject private var model: SplitConcatModel
        @State private var showTermination: Bool = false
        @State private var showConfirmation: Bool = false

        var body: some View {
            Button(action: startCancelAction) {
                Text(progress.isRunning ? "Cancel" : "Split")
                    .frame(width: 100)
            }
            .confirmationDialog("Overwrite existing files?", isPresented: $showConfirmation) {
                Button("Overwrite", role: .destructive, action: confirmOverwrite)
                Button("Cancel", role: .cancel) { }
                    .keyboardShortcut(.defaultAction)
            }
            .alert(progress.isFinished ? "Finished" : "Canceled", isPresented: $showTermination) {
                Button("OK", action: handleTerminationAcknowledgement)
            } message: {
                Text(progress.isFinished ? "The file has been split successfully." : "The split has been canceled.")
            }
            .controlSize(.extraLarge)
            .buttonStyle(.borderedProminent)
            .disabled(false)
        }
        
        private func startCancelAction() {
            if progress.isRunning {
                cancelSplit()
            } else {
                prepareSplit()
            }
        }

        private func prepareSplit() {
            guard let configuration = model.splitConfiguration else { return }

            if !existingSplitParts(for: configuration).isEmpty {
                showConfirmation = true
                return
            }

            startSplit()
        }

        private func cancelSplit() {
            progress.terminateProcess()
        }

        private func confirmOverwrite() {
            guard let configuration = model.splitConfiguration else { return }

            FileManager.removeSplitParts(
                atPath: configuration.destinationFolder.path,
                templateFilename: splitPartSearchTemplateFilename(for: configuration.templateFilename)
            )
            startSplit()
        }

        private func handleTerminationAcknowledgement() {
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

        private func existingSplitParts(for configuration: SplitConfiguration) -> [String] {
            FileManager.splitParts(
                atPath: configuration.destinationFolder.path,
                templateFilename: splitPartSearchTemplateFilename(for: configuration.templateFilename)
            )
        }

        private func splitPartSearchTemplateFilename(for templateFilename: String) -> String {
            let partExtension = ".part"
            guard templateFilename.hasSuffix(partExtension) else {
                return templateFilename
            }
            return String(templateFilename.dropLast(partExtension.count))
        }

        private func startSplit() {
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

    }

    private struct ChunkCountField: View {
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
