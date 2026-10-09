import Foundation

public struct GuidanceReference: Codable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let url: URL
    public let reviewedOn: String
}

public enum GuidanceStore {
    public static let version = "2026-10-09"
    public static let references: [GuidanceReference] = [
        .init(id: "bsp-fraud", title: "BSP: Protect yourself from fraud and scams",
              url: URL(string: "https://www.bsp.gov.ph/Media_and_Research/Primers%20Faqs/Protect_yourself_from_Fraud_and_Scam.pdf")!, reviewedOn: version),
        .init(id: "psa-phishing", title: "PSA: Messaging-app phishing advisory",
              url: URL(string: "https://psa.gov.ph/system/files/philsys/Public%20Advisory%20on%20Phishing%20Scams%20and%20Offers%20of%20Assistance%20in%20Downloading%20the%20Digital%20National%20ID%20via%20Messaging%20Apps.pdf")!, reviewedOn: version)
    ]
    public static func nextStep(for action: RequestedAction) -> String {
        switch action {
        case .shareCode: "Keep your code private. Open your institution's official app yourself, or contact it through a number you obtained independently."
        case .payUpfront, .sendMoney, .changeDestination: "Pause the payment. Call the person or institution using a contact you already know, and confirm the request independently."
        case .sharePersonalDetails: "Do not share your details yet. Verify the request through the institution's independently obtained official channel."
        case .openLink, .installSoftware: "Avoid the supplied link or download for now. Open the official app or website yourself and check the request there."
        case .ordinary: "If anything still feels unusual, confirm with a contact you know. No obvious warning signs is not proof of legitimacy."
        case .unknown: "Read the complete message or ask someone you trust to help verify what it asks you to do."
        }
    }
}
