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
        switch frequency {
        case .disabled:
            return []
        case .everyHour:
            return hourlyDates(from: 8, through: 20, step: 1)
        case .everyTwoHours:
            return hourlyDates(from: 8, through: 20, step: 2)
        case .everyFourHours:
            return [8, 12, 16, 20].map { dateComponents(hour: $0) }
        case .everySixHours:
            return [8, 14, 20].map { dateComponents(hour: $0) }
        case .morningOnly:
            return [dateComponents(hour: 8)]
        case .eveningOnly:
            return [dateComponents(hour: 19)]
        case .eveningQuarterHourly:
            return eveningQuarterHourlyDates()
        }
    }

    private static func hourlyDates(from startHour: Int, through endHour: Int, step: Int) -> [DateComponents] {
        Array(stride(from: startHour, through: endHour, by: step)).map { dateComponents(hour: $0) }
    }

    private static func eveningQuarterHourlyDates() -> [DateComponents] {
        let eveningHours = (18...23).flatMap { hour in
            [0, 15, 30, 45].map { minute in
                dateComponents(hour: hour, minute: minute)
            }
        }

        let afterMidnight = [0].flatMap { hour in
            [0, 15, 30, 45].map { minute in
                dateComponents(hour: hour, minute: minute)
            }
        }

        return eveningHours + afterMidnight + [dateComponents(hour: 1)]
    }

    private static func dateComponents(hour: Int, minute: Int = 0) -> DateComponents {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return components
    }

    private static let managedIdentifiers = (0..<64).map { "healing.quote-pulse.\($0)" }
}
