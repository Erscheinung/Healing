import Foundation

struct QuoteStore: Sendable {
    enum QuoteStoreError: Error {
        case missingQuotesFile
    }

    static let shared = QuoteStore()

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

    private static let fallbackQuotes: [Quote] = [
        Quote(
            id: 0,
            text: "Return to this breath. It is enough for now.",
            author: "Healing",
            theme: "Calm",
            backgroundColor: "#EAF5F4",
            foregroundColor: "#123456",
            accentColor: "#7FB3AC"
        )
    ]
}
