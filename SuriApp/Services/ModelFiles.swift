import Foundation
import CryptoKit

nonisolated enum ModelFiles {
    static let identifier = "ggml-org/Qwen3-1.7B-GGUF"
    static let revision = "daeb8e2d528a760970442092f6bf1e55c3b659eb"
    static let directory: URL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Qwen3-1.7B-GGUF", isDirectory: true)

    struct FileSpec: Sendable {
        let name: String
        let bytes: Int64
        let sha256: String?
    }
    static let files: [FileSpec] = [
        .init(name: "Qwen3-1.7B-Q4_K_M.gguf", bytes: 1282439264, sha256: "d2387ca2dbfee2ffabce7120d3770dadca0b293052bc2f0e138fdc940d9bc7b5")
    ]
    static var isInstalled: Bool {
        guard (try? String(contentsOf: directory.appendingPathComponent(".complete"), encoding: .utf8)) == revision else { return false }
        return files.allSatisfy {
            let attributes = try? FileManager.default.attributesOfItem(atPath: directory.appendingPathComponent($0.name).path)
            return (attributes?[.size] as? NSNumber)?.int64Value == $0.bytes
        }
    }

    @concurrent static func install(progress: @Sendable (String) async -> Void) async throws {
        let manager = FileManager.default
        try manager.createDirectory(at: directory, withIntermediateDirectories: true)
        var protectedURL = directory
        var values = URLResourceValues(); values.isExcludedFromBackup = true
        try protectedURL.setResourceValues(values)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 1800
        configuration.httpCookieStorage = nil
        configuration.urlCache = nil
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        for spec in files {
            try Task.checkCancellation()
            let destination = directory.appendingPathComponent(spec.name)
            if (try? validate(destination, spec: spec)) != nil { continue }
            await progress("Downloading the local model (1.28 GB). Keep Suri open.")
            let url = URL(string: "https://huggingface.co/\(identifier)/resolve/\(revision)/\(spec.name)")!
            let (temporary, response) = try await session.download(from: url)
            defer { try? manager.removeItem(at: temporary) }
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw ModelError.download }
            try Task.checkCancellation()
            try validate(temporary, spec: spec)
            if manager.fileExists(atPath: destination.path) { try manager.removeItem(at: destination) }
            try manager.moveItem(at: temporary, to: destination)
        }
        try Task.checkCancellation()
        try revision.write(to: directory.appendingPathComponent(".complete"), atomically: true, encoding: .utf8)
        await progress("Model ready for local checking")
    }

    static func validate(_ url: URL, spec: FileSpec) throws {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        guard (attributes[.size] as? NSNumber)?.int64Value == spec.bytes else { throw ModelError.download }
        if let expected = spec.sha256 {
            let handle = try FileHandle(forReadingFrom: url)
            defer { try? handle.close() }
            var hasher = SHA256()
            while let data = try handle.read(upToCount: 4 * 1024 * 1024), !data.isEmpty {
                try Task.checkCancellation()
                hasher.update(data: data)
            }
            guard hasher.finalize().map({ String(format: "%02x", $0) }).joined() == expected else { throw ModelError.download }
        }
    }
}

nonisolated enum ModelError: Error, LocalizedError {
    case missing, download, busy, timeout, load
    var errorDescription: String? {
        switch self {
        case .missing: "Download the local model in Settings before checking. No message will be uploaded."
        case .download: "A model file could not be verified. Check your connection and try downloading again."
        case .load: "The local model could not load. Check available memory and try again."
        case .busy: "Another check is finishing. Try again in a moment."
        case .timeout: "The local check took too long. Try a shorter message or ask someone you trust."
        }
    }
}
