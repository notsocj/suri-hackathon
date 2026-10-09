import Foundation

/// Notifications contain only fixed copy, never message excerpts, senders, URLs, or model prose.
public enum AutomationPolicy {
    public struct Warning: Equatable, Sendable {
        public let title: String
        public let body: String
    }
    public static func warning(for result: ModelAssessment) -> Warning? {
        guard result.quality == .complete, result.risk == .warningSigns,
              result.findings.contains(where: { $0.code != .timePressure }) else { return nil }
        return Warning(title: "Suri: Warning signs found",
                       body: "Pause before acting. Open Suri to review this local check and verify independently.")
    }
    public static func summary(for result: ModelAssessment) -> String {
        guard result.quality == .complete else { return "Insufficient content. Review the full message before acting." }
        return switch result.risk {
        case .warningSigns: "Warning signs found. Verify independently before acting."
        case .needsVerification: "Needs verification. Review the full message before acting."
        case .noObviousSigns: "No obvious warning signs. This does not confirm legitimacy."
        }
    }
}

/// Bounds work and prevents repeated alerts; failures do not poison the retry cache.
public struct AutomationLedger: Sendable {
    public enum Reservation: Equatable, Sendable { case accepted, duplicate, busy }
    private var active: String?
    private var completed: [String: Date] = [:]
    public init() {}
    public mutating func clearCompleted() { completed.removeAll() }
    public mutating func begin(_ fingerprint: String, now: Date) -> Reservation {
        completed = completed.filter { now.timeIntervalSince($0.value) < 300 }
        if completed[fingerprint] != nil || active == fingerprint { return .duplicate }
        guard active == nil else { return .busy }
        active = fingerprint
        return .accepted
    }
    public mutating func finish(_ fingerprint: String, succeeded: Bool, now: Date) {
        guard active == fingerprint else { return }
        active = nil
        guard succeeded else { return }
        completed[fingerprint] = now
        if completed.count > 100, let oldest = completed.min(by: { $0.value < $1.value })?.key {
            completed.removeValue(forKey: oldest)
        }
    }
}
