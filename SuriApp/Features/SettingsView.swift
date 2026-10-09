import SwiftUI
import SuriCore

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var consent = false
    @State private var clear = false
    var body: some View {
        @Bindable var model = model
        Form {
            Section {
                Label { Text("Qwen3 1.7B · 4-bit").font(.headline.weight(.bold)) } icon: { SolarIcon(name: "shield-check-outline") }
                Text(model.modelStatus).font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                if model.installing {
                    if let fraction = model.downloadFraction { ProgressView(value: fraction) } else { ProgressView() }
                    Button("Pause download", role: .cancel) { model.cancelDownload() }
                } else if !model.modelInstalled {
                    Button(model.downloadButtonTitle) { model.installModel() }.accessibilityIdentifier("download-model")
                }
            } header: { Text("Offline checker") } footer: {
                Text("Downloaded once from Hugging Face. Messages are never part of the download, and checks then work without internet. Accuracy on Filipino and Taglish hasn't been measured yet.")
            }
            Section {
                Toggle("Online guidance", isOn: Binding(get: { model.cloudEnabled }, set: { enabled in
                    if enabled { consent = true } else { model.cloudEnabled = false }
                }))
                Toggle("Wi-Fi only", isOn: $model.wifiOnly).disabled(!model.cloudEnabled)
                NavigationLink("Online service") { OnlineServiceView() }
            } header: { Text("Online guidance (optional)") } footer: {
                Text("Only the requested action and warning categories can leave your phone. Never screenshots, message text, quotes, codes, contacts, or links. It doesn't verify the original message. Turning this off cancels pending requests; requests already sent can't be recalled.")
            }
            Section {
                Toggle("Save check history", isOn: $model.historyEnabled)
                Button("Delete all checks", role: .destructive) { clear = true }
            } header: { Text("On this device") } footer: {
                Text("History keeps results and quoted evidence for 7 days, up to 50 checks. Screenshots and full messages are never saved.")
            }
            Section {
                NavigationLink("About and licenses") { AboutView() }
            }
            Section {
                NavigationLink("Message automation") { AutomationSettingsView() }
            } header: { Text("Shortcuts and warnings") }
        }.navigationTitle("Settings").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .alert("Turn on online guidance?", isPresented: $consent) {
                Button("Keep local only", role: .cancel) { }
                Button("Turn on") { model.cloudEnabled = true }
            } message: {
                Text("After a local check, Suri may send fixed action and warning categories to your configured online service when an allowed connection exists. The service uses OpenAI. No message text, screenshot, quote, recipient, or code is sent.")
            }
            .confirmationDialog("Delete all saved checks?", isPresented: $clear, titleVisibility: .visible) {
                Button("Delete all checks", role: .destructive) { model.clearHistory() }
            }
    }
}

/// Developer-facing connection details, kept off the main settings list.
struct OnlineServiceView: View {
    @Environment(AppModel.self) private var model
    @State private var token = ""
    var body: some View {
        @Bindable var model = model
        Form {
            Section {
                TextField("Gateway URL", text: $model.gatewayURL).keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                SecureField("Gateway access token", text: $token).textInputAutocapitalization(.never).autocorrectionDisabled()
                Button("Save access token") { model.saveGatewayToken(token); token = "" }.disabled(token.isEmpty)
            } footer: {
                Text("The OpenAI API key stays on your server. Enter only the gateway access token here. HTTPS is required outside localhost.")
            }
            Section {
                Text("\(model.network.connected ? "Network available" : "No network")\(model.network.wifi ? " · Wi-Fi" : "")")
                    .foregroundStyle(.secondary)
            }
        }.navigationTitle("Online service").navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView: View {
    var body: some View {
        Form {
            Section {
                Text("Suri bago sorry.").font(.headline.weight(.bold))
                Text("Suri helps you pause and verify. It can't guarantee a message is legitimate, confirm who sent it, or block a payment.")
            }
            Section {
                Text("Built with SwiftUI, Apple Vision, llama.cpp, and Qwen3 (Apache 2.0). Solar icons by 480 Design (CC BY 4.0). Development assisted by Codex and Claude Code.")
                    .font(.footnote.weight(.medium)).foregroundStyle(.secondary)
                Link("Solar icon attribution", destination: URL(string: "https://icon-sets.iconify.design/solar/")!)
                Link("Qwen model and license", destination: URL(string: "https://huggingface.co/ggml-org/Qwen3-1.7B-GGUF")!)
                NavigationLink("Third-party notices") {
                    ScrollView {
                        Text((try? String(contentsOf: Bundle.main.url(forResource: "THIRD_PARTY_NOTICES", withExtension: "txt")!, encoding: .utf8)) ?? "License notices unavailable.")
                            .font(.footnote.weight(.medium)).textSelection(.enabled).padding(24)
                    }.navigationTitle("Notices")
                }
            }
        }.navigationTitle("About").navigationBarTitleDisplayMode(.inline)
    }
}
