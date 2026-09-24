import SwiftUI
import UniformTypeIdentifiers

struct NotesImportView: View {
    @ObservedObject var library: QuoteLibraryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var source = "Practice for Musku"
    @State private var text = ""
    @State private var noteLink = ""
    @State private var grouping: NotesImportEngine.Grouping = .lines
    @State private var preview: NotesImportEngine.Preview?
    @State private var showingFilePicker = false
    @State private var message: String?

    private let sources = ["Practice for Musku", "Practice for Yourself"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Source note") {
                    Picker("Practice", selection: $source) {
                        ForEach(sources, id: \.self) { Text($0) }
                    }
                    TextField("Private iCloud note link", text: $noteLink)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    if let url = validNoteURL {
                        Link("Open Source Note", destination: url)
                    }
                    Text("Open the note and copy its text, or export it as Markdown to Files. Return here to import. Apple Notes does not allow Healing to fetch notes automatically.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Note text") {
                    PasteButton(payloadType: String.self) { values in
                        text = values.joined(separator: "\n")
                    }
                    Button("Choose Text or Markdown File") { showingFilePicker = true }
                    TextEditor(text: $text)
                        .frame(minHeight: 180)
                        .accessibilityLabel("Text copied from the note")
                    Picker("One quote per", selection: $grouping) {
                        ForEach(NotesImportEngine.Grouping.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Text("Images are ignored. Use Each line for lists, or Paragraphs for text separated by blank lines. Review the preview before importing.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Button("Find New Quotes") {
                        preview = library.notesPreview(text: text, source: source, grouping: grouping)
                        message = nil
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                if let preview {
                    Section("Import preview") {
                        Text("\(preview.newEntries.count) new · \(preview.duplicateCount) already known or repeated")
                        if let position = preview.lastKnownPosition {
                            Text("Last known match: entry \(position) of \(preview.entries.count). The entire note was checked, including earlier additions.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                        ForEach(Array(preview.newEntries.enumerated()), id: \.offset) { _, entry in
                            Text(entry)
                        }
                        Button("Import \(preview.newEntries.count) New Quotes") {
                            let count = library.importNotes(text: text, source: source, grouping: grouping)
                            self.preview = nil
                            text = ""
                            message = "Imported \(count) new quotes. \(library.syncStatus)"
                        }
                        .disabled(preview.newEntries.isEmpty)
                    }
                }
                if let message {
                    Section { Text(message) }
                }
            }
            .navigationTitle("Import Notes")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .onAppear { loadLink() }
            .onChange(of: source) { _, _ in
                text = ""
                preview = nil
                message = nil
                loadLink()
            }
            .onChange(of: noteLink) { _, value in
                UserDefaults.standard.set(value, forKey: linkKey)
            }
            .onChange(of: text) { _, _ in preview = nil }
            .onChange(of: grouping) { _, _ in preview = nil }
            .fileImporter(isPresented: $showingFilePicker,
                          allowedContentTypes: [.plainText, UTType(filenameExtension: "md") ?? .plainText]) { result in
                do {
                    let url = try result.get()
                    let scoped = url.startAccessingSecurityScopedResource()
                    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                    let data = try Data(contentsOf: url, options: .mappedIfSafe)
                    guard data.count <= 2_000_000, let contents = String(data: data, encoding: .utf8) else {
                        message = "Choose a UTF-8 text or Markdown file smaller than 2 MB."
                        return
                    }
                    text = contents
                    message = nil
                } catch {
                    message = "Could not read the file. Please choose it again."
                }
            }
        }
    }

    private var linkKey: String { "healing.notes.link.\(source)" }

    private var validNoteURL: URL? {
        guard let url = URL(string: noteLink.trimmingCharacters(in: .whitespacesAndNewlines)),
              url.scheme == "https", ["icloud.com", "www.icloud.com"].contains(url.host ?? ""),
              url.path.hasPrefix("/notes/"), url.user == nil, url.password == nil else { return nil }
        return url
    }

    private func loadLink() {
        if let saved = UserDefaults.standard.string(forKey: linkKey) {
            noteLink = saved
        } else if let url = Bundle.main.url(forResource: "NotesSources.private", withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let links = try? JSONDecoder().decode([String: String].self, from: data) {
            noteLink = links[source] ?? ""
        } else {
            noteLink = ""
        }
    }
}
