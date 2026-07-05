import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = QuoteLibraryViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(viewModel.quotes) { quote in
                        Button {
                            viewModel.edit(quote)
                        } label: {
                            QuoteRow(quote: quote)
                        }
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button(role: .destructive) {
                                if let index = viewModel.quotes.firstIndex(of: quote) {
                                    viewModel.delete(at: IndexSet(integer: index))
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete(perform: viewModel.delete)
                } header: {
                    Text("Quotes")
                } footer: {
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
                        backgroundColors: viewModel.backgroundColors,
                        foregroundColors: viewModel.foregroundColors,
                        accentColors: viewModel.accentColors
                    ) { updatedQuote in
                        viewModel.save(updatedQuote)
                    }
                }
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
