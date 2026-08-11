import Foundation

struct QuoteStore: Sendable {
    enum QuoteStoreError: Error {
        case missingQuotesFile
    }

    static let shared = QuoteStore()
    static let appGroupIdentifier = "group.com.Erscheinung.Healing"
    static let syncedQuotesStorageKey = "healing.syncedQuotes"
    static let widgetKind = "HealingQuoteWidget"

    private let quotes: [Quote]

    init(bundle: Bundle = .main) {
        self.quotes = (try? Self.loadQuotes(from: bundle)) ?? Self.fallbackQuotes
    }

    var allQuotes: [Quote] {
        quotes
    }

    func randomQuote(excluding quote: Quote? = nil) -> Quote {
        let candidates = quotes.filter { $0.id != quote?.id }
        return candidates.randomElement() ?? quotes.randomElement() ?? Self.fallbackQuotes[0]
    }

    func quote(for id: Int) -> Quote? {
        quotes.first { $0.id == id }
    }

    static func loadQuotes(from bundle: Bundle) throws -> [Quote] {
        guard let url = bundle.url(forResource: "Quotes", withExtension: "json") else {
            throw QuoteStoreError.missingQuotesFile
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([Quote].self, from: data)
    }

    static func loadSyncedQuotes() -> [Quote]? {
        guard let data = sharedDefaults.data(forKey: syncedQuotesStorageKey),
              let quotes = try? JSONDecoder().decode([Quote].self, from: data),
              quotes.isEmpty == false
        else {
            return nil
        }

        return quotes
    }

    static func saveSyncedQuotesData(_ data: Data) -> [Quote]? {
        guard let quotes = try? JSONDecoder().decode([Quote].self, from: data),
              quotes.isEmpty == false
        else {
            return nil
        }

        sharedDefaults.set(data, forKey: syncedQuotesStorageKey)
        return quotes
    }

    private static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }

    private static let fallbackQuotes: [Quote] = [
        Quote(
            id: 0,
            text: "Return to this breath. It is enough for now.",
            author: "Healing",
            practice: nil,
            theme: "Calm",
            backgroundColor: "#EAF5F4",
            foregroundColor: "#123456",
            accentColor: "#7FB3AC"
        )
    ]
}
