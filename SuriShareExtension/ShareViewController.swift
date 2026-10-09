import UIKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor final class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let view = UIHostingController(rootView: ShareImportView(context: extensionContext))
        addChild(view); self.view.addSubview(view.view)
        view.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            view.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            view.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            view.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        view.didMove(toParent: self)
    }
}

struct ShareImportView: View {
    let context: NSExtensionContext?
    @State private var status = "Preparing your selected content…"
    @State private var loaded = false
    @State private var image: Data?
    @State private var text: String?
    @State private var saved = false
    @State private var task: Task<Void, Never>?
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Suri").font(.largeTitle.bold())
                    Text("Suri bago sorry.").foregroundStyle(.secondary)
                    Text(saved ? "Ready to check in Suri" : "Check selected content").font(.title2.weight(.semibold))
                    Text(status)
                    if let image, let preview = UIImage(data: image) {
                        Image(uiImage: preview).resizable().scaledToFit().frame(maxHeight: 300).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    if let text { Text(text).lineLimit(12).font(.body).textSelection(.enabled) }
                    if loaded && !saved {
                        Button("Save for local checking") { save() }.buttonStyle(.borderedProminent).controlSize(.large)
                    }
                    if saved {
                        Text("Open Suri to review the extracted text and run the local check. This extension does not upload content or run a background check.")
                            .foregroundStyle(.secondary)
                        Button("Done") { context?.completeRequest(returningItems: nil) }.buttonStyle(.borderedProminent).controlSize(.large)
                    }
                    Text("Pending shared content expires after one hour. It is removed when imported or when Suri next checks the inbox.").font(.footnote).foregroundStyle(.secondary)
                }.padding(24)
            }.navigationTitle("Share to Suri").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { task?.cancel(); context?.completeRequest(returningItems: nil) } } }
                .onAppear { task = Task { await load() } }
                .onDisappear { task?.cancel() }
        }.tint(Color(red: 0.13, green: 0.40, blue: 0.36))
    }
    private func load() async {
        let items = context?.inputItems.compactMap { $0 as? NSExtensionItem } ?? []
        let providers = items.flatMap { $0.attachments ?? [] }
        do {
            if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) }) {
                let data = try await data(from: provider, type: UTType.image.identifier)
                try Task.checkCancellation()
                guard data.count <= 25 * 1024 * 1024, UIImage(data: data) != nil else { throw InboxError.unavailable }
                image = data; loaded = true; status = "Only this selected image will be imported."
            } else if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) }) {
                let data = try await data(from: provider, type: UTType.plainText.identifier)
                try Task.checkCancellation()
                guard data.count <= 20_000 else { throw InboxError.unavailable }
                text = String(decoding: data, as: UTF8.self); loaded = true; status = "Review the text selected for local checking."
            } else if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }) {
                let item = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier) { item, error in
                        if let error { continuation.resume(throwing: error) }
                        else if let url = item as? URL { continuation.resume(returning: url.absoluteString) }
                        else { continuation.resume(throwing: InboxError.unavailable) }
                    }
                }
                try Task.checkCancellation(); text = item; loaded = true
                status = "The link will be imported as text. Suri will not open it automatically."
            } else { status = "This app did not share readable text or an image. Take a screenshot and import it in Suri." }
        } catch is CancellationError { }
        catch { status = error.localizedDescription }
    }
    private func data(from provider: NSItemProvider, type: String) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadDataRepresentation(forTypeIdentifier: type) { data, error in
                if let error { continuation.resume(throwing: error) }
                else if let data { continuation.resume(returning: data) }
                else { continuation.resume(throwing: InboxError.unavailable) }
            }
        }
    }
    private func save() {
        do {
            if let image { try SharedInbox.save(image, image: true) }
            else if let text { try SharedInbox.save(Data(text.utf8), image: false) }
            else { throw InboxError.unavailable }
            saved = true; status = "Saved on this device. Nothing was sent online."
        } catch { status = error.localizedDescription }
    }
}
