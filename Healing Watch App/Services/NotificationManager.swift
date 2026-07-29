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

    func schedulePulses(frequency: NotificationFrequency) async throws -> Int {
        center.removePendingNotificationRequests(withIdentifiers: Self.managedIdentifiers)

        guard frequency.isEnabled else { return 0 }

        let requests = makeRequests(for: frequency)
        for request in requests {
            try await center.add(request)
        }

        return requests.count
    }

    func clearScheduledNotifications() {
        center.removePendingNotificationRequests(withIdentifiers: Self.managedIdentifiers)
    }

    private func makeRequests(for frequency: NotificationFrequency) -> [UNNotificationRequest] {
        let dates = Self.upcomingDates(for: frequency, limit: Self.maximumScheduledPulses)
        let quotes = QuoteStore.loadSyncedQuotes() ?? quoteStore.allQuotes
        let availableQuotes = quotes.isEmpty ? [quoteStore.randomQuote()] : quotes

        return dates.enumerated().map { index, date in
            let quote = availableQuotes[index % availableQuotes.count]
            let content = UNMutableNotificationContent()
            content.title = "Healing"
            content.body = quote.author.map { "\(quote.text) - \($0)" } ?? quote.text
            content.sound = .default
            content.interruptionLevel = .timeSensitive
            content.userInfo = ["quoteID": quote.id]

            let dateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: date
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            return UNNotificationRequest(
                identifier: Self.managedIdentifiers[index],
                content: content,
                trigger: trigger
            )
        }
    }

    private static func upcomingDates(
        for frequency: NotificationFrequency,
        from now: Date = Date(),
        calendar: Calendar = .current,
        limit: Int
    ) -> [Date] {
        guard frequency.isEnabled else { return [] }

        var dates: [Date] = []
        var dayOffset = 0
        while dates.count < limit, dayOffset < 90 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfDay(for: now, calendar: calendar)) else {
                dayOffset += 1
                continue
            }

            let dayDates = times(for: frequency).compactMap { time in
                calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: day)
            }
            .filter { $0 > now }

            dates.append(contentsOf: dayDates)
            dayOffset += 1
        }

        return Array(dates.sorted().prefix(limit))
    }

    private static func times(for frequency: NotificationFrequency) -> [(hour: Int, minute: Int)] {
        switch frequency {
        case .disabled:
            return []
        case .everyHour:
            return hourlyTimes(from: 8, through: 20, step: 1)
        case .everyTwoHours:
            return hourlyTimes(from: 8, through: 20, step: 2)
        case .everyFourHours:
            return [8, 12, 16, 20].map { ($0, 0) }
        case .everySixHours:
            return [8, 14, 20].map { ($0, 0) }
        case .morningOnly:
            return [(8, 0)]
        case .eveningOnly:
            return [(19, 0)]
        case .eveningQuarterHourly:
            return eveningQuarterHourlyTimes()
        }
    }

    private static func hourlyTimes(from startHour: Int, through endHour: Int, step: Int) -> [(hour: Int, minute: Int)] {
        Array(stride(from: startHour, through: endHour, by: step)).map { ($0, 0) }
    }

    private static func eveningQuarterHourlyTimes() -> [(hour: Int, minute: Int)] {
        let eveningHours = (18...23).flatMap { hour in
            [0, 15, 30, 45].map { minute in
                (hour, minute)
            }
        }

        let afterMidnight = [0].flatMap { hour in
            [0, 15, 30, 45].map { minute in
                (hour, minute)
            }
        }

        return eveningHours + afterMidnight + [(1, 0)]
    }

    private static func startOfDay(for date: Date, calendar: Calendar) -> Date {
        calendar.startOfDay(for: date)
    }

    private static let maximumScheduledPulses = 64
    private static let managedIdentifiers = (0..<maximumScheduledPulses).map { "healing.quote-pulse.\($0)" }
}
