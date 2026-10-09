import Foundation
import CryptoKit
import UserNotifications
import UIKit
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
            UserDefaults.standard.removeObject(forKey: "automationLastRun")
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
    /// Which stage each automatic run reached, for diagnosing runs that Shortcuts reports as failed.
    /// Only times and a stage name are stored: never the message, sender, or evidence.
    enum RunStage: String { case checking, saved, finished, failed, interrupted }
    private static let lastRunKey = "automationLastRun"
    static func recordRun(_ stage: RunStage, started: Date) {
        UserDefaults.standard.set("\(started.timeIntervalSince1970)|\(Date().timeIntervalSince1970)|\(stage.rawValue)", forKey: lastRunKey)
    }
    static func recordRunInterrupted() {
        guard let run = lastRun, run.stage == .checking || run.stage == .saved else { return }
        recordRun(.interrupted, started: run.started)
    }
    static var lastRun: (started: Date, updated: Date, stage: RunStage)? {
        let parts = (UserDefaults.standard.string(forKey: lastRunKey) ?? "").split(separator: "|").map(String.init)
        guard parts.count == 3, let a = Double(parts[0]), let b = Double(parts[1]), let stage = RunStage(rawValue: parts[2]) else { return nil }
        return (Date(timeIntervalSince1970: a), Date(timeIntervalSince1970: b), stage)
    }
    static var lastRunSummary: String? {
        guard let run = lastRun else { return nil }
        let seconds = max(0, Int(run.updated.timeIntervalSince(run.started).rounded()))
        let time = run.started.formatted(date: .omitted, time: .shortened)
        return switch run.stage {
        case .finished: "Last automatic check at \(time) finished in \(seconds) seconds."
        case .checking: "The automatic check at \(time) started but didn't finish. iOS may have stopped it."
        case .saved: "The automatic check at \(time) was saved, but stopped before the warning step."
        case .interrupted: "iOS stopped the automatic check at \(time) after \(seconds) seconds."
        case .failed: "The automatic check at \(time) failed after \(seconds) seconds."
        }
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
    private var active: Task<String, Error>?
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
        let consent = AutomationPreferences.consent
        let started = Date()
        // Risky-looking texts get an instant "wait" before the model runs; the result later replaces it.
        let notificationID: String? = source == .shortcut && AutomationPolicy.needsHeadsUp(text) ? "suri-run-" + UUID().uuidString : nil
        if let notificationID { await Self.post(AutomationPolicy.headsUp, id: notificationID, assessmentID: nil) }
        // Keeps the app running if Shortcuts stops waiting, so the check can still save and warn.
        let assertion = BackgroundAssertion.begin()
        if source == .shortcut { AutomationPreferences.recordRun(.checking, started: started) }
        let work = Task { () throws -> String in
            var succeeded = false
            defer { self.ledger.finish(fingerprint, succeeded: succeeded, now: Date()); self.active = nil; assertion.end() }
            do {
                let summary = try await self.complete(text, consent: consent, started: started, source: source, notificationID: notificationID)
                succeeded = true
                return summary
            } catch {
                if source == .shortcut { AutomationPreferences.recordRun(.failed, started: started) }
                if let notificationID {
                    if error is AutomationError, (error as? AutomationError) == .disabled {
                        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notificationID])
                    } else {
                        await Self.post(AutomationPolicy.couldNotFinish, id: notificationID, assessmentID: nil)
                    }
                }
                throw error
            }
        }
        active = work
        guard source == .shortcut else { return try await work.value }
        // Shortcuts gives up on a background action after an undocumented limit and then reports
        // "unknown error". Answer before that; the check keeps running and warns when it finishes.
        // (A task group can't do this: it waits for every child before returning.)
        let limit = Self.shortcutWaitLimit
        let gate = FirstResult()
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do { gate.resume(continuation, with: .success(try await work.value)) }
                catch { gate.resume(continuation, with: .failure(error)) }
            }
            Task {
                try? await Task.sleep(for: limit)
                gate.resume(continuation, with: .success("Still checking on this device. Suri will send a private warning if it finds warning signs."))
            }
        }
    }

    static var shortcutWaitLimit: Duration = .seconds(20)

    /// Posts fixed copy only. Reusing an identifier replaces the earlier notification in place.
    private static func post(_ copy: AutomationPolicy.Warning, id: String, assessmentID: UUID?) async {
        let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional || status == .ephemeral else { return }
        let content = UNMutableNotificationContent()
        content.title = copy.title; content.body = copy.body; content.sound = .default
        content.threadIdentifier = "suri-message-warnings"
        if let assessmentID { content.userInfo = ["suriAssessmentID": assessmentID.uuidString] }
        try? await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: id, content: content, trigger: nil))
    }

    private func complete(_ text: String, consent: String, started: Date, source: Source, notificationID: String?) async throws -> String {
        let result = try await analyzer.assess(text: text, revision: UUID())
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
        if source == .shortcut { AutomationPreferences.recordRun(.saved, started: started) }
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
                let identifier = notificationID ?? "suri-check-" + result.id.uuidString // replaces the heads-up
                do {
                    try await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: identifier, content: content, trigger: nil))
                    if !AutomationPreferences.enabled || AutomationPreferences.consent != consent {
                        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
                        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
                        throw AutomationError.disabled
                    }
                    summary += " A private warning was submitted to iOS; display depends on notification and Focus settings."
                } catch let error as AutomationError { throw error }
                catch { summary += " iOS did not accept the warning notification. Open Suri to see the result." }
            } else {
                summary += " No notification was submitted. Enable Suri notifications in Settings."
            }
        } else if let notificationID {
            await Self.post(AutomationPolicy.finished(for: result.result), id: notificationID, assessmentID: saved ? result.id : nil)
        }
        if source == .shortcut {
            AutomationPreferences.recordCheck(outcome: result.result.risk.rawValue)
            AutomationPreferences.recordRun(.finished, started: started)
        }
        return summary
    }
}

/// Resumes a continuation once, with whichever result arrives first.
@MainActor private final class FirstResult {
    private var done = false
    func resume(_ continuation: CheckedContinuation<String, Error>, with result: Result<String, Error>) {
        guard !done else { return }
        done = true
        continuation.resume(with: result)
    }
}

/// A UIKit background-time request tied to one automated check.
@MainActor final class BackgroundAssertion {
    private var id: UIBackgroundTaskIdentifier = .invalid
    static func begin() -> BackgroundAssertion {
        let assertion = BackgroundAssertion()
        assertion.id = UIApplication.shared.beginBackgroundTask(withName: "Suri local check") { [weak assertion] in
            AutomationPreferences.recordRunInterrupted()
            assertion?.end()
        }
        return assertion
    }
    func end() {
        guard id != .invalid else { return }
        UIApplication.shared.endBackgroundTask(id)
        id = .invalid
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
