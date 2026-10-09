import Foundation

nonisolated enum SharedInbox {
    static let group = "group.ph.suri.app"
    enum Content: Sendable { case text(String), image(Data) }
    static var directory: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)?.appendingPathComponent("Inbox", isDirectory: true)
    }
    static func save(_ data: Data, image: Bool) throws {
        guard let directory, !data.isEmpty, data.count <= (image ? 25 * 1024 * 1024 : 20_000) else { throw InboxError.unavailable }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        purgeExpired()
        let existing = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        guard existing.count < 10 else { throw InboxError.full }
        let url = directory.appendingPathComponent(UUID().uuidString + (image ? ".image" : ".txt"))
        try data.write(to: url, options: [.atomic, .completeFileProtection])
        var protectedURL = url
        var values = URLResourceValues(); values.isExcludedFromBackup = true
        try protectedURL.setResourceValues(values)
    }
    static func takeNext() -> Content? {
        guard let directory else { return nil }
        purgeExpired()
        let values = ((try? FileManager.default.contentsOfDirectory(at: directory,
            includingPropertiesForKeys: [.creationDateKey, .fileSizeKey, .isSymbolicLinkKey])) ?? [])
            .filter { ["image", "txt"].contains($0.pathExtension) }
            .sorted { ((try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast)
                < ((try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast) }
        guard let url = values.first,
              let attributes = try? url.resourceValues(forKeys: [.fileSizeKey, .isSymbolicLinkKey]),
              attributes.isSymbolicLink != true,
              let size = attributes.fileSize, size <= 25 * 1024 * 1024,
              let data = try? Data(contentsOf: url) else { return nil }
        try? FileManager.default.removeItem(at: url)
        return url.pathExtension == "image" ? .image(data) : .text(String(decoding: data, as: UTF8.self))
    }
    private static func purgeExpired() {
        guard let directory else { return }
        for url in (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.creationDateKey])) ?? [] {
            let created = (try? url.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            if Date().timeIntervalSince(created) > 3600 { try? FileManager.default.removeItem(at: url) }
        }
    }
}

nonisolated enum InboxError: Error, LocalizedError {
    case unavailable, full
    var errorDescription: String? {
        switch self {
        case .unavailable: "Could not save this content for Suri. Try importing it directly in the app."
        case .full: "Open Suri to review your pending imports, then share again."
        }
    }
}
