import AppIntents

struct CheckMessageLocallyIntent: AppIntent {
    nonisolated static var title: LocalizedStringResource { "Check Message Locally" }
    nonisolated static var description: IntentDescription {
        "Check supplied message text with Suri's downloaded local model. Never sends text to a cloud service. Warning notifications require opt-in and notification permission."
    }
    @available(iOS 26.0, *)
    nonisolated static var supportedModes: IntentModes { .background }
    @Parameter(title: "Message text", description: "Pass the received message body from Shortcut Input. Do not pass only the sender or notification title.")
    var message: String
    nonisolated static var parameterSummary: some ParameterSummary { Summary("Check \(\.$message) locally") }
    @MainActor func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: try await AutomationService.shared.check(message))
    }
}

/// Opens Suri and checks the text just copied, for apps such as Messenger that iOS automations
/// can't read. The clipboard is read only when the person runs this action, never in the background.
struct CheckCopiedMessageIntent: AppIntent {
    nonisolated static var title: LocalizedStringResource { "Check Copied Message" }
    nonisolated static var description: IntentDescription {
        "Opens Suri and checks the message you just copied, on this device. Copy a message in Messenger or any app first."
    }
    nonisolated static var openAppWhenRun: Bool { true }
    @available(iOS 26.0, *)
    nonisolated static var supportedModes: IntentModes { .foreground }
    @MainActor func perform() async throws -> some IntentResult {
        ClipboardCheck.request()
        return .result()
    }
}

/// A one-shot request the Check screen consumes, so it survives a cold launch by the action.
@MainActor enum ClipboardCheck {
    static let requested = Notification.Name("suri.clipboardCheckRequested")
    private static let key = "pendingClipboardCheck"
    static func request() {
        UserDefaults.standard.set(true, forKey: key)
        NotificationCenter.default.post(name: requested, object: nil)
    }
    static func take() -> Bool {
        guard UserDefaults.standard.bool(forKey: key) else { return false }
        UserDefaults.standard.removeObject(forKey: key)
        return true
    }
}

nonisolated struct SuriShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: CheckMessageLocallyIntent(), phrases: ["Check a message with \(.applicationName)"],
                    shortTitle: "Check Message Locally", systemImageName: "checkmark.shield")
        AppShortcut(intent: CheckCopiedMessageIntent(), phrases: ["Check copied message with \(.applicationName)", "Check my clipboard with \(.applicationName)"],
                    shortTitle: "Check Copied Message", systemImageName: "doc.on.clipboard")
    }
}
