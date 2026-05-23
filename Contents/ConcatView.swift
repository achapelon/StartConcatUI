//
//  SplitView.swift
//  SplitUI
//
//  Created by Anthony Chapelon on 16/08/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct ConcatView: View {
    @State private var progress: SplitConcatProgress = SplitConcatProgress(operation: .concat)

    var body: some View {
        VStack {
            ParametersView()
                .padding(.bottom, 16)

            Spacer()

            SplitConcatProgressView(_progress)

            OperationActionButtonView(_progress)
        }
        .padding()
    }

    private struct ParametersView: View {
        @EnvironmentObject private var model: SplitConcatModel

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                if let configuration = model.concatConfiguration {
                    let fileSize = FilesizeFormatter.string(fromByteCount: configuration.destinationFileSize)
                    
                    FileListView(files: partURLsBinding)
                    
                    FileField(
                        destinationFolderBinding,
                        label: "Folder destination")
                    
                    Text("Destination file: \(configuration.destinationFilename) (\(fileSize))")
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
