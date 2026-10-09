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
    @Test func senderInsteadOfMessageIsDetected() {
        for sender in ["09171234567", "+63 917 123 4567", "(02) 8123-4567", "123456"] {
            #expect(AutomationPolicy.inputIssue(for: sender) == .looksLikeSender)
        }
    }
    @Test func veryShortTextsAreSkippedWithoutModelWork() {
        for text in ["", "   ", "ok", "Salamat!", "GCASH"] {
            #expect(AutomationPolicy.inputIssue(for: text) == .tooShort)
        }
    }
    @Test func realMessagesAreNeverScreenedOut() {
        let messages = ["Your login code is 752184. Never share it.",
                        "Reply with your OTP to unlock your account.",
                        "Huwag ibigay ang code. Bukas ang appointment mo, 4 PM.",
                        "Call 09171234567 now to claim your prize"]
        for text in messages { #expect(AutomationPolicy.inputIssue(for: text) == nil) }
    }
    @Test func moneyCodesPromosAndLinksGetAHeadsUp() {
        let risky = ["Pay ₱800 registration fee today", "Earn P3,000 daily, no interview", "Your OTP is 482913",
                     "Ibigay ang code na natanggap mo", "Libre na load! Claim mo na", "GCash: May suspicious transaction sa wallet mo",
                     "Update your password here: https://example.invalid/login", "Nanalo ka ng premyo!", "Send PHP 500 now"]
        for text in risky { #expect(AutomationPolicy.needsHeadsUp(text), "\(text)") }
    }
    @Test func ordinaryTextsStayQuiet() {
        let ordinary = ["Hi anak, dinner at 7 tonight sa bahay ni Tita. Bring a jacket, malamig daw.",
                        "Nasa jeep na ako, malapit na.", "Happy birthday! See you on Sunday.", "Okay po, salamat."]
        for text in ordinary { #expect(!AutomationPolicy.needsHeadsUp(text), "\(text)") }
    }
    @Test func headsUpAndFollowUpsCarryNoMessageContent() {
        let result = ModelAssessment(risk: .noObviousSigns, action: .ordinary, quality: .complete, findings: [])
        let copy = [AutomationPolicy.headsUp, AutomationPolicy.couldNotFinish, AutomationPolicy.finished(for: result)]
            .map { $0.title + $0.body }.joined()
        #expect(!copy.contains("482913"))
        #expect(!copy.lowercased().contains("safe"))
        #expect(copy.contains("does not confirm legitimacy"))
    }
}
