//
//  DropZone.swift
//  SplitUI
//
//  Created by Anthony Chapelon on 16/08/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct Dropzone: View {
    @State private var isTargeted = false
    @State private var isImporterPresented = false
    @State private var dashPhase: CGFloat = 0
    var text: String
    @EnvironmentObject private var model: SplitConcatModel
    
    init(_ text: String = "Drag a file here") {
        self.text = text
    }
    
    var body: some View {
        ZStack {
            Text(text)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            Button(action: {isImporterPresented = true}) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.06))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isTargeted ? Color.blue : Color.gray,
                                style: StrokeStyle(lineWidth: 2, dash: [10], dashPhase: dashPhase)
                            )
                    }
                
            }
            .buttonStyle(PlainButtonStyle())
            .fileImporter(
                isPresented: $isImporterPresented,
                allowedContentTypes: [.item],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    model.sourceURL = urls.first
                case .failure(let error):
                    print("Erreur : \(error.localizedDescription)")
                }
            }

        }
        .contentShape(Rectangle())
        .onDrop(
            of: [.fileURL],
            delegate: FileDropDelegate(
                model: model,
                isTargeted: $isTargeted
            )
        )
        .onChange(of: isTargeted) { _, isTargeted in
            if isTargeted {
                withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                    dashPhase = -20
                }
            } else {
                withAnimation(.default) {
                    dashPhase = 0
                }
            }
        }
        .padding()
    }
}

private struct FileDropDelegate: DropDelegate {
    let model: SplitConcatModel
    @Binding var isTargeted: Bool

    func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: [.fileURL])
    }

    func dropEntered(info: DropInfo) {
        updateTargetState(info: info)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        updateTargetState(info: info)
        return DropProposal(operation: isTargeted ? .copy : .forbidden)
    }

    func dropExited(info: DropInfo) {
        isTargeted = false
    }

    func performDrop(info: DropInfo) -> Bool {
        isTargeted = false

        guard let provider = info.itemProviders(for: [.fileURL]).first else {
            return false
        }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let droppedURL = Self.url(from: item),
                  !droppedURL.hasDirectoryPath else {
                return
            }

            DispatchQueue.main.async {
                model.sourceURL = droppedURL
            }
        }

        return true
    }

    private func updateTargetState(info: DropInfo) {
        guard let provider = info.itemProviders(for: [.fileURL]).first else {
            isTargeted = false
            return
        }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            let acceptsDrop = Self.url(from: item)?.hasDirectoryPath == false

            DispatchQueue.main.async {
                isTargeted = acceptsDrop
            }
        }
    }

    private static func url(from item: NSSecureCoding?) -> URL? {
        if let url = item as? URL {
            return url
        }

        if let data = item as? Data {
            return URL(dataRepresentation: data, relativeTo: nil)
        }

        return nil
    }
}

#Preview {
    @Previewable @State var fileURL: URL? = URL(fileURLWithPath: "/Users/achapelon/Downloads/GlobalProtect_Linux_6-2-9-c4.tar")
    Dropzone()
}
