import Foundation
import CryptoKit

/// Pure text comparison; no Notes credentials, network requests, or image decoding.
enum NotesImportEngine {
    enum Grouping: String, CaseIterable, Identifiable {
        case lines = "Each line"
        case paragraphs = "Paragraphs"
        var id: String { rawValue }
    }

    struct Preview {
        enum ItemState: String, Hashable {
            case new
            case alreadyKnown
            case repeated
        }

        struct Item: Identifiable, Hashable {
            /// The position in the pasted note. Keeping this stable lets the UI select
            /// individual rows even when two entries happen to have the same text.
            let index: Int
            let text: String
            let fingerprint: String
            let state: ItemState

            var id: Int { index }
            var isNew: Bool { state == .new }
        }

        let entries: [String]
        let newEntries: [String]
        let duplicateCount: Int
        let lastKnownPosition: Int?
        let items: [Item]

        /// The note's bottom entries are shown first because they are normally the
        /// newest additions to an Apple Note.
        var displayItems: [Item] { Array(items.reversed()) }
        var newItems: [Item] { items.filter(\.isNew) }
    }

    nonisolated static func fingerprint(_ text: String) -> String {
        digest(normalizedText(text))
    }

    /// The importer used this narrower form before the comparison rules were
    /// expanded. Remembered imports may still contain these hashes, so previews
    /// check both forms while the current form is stored for new imports.
    private static func legacyFingerprint(_ text: String) -> String {
        let normalized = text.precomposedStringWithCanonicalMapping
            .lowercased()
            .replacingOccurrences(of: "[’‘]", with: "'", options: .regularExpression)
            .replacingOccurrences(of: "[“”]", with: "\"", options: .regularExpression)
            .replacingOccurrences(of: "[–—]", with: "-", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return digest(normalized)
    }

    private static func normalizedText(_ text: String) -> String {
        var normalized = text.precomposedStringWithCanonicalMapping
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\u{202F}", with: " ")
            .replacingOccurrences(of: "\u{200B}", with: "")
            .replacingOccurrences(of: "\u{200C}", with: "")
            .replacingOccurrences(of: "\u{200D}", with: "")
            .replacingOccurrences(of: "\u{FEFF}", with: "")
            .lowercased()
            .replacingOccurrences(of: "[’‘ʼ＇]", with: "'", options: .regularExpression)
            .replacingOccurrences(of: "[“”„‟«»]", with: "\"", options: .regularExpression)
            .replacingOccurrences(of: "[–—―−‒]", with: "-", options: .regularExpression)
            .replacingOccurrences(of: "…", with: "...", options: .literal)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove a matching pair of quote marks without damaging contractions
        // or words that merely begin with an apostrophe.
        while let first = normalized.first,
              let last = normalized.last,
              normalized.count > 1,
              (first == "\"" && last == "\"") || (first == "'" && last == "'") {
            normalized.removeFirst()
            normalized.removeLast()
            normalized = normalized.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return normalized
    }

    private static func digest(_ normalized: String) -> String {
        SHA256.hash(data: Data(normalized.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    static func entries(in text: String, grouping: Grouping) -> [String] {
        var cleaned = text.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "\u{FFFC}", with: "")
            .replacingOccurrences(of: "\u{FEFF}", with: "")
        // Drop image markup including alt text, and image reference definitions.
        for pattern in [#"!\[[^\]]*\]\((?:[^()\n]|\([^()\n]*\))*\)"#, #"!\[[^\]]*\](?:\[[^\]]*\])?"#,
                        #"(?is)<img\b[^>]*>"#, #"(?im)^\s*\[[^\]]+\]:\s*.*\.(?:png|jpe?g|gif|heic|webp|svg)\b.*$"#] {
            cleaned = cleaned.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
        }
        let lines = cleaned.components(separatedBy: "\n").map { line -> String in
            var value = line.trimmingCharacters(in: .whitespaces)
            if value.range(of: #"^#{1,6}\s|^(?:[-*_]\s*){3,}$"#, options: .regularExpression) != nil { return "" }
            value = value.replacingOccurrences(of: #"^(?:[-*•] |\d+[.)] |>[ ]?)(?:\[[ xX]\] )?"#, with: "", options: .regularExpression)
            value = value.replacingOccurrences(of: #"\*\*(.*?)\*\*|__(.*?)__"#, with: "$1$2", options: .regularExpression)
            if ["practice for musku", "practice for yourself"].contains(value.lowercased()) { return "" }
            if value.range(of: #"^https?://(?:www\.)?icloud\.com/notes/"#, options: .regularExpression) != nil { return "" }
            if value.range(of: #"(?i)^\S+\.(?:png|jpe?g|gif|heic|webp|svg)$"#, options: .regularExpression) != nil { return "" }
            return value
        }
        let parts: [String]
        if grouping == .lines {
            parts = lines
        } else {
            parts = lines.joined(separator: "\n").components(separatedBy: "\n\n")
        }
        return parts.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    static func preview(text: String, grouping: Grouping, existing: [String], remembered: Set<String>) -> Preview {
        let entries = entries(in: text, grouping: grouping)
        let known = Set(existing.map(fingerprint)).union(remembered)
        let legacyKnown = Set(existing.map(legacyFingerprint))
        var seen = known
        var additions: [String] = []
        var items: [Preview.Item] = []
        var lastKnown: Int?
        for (index, entry) in entries.enumerated() {
            let key = fingerprint(entry)
            let legacyKey = legacyFingerprint(entry)
            let state: Preview.ItemState
            if known.contains(key) || legacyKnown.contains(legacyKey) || remembered.contains(legacyKey) {
                lastKnown = index + 1
                state = .alreadyKnown
            } else if seen.insert(key).inserted {
                additions.append(entry)
                state = .new
            } else {
                state = .repeated
            }
            items.append(Preview.Item(index: index, text: entry, fingerprint: key, state: state))
        }
        return Preview(entries: entries, newEntries: additions,
                       duplicateCount: entries.count - additions.count, lastKnownPosition: lastKnown,
                       items: items)
    }
}
