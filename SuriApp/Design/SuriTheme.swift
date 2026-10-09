import SwiftUI
import SuriCore

enum SuriTheme {
    static let teal = Color("Accent")
    static let warning = Color("Warning")
    static let danger = Color("Danger")
    static let background = Color("Background")
    static let surface = Color("Surface")
    static let ink = Color("Ink")
}

extension RiskCategory {
    /// Colour never carries the verdict alone; the title and glyph repeat it.
    /// "No obvious warning signs" stays neutral so it can't read as an all-clear.
    var tint: Color {
        switch self {
        case .warningSigns: SuriTheme.danger
        case .needsVerification: SuriTheme.warning
        case .noObviousSigns: SuriTheme.ink
        }
    }
    var glyph: String { self == .noObviousSigns ? "shield-check-outline" : "danger-triangle-outline" }
}

struct SolarIcon: View {
    let name: String
    var size: CGFloat = 24
    var body: some View {
        Image("solar-" + name).renderingMode(.template).resizable().scaledToFit()
            .frame(width: size, height: size).accessibilityHidden(true)
    }
}

struct SuriButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var enabled
    var filled = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline.weight(.bold)).frame(maxWidth: .infinity).padding(.vertical, 16).padding(.horizontal, 12)
            .foregroundStyle(filled ? Color("ActionText") : SuriTheme.ink)
            .background(filled ? SuriTheme.teal : SuriTheme.surface, in: Capsule())
            .overlay(Capsule().strokeBorder(filled ? .clear : Color.primary.opacity(0.12)))
            .opacity(!enabled ? 0.45 : configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 1), value: configuration.isPressed)
    }
}

/// Quiet inline action: teal, semibold, comfortable 44pt tap height.
struct SuriLinkStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.subheadline.weight(.bold)).foregroundStyle(SuriTheme.teal)
            .frame(minHeight: 44).contentShape(Rectangle()).opacity(configuration.isPressed ? 0.6 : 1)
    }
}

extension View {
    func suriCard(radius: CGFloat = 20) -> some View {
        background(SuriTheme.surface, in: RoundedRectangle(cornerRadius: radius))
            .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(Color.primary.opacity(0.06)))
    }
}

struct SectionHeading: View {
    let title: String
    var body: some View {
        Text(title).font(.headline.weight(.bold)).foregroundStyle(SuriTheme.ink).accessibilityAddTraits(.isHeader)
    }
}

/// Suri's mark: a message bubble with a lens cut into it. Template-rendered, so it takes the tint it is given.
struct SuriMark: View {
    var size: CGFloat = 30
    var body: some View {
        Image("suri-mark").renderingMode(.template).resizable().scaledToFit()
            .frame(width: size, height: size).accessibilityHidden(true)
    }
}

struct SuriWordmark: View {
    var body: some View {
        HStack(spacing: 8) {
            SuriMark(size: 30).foregroundStyle(SuriTheme.teal)
            Text("Suri").font(.system(.title2, design: .default, weight: .heavy)).tracking(-0.5)
        }.accessibilityElement(children: .ignore).accessibilityLabel("Suri")
    }
}

/// Round, quiet icon button used in custom headers (matches the system toolbar button's weight).
struct SuriIconButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            SolarIcon(name: icon, size: 22).foregroundStyle(SuriTheme.teal)
                .frame(width: 44, height: 44)
                .background(SuriTheme.surface, in: Circle())
                .overlay(Circle().strokeBorder(Color.primary.opacity(0.08)))
        }.accessibilityLabel(label)
    }
}
