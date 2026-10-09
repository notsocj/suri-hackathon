import SwiftUI
import SuriCore

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var consent = false
    @State private var token = ""
    @State private var clear = false
    var body: some View {
        @Bindable var model = model
        Form {
            Section {
                Label { Text("Qwen3 1.7B · 4-bit").font(.headline) } icon: { SolarIcon(name: "shield-check-outline") }
                Text(model.modelStatus).font(.subheadline).foregroundStyle(.secondary)
                if model.installing {
                    ProgressView()
                    Button("Cancel download", role: .cancel) { model.cancelDownload() }
                } else if !model.modelInstalled {
                    Button("Download local model (about 1.3 GB)") { model.installModel() }.accessibilityIdentifier("download-model")
                }
            } header: { Text("Local AI") } footer: {
                Text("Setup downloads model files from Qwen on Hugging Face. Messages are not part of the download. Once installed, local checking needs no internet. Filipino/Taglish quality depends on the model and should be evaluated.")
            }
            Section {
                Toggle("Automatic online guidance", isOn: Binding(get: { model.cloudEnabled }, set: { enabled in
                    if enabled { consent = true } else { model.cloudEnabled = false }
                }))
                Toggle("Use Wi-Fi only", isOn: $model.wifiOnly).disabled(!model.cloudEnabled)
                Text("\(model.network.connected ? "Network path available" : "No network path")\(model.network.wifi ? " · Wi-Fi" : "")")
                    .font(.footnote).foregroundStyle(.secondary)
            } header: { Text("Optional online guidance") } footer: {
                Text("Only fixed requested-action and warning-pattern categories may leave the device. Never screenshots, message text, quotes, private codes, contact details, or URLs. Guidance does not verify the original message. Turning this off cancels pending requests; requests already transmitted cannot be recalled.")
            }
            Section("Online service setup") {
                TextField("Gateway URL", text: $model.gatewayURL).keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                SecureField("Gateway access token", text: $token).textInputAutocapitalization(.never).autocorrectionDisabled()
                Button("Save gateway access token") { model.saveGatewayToken(token); token = "" }
                Text("The OpenAI API key stays on your server. Enter only the gateway access token here. HTTPS is required outside localhost.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("On this device") {
                Toggle("Save check history", isOn: $model.historyEnabled)
                Text("History retains results and evidence quotes for 7 days, at most 50 checks; expired records are removed when Suri next opens. Original screenshots and full messages are not retained.")
                    .font(.footnote).foregroundStyle(.secondary)
                Button("Delete saved checks", role: .destructive) { clear = true }
            }
            Section("About Suri") {
                Text("Suri bago sorry.").font(.headline)
                Text("Suri helps you pause and verify. It cannot guarantee legitimacy, confirm a sender's identity, or block a payment.")
                Text("Built with SwiftUI, Apple Vision, llama.cpp, and Qwen3. Qwen3 model: Apache 2.0. Solar icons by 480 Design: CC BY 4.0. Development assisted by Codex.")
                    .font(.footnote).foregroundStyle(.secondary)
                Link("Solar icon attribution", destination: URL(string: "https://icon-sets.iconify.design/solar/")!)
                Link("Qwen model and license", destination: URL(string: "https://huggingface.co/ggml-org/Qwen3-1.7B-GGUF")!)
                NavigationLink("Third-party notices") {
                    ScrollView {
                        Text((try? String(contentsOf: Bundle.main.url(forResource: "THIRD_PARTY_NOTICES", withExtension: "txt")!, encoding: .utf8)) ?? "License notices unavailable.")
                            .font(.footnote).textSelection(.enabled).padding(24)
                    }.navigationTitle("Notices")
                }
            }
        }.navigationTitle("Settings").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .alert("Enable category-only online guidance?", isPresented: $consent) {
                Button("Keep local only", role: .cancel) { }
                Button("Enable online guidance") { model.cloudEnabled = true }
            } message: {
                Text("After a local check, Suri may send fixed action and warning categories to your configured online service when an allowed connection exists. The service uses OpenAI. No message text, screenshot, evidence quote, recipient, or private code is sent.")
            }
            .confirmationDialog("Delete all saved checks?", isPresented: $clear, titleVisibility: .visible) {
                Button("Delete saved checks", role: .destructive) { model.clearHistory() }
            }
    }
}
