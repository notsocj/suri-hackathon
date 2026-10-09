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
}
