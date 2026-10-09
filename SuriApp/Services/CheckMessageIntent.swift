import AppIntents

struct CheckMessageLocallyIntent: AppIntent {
    nonisolated static var title: LocalizedStringResource { "Check Message Locally" }
    nonisolated static var description: IntentDescription {
        "Check supplied message text with Suri's downloaded local model. Never sends text to a cloud service. Warning notifications require opt-in and notification permission."
    }
    @available(iOS 26.0, *)
    nonisolated static var supportedModes: IntentModes { .background }
    @Parameter(title: "Message text", description: "Pass the received message body from Shortcut Input. Do not pass only the sender or notification title.", inputConnectionBehavior: .connectToPreviousIntentResult)
    var message: String
    nonisolated static var parameterSummary: some ParameterSummary { Summary("Check \(\.$message) locally") }
    @MainActor func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: try await AutomationService.shared.check(message))
    }
}

nonisolated struct SuriShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: CheckMessageLocallyIntent(), phrases: ["Check a message with \(.applicationName)"],
                    shortTitle: "Check Message Locally", systemImageName: "checkmark.shield")
    }
}
