//
//  SplitView.swift
//  SplitUI
//
//  Created by Anthony Chapelon on 16/08/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct SplitView: View {
    @State private var progress: SplitConcatProgress = SplitConcatProgress(operation: .split)
    
    var body: some View {
        VStack(spacing: 12) {
            ParametersView()

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
                FileField($model.sourceURL)
                
                FilesizeField($model.sourceURL)
                
                FileField(
                    destinationFolderBinding,
                    label: "Destination folder")
                
                ChunkCountField(chunkCountBinding)
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



#Preview {
    SplitView()
        .environmentObject(SplitConcatModel(sourceURL: URL(fileURLWithPath: "/Users/achapelon/Downloads/GlobalProtect_Linux_6-2-9-c4.tar")))
}
