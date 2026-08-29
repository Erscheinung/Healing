import SwiftUI

struct QuoteCardView: View {
    let quote: Quote
    let showAuthor: Bool

    private var theme: QuoteTheme {
        quote.colors
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(quote.text)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(theme.foreground)
                .multilineTextAlignment(.leading)
                .lineLimit(6)
                .minimumScaleFactor(0.62)
                .contentTransition(.opacity)

            if showAuthor, let author = quote.author, author.isEmpty == false {
                Text(author)
                    .font(.system(.footnote, design: .rounded, weight: .medium))
                    .foregroundStyle(theme.foreground.opacity(0.72))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(theme.background)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(theme.accent)
                        .frame(width: 4)
                        .padding(.vertical, 14)
                }
                .shadow(color: .black.opacity(0.22), radius: 10, x: 0, y: 5)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(quote.accessibilityLabel)
    }
}

#Preview {
    QuoteCardView(quote: QuoteStore.shared.randomQuote(), showAuthor: true)
        .padding()
}
