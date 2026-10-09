import Testing
import Foundation
@testable import SuriCore

struct AutomationTests {
    @Test func notificationsExcludeSensitiveEvidence() {
        let value = ModelAssessment(risk: .warningSigns, action: .shareCode, quality: .complete,
                                    findings: [.init(code: .codeDisclosure, evidence: "Send OTP 123456 to 09999999999 at private.invalid")])
        let warning = AutomationPolicy.warning(for: value)
        #expect(warning != nil)
        let copy = (warning?.title ?? "") + (warning?.body ?? "") + AutomationPolicy.summary(for: value)
        #expect(!copy.contains("123456"))
        #expect(!copy.contains("09999999999"))
        #expect(!copy.contains("private.invalid"))
        #expect(!copy.lowercased().contains("is a scam"))
    }
    @Test func partialAndUrgencyOnlyResultsNeverAlert() {
        let partial = ModelAssessment(risk: .warningSigns, action: .shareCode, quality: .partial,
                                      findings: [.init(code: .codeDisclosure, evidence: "give OTP")])
        let urgency = ModelAssessment(risk: .warningSigns, action: .ordinary, quality: .complete,
                                      findings: [.init(code: .timePressure, evidence: "confirm today")])
        #expect(AutomationPolicy.warning(for: partial) == nil)
        #expect(AutomationPolicy.warning(for: urgency) == nil)
    }
    @Test func ordinaryAndUncertainResultsNeverAlert() {
        for risk in [RiskCategory.noObviousSigns, .needsVerification] {
            let result = ModelAssessment(risk: risk, action: .ordinary, quality: .complete, findings: [])
            #expect(AutomationPolicy.warning(for: result) == nil)
        }
    }
    @Test func duplicateAndConcurrentWorkAreBounded() {
        var ledger = AutomationLedger(); let now = Date()
        #expect(ledger.begin("one", now: now) == .accepted)
        #expect(ledger.begin("one", now: now) == .duplicate)
        #expect(ledger.begin("two", now: now) == .busy)
        ledger.finish("one", succeeded: true, now: now)
        #expect(ledger.begin("one", now: now.addingTimeInterval(299)) == .duplicate)
        #expect(ledger.begin("one", now: now.addingTimeInterval(301)) == .accepted)
    }
    @Test func failedChecksCanBeRetried() {
        var ledger = AutomationLedger(); let now = Date()
        #expect(ledger.begin("one", now: now) == .accepted)
        ledger.finish("other", succeeded: true, now: now)
        #expect(ledger.begin("two", now: now) == .busy)
        ledger.finish("one", succeeded: false, now: now)
        #expect(ledger.begin("one", now: now) == .accepted)
    }
}
