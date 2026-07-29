import Foundation
import WatchConnectivity
import WidgetKit

@MainActor
final class WatchQuoteSyncManager: NSObject {
    static let quotesDidChangeNotification = Notification.Name("WatchQuoteSyncManager.quotesDidChange")

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
        QuoteStore.loadSyncedQuotes()
    }

    private func applyApplicationContext() {
        guard let data = session?.receivedApplicationContext["quotesData"] as? Data else { return }
        save(data: data)
    }

    private func save(data: Data) {
        guard let quotes = QuoteStore.saveSyncedQuotesData(data) else { return }

        WidgetCenter.shared.reloadTimelines(ofKind: QuoteStore.widgetKind)
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
