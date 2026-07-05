import SwiftUI
import WatchKit

struct ContentView: View {
    @StateObject private var viewModel = QuoteViewModel()
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                viewModel.quote.colors.background
                    .opacity(0.26)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        QuoteCardView(
                            quote: viewModel.quote,
                            showAuthor: viewModel.settings.showAuthor
                        )
                        .id(viewModel.quote.id)
                        .transition(.scale(scale: 0.96).combined(with: .opacity))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 8)
                }
                .gesture(
                    DragGesture(minimumDistance: 18)
                        .onEnded { value in
                            guard value.translation.width > 35,
                                  abs(value.translation.width) > abs(value.translation.height)
                            else { return }

                            WKInterfaceDevice.current().play(.click)
                            viewModel.newQuote()
                        }
                )
                .accessibilityAction(named: "New Quote") {
                    viewModel.newQuote()
                }
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
            }
        }
    }
}

#Preview {
    ContentView()
}
