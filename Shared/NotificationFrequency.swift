import Foundation

enum NotificationFrequency: String, CaseIterable, Identifiable, Sendable {
    case disabled
    case everyTwoHours
    case everyFourHours
    case everySixHours
    case morningOnly
    case eveningOnly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .disabled:
            "Disabled"
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
        }
    }

    var isEnabled: Bool {
        self != .disabled
    }
}
