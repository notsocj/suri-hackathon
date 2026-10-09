import SwiftUI
import SuriCore
import AVFoundation

struct ResultView: View {
    @Environment(AppModel.self) private var model
    let assessment: Assessment
    let askFamily: () -> Void
    let checkAnother: () -> Void
    @State private var speaker = AVSpeechSynthesizer()
    @State private var speaking = false

    private var risk: RiskCategory { assessment.result.risk }
    private var nextStep: String { GuidanceStore.nextStep(for: assessment.result.action) }
    private var provenance: String {
        let fromText = model.resultFromAutomation && model.assessment?.id == assessment.id
        return fromText
            ? "Checked automatically on this device when a text arrived at \(assessment.createdAt.formatted(date: .omitted, time: .shortened))"
            : "Checked on this device"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            verdict
            actionCard
            if !assessment.result.findings.isEmpty { evidence }
            Text(assessment.uncertainty).font(.footnote.weight(.medium)).foregroundStyle(.secondary)
            secondaryAction
            if model.cloudEnabled || hasOnlineGuidance { onlineSection }
            details
        }
        .onDisappear { speaker.stopSpeaking(at: .immediate); speaking = false }
    }

    // The one expressive element: the verdict, its requested action, and nothing else competing with it.
    private var verdict: some View {
        VStack(alignment: .leading, spacing: 12) {
            SolarIcon(name: risk.glyph, size: 34).foregroundStyle(risk.tint)
            Text(risk.title).font(.title.weight(.heavy)).tracking(-0.4).foregroundStyle(risk.tint)
                .accessibilityAddTraits(.isHeader)
            Text(assessment.result.action.description).font(.title3.weight(.medium)).foregroundStyle(SuriTheme.ink)
            Label { Text(provenance) } icon: { SolarIcon(name: "lock-keyhole-outline", size: 14) }
                .font(.footnote.weight(.medium)).foregroundStyle(.secondary).padding(.top, 4)
        }
        .padding(22).frame(maxWidth: .infinity, alignment: .leading)
        .background(risk.tint.opacity(0.09), in: RoundedRectangle(cornerRadius: 28))
    }

    private var actionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeading(title: "What to do")
            Text(nextStep).font(.body.weight(.medium))
            Button(speaking ? "Stop reading" : "Read aloud") { toggleSpeech() }.buttonStyle(SuriLinkStyle())
        }
        .padding(20).frame(maxWidth: .infinity, alignment: .leading).suriCard()
    }

    private var evidence: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeading(title: "What stood out")
            ForEach(assessment.result.findings) { finding in
                VStack(alignment: .leading, spacing: 8) {
                    Text(finding.code.title).font(.subheadline.weight(.bold))
                    HStack(alignment: .top, spacing: 12) {
                        RoundedRectangle(cornerRadius: 2).fill(risk.tint.opacity(0.8)).frame(width: 3)
                        Text("“\(finding.evidence)”").font(.body.weight(.medium)).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                    }.fixedSize(horizontal: false, vertical: true).padding(14)
                        .background(risk.tint.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
                    Text(finding.code.explanation).font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                }
            }
        }
    }

    /// The pinned bar holds the primary action; this is the other one.
    @ViewBuilder private var secondaryAction: some View {
        if risk == .noObviousSigns {
            Button(action: askFamily) {
                Label { Text("Ask my family") } icon: { SolarIcon(name: "users-group-rounded-outline") }
            }.buttonStyle(SuriButtonStyle(filled: false))
        } else {
            Button("Check another message", action: checkAnother).buttonStyle(SuriButtonStyle(filled: false))
        }
    }

    private var hasOnlineGuidance: Bool { model.online != nil && model.assessment?.id == assessment.id }

    private var onlineSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label { SectionHeading(title: "Online guidance") } icon: { SolarIcon(name: "cloud-check-outline") }
            if let online = model.online, hasOnlineGuidance {
                Text(online.guidance).textSelection(.enabled)
                Text("Guidance about the detected pattern. The cloud did not receive or verify your original message.")
                    .font(.footnote.weight(.medium)).foregroundStyle(.secondary)
                ForEach(GuidanceStore.references.filter { online.referenceIDs.contains($0.id) }) { reference in
                    Link(reference.title, destination: reference.url).font(.subheadline.weight(.medium))
                }
                Text(online.generatedAt.formatted(date: .abbreviated, time: .shortened)).font(.caption.weight(.medium)).foregroundStyle(.secondary)
            } else {
                Text(model.onlineStatus).font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                Button("Get category-only guidance") { model.requestGuidance(assessment) }.buttonStyle(SuriLinkStyle())
            }
        }
    }

    private var details: some View {
        DisclosureGroup("References and details") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(GuidanceStore.references) { reference in
                    Link(reference.title, destination: reference.url).font(.subheadline.weight(.medium))
                }
                Text("Guidance pack reviewed \(GuidanceStore.version). These are verification references, not evidence about this sender.")
                Text("Model: \(assessment.model)")
                Text("Local processing: \(assessment.elapsedSeconds, specifier: "%.1f") seconds")
                Text(assessment.createdAt.formatted(date: .abbreviated, time: .shortened))
            }.font(.caption.weight(.medium)).foregroundStyle(.secondary).padding(.top, 12)
        }.font(.subheadline.weight(.medium))
    }

    private func toggleSpeech() {
        if speaking { speaker.stopSpeaking(at: .immediate); speaking = false; return }
        let utterance = AVSpeechUtterance(string: "\(risk.title). \(assessment.result.action.description). \(assessment.uncertainty) \(nextStep)")
        utterance.rate = 0.45
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speaker.speak(utterance); speaking = true
    }
}

struct HistoryRow: View {
    let assessment: Assessment
    private var risk: RiskCategory { assessment.result.risk }
    private var summary: String {
        assessment.result.findings.first.map { "“\($0.evidence)”" } ?? assessment.result.action.description
    }
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            SolarIcon(name: risk.glyph).foregroundStyle(risk.tint).padding(.top, 1)
            VStack(alignment: .leading, spacing: 3) {
                Text(risk.title).font(.headline.weight(.bold)).foregroundStyle(SuriTheme.ink)
                Text(summary).font(.subheadline.weight(.medium)).foregroundStyle(.secondary).lineLimit(2)
                Text(assessment.createdAt.formatted(.relative(presentation: .named))).font(.caption.weight(.medium)).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            SolarIcon(name: "alt-arrow-right-outline", size: 16).foregroundStyle(.secondary).padding(.top, 4)
        }.padding(.vertical, 10).frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
    }
}
