//
//  SplitConcatModel.swift
//  SplitUI
//
//  Created by Codex on 11/05/2026.
//

import Foundation

enum SplitConcatOperation {
    case split
    case concat
}

final class SplitConcatModel: ObservableObject {
    @Published var sourceURL: URL? {
        didSet {
            configuration = Self.makeConfiguration(for: sourceURL)
        }
    }

    @Published var configuration: (any SplitConcatConfiguration)?

    init(sourceURL: URL? = nil) {
        self.sourceURL = sourceURL
        self.configuration = Self.makeConfiguration(for: sourceURL)
    }

    var operation: SplitConcatOperation? {
        guard let sourceURL else { return nil }
        return sourceURL.pathExtension.lowercased() == "split" ? .concat : .split
    }

    var windowTitle: String {
        sourceURL?.lastPathComponent ?? "SplitConcatUI"
    }

    var splitConfiguration: SplitConfiguration? {
        get { configuration as? SplitConfiguration }
        set { configuration = newValue }
    }

    var concatConfiguration: ConcatConfiguration? {
        get { configuration as? ConcatConfiguration }
        set { configuration = newValue }
    }

    private static func makeConfiguration(for sourceURL: URL?) -> (any SplitConcatConfiguration)? {
        guard let sourceURL else { return nil }
        if sourceURL.pathExtension.lowercased() == "split" {
            return ConcatConfiguration(sourceURL: sourceURL)
        }
        return SplitConfiguration(sourceURL: sourceURL)
    }
}

protocol SplitConcatConfiguration { }

struct SplitConfiguration: SplitConcatConfiguration {
    var sourceURL: URL
    var destinationFolder: URL
    var templateFilename: String
    var chunkCount: Int

    init(sourceURL: URL, destinationFolder: URL? = nil, templateFilename: String? = nil, chunkCount: Int = 2) {
        self.sourceURL = sourceURL
        self.destinationFolder = destinationFolder ?? sourceURL.deletingLastPathComponent()
        self.templateFilename = templateFilename ?? sourceURL.lastPathComponent + ".part"
        self.chunkCount = chunkCount
    }

    var destinationURL: URL {
        destinationFolder.appendingPathComponent(templateFilename)
    }

    var estimatedChunkSize: UInt64 {
        guard chunkCount > 0 else { return 0 }
        return FileManager.filesize(for: sourceURL) / UInt64(chunkCount)
    }
}

struct ConcatConfiguration: SplitConcatConfiguration {
    var sourceURL: URL
    var destinationFolder: URL
    var destinationFilename: String
    var partURLs: [URL]
    var destinationFileSize: UInt64

    init(sourceURL: URL) {
        self.sourceURL = sourceURL

        var normalizedURL = sourceURL
        if normalizedURL.pathExtension.lowercased() == "split" {
            normalizedURL = normalizedURL.deletingPathExtension()
        }
        normalizedURL = normalizedURL.deletingPathExtension()

        self.destinationFilename = normalizedURL.lastPathComponent
        self.destinationFolder = normalizedURL.deletingLastPathComponent()

        let parts = FileManager.splitParts(
            atPath: destinationFolder.path,
            templateFilename: destinationFilename
        )
        self.partURLs = parts.map { URL(filePath: $0) }
        self.destinationFileSize = parts.reduce(0) { partialResult, path in
            partialResult + FileManager.filesize(forPath: path)
        }
    }

    var destinationURL: URL {
        destinationFolder.appending(path: destinationFilename)
    }
}
