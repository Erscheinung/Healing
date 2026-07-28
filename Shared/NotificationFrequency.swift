import Foundation

enum NotificationFrequency: String, CaseIterable, Identifiable, Sendable {
    case disabled
    case everyHour
    case everyTwoHours
    case everyFourHours
    case everySixHours
    case morningOnly
    case eveningOnly
    case eveningQuarterHourly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .disabled:
            "Disabled"
        case .everyHour:
            "Every hour"
        case .everyTwoHours:
            "Every 2 hours"
        case .everyFourHours:
            "Every 4 hours"
        case .everySixHours:
            "Every 6 hours"
        case .morningOnly:
            "Morning only"
        case .eveningOnly:
            "Evening only"
        case .eveningQuarterHourly:
            "6 PM-1 AM, every 15 min"
        }
    }

    var isEnabled: Bool {
        self != .disabled
    }
}
