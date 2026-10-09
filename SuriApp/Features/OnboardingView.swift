import SwiftUI

struct OnboardingView: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                SuriWordmark().padding(.top, 30)
                Text("Suri bago sorry.").font(.title3).foregroundStyle(.secondary)
                Text("A moment to check.\nA clearer next step.").font(.largeTitle.weight(.semibold)).tracking(-0.7)
                onboardingRow("A private first check", "Choose a screenshot or paste a message. Local AI looks for warning signs without uploading it.", "lock-keyhole-outline")
                onboardingRow("Evidence you can review", "See the exact words behind a finding. Correct screenshot text before you check.", "document-text-outline")
                onboardingRow("Help on your terms", "Ask a person you trust. You review the help message and choose whether to send it.", "users-group-rounded-outline")
                Text("Download the local model once in Settings. Online guidance is optional and off by default. Suri offers a second opinion, not proof that a message is safe or fraudulent.")
                    .font(.footnote).foregroundStyle(.secondary)
            }.padding(26)
        }.background(SuriTheme.background)
            .safeAreaInset(edge: .bottom) {
                Button("Start using Suri") { model.completedOnboarding = true }
                    .buttonStyle(SuriButtonStyle()).accessibilityIdentifier("start-suri")
                    .padding(.horizontal, 26).padding(.vertical, 16).background(SuriTheme.background)
            }
    }
    private func onboardingRow(_ title: String, _ text: String, _ icon: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            SolarIcon(name: icon, size: 27).foregroundStyle(SuriTheme.teal).padding(.top, 2)
            VStack(alignment: .leading, spacing: 7) {
                Text(title).font(.headline)
                Text(text).font(.body).foregroundStyle(.secondary)
            }
        }
    }
}
