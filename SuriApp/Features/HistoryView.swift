import SwiftUI

struct HistoryView: View {
    @Environment(AppModel.self) private var model
    @State private var clear = false
    var body: some View {
        Group {
            if model.history.isEmpty {
                ContentUnavailableView {
                    Label { Text("Your checks will be here") } icon: { SolarIcon(name: "history-outline", size: 44) }
                } description: { Text("Check a message to save its result locally. Screenshots and full messages are not saved.") }
                actions: { Button("Check a message") { model.selectedTab = 0 }.buttonStyle(.borderedProminent) }
            } else {
                List {
                    Section {
                        ForEach(model.history) { item in
                            Button { model.viewHistory(item) } label: { HistoryRow(assessment: item) }.buttonStyle(.plain)
                        }.onDelete { model.deleteHistory(at: $0) }
                    } footer: { Text("Results and quoted evidence stay on this device until they expire after 7 days, limited to 50 checks; expired records are removed when Suri next opens. Screenshots and full messages are not saved.") }
                    Section { Button("Delete all saved checks", role: .destructive) { clear = true } }
                }.scrollContentBackground(.hidden)
            }
        }.background(SuriTheme.background).navigationTitle("History")
            .confirmationDialog("Delete all saved checks?", isPresented: $clear, titleVisibility: .visible) {
                Button("Delete saved checks", role: .destructive) { model.clearHistory() }
            }
    }
}
