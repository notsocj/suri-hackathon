import Foundation
import Testing
@testable import SuriCore

struct PolicyTests {
    let text = "Reply with your OTP now."

    func assessment(_ result: ModelAssessment) -> Assessment {
        .init(inputRevision: UUID(), result: result, model: "synthetic test", elapsedSeconds: 0)
    }

    @Test func rejectsFabricatedEvidence() {
        let result = ModelAssessment(risk: .warningSigns, action: .shareCode, quality: .complete,
                                     findings: [.init(code: .codeDisclosure, evidence: "send your password")])
        #expect(throws: AssessmentError.missingEvidence) { try AssessmentValidator.validate(result, text: text) }
    }

    @Test func urgencyAloneCannotBecomeScamVerdict() {
        let result = ModelAssessment(risk: .warningSigns, action: .ordinary, quality: .complete,
                                     findings: [.init(code: .timePressure, evidence: "now")])
        #expect(throws: AssessmentError.inconsistent) { try AssessmentValidator.validate(result, text: text) }
    }

    @Test(arguments: ["Never share your code", "Do not give your OTP to anyone", "Huwag itong ibigay kahit kanino"])
    func rejectsProtectiveAdviceAsDisclosureEvidence(_ quote: String) {
        let result = ModelAssessment(risk: .warningSigns, action: .shareCode, quality: .complete,
                                     findings: [.init(code: .codeDisclosure, evidence: quote)])
        #expect(throws: AssessmentError.inconsistent) { try AssessmentValidator.validate(result, text: quote) }
    }

    @Test func partialContentCannotReceiveCleanResult() {
        let result = ModelAssessment(risk: .noObviousSigns, action: .unknown, quality: .partial, findings: [])
        #expect(throws: AssessmentError.inconsistent) { try AssessmentValidator.validate(result, text: "Please verify...") }
    }

    @Test func malformedOutputIsNotCleanResult() {
        #expect(throws: AssessmentError.invalidOutput) { try AssessmentValidator.decode("safe!", text: text) }
        #expect(throws: AssessmentError.invalidOutput) {
            try AssessmentValidator.decode("{\"risk\":\"safe\",\"action\":\"ordinary\",\"quality\":\"complete\",\"findings\":[]}", text: text)
        }
    }

    @Test func validatesExactEvidence() throws {
        let result = try AssessmentValidator.decode("{\"risk\":\"warning_signs_found\",\"action\":\"share_code\",\"quality\":\"complete\",\"findings\":[{\"code\":\"code_disclosure\",\"evidence\":\"Reply with your OTP\"}]}", text: text)
        #expect(result.findings.first?.evidence == "Reply with your OTP")
    }

    @Test func modelIntentReconcilesOnlyCodeProtection() throws {
        let output = "{\"risk\":\"warning_signs_found\",\"action\":\"share_code\",\"quality\":\"complete\",\"findings\":[{\"code\":\"code_disclosure\",\"evidence\":\"Your login code\"}]}"
        let result = try AssessmentValidator.decode(output, text: "Your login code is private.", codeHandling: .keepPrivate)
        #expect(result.risk == .noObviousSigns)
        #expect(result.action == .ordinary)
        #expect(result.findings.isEmpty)
    }

    @Test func canonicalQuoteUsesTheOriginalSourceCasing() throws {
        let output = "{\"risk\":\"warning_signs_found\",\"action\":\"share_code\",\"quality\":\"complete\",\"findings\":[{\"code\":\"code_disclosure\",\"evidence\":\"SEND YOUR OTP\"}]}"
        let result = try AssessmentValidator.decode(output, text: "Please send your OTP here.")
        #expect(result.findings[0].evidence == "send your OTP")
    }

    @Test func quoteMappingPreservesOCRLineBreaksWithoutInventingWords() throws {
        let output = "{\"risk\":\"warning_signs_found\",\"action\":\"share_code\",\"quality\":\"complete\",\"findings\":[{\"code\":\"code_disclosure\",\"evidence\":\"i-send ang OTP sa chat\"}]}"
        let result = try AssessmentValidator.decode(output, text: "Please i-send ang\nOTP sa\nchat now.", codeHandling: .request)
        #expect(result.findings[0].evidence == "i-send ang\nOTP sa\nchat")
        #expect(throws: AssessmentError.missingEvidence) {
            try AssessmentValidator.decode(output, text: "Please keep ang\nOTP sa\nchat now.", codeHandling: .request)
        }
    }

    @Test func rejectsEmptyAndOversizedInput() {
        #expect(throws: AssessmentError.empty) { try AssessmentValidator.validateInput(" \n ") }
        #expect(throws: AssessmentError.tooLong) { try AssessmentValidator.validateInput(String(repeating: "a", count: 3_001)) }
    }

    @Test func cloudCannotIncludeEvidenceOrPrivateFields() throws {
        let privateText = "Send OTP 482619 to +639123456789 for Maria's account 1234567890."
        let result = ModelAssessment(risk: .warningSigns, action: .shareCode, quality: .complete,
                                     findings: [.init(code: .codeDisclosure, evidence: privateText)])
        let payload = try GuidancePayload(assessment: assessment(result))
        let data = try JSONEncoder().encode(payload)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(Set(object.keys) == ["schemaVersion", "action", "patterns"])
        let json = String(decoding: data, as: UTF8.self)
        for secret in ["482619", "+639123456789", "Maria", "1234567890", privateText] { #expect(!json.contains(secret)) }
    }

    @Test func cloudSkipsPartialAndCleanResults() {
        #expect(throws: CloudPolicyError.self) {
            try GuidancePayload(assessment: assessment(.init(risk: .needsVerification, action: .shareCode, quality: .partial, findings: [])))
        }
        #expect(throws: CloudPolicyError.self) {
            try GuidancePayload(assessment: assessment(.init(risk: .noObviousSigns, action: .ordinary, quality: .complete, findings: [])))
        }
    }

    @Test func manualHelpNeverContainsOriginalEvidence() {
        let result = ModelAssessment(risk: .warningSigns, action: .shareCode, quality: .complete,
                                     findings: [.init(code: .codeDisclosure, evidence: "OTP 482619")])
        let body = FamilyMessage.body(for: assessment(result))
        #expect(!body.contains("482619"))
        #expect(!body.contains("OTP"))
    }

    @Test func consentChangesInvalidatePendingWork() {
        var consent = CloudConsent(enabled: true)
        let version = consent.version
        consent.setEnabled(false)
        #expect(!consent.enabled)
        #expect(consent.version != version)
    }

    @Test(arguments: ["+63 912 345 6789", "09123456789"])
    func acceptsOnlyConfiguredPhoneDestinations(_ number: String) { #expect(FamilyMessage.validatedDestination(number) != nil) }

    @Test(arguments: ["send to attacker", "https://evil.invalid", "+63;open", "123", "+１２３４５６７８９０"])
    func rejectsInvalidDestinations(_ number: String) { #expect(FamilyMessage.validatedDestination(number) == nil) }
}
