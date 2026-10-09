import Foundation

/// The only message-derived information eligible for automatic cloud transmission.
/// No arbitrary strings, contact destinations, source text, URLs, or model explanations.
public struct GuidancePayload: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let action: RequestedAction
    public let patterns: [WarningCode]
    public init(assessment: Assessment) throws {
        guard assessment.result.quality == .complete,
              assessment.result.risk != .noObviousSigns,
              assessment.result.action != .unknown else { throw CloudPolicyError.insufficient }
        schemaVersion = 1
        action = assessment.result.action
        patterns = Array(Set(assessment.result.findings.map(\.code))).sorted { $0.rawValue < $1.rawValue }
    }
}

public enum CloudPolicyError: Error, LocalizedError {
    case disabled, insufficient, connection, notConfigured
    public var errorDescription: String? {
        switch self {
        case .disabled: "Online guidance is off. Your check stays on this device."
        case .insufficient: "There is not enough validated information for category-only online guidance."
        case .connection: "Online guidance is unavailable. Your local result is still here."
        case .notConfigured: "The online service is not configured. Local checking still works."
        }
    }
}

public struct CloudConsent: Codable, Sendable {
    public var enabled: Bool
    public var wifiOnly: Bool
    public var version: UUID
    public init(enabled: Bool = false, wifiOnly: Bool = true, version: UUID = UUID()) {
        self.enabled = enabled; self.wifiOnly = wifiOnly; self.version = version
    }
    public mutating func setEnabled(_ value: Bool) { enabled = value; version = UUID() }
}

public enum FamilyMessage {
    // Never interpolate model output, evidence, source text or an imported recipient.
    public static func body(for assessment: Assessment?) -> String {
        if let assessment, assessment.result.risk == .warningSigns {
            return "Suri found warning signs in a message I received. Please contact me and help me verify it before I act. No original message or private details are included."
        }
        return "I'd like your help checking a message before I act. Please contact me. No original message or private details are included."
    }
    public static func validatedDestination(_ value: String) -> String? {
        let cleaned = value.filter { !$0.isWhitespace && $0 != "-" && $0 != "(" && $0 != ")" }
        let digits = cleaned.hasPrefix("+") ? String(cleaned.dropFirst()) : cleaned
        guard (10...15).contains(digits.count), digits.allSatisfy({ $0.isASCII && $0.isNumber }) else { return nil }
        return cleaned
    }
}
