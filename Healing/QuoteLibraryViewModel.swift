import Foundation
import Combine
import SwiftUI

@MainActor
final class QuoteLibraryViewModel: ObservableObject {
    struct PracticeSection {
        let title: String
        let quotes: [Quote]
    }

    @Published var quotes: [Quote] = [] {
        didSet {
            guard isLoaded else { return }
            save()
        }
    }

    @Published var selectedQuote: Quote?
    @Published var isShowingEditor = false
    @Published var syncStatus = "Not synced yet"

    let syncManager = PhoneQuoteSyncManager()

    private let storageKey = "healing.customQuotes"
    private var isLoaded = false

    init() {
        syncManager.$status
            .receive(on: DispatchQueue.main)
            .assign(to: &$syncStatus)
        load()
        isLoaded = true
    }

    var themes: [String] {
        uniqueValues(quotes.map(\.theme))
    }

    var practices: [String] {
        uniqueValues(quotes.compactMap(\.practice))
    }

    var authors: [String] {
        uniqueValues(quotes.compactMap(\.author).filter { $0.isEmpty == false })
    }

    var backgroundColors: [String] {
        uniqueValues(quotes.map(\.backgroundColor))
    }

    var foregroundColors: [String] {
        uniqueValues(quotes.map(\.foregroundColor))
    }

    var accentColors: [String] {
        uniqueValues(quotes.map(\.accentColor))
    }

    var practiceSections: [PracticeSection] {
        let categories = ["Practice for Yourself", "Practice for Musku"]
        let grouped = categories.compactMap { category -> PracticeSection? in
            let matchingQuotes = quotes.filter { $0.practice == category }
            return matchingQuotes.isEmpty ? nil : PracticeSection(title: category, quotes: matchingQuotes)
        }
        let generalQuotes = quotes.filter { $0.practice == nil }
        return grouped + (generalQuotes.isEmpty ? [] : [PracticeSection(title: "General", quotes: generalQuotes)])
    }

    func addQuote() {
        let template = quotes.first ?? QuoteStore.shared.randomQuote()
        selectedQuote = Quote(
            id: nextID(),
            text: "",
            author: template.author,
            practice: template.practice,
            theme: template.theme,
            backgroundColor: template.backgroundColor,
            foregroundColor: template.foregroundColor,
            accentColor: template.accentColor
        )
        isShowingEditor = true
    }

    func edit(_ quote: Quote) {
        selectedQuote = quote
        isShowingEditor = true
    }

    func save(_ quote: Quote) {
        if let index = quotes.firstIndex(where: { $0.id == quote.id }) {
            quotes[index] = quote
        } else {
            quotes.insert(quote, at: 0)
        }
    }

    func delete(at offsets: IndexSet) {
        quotes.remove(atOffsets: offsets)
    }

    func delete(_ quote: Quote) {
        quotes.removeAll { $0.id == quote.id }
    }

    func delete(quotes sectionQuotes: [Quote], at offsets: IndexSet) {
        let ids = offsets.map { sectionQuotes[$0].id }
        quotes.removeAll { ids.contains($0.id) }
    }

    func restoreBundledQuotes() {
        quotes = QuoteStore.shared.allQuotes
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Quote].self, from: data),
           decoded.isEmpty == false {
            quotes = decoded
        } else {
            quotes = QuoteStore.shared.allQuotes
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(quotes) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
        syncManager.sync(quotes: quotes)
    }

    private func nextID() -> Int {
        (quotes.map(\.id).max() ?? 0) + 1
    }

    private func uniqueValues(_ values: [String]) -> [String] {
        Array(Set(values)).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }
}
