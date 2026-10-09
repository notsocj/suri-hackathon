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

    var body: some View {
        @Bindable var model = model
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                if model.phase == .result, let assessment = model.assessment {
                    ResultView(assessment: assessment) { help = true }
                    Button("Check another message") { model.clearInput() }.buttonStyle(SuriButtonStyle(filled: false))
                } else {
                    header
                    captureButtons
                    if !model.modelInstalled { setupCard }
                    inputEditor
                    phaseContent
                    if model.phase != .checking && model.phase != .extracting {
                        Button {
                            editing = false; model.check()
                        } label: { Label { Text("Check this message") } icon: { SolarIcon(name: "shield-check-outline") } }
                            .buttonStyle(SuriButtonStyle())
                            .disabled(model.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .opacity(model.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                            .accessibilityIdentifier("check-message")
                    }
                    if model.text.isEmpty { recentChecks }
                    Text("Your screenshot and message stay on this device. Online guidance is optional and shares categories only.")
                        .font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
            }.padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 30)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(SuriTheme.background)
        .navigationTitle(model.phase == .result ? "Your check" : "")
        .navigationBarTitleDisplayMode(.inline)
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            SuriWordmark()
            Text("Suri bago sorry.").font(.subheadline).foregroundStyle(.secondary)
            Text("Pause. Check.\nDecide with care.")
                .font(.system(.largeTitle, design: .default, weight: .semibold)).tracking(-0.8).padding(.top, 14)
            Text("Get a second opinion on a message before you reply, click, or pay.")
                .font(.body).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }
    private var captureButtons: some View {
        VStack(spacing: 12) {
            PhotosPicker(selection: $photo, matching: .images) {
                Label { Text("Choose screenshot") } icon: { SolarIcon(name: "gallery-outline") }
            }.buttonStyle(SuriButtonStyle()).accessibilityIdentifier("choose-screenshot")
            Button { editing = true } label: {
                Label { Text("Paste or type a message") } icon: { SolarIcon(name: "clipboard-text-outline") }
            }.buttonStyle(SuriButtonStyle(filled: false))
            Button("Import an image from Files") { importFile = true }.font(.subheadline).padding(.vertical, 4)
        }
    }
    private var setupCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label { Text("Prepare your offline checker").font(.headline) } icon: { SolarIcon(name: "download-minimalistic-outline") }
            Text("Download the local model once (about 1.3 GB). After setup, checking works without internet.")
                .font(.subheadline).foregroundStyle(.secondary)
            Button("Open model setup") { settings = true }.font(.headline).padding(.vertical, 6)
        }.padding(20).background(SuriTheme.surface, in: RoundedRectangle(cornerRadius: 20))
    }
    private var inputEditor: some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeading(title: "Message to check")
                Spacer()
                if !model.text.isEmpty { Button("Clear") { model.clearInput() }.font(.subheadline) }
            }
            ZStack(alignment: .topLeading) {
                if model.text.isEmpty { Text("Paste or type the message here…").foregroundStyle(.secondary).padding(.top, 12).padding(.leading, 5).allowsHitTesting(false) }
                TextEditor(text: $model.text).frame(minHeight: 145).scrollContentBackground(.hidden)
                    .focused($editing).accessibilityLabel("Message to check").accessibilityIdentifier("message-input")
            }.padding(12).background(SuriTheme.surface, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.primary.opacity(editing ? 0.25 : 0.08)))
            if !model.text.isEmpty {
                Text("Review the text first—especially ‘not’, codes, amounts, and links. Edit anything the screenshot reader missed.")
                    .font(.footnote).foregroundStyle(model.needsOCRReview ? SuriTheme.warning : .secondary)
                Text("\(model.text.count) / 3,000 characters").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
    @ViewBuilder private var phaseContent: some View {
        switch model.phase {
        case .checking, .extracting:
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) { ProgressView(); Text(model.phase == .checking ? "Checking on this device…" : "Reading your screenshot…").font(.headline) }
                Text(model.phase == .checking ? "The first check may take longer while the model loads. Your message stays here." : "You can review and correct the text before checking.")
                    .font(.subheadline).foregroundStyle(.secondary)
                Button("Cancel") { model.cancelCheck() }.padding(.vertical, 5)
            }.padding(20).background(SuriTheme.surface, in: RoundedRectangle(cornerRadius: 18))
        case .failed(let message):
            VStack(alignment: .leading, spacing: 10) {
                Text("Could not complete check").font(.headline)
                Text(message).font(.subheadline)
                Button("Ask someone I trust") { help = true }.font(.headline).padding(.vertical, 5)
            }.foregroundStyle(SuriTheme.warning).padding(20).background(SuriTheme.surface, in: RoundedRectangle(cornerRadius: 18))
        default: EmptyView()
        }
    }
    @ViewBuilder private var recentChecks: some View {
        if !model.history.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                HStack { SectionHeading(title: "Recent checks"); Spacer(); Button("See all") { model.selectedTab = 1 }.font(.subheadline) }
                ForEach(model.history.prefix(2)) { item in
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
