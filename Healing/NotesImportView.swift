import SwiftUI
import UniformTypeIdentifiers

struct NotesImportView: View {
    @ObservedObject var library: QuoteLibraryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var source = "Practice for Musku"
    @State private var text = ""
    @State private var noteLink = ""
    @State private var grouping: NotesImportEngine.Grouping = .paragraphs
    @State private var preview: NotesImportEngine.Preview?
    @State private var selectedItemIDs = Set<Int>()
    @State private var showingFilePicker = false
    @State private var message: String?

    private let sources = ["Practice for Musku", "Practice for Yourself"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        findNewQuotes()
                    } label: {
                        Label("Find New Quotes", systemImage: "sparkles.magnifyingglass")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Text("Paste or choose a note below, then find quotes. The preview starts with the newest entries from the bottom of the note.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
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
                    Text("Images are ignored. Paragraphs keeps wrapped quotes together and is the best choice for pasted note text. Use Each line for a list of one-line quotes.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                if let preview {
                    Section("Import preview") {
                        Text("\(selectedItemIDs.count) selected · \(preview.newEntries.count) new · \(preview.duplicateCount) already known or repeated")
                            .font(.subheadline.weight(.medium))
                        if let position = preview.lastKnownPosition {
                            Text("Last known match: entry \(position) of \(preview.entries.count). The entire note was checked, including earlier additions.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                        HStack {
                            Button("Select All New") {
                                selectedItemIDs = Set(preview.newItems.map(\.id))
                            }
                            .disabled(preview.newItems.isEmpty || selectedItemIDs.count == preview.newItems.count)
                            Spacer()
                            Button("Clear Selection") {
                                selectedItemIDs.removeAll()
                            }
                            .disabled(selectedItemIDs.isEmpty)
                        }

                        ForEach(preview.displayItems) { item in
                            Button {
                                toggleSelection(for: item)
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: selectionIcon(for: item))
                                        .foregroundStyle(selectionColor(for: item))
                                        .font(.title3)
                                        .accessibilityHidden(true)
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(item.text)
                                            .foregroundStyle(.primary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        Text(statusText(for: item))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(item.isNew == false)
                        }
                        Button("Import \(selectedItemIDs.count) Selected Quotes") {
                            let fingerprints = Set(preview.items.filter { selectedItemIDs.contains($0.id) && $0.isNew }
                                .map(\.fingerprint))
                            let count = library.importNotes(text: text, source: source, grouping: grouping,
                                                            selectedFingerprints: fingerprints)
                            self.preview = nil
                            selectedItemIDs.removeAll()
                            text = ""
                            message = "Imported \(count) new quotes. \(library.syncStatus)"
                        }
                        .disabled(selectedItemIDs.isEmpty)
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
                selectedItemIDs.removeAll()
                message = nil
                loadLink()
            }
            .onChange(of: noteLink) { _, value in
                UserDefaults.standard.set(value, forKey: linkKey)
            }
            .onChange(of: text) { _, _ in
                preview = nil
                selectedItemIDs.removeAll()
            }
            .onChange(of: grouping) { _, _ in
                preview = nil
                selectedItemIDs.removeAll()
            }
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

    private func findNewQuotes() {
        preview = library.notesPreview(text: text, source: source, grouping: grouping)
        selectedItemIDs = Set(preview?.newItems.map(\.id) ?? [])
        message = nil
    }

    private func toggleSelection(for item: NotesImportEngine.Preview.Item) {
        guard item.isNew else { return }
        if selectedItemIDs.contains(item.id) {
            selectedItemIDs.remove(item.id)
        } else {
            selectedItemIDs.insert(item.id)
        }
    }

    private func selectionIcon(for item: NotesImportEngine.Preview.Item) -> String {
        switch item.state {
        case .new:
            return selectedItemIDs.contains(item.id) ? "checkmark.circle.fill" : "circle"
        case .alreadyKnown:
            return "checkmark.circle"
        case .repeated:
            return "arrow.triangle.2.circlepath"
        }
    }

    private func selectionColor(for item: NotesImportEngine.Preview.Item) -> Color {
        switch item.state {
        case .new:
            return selectedItemIDs.contains(item.id) ? .accentColor : .secondary
        case .alreadyKnown, .repeated:
            return .secondary
        }
    }

    private func statusText(for item: NotesImportEngine.Preview.Item) -> String {
        switch item.state {
        case .new:
            return selectedItemIDs.contains(item.id) ? "Selected for import" : "New quote"
        case .alreadyKnown:
            return "Already saved"
        case .repeated:
            return "Repeated in pasted note"
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
