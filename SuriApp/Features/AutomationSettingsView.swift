import SwiftUI
import UserNotifications
import AppIntents

struct AutomationSettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL
    @State private var enabled = AutomationPreferences.enabled
    @State private var permission = "Checking permission…"
    @State private var error: String?

    var body: some View {
        Form {
            Section {
                Text("Suri’s checking shortcut comes with the app. Open it below, then connect it to a Message trigger once.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Section {
                Text(model.modelInstalled ? "Local model ready" : "Download the model in Settings first")
                Toggle("Allow Shortcuts checks", isOn: Binding(get: { enabled }, set: {
                    enabled = $0; AutomationPreferences.setEnabled($0)
                })).accessibilityIdentifier("allow-shortcuts-checks")
                Button("Allow warning notifications") {
                    Task {
                        do {
                            _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
                            AutomationService.shared.resetRecentChecks()
                            await refreshPermission()
                        } catch { self.error = "Check iPhone Settings → Notifications → Suri to allow warnings." }
                    }
                }
                Text(permission).font(.footnote).foregroundStyle(.secondary)
            } header: { Text("1. Allow local checks and warnings") } footer: {
                Text("This lets Shortcuts pass message text to Suri. It does not give Suri access to your inbox.")
            }
            Section {
                ShortcutsLink(action: { SuriShortcuts.updateAppShortcutParameters() })
                    .shortcutsLinkStyle(.automatic)
                    .accessibilityIdentifier("open-suri-shortcuts")
                    .disabled(!enabled || !model.modelInstalled)
                Text("Look for Check Message Locally on Suri’s page. No separate download or iCloud link is needed.")
                    .font(.footnote).foregroundStyle(.secondary)
            } header: { Text("2. Open the ready-made shortcut") }
            Section {
                Text("Shortcuts → Automation → + → Message").font(.headline)
                Text("Choose a sender or text filter, select Run Immediately if offered, and use Suri’s Check Message Locally action.")
                Text("Message text must use the received message body from Shortcut Input. Confirm the input before saving.")
                    .font(.subheadline).foregroundStyle(.secondary)
                Button("Open Shortcuts") { openURL(URL(string: "shortcuts://")!) }
            } header: { Text("3. Connect incoming messages") } footer: {
                Text("Apple keeps this trigger on each phone. Suri cannot silently install it or select which messages you monitor.")
            }
            Section {
                Text("Send a synthetic test message from the selected sender. Start unlocked, then try while locked. If Shortcuts reports an error, the message was not checked.")
                NavigationLink("Coverage and privacy") { AutomationCoverageView() }
            } header: { Text("Check your setup") }
        }
        .navigationTitle("Message automation").navigationBarTitleDisplayMode(.inline)
        .task { await refreshPermission() }
        .alert("Notifications", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("OK") { error = nil }
        } message: { Text(error ?? "") }
    }
    private func refreshPermission() async {
        let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        switch status {
        case .authorized, .provisional, .ephemeral: permission = "Notification permission allowed"
        case .denied: permission = "Off. Enable Suri in iPhone Settings → Notifications."
        default: permission = "Notification permission not requested"
        }
    }
}

struct AutomationCoverageView: View {
    var body: some View {
        Form {
            Section("Which messages are checked") {
                Text("Only text passed by your Shortcuts trigger is checked. Sender and text filters determine coverage; this is not guaranteed protection for every incoming message.")
                Text("Suri cannot read Messenger or other apps’ notification inboxes on iOS 26. Use sharing, copied text, or screenshot import for those apps.")
                Text("Background and locked-screen execution depend on iOS and need testing on your phone. An error means no completed check.")
            }
            Section("Private warnings") {
                Text("The action uses local AI only. Warnings never include the message, OTP, sender, links, or model-generated text. Focus settings may silence or delay alerts.")
                Text("Only complete validated warning results create alerts. Urgency alone, incomplete input, and failures never become confirmed scam verdicts. Results can be wrong; verify independently.")
            }
            Section("Your controls") {
                Text("Turning off Shortcuts checks cancels the active automated check and pending Suri warnings. No message is queued for later upload and no family message is sent automatically.")
                Text("Save check history applies to automated checks. Evidence may contain private details; notification previews do not. Repeated identical text is suppressed for five minutes while the app process remains running.")
            }
        }.navigationTitle("Coverage and privacy").navigationBarTitleDisplayMode(.inline)
    }
}
