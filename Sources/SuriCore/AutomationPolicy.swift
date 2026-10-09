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
    /// Shown the moment a risky-looking text arrives, before the model runs. Fixed copy only.
    public static let headsUp = Warning(title: "Wait! Hayaan mo si Suri suriin ito.",
        body: "This text mentions money, a code, a promo, or a link. Don't reply, click, or pay until Suri finishes checking.")
    public static let couldNotFinish = Warning(title: "Suri couldn't finish checking",
        body: "Open Suri and paste the message to check it again. Until then, don't reply, click, or pay.")
    /// Replaces the heads-up when the check ends without warning signs. Never says "safe".
    public static func finished(for result: ModelAssessment) -> Warning {
        Warning(title: "Suri finished checking", body: summary(for: result))
    }

    /// Deterministic pre-screen for the heads-up: money, codes, promos, accounts, links, and pressure.
    /// It decides only whether to say "wait"; the verdict always comes from the full local check.
    public static func needsHeadsUp(_ text: String) -> Bool {
        let lower = text.lowercased()
        if lower.range(of: #"[₱$€£¥]|\b(?:php|usd|p)\s?\d{2,}|(?<![\d,.])\d{1,3}(?:,\d{3})+(?:\.\d+)?"#, options: .regularExpression) != nil { return true }
        if lower.range(of: #"https?://|www\.|\b[a-z0-9-]+\.(?:com|ph|net|org|xyz|top|info|link|site|online)\b|bit\.ly"#, options: .regularExpression) != nil { return true }
        let words = #"\b(?:pesos?|piso|bayad|bayaran|magbayad|fee|deposit|payment|pay|padala|send money|cash|loan|utang|gcash|maya|bank|bangko|account|wallet|otp|code|pin|password|passcode|verification|verify|i-verify|promo|libre|free|discount|voucher|claim|prize|premyo|panalo|won|winner|reward|raffle|urgent|ngayon din|suspended|blocked|ma-block|na-block|click|link)\b"#
        return lower.range(of: words, options: .regularExpression) != nil
    }

    public enum InputIssue: Equatable, Sendable { case tooShort, looksLikeSender }
    /// Cheap, deterministic screening before any model work. A Shortcut that is wired to the sender instead of
    /// the message body passes a phone number; very short texts carry too little to assess.
    public static func inputIssue(for text: String) -> InputIssue? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let phoneLike = trimmed.count <= 20 && trimmed.filter(\.isNumber).count >= 5
            && trimmed.allSatisfy { $0.isNumber || "+-() ".contains($0) }
        if phoneLike { return .looksLikeSender }
        if trimmed.count < 10 { return .tooShort }
        return nil
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
