import WidgetKit
import SwiftUI

struct HealingQuoteEntry: TimelineEntry {
    let date: Date
    let quote: Quote
}

struct HealingQuoteProvider: TimelineProvider {
    private let quoteStore = QuoteStore.shared

    func placeholder(in context: Context) -> HealingQuoteEntry {
        HealingQuoteEntry(date: Date(), quote: quoteStore.randomQuote())
    }

    func getSnapshot(in context: Context, completion: @escaping (HealingQuoteEntry) -> Void) {
        completion(HealingQuoteEntry(date: Date(), quote: quoteStore.randomQuote()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HealingQuoteEntry>) -> Void) {
        let now = Date()
        let quotes = quoteStore.allQuotes.isEmpty ? [quoteStore.randomQuote()] : quoteStore.allQuotes

        // WidgetKit timelines are suggestions, not timers. watchOS decides when to reload,
        // may throttle frequent updates, and can keep an older entry visible to preserve power.
        let entries = (0..<8).map { index in
            HealingQuoteEntry(
                date: Calendar.current.date(byAdding: .hour, value: index * 2, to: now) ?? now,
                quote: quotes[index % quotes.count]
            )
        }

        completion(Timeline(entries: entries, policy: .after(Calendar.current.date(byAdding: .hour, value: 16, to: now) ?? now)))
    }
}

struct HealingQuoteWidget: Widget {
    let kind = "HealingQuoteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HealingQuoteProvider()) { entry in
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
            Text(shortText(maxCharacters: 72))
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(entry.quote.colors.foreground)
                .lineLimit(3)
                .minimumScaleFactor(0.75)

            if let author = entry.quote.author {
                Text(author)
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(entry.quote.colors.foreground.opacity(0.7))
                    .lineLimit(1)
            }
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
