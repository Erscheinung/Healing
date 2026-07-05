import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let quoteStore: QuoteStore

    init(quoteStore: QuoteStore = .shared) {
        self.quoteStore = quoteStore
    }

    func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound])
            } catch {
                return false
            }
        @unknown default:
            return false
        }
    }

    func schedulePulses(frequency: NotificationFrequency) async throws {
        center.removePendingNotificationRequests(withIdentifiers: Self.managedIdentifiers)

        guard frequency.isEnabled else { return }

        let requests = makeRequests(for: frequency)
        for request in requests {
            try await center.add(request)
        }
    }

    func clearScheduledNotifications() {
        center.removePendingNotificationRequests(withIdentifiers: Self.managedIdentifiers)
    }

    private func makeRequests(for frequency: NotificationFrequency) -> [UNNotificationRequest] {
        let dates = Self.scheduleDates(for: frequency)

        // watchOS does not allow arbitrary always-on background execution. Local notifications
        // must be scheduled ahead of time, may be coalesced or delayed by the system, and use the
        // standard notification haptic/sound behavior controlled by watchOS and user settings.
        return dates.enumerated().map { index, dateComponents in
            let quote = quoteStore.randomQuote()
            let content = UNMutableNotificationContent()
            content.title = "Healing"
            content.body = quote.author.map { "\(quote.text) - \($0)" } ?? quote.text
            content.sound = .default
            content.userInfo = ["quoteID": quote.id]

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            return UNNotificationRequest(
                identifier: Self.managedIdentifiers[index],
                content: content,
                trigger: trigger
            )
        }
    }

    private static func scheduleDates(for frequency: NotificationFrequency) -> [DateComponents] {
        let hours: [Int]
        switch frequency {
        case .disabled:
            hours = []
        case .everyTwoHours:
            hours = Array(stride(from: 8, through: 20, by: 2))
        case .everyFourHours:
            hours = [8, 12, 16, 20]
        case .everySixHours:
            hours = [8, 14, 20]
        case .morningOnly:
            hours = [8]
        case .eveningOnly:
            hours = [19]
        }

        return hours.map { hour in
            var components = DateComponents()
            components.hour = hour
            components.minute = 0
            return components
        }
    }

    private static let managedIdentifiers = (0..<16).map { "healing.quote-pulse.\($0)" }
}
