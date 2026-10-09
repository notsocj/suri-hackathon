import SwiftUI
import Observation
import SuriCore

@MainActor @Observable final class AppModel {
    enum Phase: Equatable { case editing, extracting, checking, result, failed(String) }
    var phase: Phase = .editing
    var text = "" {
        didSet {
            if oldValue != text {
                analysisTask?.cancel(); onlineTask?.cancel()
                revision = UUID(); assessment = nil; online = nil; onlineStatus = "Not checked online"
                phase = .editing
            }
        }
    }
    private(set) var revision = UUID()
    var assessment: Assessment?
    var history: [Assessment] = []
    var online: OnlineGuidance?
    var onlineStatus = "Not checked online"
    var modelInstalled = ModelFiles.isInstalled
    var installing = false
    var downloadFraction: Double?
    var downloadButtonTitle = "Download model (1.3 GB)"
    var modelStatus = ModelFiles.isInstalled ? "Ready for offline checks" : "Local model download needed"
    var notice: String?
    var needsOCRReview = false
    var selectedTab = 0
    let network = NetworkState()
    private let analyzer = LocalAnalyzer.shared
    private let cases = CaseStore.shared
    private var analysisTask: Task<Void, Never>?
    private var onlineTask: Task<Void, Never>?
    private var captureTask: Task<Void, Never>?
    private var consentVersion = UUID()
    private var requestedOnline = Set<UUID>()

    var familyName: String { didSet { UserDefaults.standard.set(familyName, forKey: "familyName") } }
    var familyNumber: String
    var gatewayToken: String
    var gatewayURL: String { didSet { UserDefaults.standard.set(gatewayURL, forKey: "gatewayURL"); revokePendingOnline() } }
    var cloudEnabled: Bool { didSet { UserDefaults.standard.set(cloudEnabled, forKey: "cloudEnabled"); revokePendingOnline() } }
    var wifiOnly: Bool { didSet { UserDefaults.standard.set(wifiOnly, forKey: "wifiOnly"); revokePendingOnline() } }
    var historyEnabled: Bool { didSet { UserDefaults.standard.set(historyEnabled, forKey: "historyEnabled") } }
    var completedOnboarding: Bool { didSet { UserDefaults.standard.set(completedOnboarding, forKey: "completedOnboarding") } }

    init() {
        familyName = UserDefaults.standard.string(forKey: "familyName") ?? ""
        familyNumber = KeychainStore.read("familyNumber")
        gatewayToken = KeychainStore.read("gatewayToken")
        gatewayURL = UserDefaults.standard.string(forKey: "gatewayURL") ?? ""
        cloudEnabled = UserDefaults.standard.bool(forKey: "cloudEnabled")
        wifiOnly = UserDefaults.standard.object(forKey: "wifiOnly") as? Bool ?? true
        historyEnabled = UserDefaults.standard.object(forKey: "historyEnabled") as? Bool ?? true
        completedOnboarding = UserDefaults.standard.bool(forKey: "completedOnboarding")
        ModelDownloader.shared.setHandler { [weak self] event in Task { @MainActor in self?.handleDownload(event) } }
    }

    func loadHistory() async {
        do { history = try await cases.load(); try await cases.save(history) }
        catch { notice = "Saved checks could not be loaded. You can still check a new message." }
    }
    func openPendingAutomationResult() async {
        guard let id = UserDefaults.standard.string(forKey: "pendingAutomationAssessment") else { return }
        UserDefaults.standard.removeObject(forKey: "pendingAutomationAssessment")
        if let result = history.first(where: { $0.id.uuidString == id }) { viewHistory(result) }
        else { notice = "The warning came from a local check. Its saved result is unavailable or history was off. Paste the original message to review it again." }
    }

    func saveFamily(name: String, number: String) throws {
        guard let valid = FamilyMessage.validatedDestination(number), !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FamilySetupError.invalid
        }
        try KeychainStore.write(valid, key: "familyNumber")
        familyNumber = valid; familyName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    func removeFamily() {
        do { try KeychainStore.write("", key: "familyNumber"); familyNumber = ""; familyName = "" }
        catch { notice = error.localizedDescription }
    }
    func saveGatewayToken(_ token: String) {
        guard !token.hasPrefix("sk-") else { notice = "Keep the OpenAI API key on the server. Enter only the gateway access token here."; return }
        do { try KeychainStore.write(token, key: "gatewayToken"); gatewayToken = token; revokePendingOnline() }
        catch { notice = error.localizedDescription }
    }

    func importImage(_ data: Data) {
        cancelCheck(); captureTask?.cancel(); phase = .extracting; selectedTab = 0
        let current = revision
        captureTask = Task {
            do {
                let result = try await OCRService.extract(data)
                try Task.checkCancellation()
                guard revision == current else { return }
                text = result.text; needsOCRReview = result.needsReview; phase = .editing
            } catch is CancellationError { }
            catch { guard revision == current else { return }; phase = .failed(error.localizedDescription) }
        }
    }

    func check() {
        cancelCheck()
        do { try AssessmentValidator.validateInput(text) }
        catch { phase = .failed(error.localizedDescription); return }
        guard modelInstalled else { phase = .failed(ModelError.missing.localizedDescription); return }
        phase = .checking; assessment = nil; online = nil; onlineStatus = "Not checked online"
        let input = text, current = revision
        analysisTask = Task {
            do {
                let result = try await analyzer.assess(text: input, revision: current)
                try Task.checkCancellation()
                guard revision == current else { return }
                assessment = result; phase = .result
                if historyEnabled {
                    do { history = try await cases.append(result) }
                    catch { notice = "This result is ready, but it could not be saved to history." }
                }
                guard revision == current, !Task.isCancelled else { return }
                if cloudEnabled { requestGuidance(result) }
            } catch is CancellationError { }
            catch { guard revision == current else { return }; phase = .failed(error.localizedDescription) }
        }
    }

    func cancelCheck() { analysisTask?.cancel(); captureTask?.cancel(); onlineTask?.cancel(); phase = .editing }
    func clearInput() { cancelCheck(); text = ""; assessment = nil; needsOCRReview = false }
    func viewHistory(_ value: Assessment) { onlineTask?.cancel(); online = nil; onlineStatus = "Not checked online"; assessment = value; phase = .result; selectedTab = 0 }

    func installModel() {
        guard !installing else { return }
        installing = true; downloadFraction = nil; downloadButtonTitle = "Download model (1.3 GB)"; modelStatus = "Starting download…"
        Task { await ModelDownloader.shared.start() }
    }
    func cancelDownload() { Task { await ModelDownloader.shared.pause() } }

    /// Picks up a download that kept running while Suri was suspended or closed.
    func reconnectDownload() async {
        guard !modelInstalled else { return }
        ModelDownloader.shared.reconnect()
        if await ModelDownloader.shared.isDownloading() { installing = true; modelStatus = "Downloading…" }
    }
    private func handleDownload(_ event: ModelDownloader.Event) {
        switch event {
        case .progress(let written, let total):
            installing = true
            downloadFraction = total > 0 ? min(1, Double(written) / Double(total)) : nil
            let size = { (bytes: Int64) in ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file) }
            modelStatus = "Downloading \(Int((downloadFraction ?? 0) * 100))% · \(size(written)) of \(size(total)). You can lock your phone or switch apps. Don't force-quit Suri."
        case .finished:
            installing = false; downloadFraction = nil
            modelInstalled = ModelFiles.isInstalled
            modelStatus = modelInstalled ? "Ready for offline checks" : ModelError.download.localizedDescription
        case .paused:
            installing = false; downloadFraction = nil
            downloadButtonTitle = "Resume download"; modelStatus = "Download paused. Your progress is kept."
        case .failed(let message):
            installing = false; downloadFraction = nil; downloadButtonTitle = "Try again"; modelStatus = message
        }
    }

    func requestGuidance(_ result: Assessment) {
        guard cloudEnabled else { onlineStatus = CloudPolicyError.disabled.localizedDescription; return }
        guard network.connected, !wifiOnly || network.wifi else { onlineStatus = "Local result ready. Online guidance needs an allowed connection."; return }
        guard !requestedOnline.contains(result.id) else { return }
        let payload: GuidancePayload
        do { payload = try GuidancePayload(assessment: result) }
        catch { onlineStatus = "No online request needed for this result."; return }
        guard !gatewayURL.isEmpty, !gatewayToken.isEmpty else { onlineStatus = "Online service not configured. This result is local."; return }
        requestedOnline.insert(result.id)
        let consent = consentVersion, endpoint = gatewayURL, token = gatewayToken, wifiPolicy = wifiOnly
        onlineStatus = "Getting category-only online guidance…"
        onlineTask?.cancel()
        onlineTask = Task {
            do {
                let value = try await GuidanceClient.request(payload: payload, endpoint: endpoint, token: token, wifiOnly: wifiPolicy)
                try Task.checkCancellation()
                guard consentVersion == consent, cloudEnabled, assessment?.id == result.id else { return }
                online = value; onlineStatus = "Online guidance added"
            } catch is CancellationError { }
            catch {
                guard consentVersion == consent, assessment?.id == result.id else { return }
                requestedOnline.remove(result.id)
                onlineStatus = "Couldn't get online guidance. Your local result is unchanged."
            }
        }
    }
    func revokePendingOnline() { consentVersion = UUID(); onlineTask?.cancel(); requestedOnline.removeAll(); online = nil; onlineStatus = "Not checked online" }

    func deleteHistory(at offsets: IndexSet) {
        history.remove(atOffsets: offsets)
        let current = history
        Task { do { try await cases.save(current) } catch { notice = "Could not update saved history." } }
    }
    func clearHistory() {
        history = []
        Task { do { try await cases.save([]) } catch { notice = "Could not clear saved history. Please try again." } }
    }
}

nonisolated enum FamilySetupError: Error, LocalizedError {
    case invalid
    var errorDescription: String? { "Enter a name and a valid phone number. Confirm the number with the person you trust." }
}
