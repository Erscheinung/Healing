import Foundation

@main
struct NotesImportEngineTests {
    static func main() {
        func preview(_ text: String, existing: [String] = [], remembered: Set<String> = [], grouping: NotesImportEngine.Grouping = .lines) -> NotesImportEngine.Preview {
            NotesImportEngine.preview(text: text, grouping: grouping, existing: existing, remembered: remembered)
        }
        let first = preview("Practice for Musku\n- Breathe slowly.\n- Stay present.\n- Breathe slowly.")
        assert(first.newEntries == ["Breathe slowly.", "Stay present."])
        assert(first.duplicateCount == 1)
        let history = Set(first.entries.map(NotesImportEngine.fingerprint))
        assert(preview("Breathe slowly.\nStay present.", remembered: history).newEntries.isEmpty)
        let changed = preview("A new beginning.\nBreathe slowly.\nMiddle addition.\nStay present.\nA new ending.", remembered: history)
        assert(changed.newEntries == ["A new beginning.", "Middle addition.", "A new ending."])
        assert(changed.lastKnownPosition == 4)
        assert(preview("  STAY   present. ", existing: ["Stay present."]).newEntries.isEmpty)
        assert(preview("“It’s okay.”", existing: ["It's okay."]).newEntries.isEmpty)
        assert(preview("# Heading\n![secret alt](photo.png)\n<img src='photo.jpg'>\nphoto.heic\n\u{FFFC}\nText only.").newEntries == ["Text only."])
        assert(preview("![alt][image]\n[image]: image.png\nText only.").newEntries == ["Text only."])
        assert(preview("First line\ncontinues here.\n\nSecond paragraph.", grouping: .paragraphs).newEntries == ["First line\ncontinues here.", "Second paragraph."])
        assert(preview("- [x] Completed item\n1. Numbered item\n**Bold text**").newEntries == ["Completed item", "Numbered item", "Bold text"])
        // A deleted imported quote stays remembered; a genuinely edited entry remains discoverable.
        assert(preview("Breathe slowly.\nBreathe deeply.", remembered: history).newEntries == ["Breathe deeply."])
        assert(preview("").newEntries.isEmpty)
        assert(preview("![a](a.png)Keep this text![b](b.png)").newEntries == ["Keep this text"])
        assert(preview("\u{FEFF}# Heading\n#gratitude matters").newEntries == ["#gratitude matters"])
        assert(preview("Go!", existing: ["Go?"]).newEntries == ["Go!"])
        print("Notes import regression checks passed")
    }
}
