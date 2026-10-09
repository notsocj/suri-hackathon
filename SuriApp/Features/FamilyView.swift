import SwiftUI
import MessageUI
import SuriCore

struct FamilyView: View {
    @Environment(AppModel.self) private var model
    @State private var editing = false
    @State private var help = false
    @State private var removing = false
    private var initial: String { model.familyName.first.map { String($0).uppercased() } ?? "" }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if model.familyNumber.isEmpty { emptyState } else { contact }
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeading(title: "You stay in control")
                    Text("Nothing sends automatically. You review the draft and tap Send in Messages.")
                    Text("The draft never includes your screenshot, the message, codes, or account details.")
                }.font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
            }.padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 24)
        }.background(SuriTheme.background).navigationTitle("Family").navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $editing) { NavigationStack { ContactSetupView() } }
            .sheet(isPresented: $help) { NavigationStack { FamilyHelpView(assessment: model.assessment) } }
            .confirmationDialog("Remove this trusted person?", isPresented: $removing, titleVisibility: .visible) {
                Button("Remove \(model.familyName)", role: .destructive) { model.removeFamily() }
            }
    }
    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 14) {
            SolarIcon(name: "users-group-rounded-outline", size: 36).foregroundStyle(SuriTheme.teal)
            Text("Add someone you trust").font(.title.weight(.heavy)).tracking(-0.4)
            Text("When a message feels wrong, Suri drafts a short note to them. You choose whether to send it.")
                .foregroundStyle(.secondary)
            Button("Add trusted person") { editing = true }.buttonStyle(SuriButtonStyle()).padding(.top, 6)
        }
    }
    private var contact: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Text(initial).font(.title2.weight(.bold)).foregroundStyle(SuriTheme.teal)
                    .frame(width: 52, height: 52).background(SuriTheme.teal.opacity(0.12), in: Circle()).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.familyName).font(.title3.weight(.bold))
                    Text(model.familyNumber).font(.subheadline.weight(.medium)).foregroundStyle(.secondary).textSelection(.enabled)
                }
                Spacer(minLength: 8)
                Button("Edit") { editing = true }.buttonStyle(SuriLinkStyle())
            }.padding(18).frame(maxWidth: .infinity, alignment: .leading).suriCard()
            Button { help = true } label: { Label { Text("Ask my family") } icon: { SolarIcon(name: "users-group-rounded-outline") } }
                .buttonStyle(SuriButtonStyle())
            Text("Confirm this number with them directly. Suri can't verify who they are.")
                .font(.footnote.weight(.medium)).foregroundStyle(.secondary)
            Button("Remove trusted person", role: .destructive) { removing = true }
                .font(.subheadline.weight(.bold)).frame(minHeight: 44)
        }
    }
}

struct ContactSetupView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var number = ""
    @State private var confirmed = false
    @State private var error: String?
    var body: some View {
        Form {
            Section("Name and number") {
                TextField("Name", text: $name).textContentType(.name)
                TextField("Phone number", text: $number).keyboardType(.phonePad).textContentType(.telephoneNumber)
            }
            Section {
                Toggle("I checked this number and they agreed to help", isOn: $confirmed)
            } footer: { Text("Suri can't verify who they are. Choose someone you know. You can remove them at any time.") }
            if let error { Section { Text(error).foregroundStyle(SuriTheme.danger) } }
            Section {
                Button("Save trusted person") {
                    do { try model.saveFamily(name: name, number: number); dismiss() }
                    catch { self.error = error.localizedDescription }
                }.disabled(!confirmed || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || FamilyMessage.validatedDestination(number) == nil)
            }
        }.navigationTitle("Trusted person").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .onAppear { name = model.familyName; number = model.familyNumber }
    }
}

struct FamilyHelpView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let assessment: Assessment?
    @State private var setup = false
    @State private var compose = false
    @State private var status = "Not sent"
    private var bodyText: String { FamilyMessage.body(for: assessment) }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if model.familyNumber.isEmpty {
                    Text("Add someone you trust").font(.title.weight(.heavy)).tracking(-0.4)
                    Text("Choose a trusted person first. Then Suri can draft a help message for you to review.").foregroundStyle(.secondary)
                    Button("Add trusted person") { setup = true }.buttonStyle(SuriButtonStyle())
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("To").font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                        Text(model.familyName).font(.title3.weight(.bold))
                        Text(model.familyNumber).font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeading(title: "Message")
                        Text(bodyText).textSelection(.enabled)
                    }.padding(20).frame(maxWidth: .infinity, alignment: .leading).suriCard()
                    Text("It includes no original message or private details. Messages opens next, and you choose whether to send.")
                        .font(.footnote.weight(.medium)).foregroundStyle(.secondary)
                    if MFMessageComposeViewController.canSendText() {
                        Button("Open Messages") { compose = true }.buttonStyle(SuriButtonStyle())
                    } else {
                        Text("This device can't send through Messages. You can copy the draft instead.")
                            .font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                    }
                    Button("Copy message") { UIPasteboard.general.string = bodyText; status = "Copied. Not sent." }
                        .buttonStyle(SuriButtonStyle(filled: !MFMessageComposeViewController.canSendText()))
                    Text(status).font(.footnote.weight(.medium)).foregroundStyle(.secondary).accessibilityIdentifier("family-status")
                }
            }.padding(24)
        }.background(SuriTheme.background).navigationTitle("Ask my family").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
            .sheet(isPresented: $setup) { NavigationStack { ContactSetupView() } }
            .sheet(isPresented: $compose) {
                MessageComposer(recipient: model.familyNumber, message: bodyText) { result in
                    compose = false
                    status = switch result {
                    case .sent: "Submitted to Messages. Delivery is not confirmed."
                    case .cancelled: "Canceled. Not sent."
                    case .failed: "Messages could not send this draft."
                    @unknown default: "Delivery status unavailable."
                    }
                }.ignoresSafeArea()
            }
    }
}

struct MessageComposer: UIViewControllerRepresentable {
    let recipient: String
    let message: String
    let completion: @MainActor (MessageComposeResult) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.recipients = [recipient]; controller.body = message
        controller.messageComposeDelegate = context.coordinator
        return controller
    }
    func updateUIViewController(_ controller: MFMessageComposeViewController, context: Context) { }
    @MainActor final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let completion: @MainActor (MessageComposeResult) -> Void
        init(completion: @escaping @MainActor (MessageComposeResult) -> Void) { self.completion = completion }
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) { completion(result) }
    }
}
