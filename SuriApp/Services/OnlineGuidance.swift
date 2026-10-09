import Foundation
import Network
import Observation
import SuriCore

@MainActor @Observable final class NetworkState {
    var connected = false
    var wifi = false
    private let monitor = NWPathMonitor()
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            let wifi = path.usesInterfaceType(.wifi)
            Task { @MainActor in self?.connected = connected; self?.wifi = wifi }
        }
        monitor.start(queue: DispatchQueue(label: "suri.network-status"))
    }
}

nonisolated struct OnlineGuidance: Decodable, Sendable {
    let guidance: String
    let referenceIDs: [String]
    let generatedAt: Date
    let scope: String
}

nonisolated enum GuidanceClient {
    static func request(payload: GuidancePayload, endpoint: String, token: String, wifiOnly: Bool) async throws -> OnlineGuidance {
        guard let base = URL(string: endpoint), base.user == nil, base.password == nil,
              base.query == nil, base.fragment == nil,
              base.scheme == "https" || (base.scheme == "http" && ["localhost", "127.0.0.1"].contains(base.host ?? "")),
              !token.isEmpty else { throw CloudPolicyError.notConfigured }
        var request = URLRequest(url: base.appendingPathComponent("guidance"))
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.allowsCellularAccess = !wifiOnly
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(payload)
        let config = URLSessionConfiguration.ephemeral
        config.allowsCellularAccess = !wifiOnly
        config.urlCache = nil; config.httpCookieStorage = nil
        let session = URLSession(configuration: config, delegate: NoRedirects(), delegateQueue: nil)
        defer { session.invalidateAndCancel() }
        let (bytes, response) = try await session.bytes(for: request)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else { throw CloudPolicyError.connection }
        var data = Data()
        for try await byte in bytes {
            try Task.checkCancellation()
            guard data.count < 16_384 else { throw CloudPolicyError.connection }
            data.append(byte)
        }
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let value = try decoder.decode(OnlineGuidance.self, from: data)
        let allowed = Set(GuidanceStore.references.map(\.id))
        guard !value.guidance.isEmpty, value.guidance.count <= 1500,
              value.scope == "pattern_guidance", !value.referenceIDs.isEmpty,
              value.referenceIDs.count <= 2,
              value.referenceIDs.allSatisfy(allowed.contains),
              abs(value.generatedAt.timeIntervalSinceNow) < 300 else { throw CloudPolicyError.connection }
        return value
    }
}

private final class NoRedirects: NSObject, URLSessionTaskDelegate, Sendable {
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest,
                    completionHandler: @escaping @Sendable (URLRequest?) -> Void) { completionHandler(nil) }
}
