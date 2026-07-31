import WidgetKit
import SwiftUI

struct HealingQuoteEntry: TimelineEntry {
    let date: Date
    let quote: Quote
}

struct HealingQuoteProvider: TimelineProvider {
    private let quoteStore = QuoteStore.shared
    private let calendar = Calendar.current

    func placeholder(in context: Context) -> HealingQuoteEntry {
        HealingQuoteEntry(date: Date(), quote: quoteStore.randomQuote())
    }

    func getSnapshot(in context: Context, completion: @escaping (HealingQuoteEntry) -> Void) {
        completion(HealingQuoteEntry(date: Date(), quote: currentQuote(at: Date())))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HealingQuoteEntry>) -> Void) {
        let now = Date()
        let startDate = roundedDownToQuarterHour(now)
        let entries = (0..<48).map { index in
            let entryDate = calendar.date(byAdding: .minute, value: index * 15, to: startDate) ?? now
            return HealingQuoteEntry(date: entryDate, quote: currentQuote(at: entryDate))
        }

        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func currentQuote(at date: Date) -> Quote {
        let quotes = availableQuotes
        let timeSlot = Int(date.timeIntervalSinceReferenceDate / (15 * 60))
        let index = positiveModulo(timeSlot, quotes.count)
        return quotes[index]
    }

    private var availableQuotes: [Quote] {
        let quotes = QuoteStore.loadSyncedQuotes() ?? quoteStore.allQuotes
        return quotes.isEmpty ? [quoteStore.randomQuote()] : quotes
    }

    private func roundedDownToQuarterHour(_ date: Date) -> Date {
        let minute = calendar.component(.minute, from: date)
        let roundedMinute = minute - (minute % 15)
        var components = calendar.dateComponents([.year, .month, .day, .hour], from: date)
        components.minute = roundedMinute
        components.second = 0
        return calendar.date(from: components) ?? date
    }

    private func positiveModulo(_ value: Int, _ divisor: Int) -> Int {
        let remainder = value % divisor
        return remainder >= 0 ? remainder : remainder + divisor
    }
}

struct HealingQuoteWidget: Widget {
    static let kind = QuoteStore.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: HealingQuoteProvider()) { entry in
            HealingQuoteWidgetView(entry: entry)
                .widgetURL(URL(string: "healing://quote/\(entry.quote.id)"))
        }
        .configurationDisplayName("Healing Quote")
        .description("Keep a gentle quote visible on your watch face.")
        .supportedFamilies(supportedFamilies)
    }

    private var supportedFamilies: [WidgetFamily] {
        var families: [WidgetFamily] = [
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ]

        if #available(watchOSApplicationExtension 9.0, *) {
            families.append(.accessoryCorner)
        }

        return families
    }
}

struct HealingQuoteWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: HealingQuoteEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .accessoryInline:
            inlineView
        case .accessoryCorner:
            cornerView
        default:
            rectangularView
        }
    }

    private var circularView: some View {
        ZStack {
            Circle()
                .fill(entry.quote.colors.background)
            Text(shortText(maxCharacters: 22))
                .font(.system(.caption2, design: .rounded, weight: .semibold))
                .foregroundStyle(entry.quote.colors.foreground)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.55)
                .padding(6)
        }
        .containerBackground(entry.quote.colors.background, for: .widget)
    }

    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 3) {
            if let author = entry.quote.author {
                Text(author)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(entry.quote.colors.foreground)
                    .lineLimit(1)
            }

            Text(shortText(maxCharacters: 72))
                .font(.system(.caption2, design: .rounded, weight: .medium))
                .foregroundStyle(entry.quote.colors.foreground.opacity(0.7))
                .lineLimit(3)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(entry.quote.colors.background, for: .widget)
    }

    private var inlineView: some View {
        Text(shortText(maxCharacters: 36))
            .font(.system(.caption, design: .rounded, weight: .medium))
            .foregroundStyle(entry.quote.colors.foreground)
            .containerBackground(entry.quote.colors.background, for: .widget)
    }

    private var cornerView: some View {
        Text(shortText(maxCharacters: 18))
            .font(.system(.caption2, design: .rounded, weight: .semibold))
            .foregroundStyle(entry.quote.colors.foreground)
            .widgetCurvesContent()
            .containerBackground(entry.quote.colors.background, for: .widget)
    }

    private func shortText(maxCharacters: Int) -> String {
        guard entry.quote.text.count > maxCharacters else { return entry.quote.text }
        let index = entry.quote.text.index(entry.quote.text.startIndex, offsetBy: maxCharacters)
        return String(entry.quote.text[..<index]).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
    }
}

#Preview(as: .accessoryRectangular) {
    HealingQuoteWidget()
} timeline: {
    HealingQuoteEntry(date: Date(), quote: QuoteStore.shared.randomQuote())
}
