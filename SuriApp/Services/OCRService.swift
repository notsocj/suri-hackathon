import Foundation
import Vision
import ImageIO

nonisolated struct OCRResult: Sendable { let text: String; let needsReview: Bool }

nonisolated enum OCRService {
    @concurrent static func extract(_ data: Data) async throws -> OCRResult {
        try Task.checkCancellation()
        guard data.count <= 25 * 1024 * 1024,
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: 2400,
                kCGImageSourceCreateThumbnailWithTransform: true
              ] as CFDictionary) else { throw CaptureError.invalidImage }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        request.automaticallyDetectsLanguage = true
        try VNImageRequestHandler(cgImage: image).perform([request])
        try Task.checkCancellation()
        let candidates = (request.results ?? []).compactMap { $0.topCandidates(1).first }
        let text = candidates.map(\.string).joined(separator: "\n")
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw CaptureError.unreadable }
        return OCRResult(text: text, needsReview: candidates.contains { $0.confidence < 0.8 })
    }
}

nonisolated enum CaptureError: Error, LocalizedError {
    case invalidImage, unreadable
    var errorDescription: String? {
        switch self {
        case .invalidImage: "Choose a readable screenshot smaller than 25 MB."
        case .unreadable: "No readable text was found. Try a clearer screenshot or paste the message."
        }
    }
}
