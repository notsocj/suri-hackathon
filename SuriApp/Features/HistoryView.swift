import SwiftUI

struct HistoryView: View {
    @Environment(AppModel.self) private var model
    @State private var clear = false
    var body: some View {
        Group {
            if model.history.isEmpty {
                ContentUnavailableView {
                    Label { Text("No checks yet") } icon: { SolarIcon(name: "history-outline", size: 44) }
                } description: { Text("Results appear here for 7 days. Screenshots and full messages are never saved.") }
                actions: { Button("Check a message") { model.selectedTab = 0 }.buttonStyle(.borderedProminent) }
            } else {
                List {
                    Section {
                        ForEach(model.history) { item in
                            Button { model.viewHistory(item) } label: { HistoryRow(assessment: item) }.buttonStyle(.plain)
                        }.onDelete { model.deleteHistory(at: $0) }
                    } footer: { Text("Kept on this device for 7 days, up to 50 checks. Expired checks are removed the next time Suri opens. Screenshots and full messages are never saved.") }
                    Section { Button("Delete all checks", role: .destructive) { clear = true } }
                }.scrollContentBackground(.hidden)
            }
        }.background(SuriTheme.background).navigationTitle("History").navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Delete all saved checks?", isPresented: $clear, titleVisibility: .visible) {
                Button("Delete all checks", role: .destructive) { model.clearHistory() }
            }
    }
}
