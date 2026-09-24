import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = QuoteLibraryViewModel()
    @State private var isShowingNotesImport = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        isShowingNotesImport = true
                    } label: {
                        Label("Import Notes", systemImage: "square.and.arrow.down")
                    }
                }
                ForEach(viewModel.practiceSections, id: \.title) { section in
                    Section(section.title) {
                        ForEach(section.quotes) { quote in
                            Button {
                                viewModel.edit(quote)
                            } label: {
                                QuoteRow(quote: quote)
                            }
                            .buttonStyle(.plain)
                            .swipeActions {
                                Button(role: .destructive) {
                                    viewModel.delete(quote)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .onDelete { offsets in
                            viewModel.delete(quotes: section.quotes, at: offsets)
                        }
                    }
                }

                Section {
                    Text(viewModel.syncStatus)
                }
            }
            .navigationTitle("Healing")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            viewModel.restoreBundledQuotes()
                        } label: {
                            Label("Restore Bundled Quotes", systemImage: "arrow.counterclockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("More")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.addQuote()
                    } label: {
                        Label("Add Quote", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.isShowingEditor) {
                if let quote = viewModel.selectedQuote {
                    QuoteEditorView(
                        quote: quote,
                        themes: viewModel.themes,
                        authors: viewModel.authors,
                        practices: viewModel.practices,
                        backgroundColors: viewModel.backgroundColors,
                        foregroundColors: viewModel.foregroundColors,
                        accentColors: viewModel.accentColors
                    ) { updatedQuote in
                        viewModel.save(updatedQuote)
                    }
                }
            }
            .sheet(isPresented: $isShowingNotesImport) {
                NotesImportView(library: viewModel)
            }
        }
    }
}

private struct QuoteRow: View {
    let quote: Quote

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(quote.colors.background)
                .overlay {
                    Circle()
                        .fill(quote.colors.accent)
                        .padding(10)
                }
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(quote.text.isEmpty ? "New quote" : quote.text)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text("\(quote.theme) - \(quote.displayAuthor)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

#Preview {
    ContentView()
}
