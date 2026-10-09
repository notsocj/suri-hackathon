import SwiftUI
import UserNotifications
import AppIntents
import SuriCore

/// One guided checklist. iOS gives apps no way to create a Message automation, so the only step Suri cannot do
/// for the user is the trigger itself; every other step is a single tap, and the last one confirms it fired.
struct AutomationSettingsView: View {
    var showsDone = false
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @State private var enabled = AutomationPreferences.enabled
    @State private var permission: UNAuthorizationStatus = .notDetermined
    @State private var lastCheck = AutomationPreferences.lastCheck
    @State private var testing = false
    @State private var testResult: String?
    @State private var testPassed = false

    private static let sample = "Para hindi ma-freeze ang account mo, ibigay ang OTP sa akin ngayon. Ako raw ang support agent."
    private var notificationsAllowed: Bool { [.authorized, .provisional, .ephemeral].contains(permission) }
    private var turnedOn: Bool { enabled && notificationsAllowed }
    private var ready: Bool { turnedOn && model.modelInstalled }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Check incoming texts").font(.title.weight(.heavy)).tracking(-0.4)
                    Text("Suri checks each new message on this phone and warns you when one looks risky. Setup takes about two minutes.")
                        .foregroundStyle(.secondary)
                }.padding(.bottom, 6)
                turnOnStep
                modelStep
                testStep
                connectStep
                confirmStep
                NavigationLink { AutomationCoverageView() } label: {
                    Text("What gets checked, and privacy").font(.subheadline.weight(.semibold)).foregroundStyle(SuriTheme.teal)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
            }.padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 24)
        }
        .background(SuriTheme.background)
        .navigationTitle("Message automation").navigationBarTitleDisplayMode(.inline)
        .toolbar { if showsDone { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } } }
        .task { await refresh() }
        .onChange(of: scenePhase) { _, phase in if phase == .active { Task { await refresh() } } }
    }

    // MARK: Steps

    private var turnOnStep: some View {
        SetupStep(number: 1, title: "Turn on checks and warnings", done: turnedOn) {
            if turnedOn {
                Text("Shortcuts can send messages to Suri, and Suri can warn you.").font(.subheadline).foregroundStyle(.secondary)
                Button("Turn off") { enabled = false; AutomationPreferences.setEnabled(false); lastCheck = nil; testPassed = false; testResult = nil }
                    .buttonStyle(SuriLinkStyle()).accessibilityIdentifier("allow-shortcuts-checks")
            } else if permission == .denied && enabled {
                Text("Notifications are off for Suri, so warnings can't reach you.").font(.subheadline).foregroundStyle(.secondary)
                Button("Open iPhone Settings") { if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) } }
                    .buttonStyle(SuriButtonStyle()).accessibilityIdentifier("open-iphone-settings")
            } else {
                Text("This lets Shortcuts pass message text to Suri and lets Suri send you a private warning. It does not give Suri access to your inbox.")
                    .font(.subheadline).foregroundStyle(.secondary)
                Button("Turn on") { Task { await turnOn() } }.buttonStyle(SuriButtonStyle()).accessibilityIdentifier("allow-shortcuts-checks")
            }
        }
    }

    private var modelStep: some View {
        SetupStep(number: 2, title: model.modelInstalled ? "Offline checker ready" : "Get the offline checker", done: model.modelInstalled) {
            if !model.modelInstalled {
                Text("A one-time 1.3 GB download. After it, checks run on this phone without internet.").font(.subheadline).foregroundStyle(.secondary)
                if model.installing {
                    if let fraction = model.downloadFraction { ProgressView(value: fraction) } else { ProgressView() }
                    Text(model.modelStatus).font(.footnote).foregroundStyle(.secondary)
                } else {
                    Button(model.downloadButtonTitle) { model.installModel() }.buttonStyle(SuriButtonStyle())
                }
            }
        }
    }

    private var testStep: some View {
        SetupStep(number: 3, title: "Run a test", done: testPassed, locked: !ready) {
            Text("Checks a sample scam message with the same action Shortcuts will use, and sends you the real warning.")
                .font(.subheadline).foregroundStyle(.secondary)
            if testing {
                HStack(spacing: 10) { ProgressView(); Text("Checking on this device…").font(.subheadline.weight(.semibold)) }
            } else {
                Button(testPassed ? "Run again" : "Run test") { runTest() }
                    .buttonStyle(SuriButtonStyle(filled: !testPassed)).disabled(!ready).accessibilityIdentifier("run-automation-test")
            }
            if let testResult { Text(testResult).font(.footnote).foregroundStyle(testPassed ? SuriTheme.ink : SuriTheme.warning) }
        }
    }

    private var connectStep: some View {
        SetupStep(number: 4, title: "Connect incoming messages", done: lastCheck != nil) {
            Text("Apple only lets you create this trigger yourself, in the Shortcuts app.").font(.subheadline).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 10) {
                instruction("Shortcuts → Automation → + → Message")
                instruction("Tap Message Contains and enter a common letter, such as a. iOS won't continue until a sender or some text is set")
                instruction("Choose Run Immediately, then add Suri → Check Message Locally")
                instruction("Tap its Message text field and choose Shortcut Input from the row above the keyboard")
            }
            actionMock
            Text("If Shortcuts ever asks you to type a message, Message text isn't connected yet. A letter checks most texts, but not one without it, like a link or number on its own. For wider coverage, add a second automation using e. Repeats are skipped.")
                .font(.footnote).foregroundStyle(.secondary)
            Button("Open Shortcuts") { if let url = URL(string: "shortcuts://") { openURL(url) } }
                .buttonStyle(SuriButtonStyle())
            ShortcutsLink(action: { SuriShortcuts.updateAppShortcutParameters() })
                .shortcutsLinkStyle(.automatic).accessibilityIdentifier("open-suri-shortcuts")
        }
    }

    private var confirmStep: some View {
        SetupStep(number: 5, title: lastCheck == nil ? "Confirm it works" : "Connected", done: lastCheck != nil) {
            if let lastCheck {
                Text("Last text checked \(lastCheck.date.formatted(.relative(presentation: .named))): \(AutomationPreferences.outcomeTitle(lastCheck.outcome)).")
                    .font(.subheadline)
                Text("Suri keeps only this time and result, never the message.").font(.footnote).foregroundStyle(.secondary)
            } else {
                Text("Send a text to this phone from another number. When it's checked, this turns to Connected.")
                    .font(.subheadline).foregroundStyle(.secondary)
                Text("If Shortcuts shows an error, that text was not checked.").font(.footnote).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Pieces

    private func instruction(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle().fill(SuriTheme.teal).frame(width: 6, height: 6).padding(.top, 8).accessibilityHidden(true)
            Text(text).font(.subheadline)
        }
    }

    /// Shows the one wiring that matters: the action's Message text must be the Shortcut Input.
    private var actionMock: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                SuriMark(size: 22).foregroundStyle(SuriTheme.teal)
                Text("Check Message Locally").font(.subheadline.weight(.bold))
            }
            HStack(spacing: 8) {
                Text("Message text").font(.footnote).foregroundStyle(.secondary)
                Text("Shortcut Input").font(.footnote.weight(.bold)).foregroundStyle(Color("ActionText"))
                    .padding(.horizontal, 10).padding(.vertical, 4).background(SuriTheme.teal, in: Capsule())
            }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(SuriTheme.background, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.primary.opacity(0.08)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Check Message Locally, with Message text set to Shortcut Input")
    }

    // MARK: Actions

    private func turnOn() async {
        AutomationPreferences.setEnabled(true); enabled = true
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        AutomationService.shared.resetRecentChecks()
        await refresh()
    }

    private func runTest() {
        testing = true; testResult = nil
        Task {
            AutomationService.shared.resetRecentChecks()
            do { testResult = try await AutomationService.shared.check(Self.sample, source: .test); testPassed = true }
            catch { testResult = error.localizedDescription; testPassed = false }
            testing = false
        }
    }

    private func refresh() async {
        enabled = AutomationPreferences.enabled
        lastCheck = AutomationPreferences.lastCheck
        permission = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }
}

private struct SetupStep<Content: View>: View {
    let number: Int
    let title: String
    let done: Bool
    var locked = false
    @ViewBuilder var content: Content

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle().fill(done ? SuriTheme.teal : SuriTheme.teal.opacity(0.12))
                if done {
                    Image(systemName: "checkmark").font(.footnote.weight(.heavy)).foregroundStyle(Color("ActionText"))
                } else {
                    Text("\(number)").font(.subheadline.weight(.bold)).foregroundStyle(SuriTheme.teal)
                }
            }.frame(width: 32, height: 32).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 10) {
                Text(title).font(.headline.weight(.bold)).accessibilityAddTraits(.isHeader)
                content
            }
        }
        .padding(18).frame(maxWidth: .infinity, alignment: .leading).suriCard()
        .opacity(locked ? 0.55 : 1)
        .accessibilityElement(children: .contain)
        .accessibilityValue(done ? "Done" : "")
    }
}

struct AutomationCoverageView: View {
    var body: some View {
        Form {
            Section("Which messages are checked") {
                Text("Only text passed by your Shortcuts trigger is checked. iOS requires a sender or some Message Contains text, so Suri checks the texts that match what you enter. A common letter matches most messages but not all; this is not guaranteed protection for every incoming message.")
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
