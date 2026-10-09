import SwiftUI
import SuriCore
import AVFoundation

struct ResultView: View {
    @Environment(AppModel.self) private var model
    let assessment: Assessment
    let askFamily: () -> Void
    @State private var speaker = AVSpeechSynthesizer()
    @State private var speaking = false

    private var color: Color {
        switch assessment.result.risk {
        case .warningSigns: SuriTheme.danger
        case .needsVerification: SuriTheme.warning
        case .noObviousSigns: SuriTheme.ink
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            VStack(alignment: .leading, spacing: 12) {
                SolarIcon(name: assessment.result.risk == .warningSigns ? "danger-triangle-outline" : "shield-check-outline", size: 38).foregroundStyle(color)
                Text(assessment.result.risk.title).font(.largeTitle.weight(.semibold)).tracking(-0.7).foregroundStyle(color)
                Text("Checked locally on this device").font(.subheadline).foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 10) {
                SectionHeading(title: "What the message asks")
                Text(assessment.result.action.description).font(.body)
            }
            if !assessment.result.findings.isEmpty {
                VStack(alignment: .leading, spacing: 20) {
                    SectionHeading(title: "What stood out")
                    ForEach(assessment.result.findings) { finding in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(finding.code.title).font(.headline)
                            HStack(alignment: .top, spacing: 12) {
                                RoundedRectangle(cornerRadius: 2).fill(color.opacity(0.8)).frame(width: 3)
                                Text("“\(finding.evidence)”").font(.body).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                            }.fixedSize(horizontal: false, vertical: true).padding(14)
                                .background(color.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
                            Text(finding.code.explanation).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                SectionHeading(title: "What remains uncertain")
                Text(assessment.uncertainty).foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 12) {
                SectionHeading(title: "A useful next step")
                Text(GuidanceStore.nextStep(for: assessment.result.action)).font(.body)
            }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
                .background(SuriTheme.surface, in: RoundedRectangle(cornerRadius: 20))
            Button(action: askFamily) {
                Label { Text("Ask my family") } icon: { SolarIcon(name: "users-group-rounded-outline") }
            }.buttonStyle(SuriButtonStyle())
            Button(speaking ? "Stop reading" : "Read the explanation aloud") {
                if speaking { speaker.stopSpeaking(at: .immediate); speaking = false }
                else {
                    let utterance = AVSpeechUtterance(string: "\(assessment.result.risk.title). \(assessment.result.action.description). \(assessment.uncertainty) \(GuidanceStore.nextStep(for: assessment.result.action))")
                    utterance.rate = 0.45
                    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                    speaker.speak(utterance); speaking = true
                }
            }.font(.subheadline).frame(maxWidth: .infinity).padding(.vertical, 8)
            onlineSection
            DisclosureGroup("References and check details") {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(GuidanceStore.references) { reference in
                        Link(reference.title, destination: reference.url).font(.subheadline)
                    }
                    Text("Guidance pack reviewed \(GuidanceStore.version). These are verification references, not evidence about this sender.")
                    Text("Model: \(assessment.model)")
                    Text("Local processing: \(assessment.elapsedSeconds, specifier: "%.1f") seconds")
                    Text(assessment.createdAt.formatted(date: .abbreviated, time: .shortened))
                }.font(.caption).foregroundStyle(.secondary).padding(.top, 12)
            }.font(.subheadline)
        }
        .onDisappear { speaker.stopSpeaking(at: .immediate); speaking = false }
    }
    private var onlineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label { SectionHeading(title: "Online guidance") } icon: { SolarIcon(name: "cloud-check-outline") }
            if let online = model.online, model.assessment?.id == assessment.id {
                Text(online.guidance).textSelection(.enabled)
                Text("Guidance about the detected pattern. The cloud did not receive or verify your original message.")
                    .font(.footnote).foregroundStyle(.secondary)
                ForEach(GuidanceStore.references.filter { online.referenceIDs.contains($0.id) }) { reference in
                    Link(reference.title, destination: reference.url).font(.subheadline)
                }
                Text(online.generatedAt.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
            } else {
                Text(model.cloudEnabled ? model.onlineStatus : "Off. Your local result is complete.").font(.subheadline).foregroundStyle(.secondary)
                if model.cloudEnabled {
                    Button("Get category-only guidance") { model.requestGuidance(assessment) }.padding(.vertical, 5)
                }
            }
        }.padding(.top, 8)
    }
}

struct HistoryRow: View {
    let assessment: Assessment
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            SolarIcon(name: assessment.result.risk == .warningSigns ? "danger-triangle-outline" : "document-text-outline")
                .foregroundStyle(assessment.result.risk == .warningSigns ? SuriTheme.danger : SuriTheme.teal)
            VStack(alignment: .leading, spacing: 5) {
                Text(assessment.result.risk.title).font(.headline).foregroundStyle(SuriTheme.ink)
                Text(assessment.createdAt.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            SolarIcon(name: "alt-arrow-right-outline", size: 18).foregroundStyle(.secondary)
        }.padding(.vertical, 12).frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
    }
}
