import Foundation
import SuriCore

actor CaseStore {
    static let shared = CaseStore()
    private let url: URL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("checks.json")

    func load() throws -> [Assessment] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        let values = try JSONDecoder().decode([Assessment].self, from: Data(contentsOf: url))
        return values.filter { Date().timeIntervalSince($0.createdAt) < 7 * 24 * 60 * 60 }
    }
    func save(_ cases: [Assessment]) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let recent = Array(cases.filter { Date().timeIntervalSince($0.createdAt) < 7 * 24 * 60 * 60 }.prefix(50))
        try JSONEncoder().encode(recent).write(to: url, options: [.atomic, .completeFileProtection])
        var protectedURL = url
        var values = URLResourceValues(); values.isExcludedFromBackup = true
        try protectedURL.setResourceValues(values)
    }
    func append(_ assessment: Assessment) throws -> [Assessment] {
        var current = try load()
        current.removeAll { $0.id == assessment.id }
        current.insert(assessment, at: 0)
        current = Array(current.prefix(50))
        try save(current)
        return current
    }
}
