import XCTest
import UIKit
@testable import Suri

@MainActor final class CaptureTests: XCTestCase {
    private func screenshot(text: String) -> Data {
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 900, height: 400), format: format).image { context in
            UIColor.white.setFill(); context.fill(CGRect(x: 0, y: 0, width: 900, height: 400))
            (text as NSString).draw(in: CGRect(x: 35, y: 40, width: 830, height: 320), withAttributes: [
                .font: UIFont.systemFont(ofSize: 36), .foregroundColor: UIColor.black
            ])
        }
        return image.pngData()!
    }
    func testLocalOCRPreservesNegationAndTime() async throws {
        let result = try await OCRService.extract(screenshot(text: "Do not share your code with anyone.\nYour appointment is tomorrow at 4 PM."))
        XCTAssertTrue(result.text.contains("not share"))
        XCTAssertTrue(result.text.contains("4 PM"))
    }
    func testBlankScreenshotNeedsCorrection() async {
        do {
            _ = try await OCRService.extract(screenshot(text: ""))
            XCTFail("An unreadable screenshot cannot produce a clean assessment")
        } catch {
            XCTAssertTrue(error is CaptureError)
        }
    }
    func testUnknownImageDataRejected() async {
        do {
            _ = try await OCRService.extract(Data("not an image".utf8))
            XCTFail("Unsupported input must be rejected")
        } catch { XCTAssertTrue(error is CaptureError) }
    }

    func testKeychainStorageRoundTrip() throws {
        let key = "synthetic-test-" + UUID().uuidString
        defer { try? KeychainStore.write("", key: key) }
        try KeychainStore.write("synthetic-value", key: key)
        XCTAssertEqual(KeychainStore.read(key), "synthetic-value")
    }

    func testShareInboxConsumesSelectedTextLocally() throws {
        let directory = try XCTUnwrap(SharedInbox.directory)
        let existing = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        guard existing.isEmpty else { throw XCTSkip("An existing pending import belongs to the user; do not consume it in this test.") }
        let text = "Synthetic shared message for local capture."
        try SharedInbox.save(Data(text.utf8), image: false)
        guard case .text(let received) = SharedInbox.takeNext() else { return XCTFail("Shared content must be available to the host app") }
        XCTAssertEqual(received, text)
        XCTAssertNil(SharedInbox.takeNext())
    }
    func testShortcutsRequireOptIn() async {
        let defaults = UserDefaults.standard
        let previous = defaults.object(forKey: AutomationPreferences.enabledKey)
        defer {
            if let previous { defaults.set(previous, forKey: AutomationPreferences.enabledKey) }
            else { defaults.removeObject(forKey: AutomationPreferences.enabledKey) }
        }
        defaults.set(false, forKey: AutomationPreferences.enabledKey)
        do {
            _ = try await AutomationService.shared.check("Synthetic test input")
            XCTFail("Disabled Shortcuts must not run inference")
        } catch { XCTAssertTrue(error is AutomationError) }
    }
    func testShortcutsActionRunsFreshLocalInferenceAndDeduplicates() async throws {
        guard ModelFiles.isInstalled else { throw XCTSkip("The real local model must be installed") }
        let defaults = UserDefaults.standard
        let keys = [AutomationPreferences.enabledKey, "shortcutsConsent", "historyEnabled", "cloudEnabled"]
        let previous = keys.map { defaults.object(forKey: $0) }
        defer {
            for (key, value) in zip(keys, previous) {
                if let value { defaults.set(value, forKey: key) } else { defaults.removeObject(forKey: key) }
            }
        }
        defaults.set(true, forKey: AutomationPreferences.enabledKey)
        defaults.set(UUID().uuidString, forKey: "shortcutsConsent")
        defaults.set(false, forKey: "historyEnabled")
        defaults.set(true, forKey: "cloudEnabled") // The intent's path must remain independent of this setting.
        defaults.removeObject(forKey: "automationLastCheck")
        defer { defaults.removeObject(forKey: "automationLastCheck"); defaults.removeObject(forKey: "automationLastRun") }
        let previousLimit = AutomationService.shortcutWaitLimit
        AutomationService.shortcutWaitLimit = .seconds(300) // This test needs the finished summary.
        defer { AutomationService.shortcutWaitLimit = previousLimit }
        let intent = CheckMessageLocallyIntent()
        intent.message = "Your login code is 752184. Never give this code to another person. Use your usual app if this login was unexpected."
        let result = try await intent.perform()
        let summary = try XCTUnwrap(result.value)
        XCTAssertFalse(summary.contains("Warning signs found"), summary)
        XCTAssertTrue(summary.contains("No obvious warning signs") || summary.contains("Needs verification") || summary.contains("Insufficient content"), summary)
        let repeated = try await AutomationService.shared.check(intent.message)
        XCTAssertTrue(repeated.contains("No duplicate warning"))
        XCTAssertTrue(defaults.bool(forKey: "cloudEnabled"))
        // A real Shortcuts run is what flips setup to "Connected": only the time and category are kept.
        let last = try XCTUnwrap(AutomationPreferences.lastCheck)
        XCTAssertLessThan(Date().timeIntervalSince(last.date), 300)
        XCTAssertFalse(last.outcome.contains("752184"))
        XCTAssertEqual(AutomationPreferences.lastRun?.stage, .finished)
    }
    /// Shortcuts reports "unknown error" when an action runs past its limit. A slow check must answer
    /// early, keep running, and still record its result.
    func testSlowCheckAnswersShortcutsEarlyAndStillFinishes() async throws {
        guard ModelFiles.isInstalled else { throw XCTSkip("The real local model must be installed") }
        let defaults = UserDefaults.standard
        let keys = [AutomationPreferences.enabledKey, "shortcutsConsent", "historyEnabled", "automationLastCheck", "automationLastRun"]
        let previous = keys.map { defaults.object(forKey: $0) }
        let previousLimit = AutomationService.shortcutWaitLimit
        defer {
            AutomationService.shortcutWaitLimit = previousLimit
            for (key, value) in zip(keys, previous) {
                if let value { defaults.set(value, forKey: key) } else { defaults.removeObject(forKey: key) }
            }
        }
        defaults.set(true, forKey: AutomationPreferences.enabledKey)
        defaults.set(UUID().uuidString, forKey: "shortcutsConsent")
        defaults.set(false, forKey: "historyEnabled")
        defaults.removeObject(forKey: "automationLastCheck"); defaults.removeObject(forKey: "automationLastRun")
        AutomationService.shortcutWaitLimit = .milliseconds(50)
        let t0 = Date()
        let early = try await AutomationService.shared.check("Approved ka na sa online job! Pay 800 registration fee today para ma-activate ang account mo. Ref \(UUID().uuidString.prefix(6))")
        let answeredAfter = Date().timeIntervalSince(t0)
        XCTAssertTrue(early.contains("Still checking"), early)
        XCTAssertLessThan(answeredAfter, 3, "Shortcuts was answered only after \(answeredAfter) s")
        XCTAssertEqual(AutomationPreferences.lastRun?.stage, .checking)
        let deadline = Date().addingTimeInterval(180)
        while AutomationPreferences.lastRun?.stage == .checking || AutomationPreferences.lastRun?.stage == .saved, Date() < deadline {
            try await Task.sleep(for: .milliseconds(500))
        }
        let stage = AutomationPreferences.lastRun?.stage
        XCTAssertTrue(stage == .finished || stage == .failed, "Run never completed: \(String(describing: stage))")
        if stage == .finished { XCTAssertNotNil(AutomationPreferences.lastCheck) }
    }
    func testShortcutsGuardsAgainstWrongInputWithoutModelWork() async throws {
        let defaults = UserDefaults.standard
        let keys = [AutomationPreferences.enabledKey, "shortcutsConsent", "automationLastCheck"]
        let previous = keys.map { defaults.object(forKey: $0) }
        defer {
            for (key, value) in zip(keys, previous) {
                if let value { defaults.set(value, forKey: key) } else { defaults.removeObject(forKey: key) }
            }
        }
        defaults.set(true, forKey: AutomationPreferences.enabledKey)
        defaults.set(UUID().uuidString, forKey: "shortcutsConsent")
        defaults.removeObject(forKey: "automationLastCheck")
        // The Shortcut was wired to the sender: say so, and do not pretend a message was checked.
        do {
            _ = try await AutomationService.shared.check("09171234567")
            XCTFail("A bare phone number is not a message")
        } catch { XCTAssertEqual(error as? AutomationError, .senderInstead) }
        XCTAssertNil(AutomationPreferences.lastCheck)
        // Very short texts are skipped quietly, and still prove the trigger fired.
        let skipped = try await AutomationService.shared.check("ok")
        XCTAssertTrue(skipped.contains("Too short"))
        XCTAssertEqual(AutomationPreferences.lastCheck?.outcome, AutomationPreferences.skippedOutcome)
    }
}
