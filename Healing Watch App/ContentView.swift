import SwiftUI
import WatchKit

struct ContentView: View {
    @StateObject private var viewModel = QuoteViewModel()
    @State private var showingSettings = false
    @State private var crownDetent = 0
    @State private var hasPendingCrownAdvance = false
    @FocusState private var isQuoteFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                viewModel.quote.colors.background
                    .opacity(0.26)
                    .ignoresSafeArea()

                QuoteCardView(
                    quote: viewModel.quote,
                    showAuthor: viewModel.settings.showAuthor
                )
                .id(viewModel.quote)
                .transition(.scale(scale: 0.96).combined(with: .opacity))
                .padding(.horizontal, 6)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
                .onTapGesture {
                    advanceQuote()
                }
                .gesture(
                    DragGesture(minimumDistance: 18)
                        .onEnded { value in
                            guard value.translation.width > 35,
                                  abs(value.translation.width) > abs(value.translation.height)
                            else { return }

                            advanceQuote()
                        }
                )
                .accessibilityAction(named: "New Quote") {
                    advanceQuote()
                }
            }
            .focusable(true, interactions: .edit)
            .focused($isQuoteFocused)
            .digitalCrownRotation(
                detent: $crownDetent,
                from: -10_000,
                through: 10_000,
                by: 1,
                sensitivity: .medium,
                isContinuous: false,
                isHapticFeedbackEnabled: true
            ) { _ in
                hasPendingCrownAdvance = true
            } onIdle: {
                advanceQuoteFromCrownIfNeeded()
            }
            .navigationTitle("Healing")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    SettingsView(viewModel: viewModel)
                }
            }
            .task {
                await viewModel.prepareForLaunch()
                isQuoteFocused = true
            }
            .onChange(of: showingSettings) { _, isShowing in
                if isShowing == false {
                    isQuoteFocused = true
                }
            }
        }
    }

    private func advanceQuoteFromCrownIfNeeded() {
        guard hasPendingCrownAdvance else { return }

        hasPendingCrownAdvance = false
        crownDetent = 0
        advanceQuote()
    }

    private func advanceQuote() {
        WKInterfaceDevice.current().play(.click)
        viewModel.newQuote()
    }
}

#Preview {
    ContentView()
}
