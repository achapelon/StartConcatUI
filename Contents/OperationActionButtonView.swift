//
//  OperationActionButtonView.swift
//  SplitConcatUI
//
//  Created by Codex on 16/05/2026.
//

import SwiftUI

struct OperationActionMessages {
    let title: String
    let confirmationTitle: String
    let successMessage: String
    let cancelMessage: String

    init(operation: SplitConcatOperation?) {
        switch operation {
        case .split:
            title = "Split"
            confirmationTitle = "Overwrite existing files?"
            successMessage = "The file has been split successfully."
            cancelMessage = "The split has been canceled."
        case .concat:
            title = "Concatenate"
            confirmationTitle = "Overwrite existing file?"
            successMessage = "The file has been concatenated successfully."
            cancelMessage = "The concatenation has been canceled."
        case nil:
            title = "Start"
            confirmationTitle = "Overwrite existing output?"
            successMessage = "The operation has finished successfully."
            cancelMessage = "The operation has been canceled."
        }
    }
}

struct OperationActionButtonView: View {
    @State var progress: SplitConcatProgress
    @EnvironmentObject private var model: SplitConcatModel
    @State private var showTermination: Bool = false
    @State private var showConfirmation: Bool = false

    init(_ progress: State<SplitConcatProgress>) {
        self._progress = progress
    }
    var body: some View {
        let messages = OperationActionMessages(operation: progress.operation)

        Button(action: startCancelAction) {
            Text(progress.isRunning ? "Cancel" : messages.title)
                .frame(width: 100)
        }
        .confirmationDialog(messages.confirmationTitle, isPresented: $showConfirmation) {
            Button("Overwrite", role: .destructive, action: confirmOverwrite)
            Button("Cancel", role: .cancel) { }
                .keyboardShortcut(.defaultAction)
        }
        .alert(progress.isFinished ? "Finished" : "Canceled", isPresented: $showTermination) {
            Button("OK", action: handleTerminationAcknowledgement)
        } message: {
            Text(progress.isFinished ? messages.successMessage : messages.cancelMessage)
        }
        .controlSize(.extraLarge)
        .buttonStyle(.borderedProminent)
        .disabled(isDisabled)
    }

    private var isDisabled: Bool {
        switch progress.operation {
        case .split:
            model.splitConfiguration == nil
        case .concat:
            model.concatConfiguration == nil
        case nil:
            true
        }
    }

    private func startCancelAction() {
        if progress.isRunning {
            cancelOperation()
        } else {
            prepareOperation()
        }
    }

    private func prepareOperation() {
        if shouldConfirmOverwrite() {
            showConfirmation = true
            return
        }

        startOperation()
    }

    private func cancelOperation() {
        progress.terminateProcess()
    }

    private func confirmOverwrite() {
        overwriteExistingOutput()
        startOperation()
    }

    private func startOperation() {
        guard configureProcess() else { return }

        progress.runProcess()
        monitorProcess()
    }

    private func monitorProcess() {
        guard let process = progress.process else { return }

        DispatchQueue.global(qos: .background).async {
            while process.isRunning {
                progress.update()
                Thread.sleep(forTimeInterval: 0.2)
            }

            progress.update()

            DispatchQueue.main.async {
                progress.terminateProcess()
                let soundName: NSSound.Name = progress.isFinished ? "Glass" : "Sosumi"
                NSSound(named: soundName)?.play()
                showTermination = true
            }
        }
    }

    private func handleTerminationAcknowledgement() {
        if progress.isFinished {
            finishCleanup()
        } else {
            cancelCleanup()
        }
    }

    private func shouldConfirmOverwrite() -> Bool {
        switch progress.operation {
        case .split:
            guard let configuration = model.splitConfiguration else { return false }
            return !existingSplitParts(for: configuration).isEmpty
        case .concat:
            guard let configuration = model.concatConfiguration else { return false }
            return FileManager.default.fileExists(atPath: configuration.destinationURL.path)
        case nil:
            return false
        }
    }

    private func overwriteExistingOutput() {
        switch progress.operation {
        case .split:
            removeExistingSplitParts()
        case .concat:
            removeDestinationFile()
        case nil:
            break
        }
    }

    private func configureProcess() -> Bool {
        switch progress.operation {
        case .split:
            guard let configuration = model.splitConfiguration else { return false }
            progress.setProcessSplit(
                source: configuration.sourceURL,
                destination: configuration.destinationURL,
                chunkCount: configuration.chunkCount
            )
            return true
        case .concat:
            guard let configuration = model.concatConfiguration else { return false }
            progress.setProcessConcat(sources: configuration.partURLs, destination: configuration.destinationURL)
            return true
        case nil:
            return false
        }
    }

    private func finishCleanup() {
        switch progress.operation {
        case .split:
            appendSplitExtension()
        case .concat, nil:
            break
        }
    }

    private func cancelCleanup() {
        switch progress.operation {
        case .split:
            removeCreatedSplitParts()
        case .concat:
            removeDestinationFile()
        case nil:
            break
        }
    }

    private func removeExistingSplitParts() {
        guard let configuration = model.splitConfiguration else { return }

        FileManager.removeSplitParts(
            atPath: configuration.destinationFolder.path,
            templateFilename: splitPartSearchTemplateFilename(for: configuration.templateFilename)
        )
    }

    private func appendSplitExtension() {
        guard let configuration = model.splitConfiguration else { return }

        FileManager.appendPathExtensionToSplitParts(
            "split",
            atPath: configuration.destinationFolder.path,
            templateFilename: configuration.templateFilename
        )
    }

    private func removeCreatedSplitParts() {
        guard let configuration = model.splitConfiguration else { return }

        FileManager.removeSplitParts(
            atPath: configuration.destinationFolder.path,
            templateFilename: configuration.templateFilename
        )
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

    private func removeDestinationFile() {
        guard let configuration = model.concatConfiguration else { return }
        try? FileManager.default.removeItem(at: configuration.destinationURL)
    }
}
