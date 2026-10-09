import Foundation
import CryptoKit
import UserNotifications
import SuriCore

@MainActor enum AutomationPreferences {
    static let enabledKey = "allowShortcutsChecks"
    static var enabled: Bool { UserDefaults.standard.bool(forKey: enabledKey) }
    static var consent: String { UserDefaults.standard.string(forKey: "shortcutsConsent") ?? "" }
    static func setEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: enabledKey)
        UserDefaults.standard.set(UUID().uuidString, forKey: "shortcutsConsent")
        AutomationService.shared.resetRecentChecks()
        if !enabled {
            UserDefaults.standard.removeObject(forKey: "automationLastCheck")
            AutomationService.shared.cancel()
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }
    static let historyChanged = Notification.Name("suri.automationHistoryChanged")

    // Only when and what category: never the message, sender or evidence. Lets setup show "Connected".
    private static let lastCheckKey = "automationLastCheck"
    static let skippedOutcome = "skipped"
    static var lastCheck: (date: Date, outcome: String)? {
        let parts = (UserDefaults.standard.string(forKey: lastCheckKey) ?? "").split(separator: "|", maxSplits: 1).map(String.init)
        guard parts.count == 2, let seconds = Double(parts[0]) else { return nil }
        return (Date(timeIntervalSince1970: seconds), parts[1])
    }
    static func recordCheck(outcome: String) {
        UserDefaults.standard.set("\(Date().timeIntervalSince1970)|\(outcome)", forKey: lastCheckKey)
    }
    static func outcomeTitle(_ outcome: String) -> String {
        outcome == skippedOutcome ? "Message too short to check" : (RiskCategory(rawValue: outcome)?.title ?? "Checked")
    }
}

@MainActor final class AutomationService {
    static let shared = AutomationService()
    private var ledger = AutomationLedger()
    // Ephemeral salted fingerprints avoid retaining raw messages or a reusable OTP hash.
    private let salt = UUID().uuidString
    private var active: Task<Assessment, Error>?
    private let analyzer = LocalAnalyzer.shared

    func cancel() { active?.cancel() }
    func resetRecentChecks() { ledger.clearCompleted() }

    enum Source { case shortcut, test }

    func check(_ text: String, source: Source = .shortcut) async throws -> String {
        guard AutomationPreferences.enabled else { throw AutomationError.disabled }
        switch AutomationPolicy.inputIssue(for: text) {
        case .looksLikeSender: throw AutomationError.senderInstead
        case .tooShort:
            if source == .shortcut { AutomationPreferences.recordCheck(outcome: AutomationPreferences.skippedOutcome) }
            return "Too short to check. No warning."
        case nil: break
        }
        try AssessmentValidator.validateInput(text)
        guard ModelFiles.isInstalled else { throw ModelError.missing }
        let fingerprint = SHA256.hash(data: Data((salt + text).utf8)).map { String(format: "%02x", $0) }.joined()
        switch ledger.begin(fingerprint, now: Date()) {
        case .duplicate: return "Already checking or checked this text recently. No duplicate warning was queued."
        case .busy: throw AutomationError.busy
        case .accepted: break
        }
        var succeeded = false
        defer { ledger.finish(fingerprint, succeeded: succeeded, now: Date()); active = nil }
        let consent = AutomationPreferences.consent
        let task = Task { try await analyzer.assess(text: text, revision: UUID()) }
        active = task
        let result = try await withTaskCancellationHandler { try await task.value } onCancel: { task.cancel() }
        try Task.checkCancellation()
        guard AutomationPreferences.enabled, AutomationPreferences.consent == consent else { throw AutomationError.disabled }
        // Unlike manual checks, this path never calls the online guidance service.
        var saved = true
        if UserDefaults.standard.object(forKey: "historyEnabled") as? Bool ?? true {
            do {
                _ = try await CaseStore.shared.append(result)
                NotificationCenter.default.post(name: AutomationPreferences.historyChanged, object: nil)
            } catch { saved = false } // Protected history may be unavailable while the phone is locked.
        }
        try Task.checkCancellation()
        guard AutomationPreferences.enabled, AutomationPreferences.consent == consent else { throw AutomationError.disabled }
        var summary = AutomationPolicy.summary(for: result.result)
        if !saved { summary += " The result could not be saved to history." }
        if let warning = AutomationPolicy.warning(for: result.result) {
            let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
            guard AutomationPreferences.enabled, AutomationPreferences.consent == consent else { throw AutomationError.disabled }
            if status == .authorized || status == .provisional || status == .ephemeral {
                let content = UNMutableNotificationContent()
                content.title = warning.title; content.body = warning.body; content.sound = .default
                content.threadIdentifier = "suri-message-warnings"
                content.userInfo = ["suriAssessmentID": result.id.uuidString]
                let identifier = "suri-check-" + result.id.uuidString
                try await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: identifier, content: content, trigger: nil))
                if !AutomationPreferences.enabled || AutomationPreferences.consent != consent {
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
                    UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
                    throw AutomationError.disabled
                }
                summary += " A private warning was submitted to iOS; display depends on notification and Focus settings."
            } else {
                summary += " No notification was submitted. Enable Suri notifications in Settings."
            }
        }
        succeeded = true
        if source == .shortcut { AutomationPreferences.recordCheck(outcome: result.result.risk.rawValue) }
        return summary
    }
}

nonisolated enum AutomationError: Error, LocalizedError, Equatable {
    case disabled, busy, senderInstead
    var errorDescription: String? {
        switch self {
        case .senderInstead: "That looks like a phone number, not the message. In the automation, set Message text to the message body from Shortcut Input."
        case .disabled: "Shortcuts checks are off. Open Suri Settings, then Message automation, to allow them."
        case .busy: "Another automated check is running. This message was not checked; try again when it finishes."
        }
    }
}
