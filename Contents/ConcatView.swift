//
//  SplitView.swift
//  SplitUI
//
//  Created by Anthony Chapelon on 16/08/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct ConcatView: View {
    @State private var progress: SplitConcatProgress = SplitConcatProgress()

    var body: some View {
        VStack {
            ParametersView()
                .padding(.bottom, 16)

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
    }

    private struct ActionButtonView: View {
        @State var progress: SplitConcatProgress
        @EnvironmentObject private var model: SplitConcatModel
        @State private var showTermination: Bool = false
        @State private var showConfirmation: Bool = false

        var body: some View {
            Button(action: startCancelAction) {
                Text(progress.isRunning ? "Cancel" : "Concatenate")
                    .frame(width: 100)
            }
            .confirmationDialog("Overwrite existing file?", isPresented: $showConfirmation) {
                Button("Overwrite", role: .destructive, action: confirmOverwrite)
                Button("Cancel", role: .cancel) { }
                    .keyboardShortcut(.defaultAction)
            }
            .alert(progress.isFinished ? "Finished" : "Canceled", isPresented: $showTermination) {
                Button("OK", action: handleTerminationAcknowledgement)
            } message: {
                Text(progress.isFinished ? "The file has been concatenated successfully." : "The concatenation has been canceled.")
            }
            .controlSize(.extraLarge)
            .buttonStyle(.borderedProminent)
            .disabled(model.concatConfiguration == nil)
        }

        private func startCancelAction() {
            if progress.isRunning {
                cancelConcat()
            } else {
                prepareConcat()
            }
        }

        private func prepareConcat() {
            guard let configuration = model.concatConfiguration else { return }

            if FileManager.default.fileExists(atPath: configuration.destinationURL.path) {
                showConfirmation = true
                return
            }

            startConcat()
        }

        private func cancelConcat() {
            progress.terminateProcess()
        }

        private func confirmOverwrite() {
            removeDestinationFile()
            startConcat()
        }

        private func handleTerminationAcknowledgement() {
            if !progress.isFinished {
                removeDestinationFile()
            }
        }

        private func removeDestinationFile() {
            guard let configuration = model.concatConfiguration else { return }
            try? FileManager.default.removeItem(at: configuration.destinationURL)
        }

        private func startConcat() {
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
