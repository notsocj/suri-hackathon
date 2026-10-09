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

    static func prepareDirectory() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var protectedURL = directory
        var values = URLResourceValues(); values.isExcludedFromBackup = true
        try protectedURL.setResourceValues(values)
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


/// Downloads the model through a *background* URLSession. A foreground session dies whenever iOS suspends the
/// app (screen lock, app switch), which is how a 1.28 GB download used to end in "cancelled". The system now
/// keeps the transfer going, retries on connection loss, and wakes Suri to finish verification.
nonisolated final class ModelDownloader: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    static let shared = ModelDownloader()
    static let identifier = "ph.suri.app.model-download"

    enum Event: Sendable {
        case progress(written: Int64, total: Int64)
        case finished
        case paused
        case failed(String)
    }

    private let lock = NSLock()
    private var handler: (@Sendable (Event) -> Void)?
    private var backgroundCompletion: (@Sendable () -> Void)?
    private var userPaused = false
    private var lastProgress = Date.distantPast

    private var storedSession: URLSession?
    private var session: URLSession {
        lock.withLock {
            if let storedSession { return storedSession }
            let configuration = URLSessionConfiguration.background(withIdentifier: Self.identifier)
            configuration.sessionSendsLaunchEvents = true
            configuration.isDiscretionary = false
            configuration.httpCookieStorage = nil
            configuration.urlCache = nil
            configuration.timeoutIntervalForResource = 24 * 60 * 60
            let queue = OperationQueue(); queue.maxConcurrentOperationCount = 1
            let made = URLSession(configuration: configuration, delegate: self, delegateQueue: queue)
            storedSession = made
            return made
        }
    }

    private var spec: ModelFiles.FileSpec { ModelFiles.files[0] }
    private var source: URL {
        URL(string: "https://huggingface.co/\(ModelFiles.identifier)/resolve/\(ModelFiles.revision)/\(spec.name)")!
    }
    private var resumeURL: URL { ModelFiles.directory.appendingPathComponent("download.resume") }

    func setHandler(_ value: @escaping @Sendable (Event) -> Void) { lock.withLock { handler = value } }
    private func emit(_ event: Event) { let current = lock.withLock { handler }; current?(event) }
    private func setPaused(_ value: Bool) { lock.withLock { userPaused = value } }

    /// Re-attaches to a transfer that kept running (or finished) while Suri was suspended or relaunched.
    func reconnect(completion: (@Sendable () -> Void)? = nil) {
        lock.withLock { backgroundCompletion = completion }
        _ = session
    }
    func isDownloading() async -> Bool {
        await session.allTasks.contains { $0 is URLSessionDownloadTask && $0.state != .completed }
    }

    func start() async {
        setPaused(false)
        if let running = await session.allTasks.compactMap({ $0 as? URLSessionDownloadTask }).first(where: { $0.state != .completed }) {
            running.resume(); return
        }
        do { try ModelFiles.prepareDirectory() } catch { emit(.failed(ModelError.download.localizedDescription)); return }
        let task: URLSessionDownloadTask
        if let data = try? Data(contentsOf: resumeURL) {
            try? FileManager.default.removeItem(at: resumeURL)
            task = session.downloadTask(withResumeData: data)
        } else {
            task = session.downloadTask(with: source)
        }
        task.resume()
    }

    /// User pause: keep the bytes already received so Download continues instead of starting over.
    func pause() async {
        setPaused(true)
        guard let running = await session.allTasks.compactMap({ $0 as? URLSessionDownloadTask }).first(where: { $0.state == .running }) else {
            emit(.paused); return
        }
        let data: Data? = await withCheckedContinuation { continuation in running.cancel(byProducingResumeData: { continuation.resume(returning: $0) }) }
        if let data { try? data.write(to: resumeURL) }
        emit(.paused)
    }

    // MARK: URLSessionDownloadDelegate

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let now = Date()
        let due = lock.withLock { () -> Bool in
            guard now.timeIntervalSince(lastProgress) > 0.4 else { return false }
            lastProgress = now; return true
        }
        guard due else { return }
        emit(.progress(written: totalBytesWritten, total: totalBytesExpectedToWrite > 0 ? totalBytesExpectedToWrite : spec.bytes))
    }

    // The temporary file is deleted when this returns, so verify and move it here.
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            guard let status = (downloadTask.response as? HTTPURLResponse)?.statusCode, (200...299).contains(status) else { throw ModelError.download }
            try ModelFiles.validate(location, spec: spec)
            try ModelFiles.prepareDirectory()
            let destination = ModelFiles.directory.appendingPathComponent(spec.name)
            if FileManager.default.fileExists(atPath: destination.path) { try FileManager.default.removeItem(at: destination) }
            try FileManager.default.moveItem(at: location, to: destination)
            try ModelFiles.revision.write(to: ModelFiles.directory.appendingPathComponent(".complete"), atomically: true, encoding: .utf8)
            try? FileManager.default.removeItem(at: resumeURL)
            emit(.finished)
        } catch {
            try? FileManager.default.removeItem(at: resumeURL)
            emit(.failed(ModelError.download.localizedDescription))
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error else { return }
        if let data = (error as NSError).userInfo[NSURLSessionDownloadTaskResumeData] as? Data { try? data.write(to: resumeURL) }
        if lock.withLock({ userPaused }) { return }          // pause() already reported this
        let code = (error as? URLError)?.code
        if code == .cancelled { emit(.paused); return }       // system-initiated stop: resumable, never shown as "cancelled"
        switch code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff:
            emit(.failed("No internet connection. Reconnect, then continue the download."))
        case .timedOut:
            emit(.failed("The connection timed out. Continue and it picks up where it stopped."))
        default:
            emit(.failed("The download stopped. Try again to continue."))
        }
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        let completion = lock.withLock { () -> (@Sendable () -> Void)? in
            defer { backgroundCompletion = nil }
            return backgroundCompletion
        }
        if let completion { DispatchQueue.main.async { completion() } }
    }
}
