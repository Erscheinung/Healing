import SwiftUI
import Combine

@MainActor
final class SettingsManager: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()

    @AppStorage("notificationFrequency") var notificationFrequencyRawValue = NotificationFrequency.disabled.rawValue
    @AppStorage("notificationsEnabled") var notificationsEnabled = false
    @AppStorage("randomiseOnLaunch") var randomiseOnLaunch = true
    @AppStorage("showAuthor") var showAuthor = true
    @AppStorage("favouriteQuoteIDs") private var favouriteQuoteIDsValue = ""

    var notificationFrequency: NotificationFrequency {
        get { NotificationFrequency(rawValue: notificationFrequencyRawValue) ?? .disabled }
        set {
            objectWillChange.send()
            notificationFrequencyRawValue = newValue.rawValue
            notificationsEnabled = newValue.isEnabled
        }
    }

    var favouriteQuoteIDs: Set<Int> {
        get {
            Set(
                favouriteQuoteIDsValue
                    .split(separator: ",")
                    .compactMap { Int($0) }
            )
        }
        set {
            objectWillChange.send()
            favouriteQuoteIDsValue = newValue
                .sorted()
                .map(String.init)
                .joined(separator: ",")
        }
    }

    func isFavourite(_ quote: Quote) -> Bool {
        favouriteQuoteIDs.contains(quote.id)
    }

    func toggleFavourite(_ quote: Quote) {
        objectWillChange.send()
        var ids = favouriteQuoteIDs
        if ids.contains(quote.id) {
            ids.remove(quote.id)
        } else {
            ids.insert(quote.id)
        }
        favouriteQuoteIDs = ids
    }

    func resetFavourites() {
        objectWillChange.send()
        favouriteQuoteIDs = []
    }
}
