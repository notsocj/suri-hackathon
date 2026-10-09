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
    @State private var walkthrough = false
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
        .sheet(isPresented: $walkthrough, onDismiss: { Task { await refresh() } }) {
            NavigationStack { AutomationWalkthroughView() }
        }
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
            Text("Apple only lets you create this trigger yourself. We'll walk you through it, one tap at a time.")
                .font(.subheadline).foregroundStyle(.secondary)
            Button { walkthrough = true } label: {
                Label { Text(lastCheck == nil ? "Start guided setup" : "Set up again") } icon: { Image(systemName: "list.number") }
            }.buttonStyle(SuriButtonStyle(filled: lastCheck == nil)).accessibilityIdentifier("start-walkthrough")
            DisclosureGroup {
                Text("Open the automation in Shortcuts and tap Check Message Locally. Tap Message text, then Select Variable, then Shortcut Input. If you see an Ask Each Time token, tap it and choose Clear Variable. Save with the blue checkmark, then Done.")
                    .font(.footnote).foregroundStyle(.secondary).padding(.top, 6)
            } label: {
                Text("Shortcuts asks me to type a message").font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.leading).frame(maxWidth: .infinity, alignment: .leading)
            }.tint(SuriTheme.teal)
            Text("A letter checks most texts, but not one without it, like a link or number on its own. For wider coverage, add a second automation using e. Repeats are skipped.")
                .font(.footnote).foregroundStyle(.secondary)
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

/// One action per screen. Every instruction here was walked through on the iOS 26.5 simulator.
struct AutomationWalkthroughView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var index = 0

    private struct Page {
        let symbol: String, title: String, detail: String
        var opensShortcuts = false, showsWiring = false
    }
    private let pages: [Page] = [
        .init(symbol: "arrow.up.forward.app", title: "Open Shortcuts", detail: "Tap Automation at the bottom, then + at the top right.", opensShortcuts: true),
        .init(symbol: "message", title: "Choose Message", detail: "In the list of triggers, tap Message."),
        .init(symbol: "textformat", title: "Type a under Message Contains", detail: "Tap Message Contains, type the letter a, then tap Done. iOS won't continue while it's empty, and a common letter matches most texts."),
        .init(symbol: "bolt.fill", title: "Choose Run Immediately", detail: "Tap Run Immediately so it shows a tick, then tap Next at the top right."),
        .init(symbol: "plus.square.on.square", title: "Tap Create New Shortcut", detail: "Tap the grey Create New Shortcut card at the top. Don't pick Suri from the list below it, because that hides the field you need."),
        .init(symbol: "magnifyingglass", title: "Add Check Message Locally", detail: "In the search bar, type Check Message, then tap Check Message Locally (the Suri icon)."),
        .init(symbol: "link", title: "Connect the message", detail: "Tap Message text, then Select Variable, then Shortcut Input. Never choose Ask Each Time: it makes Shortcuts ask you to type.", showsWiring: true),
        .init(symbol: "checkmark.circle", title: "Save twice", detail: "Tap the blue checkmark at the top right. On the next screen, tap Done at the top right. Tap Done, not the ✕."),
        .init(symbol: "bell.badge", title: "Test it", detail: "Text this phone from another number. Setup turns to Connected when Suri checks it, and a risky text sends you a private warning.", opensShortcuts: false),
    ]
    private var last: Bool { index == pages.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Step \(index + 1) of \(pages.count)").font(.subheadline.weight(.bold)).foregroundStyle(.secondary)
                ProgressView(value: Double(index + 1), total: Double(pages.count)).tint(SuriTheme.teal)
            }.padding(.horizontal, 24).padding(.top, 8)
            TabView(selection: $index) {
                ForEach(pages.indices, id: \.self) { i in pageView(pages[i]).tag(i) }
            }.tabViewStyle(.page(indexDisplayMode: .never))
            HStack(spacing: 12) {
                if index > 0 {
                    Button("Back") { withAnimation { index -= 1 } }.buttonStyle(SuriButtonStyle(filled: false))
                }
                Button(last ? "Finish" : "Next") { if last { dismiss() } else { withAnimation { index += 1 } } }
                    .buttonStyle(SuriButtonStyle()).accessibilityIdentifier("walkthrough-next")
            }.padding(.horizontal, 24).padding(.vertical, 12)
        }
        .background(SuriTheme.background)
        .navigationTitle("Guided setup").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
    }

    private func pageView(_ page: Page) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Image(systemName: page.symbol).font(.system(size: 30, weight: .semibold)).foregroundStyle(SuriTheme.teal)
                    .frame(width: 68, height: 68).background(SuriTheme.teal.opacity(0.12), in: Circle()).accessibilityHidden(true)
                Text(page.title).font(.title.weight(.heavy)).tracking(-0.4).accessibilityAddTraits(.isHeader)
                Text(page.detail).font(.title3.weight(.medium)).foregroundStyle(.secondary)
                if page.showsWiring { WiringMock() }
                if page.opensShortcuts {
                    Button { if let url = URL(string: "shortcuts://") { openURL(url) } } label: {
                        Label { Text("Open Shortcuts") } icon: { Image(systemName: "arrow.up.forward.app") }
                    }.buttonStyle(SuriButtonStyle()).accessibilityIdentifier("walkthrough-open-shortcuts")
                }
            }.padding(.horizontal, 24).padding(.top, 20).frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// Shows the one wiring that matters: the action's Message text must be the Shortcut Input.
private struct WiringMock: View {
    var body: some View {
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
        .background(SuriTheme.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.primary.opacity(0.08)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Check Message Locally, with Message text set to Shortcut Input")
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
