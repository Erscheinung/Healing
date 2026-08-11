import SwiftUI
import UIKit

struct QuoteEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var text: String
    @State private var author: String
    @State private var practice: String
    @State private var theme: String
    @State private var backgroundColor: String
    @State private var foregroundColor: String
    @State private var accentColor: String

    let quote: Quote
    let themes: [String]
    let authors: [String]
    let practices: [String]
    let backgroundColors: [String]
    let foregroundColors: [String]
    let accentColors: [String]
    let onSave: (Quote) -> Void

    init(
        quote: Quote,
        themes: [String],
        authors: [String],
        practices: [String],
        backgroundColors: [String],
        foregroundColors: [String],
        accentColors: [String],
        onSave: @escaping (Quote) -> Void
    ) {
        self.quote = quote
        self.themes = themes
        self.authors = authors
        self.practices = practices
        self.backgroundColors = backgroundColors
        self.foregroundColors = foregroundColors
        self.accentColors = accentColors
        self.onSave = onSave

        _text = State(initialValue: quote.text)
        _author = State(initialValue: quote.author ?? "")
        _practice = State(initialValue: quote.practice ?? "")
        _theme = State(initialValue: quote.theme)
        _backgroundColor = State(initialValue: quote.backgroundColor)
        _foregroundColor = State(initialValue: quote.foregroundColor)
        _accentColor = State(initialValue: quote.accentColor)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Quote") {
                    TextField("Quote", text: $text, axis: .vertical)
                        .lineLimit(3...8)

                    TextField("Author", text: $author)
                        .textInputAutocapitalization(.words)

                    ExistingValuePicker(title: "Author", values: authors, selection: $author)
                }

                Section("Theme") {
                    TextField("Practice", text: $practice)
                        .textInputAutocapitalization(.words)

                    ExistingValuePicker(title: "Practice", values: practices, selection: $practice)

                    TextField("Theme", text: $theme)
                        .textInputAutocapitalization(.words)

                    ExistingValuePicker(title: "Theme", values: themes, selection: $theme)
                }

                Section("Colors") {
                    ColorChoiceRow(title: "Background", values: backgroundColors, selection: $backgroundColor)
                    ColorChoiceRow(title: "Text", values: foregroundColors, selection: $foregroundColor)
                    ColorChoiceRow(title: "Accent", values: accentColors, selection: $accentColor)
                }

                Section("Preview") {
                    QuotePreview(
                        quote: updatedQuote,
                        backgroundColor: backgroundColor,
                        foregroundColor: foregroundColor,
                        accentColor: accentColor
                    )
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                }
            }
            .navigationTitle(quote.text.isEmpty ? "New Quote" : "Edit Quote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave(updatedQuote)
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var updatedQuote: Quote {
        Quote(
            id: quote.id,
            text: text.trimmingCharacters(in: .whitespacesAndNewlines),
            author: author.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            practice: practice.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            theme: theme.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "Custom",
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            accentColor: accentColor
        )
    }
}

private struct ExistingValuePicker: View {
    let title: String
    let values: [String]
    @Binding var selection: String

    var body: some View {
        Picker("Use Existing \(title)", selection: $selection) {
            ForEach(values, id: \.self) { value in
                Text(value).tag(value)
            }
        }
        .disabled(values.isEmpty)
    }
}

private struct ColorChoiceRow: View {
    let title: String
    let values: [String]
    @Binding var selection: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ColorPicker(title, selection: colorBinding, supportsOpacity: false)

            if values.isEmpty == false {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(values, id: \.self) { value in
                            Button {
                                selection = value
                            } label: {
                                Circle()
                                    .fill(Color(hex: value, fallback: .gray))
                                    .frame(width: 30, height: 30)
                                    .overlay {
                                        if selection.caseInsensitiveCompare(value) == .orderedSame {
                                            Image(systemName: "checkmark")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(.white)
                                                .shadow(radius: 2)
                                        }
                                    }
                            }
                            .accessibilityLabel(value)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var colorBinding: Binding<Color> {
        Binding {
            Color(hex: selection, fallback: .gray)
        } set: { newValue in
            selection = newValue.hexString ?? selection
        }
    }
}

private struct QuotePreview: View {
    let quote: Quote
    let backgroundColor: String
    let foregroundColor: String
    let accentColor: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(quote.text.isEmpty ? "Your quote appears here." : quote.text)
                .font(.headline)
                .foregroundStyle(Color(hex: foregroundColor, fallback: .primary))
                .lineLimit(4)

            Text(quote.displayAuthor)
                .font(.subheadline)
                .foregroundStyle(Color(hex: foregroundColor, fallback: .primary).opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hex: backgroundColor, fallback: .secondary.opacity(0.16)))
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(Color(hex: accentColor, fallback: .accentColor))
                        .frame(width: 18, height: 18)
                        .padding(14)
                }
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

private extension Color {
    var hexString: String? {
        let color = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }

        return String(
            format: "#%02X%02X%02X",
            Int(red * 255),
            Int(green * 255),
            Int(blue * 255)
        )
    }
}
