import SwiftUI

enum SuriTheme {
    static let teal = Color("Accent")
    static let warning = Color("Warning")
    static let danger = Color("Danger")
    static let background = Color("Background")
    static let surface = Color("Surface")
    static let ink = Color("Ink")
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
    var filled = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).frame(maxWidth: .infinity).padding(.vertical, 17)
            .foregroundStyle(filled ? Color("ActionText") : SuriTheme.ink)
            .background(filled ? SuriTheme.teal : SuriTheme.surface, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(filled ? .clear : Color.primary.opacity(0.10)))
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 1), value: configuration.isPressed)
    }
}

struct SectionHeading: View {
    let title: String
    var body: some View { Text(title).font(.title3.weight(.semibold)).foregroundStyle(SuriTheme.ink) }
}

struct SuriWordmark: View {
    var body: some View {
        HStack(spacing: 10) {
            SolarIcon(name: "shield-check-outline", size: 31).foregroundStyle(SuriTheme.teal)
            Text("Suri").font(.system(.largeTitle, design: .default, weight: .bold)).tracking(-1)
        }.accessibilityElement(children: .ignore).accessibilityLabel("Suri")
    }
}
