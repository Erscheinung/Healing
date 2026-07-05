import Foundation
import Combine
import WatchConnectivity

@MainActor
final class PhoneQuoteSyncManager: NSObject, ObservableObject {
    @Published private(set) var status = "Not synced yet"

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
    }

    func sync(quotes: [Quote]) {
        guard let session else {
            status = "Watch sync is unavailable on this device"
            return
        }

        do {
            let data = try JSONEncoder().encode(quotes)
            try session.updateApplicationContext(["quotesData": data])
            status = session.isPaired
                ? "Synced to Apple Watch"
                : "Saved. Pair an Apple Watch to sync."
        } catch {
            status = "Unable to sync to Apple Watch"
        }
    }
}

extension PhoneQuoteSyncManager: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            if let error {
                status = "Watch sync error: \(error.localizedDescription)"
            } else if activationState == .activated {
                status = session.isPaired
                    ? "Ready to sync with Apple Watch"
                    : "Pair an Apple Watch to sync"
            }
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
