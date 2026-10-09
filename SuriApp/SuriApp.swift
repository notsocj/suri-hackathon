import SwiftUI

@main struct SuriApp: App {
    @State private var model = AppModel()
    var body: some Scene {
        WindowGroup {
            RootView().environment(model).tint(SuriTheme.teal)
                .task { await model.loadHistory() }
        }
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var model
    @State private var settings = false
    var body: some View {
        @Bindable var model = model
        TabView(selection: $model.selectedTab) {
            NavigationStack { CheckView().toolbar { settingsButton } }
                .tabItem { Label { Text("Check") } icon: { SolarIcon(name: model.selectedTab == 0 ? "shield-check-bold" : "shield-check-outline") } }.tag(0)
            NavigationStack { HistoryView().toolbar { settingsButton } }
                .tabItem { Label { Text("History") } icon: { SolarIcon(name: model.selectedTab == 1 ? "history-bold" : "history-outline") } }.tag(1)
            NavigationStack { FamilyView().toolbar { settingsButton } }
                .tabItem { Label { Text("Family") } icon: { SolarIcon(name: model.selectedTab == 2 ? "users-group-rounded-bold" : "users-group-rounded-outline") } }.tag(2)
        }
        .sheet(isPresented: $settings) { NavigationStack { SettingsView() } }
        .sheet(isPresented: Binding(get: { !model.completedOnboarding }, set: { if !$0 { model.completedOnboarding = true } })) {
            OnboardingView().interactiveDismissDisabled()
        }
        .alert("Suri", isPresented: Binding(get: { model.notice != nil }, set: { if !$0 { model.notice = nil } })) {
            Button("OK") { model.notice = nil }
        } message: { Text(model.notice ?? "") }
    }
    private var settingsButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button { settings = true } label: { SolarIcon(name: "settings-outline") }.accessibilityLabel("Settings")
        }
    }
}
