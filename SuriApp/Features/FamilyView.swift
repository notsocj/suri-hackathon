import SwiftUI
import MessageUI
import SuriCore

struct FamilyView: View {
    @Environment(AppModel.self) private var model
    @State private var editing = false
    @State private var help = false
    @State private var removing = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                SolarIcon(name: "users-group-rounded-outline", size: 42).foregroundStyle(SuriTheme.teal)
                Text("A little help\nfrom someone you trust.").font(.largeTitle.weight(.semibold)).tracking(-0.7)
                Text("Choose a person you can contact when a message feels unusual. You decide when to ask and what to share.")
                    .foregroundStyle(.secondary)
                if !model.familyNumber.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(model.familyName).font(.title2.weight(.semibold))
                        Text(model.familyNumber).font(.body).textSelection(.enabled)
                        Text("Confirm this number directly with your trusted person. Suri has not independently verified their identity.")
                            .font(.footnote).foregroundStyle(.secondary)
                        Button("Edit trusted contact") { editing = true }.padding(.vertical, 6)
                    }.padding(22).frame(maxWidth: .infinity, alignment: .leading)
                        .background(SuriTheme.surface, in: RoundedRectangle(cornerRadius: 22))
                    Button("Ask for help") { help = true }.buttonStyle(SuriButtonStyle())
                    Button("Remove trusted contact", role: .destructive) { removing = true }.padding(.vertical, 6)
                } else {
                    Button("Choose a trusted person") { editing = true }.buttonStyle(SuriButtonStyle())
                }
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeading(title: "Always your choice")
                    Text("Nothing is sent automatically. You preview a short help message and tap Send in Messages.")
                    Text("The help message contains no screenshot, original text, private codes, or account details.")
                }.font(.subheadline).foregroundStyle(.secondary)
            }.padding(24)
        }.background(SuriTheme.background).navigationTitle("Family").navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $editing) { NavigationStack { ContactSetupView() } }
            .sheet(isPresented: $help) { NavigationStack { FamilyHelpView(assessment: model.assessment) } }
            .confirmationDialog("Remove this trusted contact?", isPresented: $removing, titleVisibility: .visible) {
                Button("Remove contact", role: .destructive) { model.removeFamily() }
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
            Section("Trusted person") {
                TextField("Name", text: $name).textContentType(.name)
                TextField("Phone number", text: $number).keyboardType(.phonePad).textContentType(.telephoneNumber)
            }
            Section {
                Toggle("I checked this number and discussed asking this person for help", isOn: $confirmed)
            } footer: { Text("Suri cannot verify their identity. Choose someone you know and trust. You can remove them at any time.") }
            if let error { Section { Text(error).foregroundStyle(SuriTheme.danger) } }
            Section {
                Button("Save trusted contact") {
                    do { try model.saveFamily(name: name, number: number); dismiss() }
                    catch { self.error = error.localizedDescription }
                }.disabled(!confirmed || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || FamilyMessage.validatedDestination(number) == nil)
            }
        }.navigationTitle("Trusted contact").navigationBarTitleDisplayMode(.inline)
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
            VStack(alignment: .leading, spacing: 24) {
                Text("Ask for a second opinion.").font(.largeTitle.weight(.semibold))
                if model.familyNumber.isEmpty {
                    Text("Set up a trusted person before sending a help message.").foregroundStyle(.secondary)
                    Button("Set up trusted contact") { setup = true }.buttonStyle(SuriButtonStyle())
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeading(title: "To")
                        Text(model.familyName).font(.headline)
                        Text(model.familyNumber).foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeading(title: "Message preview")
                        Text(bodyText).textSelection(.enabled)
                    }.padding(20).background(SuriTheme.surface, in: RoundedRectangle(cornerRadius: 20))
                    Text("No original message or private details are included. Messages opens next; you choose whether to send.")
                        .font(.footnote).foregroundStyle(.secondary)
                    if MFMessageComposeViewController.canSendText() {
                        Button("Open Messages") { compose = true }.buttonStyle(SuriButtonStyle())
                    } else {
                        Text("Sending through Messages is unavailable on this device. In the simulator, you can review or copy this draft; delivery cannot be demonstrated.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    Button("Copy help message") { UIPasteboard.general.string = bodyText; status = "Copied. Not sent." }
                        .buttonStyle(SuriButtonStyle(filled: false))
                    Text(status).font(.footnote).foregroundStyle(.secondary).accessibilityIdentifier("family-status")
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
