import SwiftUI

struct OnboardingView: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 6) {
                    SuriWordmark()
                    Text("Suri bago sorry.").font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                }.padding(.top, 24)
                Text("Check a message before you act.").font(.largeTitle.weight(.heavy)).tracking(-0.6)
                onboardingRow("Private by default", "Suri reads the message on your phone. Nothing is uploaded.", "lock-keyhole-outline")
                onboardingRow("Evidence you can read", "Each warning quotes the exact words behind it. Fix any screenshot text first.", "document-text-outline")
                onboardingRow("Help when you want it", "Suri drafts a short note to someone you trust. You decide whether to send it.", "users-group-rounded-outline")
                Text("Suri gives a second opinion. It can't prove a message is safe or fraudulent. Download the offline checker once to start; online guidance is optional and off.")
                    .font(.footnote.weight(.medium)).foregroundStyle(.secondary)
            }.padding(.horizontal, 26).padding(.bottom, 16)
        }.background(SuriTheme.background)
            .safeAreaInset(edge: .bottom) {
                Button("Get started") { model.completedOnboarding = true }
                    .buttonStyle(SuriButtonStyle()).accessibilityIdentifier("start-suri")
                    .padding(.horizontal, 26).padding(.vertical, 12).background(SuriTheme.background)
            }
    }
    private func onboardingRow(_ title: String, _ text: String, _ icon: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            SolarIcon(name: icon, size: 26).foregroundStyle(SuriTheme.teal).padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline.weight(.bold))
                Text(text).font(.body.weight(.medium)).foregroundStyle(.secondary)
            }
        }
    }
}
