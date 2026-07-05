import Foundation
import WatchConnectivity

@MainActor
final class WatchQuoteSyncManager: NSObject {
    static let quotesDidChangeNotification = Notification.Name("WatchQuoteSyncManager.quotesDidChange")

    private static let storageKey = "healing.syncedQuotes"
    private let session: WCSession?

    override init() {
        if WCSession.isSupported() {
            self.session = WCSession.default
        } else {
            self.session = nil
        }

        super.init()

        session?.delegate = self
        session?.activate()
        applyApplicationContext()
    }

    static func loadSyncedQuotes() -> [Quote]? {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let quotes = try? JSONDecoder().decode([Quote].self, from: data),
              quotes.isEmpty == false
        else {
            return nil
        }

        return quotes
    }

    private func applyApplicationContext() {
        guard let data = session?.receivedApplicationContext["quotesData"] as? Data else { return }
        save(data: data)
    }

    private func save(data: Data) {
        guard let quotes = try? JSONDecoder().decode([Quote].self, from: data),
              quotes.isEmpty == false
        else {
            return
        }

        UserDefaults.standard.set(data, forKey: Self.storageKey)
        NotificationCenter.default.post(name: Self.quotesDidChangeNotification, object: quotes)
    }
}

extension WatchQuoteSyncManager: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        guard activationState == .activated else { return }

        Task { @MainActor in
            applyApplicationContext()
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        guard let data = applicationContext["quotesData"] as? Data else { return }

        Task { @MainActor in
            save(data: data)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        guard let data = userInfo["quotesData"] as? Data else { return }

        Task { @MainActor in
            save(data: data)
        }
    }
}
