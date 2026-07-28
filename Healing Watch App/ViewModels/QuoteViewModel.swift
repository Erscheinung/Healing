import SwiftUI
import Combine

@MainActor
final class QuoteViewModel: ObservableObject {
    @Published private(set) var quote: Quote
    @Published var notificationMessage: String?

    let settings: SettingsManager

    private let quoteStore: QuoteStore
    private var quotes: [Quote]
    private let quoteSyncManager: WatchQuoteSyncManager
    private let notificationManager: NotificationManager
    private var cancellables = Set<AnyCancellable>()

    init(
        quoteStore: QuoteStore = .shared,
        quoteSyncManager: WatchQuoteSyncManager = WatchQuoteSyncManager(),
        settings: SettingsManager = SettingsManager(),
        notificationManager: NotificationManager = .shared
    ) {
        self.quoteStore = quoteStore
        self.quotes = WatchQuoteSyncManager.loadSyncedQuotes() ?? quoteStore.allQuotes
        self.quoteSyncManager = quoteSyncManager
        self.settings = settings
        self.notificationManager = notificationManager
        self.quote = Self.randomQuote(from: quotes)

        NotificationCenter.default.publisher(for: WatchQuoteSyncManager.quotesDidChangeNotification)
            .compactMap { $0.object as? [Quote] }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] quotes in
                self?.useSyncedQuotes(quotes)
            }
            .store(in: &cancellables)
    }

    var isFavourite: Bool {
        settings.isFavourite(quote)
    }

    func prepareForLaunch() async {
        _ = await notificationManager.requestAuthorizationIfNeeded()
        if settings.randomiseOnLaunch {
            newQuote()
        }
    }

    func newQuote() {
        withAnimation(.easeInOut(duration: 0.35)) {
            quote = randomQuote(excluding: quote)
        }
    }

    func toggleFavourite() {
        settings.toggleFavourite(quote)
        objectWillChange.send()
    }

    func settingsDidChange() {
        objectWillChange.send()
    }

    func scheduleNotifications() async {
        let allowed = await notificationManager.requestAuthorizationIfNeeded()
        guard allowed else {
            settings.notificationsEnabled = false
            notificationMessage = "Notifications are disabled in Settings."
            return
        }

        do {
            try await notificationManager.schedulePulses(frequency: settings.notificationFrequency)
            notificationMessage = settings.notificationFrequency.isEnabled ? "Pulses scheduled." : "Notifications disabled."
        } catch {
            notificationMessage = "Unable to schedule pulses."
        }
    }

    func clearNotifications() {
        notificationManager.clearScheduledNotifications()
        notificationMessage = "Scheduled pulses cleared."
    }

    private func useSyncedQuotes(_ syncedQuotes: [Quote]) {
        guard syncedQuotes.isEmpty == false else { return }

        quotes = syncedQuotes
        if quotes.contains(where: { $0.id == quote.id }) == false {
            newQuote()
        }
    }

    private func randomQuote(excluding quote: Quote? = nil) -> Quote {
        let candidates = quotes.filter { $0 != quote }
        return candidates.randomElement() ?? quotes.randomElement() ?? quoteStore.randomQuote(excluding: quote)
    }

    private static func randomQuote(from quotes: [Quote]) -> Quote {
        quotes.randomElement() ?? QuoteStore.shared.randomQuote()
    }
}
