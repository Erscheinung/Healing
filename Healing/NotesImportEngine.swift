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
        let entries: [String]
        let newEntries: [String]
        let duplicateCount: Int
        let lastKnownPosition: Int?
    }

    nonisolated static func fingerprint(_ text: String) -> String {
        let normalized = text.precomposedStringWithCanonicalMapping
            .lowercased()
            .replacingOccurrences(of: "[’‘]", with: "'", options: .regularExpression)
            .replacingOccurrences(of: "[“”]", with: "\"", options: .regularExpression)
            .replacingOccurrences(of: "[–—]", with: "-", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return SHA256.hash(data: Data(normalized.utf8)).map { String(format: "%02x", $0) }.joined()
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
        var seen = known
        var additions: [String] = []
        var lastKnown: Int?
        for (index, entry) in entries.enumerated() {
            let key = fingerprint(entry)
            if known.contains(key) { lastKnown = index + 1 }
            if seen.insert(key).inserted { additions.append(entry) }
        }
        return Preview(entries: entries, newEntries: additions,
                       duplicateCount: entries.count - additions.count, lastKnownPosition: lastKnown)
    }
}
