import SwiftUI

struct QuoteCardView: View {
    let quote: Quote
    let showAuthor: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(quote.text)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(Color(red: 0.07, green: 0.06, blue: 0.02))
                .multilineTextAlignment(.leading)
                .lineLimit(6)
                .minimumScaleFactor(0.62)
                .contentTransition(.opacity)

            if showAuthor, let author = quote.author, author.isEmpty == false {
                Text(author)
                    .font(.system(.footnote, design: .rounded, weight: .medium))
                    .foregroundStyle(Color(red: 0.07, green: 0.06, blue: 0.02).opacity(0.72))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 1.0, green: 0.78, blue: 0.12))
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(Color(red: 0.07, green: 0.06, blue: 0.02))
                        .frame(width: 4)
                        .padding(.vertical, 14)
                }
                .shadow(color: .black.opacity(0.45), radius: 10, x: 0, y: 5)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(quote.accessibilityLabel)
    }
}

#Preview {
    QuoteCardView(quote: QuoteStore.shared.randomQuote(), showAuthor: true)
        .padding()
}
