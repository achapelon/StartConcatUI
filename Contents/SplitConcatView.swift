//
//  SplitConcatView.swift
//  SplitConcatUI
//
//  Created by Anthony Chapelon on 23/05/2026.
//


import SwiftUI

struct SplitConcatView: View {
    let operation: SplitConcatOperation
    @State private var progress: SplitConcatProgress

    init(operation: SplitConcatOperation) {
        self.operation = operation
        self._progress = State(initialValue: SplitConcatProgress(operation: operation))
    }

    var body: some View {
        VStack(spacing: 12) {
            ParametersView(operation: operation)

            Spacer()

            SplitConcatProgressView(_progress)

            OperationActionButtonView(_progress)
        }
        .padding()
    }

    private struct ParametersView: View {
        let operation: SplitConcatOperation
        @EnvironmentObject private var model: SplitConcatModel

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                switch operation {
                case .split:
                    splitParameters
                case .concat:
                    concatParameters
                }
            }
        }

        @ViewBuilder
        private var splitParameters: some View {
            FileField($model.sourceURL)

            FilesizeField($model.sourceURL)

            FileField(
                splitDestinationFolderBinding,
                label: "Destination folder"
            )

            ChunkCountField(splitChunkCountBinding)
        }

        @ViewBuilder
        private var concatParameters: some View {
            if let configuration = model.concatConfiguration {
                let fileSize = FilesizeFormatter.string(fromByteCount: configuration.destinationFileSize)

                FileListView(files: concatPartURLsBinding)

                FileField(
                    concatDestinationFolderBinding,
                    label: "Folder destination"
                )

                Text("Destination file: \(configuration.destinationFilename) (\(fileSize))")
            }
        }

        private var splitDestinationFolderBinding: Binding<URL?> {
            Binding {
                model.splitConfiguration?.destinationFolder
            } set: { newValue in
                guard let newValue else { return }
                updateSplitConfiguration { configuration in
                    configuration.destinationFolder = newValue.hasDirectoryPath ? newValue : newValue.deletingLastPathComponent()
                }
            }
        }

        private var splitChunkCountBinding: Binding<Int> {
            Binding {
                model.splitConfiguration?.chunkCount ?? 2
            } set: { newValue in
                updateSplitConfiguration { configuration in
                    configuration.chunkCount = min(max(newValue, 2), 99)
                }
            }
        }

        private var concatDestinationFolderBinding: Binding<URL?> {
            Binding {
                model.concatConfiguration?.destinationFolder
            } set: { newValue in
                guard let newValue else { return }
                updateConcatConfiguration { configuration in
                    configuration.destinationFolder = newValue.hasDirectoryPath ? newValue : newValue.deletingLastPathComponent()
                }
            }
        }

        private var concatPartURLsBinding: Binding<[URL]> {
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

        private func updateSplitConfiguration(_ update: (inout SplitConfiguration) -> Void) {
            guard var configuration = model.splitConfiguration else { return }
            update(&configuration)
            model.splitConfiguration = configuration
        }

        private func updateConcatConfiguration(_ update: (inout ConcatConfiguration) -> Void) {
            guard var configuration = model.concatConfiguration else { return }
            update(&configuration)
            model.concatConfiguration = configuration
        }
    }

    private struct ChunkCountField: View {
        @Binding var chunkCount: Int
        @EnvironmentObject private var model: SplitConcatModel

        init(_ chunkCount: Binding<Int>) {
            self._chunkCount = chunkCount
        }

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

                let estimatedChunkSize = model.splitConfiguration?.estimatedChunkSize ?? 0
                Text("Size of each part: \(FilesizeFormatter.string(fromByteCount: estimatedChunkSize))")
            }
        }
    }
}
