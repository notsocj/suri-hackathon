import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import SuriCore

struct CheckView: View {
    @Environment(AppModel.self) private var model
    @State private var photo: PhotosPickerItem?
    @State private var importFile = false
    @State private var help = false
    @State private var settings = false
    @FocusState private var editing: Bool

    private var hasText: Bool { !model.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var busy: Bool { model.phase == .checking || model.phase == .extracting }

    var body: some View {
        let result: Assessment? = model.phase == .result ? model.assessment : nil
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let result {
                    ResultView(assessment: result, askFamily: { help = true }, checkAnother: { model.clearInput() })
                } else {
                    header
                    if !model.modelInstalled { setupBanner }
                    phaseContent
                    captureButtons
                    inputEditor
                    if model.text.isEmpty { recentChecks }
                    Text("Your screenshot and message stay on this device.")
                        .font(.footnote.weight(.medium)).foregroundStyle(.secondary)
                }
            }.padding(.horizontal, 24).padding(.top, result == nil ? 12 : 8).padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(SuriTheme.background)
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar(result) }
        .navigationTitle(result == nil ? "" : "Your check")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(result == nil ? .hidden : .automatic, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { editing = false } }
        }
        .onChange(of: photo) { _, selection in
            guard let selection else { return }
            Task {
                do {
                    guard let data = try await selection.loadTransferable(type: Data.self) else { throw CaptureError.invalidImage }
                    model.importImage(data)
                } catch { model.notice = error.localizedDescription }
                photo = nil
            }
        }
        .fileImporter(isPresented: $importFile, allowedContentTypes: [.image]) { result in
            do {
                let url = try result.get()
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                guard (attributes[.size] as? NSNumber)?.intValue ?? Int.max <= 25 * 1024 * 1024 else { throw CaptureError.invalidImage }
                model.importImage(try Data(contentsOf: url))
            } catch { model.notice = error.localizedDescription }
        }
        .sheet(isPresented: $help) { NavigationStack { FamilyHelpView(assessment: model.assessment) } }
        .sheet(isPresented: $settings) { NavigationStack { SettingsView() } }
        .onChange(of: model.selectedTab) { _, _ in editing = false }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in importSharedContent() }
        .task { importSharedContent() }
    }

    // MARK: Pinned primary action — one filled button per state, always reachable.

    @ViewBuilder private func bottomBar(_ result: Assessment?) -> some View {
        if let result {
            let warn = result.result.risk != .noObviousSigns
            Group {
                if warn {
                    Button { help = true } label: { Label { Text("Ask my family") } icon: { SolarIcon(name: "users-group-rounded-outline") } }
                        .accessibilityIdentifier("ask-family")
                } else {
                    Button("Check another message") { model.clearInput() }
                }
            }.buttonStyle(SuriButtonStyle()).barBackground()
        } else if hasText && !busy {
            Button { editing = false; model.check() } label: {
                Label { Text("Check message") } icon: { SolarIcon(name: "shield-check-outline") }
            }.buttonStyle(SuriButtonStyle()).accessibilityIdentifier("check-message").barBackground()
        }
    }

    // MARK: Idle

    private var header: some View {
        VStack(alignment: .leading, spacing: 28) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    SuriWordmark()
                    Text("Suri bago sorry.").font(.footnote.weight(.medium)).foregroundStyle(.secondary)
                }
                Spacer(minLength: 12)
                SuriIconButton(icon: "settings-outline", label: "Settings") { settings = true }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Check a message").font(.largeTitle.weight(.heavy)).tracking(-0.6)
                Text("Before you reply, click, or pay.").font(.body.weight(.medium)).foregroundStyle(.secondary)
            }
        }
    }
    private var captureButtons: some View {
        VStack(spacing: 4) {
            PhotosPicker(selection: $photo, matching: .images) {
                Label { Text("Choose screenshot") } icon: { SolarIcon(name: "gallery-outline") }
            }.buttonStyle(SuriButtonStyle(filled: !hasText)).accessibilityIdentifier("choose-screenshot")
            Button("Import from Files") { importFile = true }.buttonStyle(SuriLinkStyle())
        }
    }
    private var setupBanner: some View {
        HStack(alignment: .top, spacing: 14) {
            SolarIcon(name: "download-minimalistic-outline", size: 26).foregroundStyle(SuriTheme.teal).padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text("Set up offline checking").font(.headline.weight(.bold))
                Text("One-time 1.3 GB download. After that, checks work without internet.")
                    .font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                Button("Open setup") { settings = true }.buttonStyle(SuriLinkStyle())
            }
        }.padding(18).frame(maxWidth: .infinity, alignment: .leading).suriCard()
    }
    private var inputEditor: some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionHeading(title: "Message")
                Spacer()
                if !model.text.isEmpty { Button("Clear") { model.clearInput() }.buttonStyle(SuriLinkStyle()) }
            }
            ZStack(alignment: .topLeading) {
                if model.text.isEmpty {
                    Text("Paste or type the message here…").foregroundStyle(.secondary)
                        .padding(.top, 8).padding(.leading, 5).allowsHitTesting(false)
                }
                TextEditor(text: $model.text).frame(minHeight: 120).scrollContentBackground(.hidden)
                    .autocorrectionDisabled().textInputAutocapitalization(.never)
                    .focused($editing).accessibilityLabel("Message to check").accessibilityIdentifier("message-input")
            }.padding(12).suriCard(radius: 16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(SuriTheme.teal.opacity(editing ? 0.7 : 0), lineWidth: 1.5))
            if model.text.isEmpty {
                let target = self.model
                PasteButton(payloadType: String.self) { strings in
                    guard let value = strings.first else { return }
                    Task { @MainActor in target.needsOCRReview = false; target.text = value }
                }.labelStyle(.titleAndIcon).buttonBorderShape(.capsule).tint(SuriTheme.teal)
            } else {
                Text("Check that the text matches the message, especially “not”, codes, amounts, and links. Edit anything the reader missed.")
                    .font(.footnote.weight(.medium)).foregroundStyle(model.needsOCRReview ? SuriTheme.warning : .secondary)
                if model.text.count > 2_000 {
                    Text("\(model.text.count) / 3,000 characters").font(.caption.weight(.medium)).foregroundStyle(.secondary)
                }
            }
        }
    }
    @ViewBuilder private var phaseContent: some View {
        switch model.phase {
        case .checking, .extracting:
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) { ProgressView(); Text(model.phase == .checking ? "Checking on this device…" : "Reading your screenshot…").font(.headline.weight(.bold)) }
                Text(model.phase == .checking ? "The first check takes longer while the model loads. Your message stays here." : "You can correct the text before checking.")
                    .font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                Button("Cancel") { model.cancelCheck() }.buttonStyle(SuriLinkStyle())
            }.padding(18).frame(maxWidth: .infinity, alignment: .leading).suriCard()
        case .failed(let message):
            VStack(alignment: .leading, spacing: 8) {
                Text("Could not complete check").font(.headline.weight(.bold)).foregroundStyle(SuriTheme.warning)
                Text(message).font(.subheadline.weight(.medium))
                Button("Ask someone I trust") { help = true }.buttonStyle(SuriLinkStyle())
            }.padding(18).frame(maxWidth: .infinity, alignment: .leading).suriCard()
        default: EmptyView()
        }
    }
    @ViewBuilder private var recentChecks: some View {
        if !model.history.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                HStack { SectionHeading(title: "Recent"); Spacer(); Button("See all") { model.selectedTab = 1 }.buttonStyle(SuriLinkStyle()) }
                ForEach(Array(model.history.prefix(3).enumerated()), id: \.element.id) { index, item in
                    if index > 0 { Divider() }
                    Button { model.viewHistory(item) } label: { HistoryRow(assessment: item) }.buttonStyle(.plain)
                }
            }
        }
    }
    private func importSharedContent() {
        guard let content = SharedInbox.takeNext() else { return }
        switch content {
        case .text(let value): model.cancelCheck(); model.text = value; model.selectedTab = 0
        case .image(let data): model.importImage(data)
        }
    }
}

private extension View {
    func barBackground() -> some View {
        padding(.horizontal, 24).padding(.vertical, 10).frame(maxWidth: .infinity)
            .background(SuriTheme.background)
    }
}
