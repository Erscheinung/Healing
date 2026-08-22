import SwiftUI
import Combine

@MainActor
final class QuoteViewModel: ObservableObject {
    @Published private(set) var quote: Quote
    @Published var notificationMessage: String?
    @Published private(set) var isSchedulingNotifications = false

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
        self.quotes = Self.mergeQuotes(
            synced: WatchQuoteSyncManager.loadSyncedQuotes(),
            bundled: quoteStore.allQuotes
        )
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
        let allowed = await notificationManager.requestAuthorizationIfNeeded()
        if allowed, settings.notificationFrequency.isEnabled {
            _ = try? await notificationManager.schedulePulses(frequency: settings.notificationFrequency)
        }

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
        guard isSchedulingNotifications == false else { return }

        isSchedulingNotifications = true
        defer { isSchedulingNotifications = false }

        let allowed = await notificationManager.requestAuthorizationIfNeeded()
        guard allowed else {
            settings.notificationsEnabled = false
            notificationMessage = "Notifications are disabled in Settings."
            return
        }

        do {
            let scheduledCount = try await notificationManager.schedulePulses(frequency: settings.notificationFrequency)
            notificationMessage = scheduledMessage(for: scheduledCount)
        } catch {
            notificationMessage = "Unable to schedule pulses."
        }
    }

    func clearNotifications() {
        notificationManager.clearScheduledNotifications()
        notificationMessage = "Scheduled pulses cleared."
    }

    private func scheduledMessage(for scheduledCount: Int) -> String {
        guard settings.notificationFrequency.isEnabled else { return "Notifications disabled." }
        guard scheduledCount > 0 else { return "No upcoming pulses found for this frequency." }

        if scheduledCount == 1 {
            return "1 pulse scheduled."
        }

        return "\(scheduledCount) pulses scheduled."
    }

    private func useSyncedQuotes(_ syncedQuotes: [Quote]) {
        guard syncedQuotes.isEmpty == false else { return }

        quotes = Self.mergeQuotes(synced: syncedQuotes, bundled: quoteStore.allQuotes)
        if quotes.contains(where: { $0.id == quote.id }) == false {
            newQuote()
        }
    }

    private static func mergeQuotes(synced: [Quote]?, bundled: [Quote]) -> [Quote] {
        var mergedByID = Dictionary(uniqueKeysWithValues: bundled.map { ($0.id, $0) })
        for quote in synced ?? [] {
            mergedByID[quote.id] = quote
        }
        return mergedByID.values.sorted { $0.id < $1.id }
    }

    private func randomQuote(excluding quote: Quote? = nil) -> Quote {
        let candidates = quotes.filter { $0 != quote }
        return candidates.randomElement() ?? quotes.randomElement() ?? quoteStore.randomQuote(excluding: quote)
    }

    private static func randomQuote(from quotes: [Quote]) -> Quote {
        quotes.randomElement() ?? QuoteStore.shared.randomQuote()
    }
}
