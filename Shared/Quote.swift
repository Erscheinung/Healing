import SwiftUI

struct Quote: Codable, Identifiable, Equatable, Hashable, Sendable {
    let id: Int
    let text: String
    let author: String?
    let practice: String?
    let theme: String
    let backgroundColor: String
    let foregroundColor: String
    let accentColor: String

    var displayAuthor: String {
        guard let author, author.isEmpty == false else { return "Unknown" }
        return author
    }

    var accessibilityLabel: String {
        if let author, author.isEmpty == false {
            return "\(text). \(author)."
        }
        return text
    }

    var colors: QuoteTheme {
        QuoteTheme(
            background: Color(hex: backgroundColor, fallback: QuoteTheme.fallback.background),
            foreground: Color(hex: foregroundColor, fallback: QuoteTheme.fallback.foreground),
            accent: Color(hex: accentColor, fallback: QuoteTheme.fallback.accent)
        )
    }
}

struct QuoteTheme {
    let background: Color
    let foreground: Color
    let accent: Color

    static let fallback = QuoteTheme(
        background: Color(hex: "#EAF5F4", fallback: .black),
        foreground: Color(hex: "#123456", fallback: .white),
        accent: Color(hex: "#7FB3AC", fallback: .secondary)
    )
}

extension Color {
    init(hex: String, fallback: Color) {
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("#") {
            value.removeFirst()
        }

        guard value.count == 6, let integer = UInt64(value, radix: 16) else {
            self = fallback
            return
        }

        let red = Double((integer >> 16) & 0xFF) / 255.0
        let green = Double((integer >> 8) & 0xFF) / 255.0
        let blue = Double(integer & 0xFF) / 255.0

        self = Color(red: red, green: green, blue: blue)
    }
}
