//
//  Progress.swift
//  SplitUI
//
//  Created by Anthony Chapelon on 29/08/2025.
//

import Foundation

class Progress: ObservableObject {
    struct ElapsedTime {
        var startTime: Date = Date()

        func elapsed() -> Double {
            return Date().timeIntervalSince(startTime)
        }
        
        func string() -> String {
            let elapsed = elapsed()
            let stringElapsed = Duration.seconds(elapsed).formatted(
                .units(
                    allowed: [.hours, .minutes, .seconds],
                    width: .condensedAbbreviated
                ))
            return "\(stringElapsed)"
        }
    }

    @Published var totalByteCount: UInt64 = 0
    @Published var currentByteCount: UInt64 = 0
    
    var elapsed: ElapsedTime?
    var process: Process?
    var outputURL: URL?
    
    var isRunning: Bool { process != nil }
    var isFinished: Bool { get { value == 1 } set { newValue ? DispatchQueue.main.async { [self] in (currentByteCount = totalByteCount) } : () } }
    var value: Double { Double(currentByteCount) / Double(totalByteCount) }
    var message: String {
        get {
            var message = "0%"
            if totalByteCount > 0 {
                let stringElapsed = elapsed?.string() ?? "0s"
                let stringETA = stringETA()
                let currentByteCountString = FilesizeFormatter.string(fromByteCount: currentByteCount)
                let totalByteCountString = FilesizeFormatter.string(fromByteCount: totalByteCount)
                message = "\(currentByteCountString) over \(totalByteCountString) - \(stringElapsed) elapsed - about \(stringETA) remaining (\(Int(value * 100))%)"
            }
            return message
        }
    }
    func set(toByteCount totalByteCount: UInt64) {
        DispatchQueue.main.async {
            self.totalByteCount = totalByteCount
            self.currentByteCount = 0
            //self.message = nil
        }
    }
    
    func stringETA() -> String {
        let eta = getETA()
        if eta.isFinite, eta > 0 {
            let units: Set<Duration.UnitsFormatStyle.Unit> = (eta > 3600) ? [.hours, .minutes] : (eta > 60) ? [.minutes] : [.seconds]
            let stringETA = Duration.seconds(eta).formatted(
                .units(
                    allowed: units,
                    width: .condensedAbbreviated
                ))
            return "\(stringETA)"
        }
        return "???"
    }
    
    func getETA() -> Double {
        guard totalByteCount > 0, currentByteCount > 0 else { return 0.0 }
        let elapsed = elapsed?.elapsed() ?? 0.0
        //let remaining = Double(totalByteCount - currentByteCount) / Double(currentByteCount) * elapsed
        if elapsed > 0 {
            let speed = Double(currentByteCount) / elapsed // octets/seconde
            let remaining = Double(totalByteCount - currentByteCount) / speed
            return remaining
        }
        return 0.0
    }
    
    func setProcessSplit(source: URL, destination: URL, chunkCount: Int) {
        set(toByteCount: FileManager.filesize(for: source))
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/split")
        
        var args: [String] = []
        
        args.append("-d")
        let suffixLength = Int(ceil(log10(Double(chunkCount))))
        args.append(contentsOf: ["-a", "\(suffixLength)"])
        args.append(contentsOf: ["-n", "\(chunkCount)"])
        
        args.append(source.path)
        args.append(destination.path)
        
        process.arguments = args
        
        self.process = process
        
        outputURL = destination
    }
    
    func setProcessConcat(sources: [URL], destination: URL) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/cat")

        var args: [String] = []
        var size: UInt64 = 0
        for file in sources {
            args.append(file.path)
            size += FileManager.filesize(for: URL(fileURLWithPath: file.path))
        }
        set(toByteCount: size)

        process.arguments = args
        
        FileManager.default.createFile(atPath: destination.path, contents: nil)
        let outHandle = try? FileHandle(forWritingTo: destination)
        process.standardOutput = outHandle
        
        self.process = process
        
        outputURL = destination
    }
    
    func runProcess() {
        elapsed = ElapsedTime()
        
        let process = process!
        let pipe = Pipe()
        if (process.standardOutput == nil) {
            process.standardOutput = pipe
        }
        process.standardError = pipe
        process.terminationHandler = { [self] _ in
            let status = process.terminationStatus
            print("Process terminated with status \(status)")
            isFinished = (status == 0)
            
            let pipe = process.standardError! as! Pipe
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                print("\(output)")
            }
        }
        
        do {
            try process.run()
        } catch {
            print(error)
        }
        let exec = process.executableURL?.lastPathComponent ?? "(no executable)"
        let args = process.arguments?.joined(separator: " ") ?? "(no arguments)"
        print("Process started command \(exec) \(args)")
    }
    
    func terminateProcess() {
        process?.terminate()
        process = nil
        elapsed = nil
    }
    
    func update() {
        guard let process = process else { return }
        guard let exec = process.executableURL?.lastPathComponent else { return }
        switch exec {
        case "split":
            let templateFilename = outputURL?.lastPathComponent
            let destFolder: URL = outputURL!.deletingLastPathComponent()
            let files = FileManager.contentsOfDirectory(atPath: destFolder.path, matching: templateFilename)
            
            var size: UInt64 = 0
            files.forEach { size += FileManager.filesize(forPath: $0) }
            
            DispatchQueue.main.async { self.currentByteCount = size }
            break;
        case "cat":
            let size: UInt64 = FileManager.filesize(forPath: outputURL!.path)
            DispatchQueue.main.async { self.currentByteCount = size }
            break;
        default:
            break;
        }
    }
}
