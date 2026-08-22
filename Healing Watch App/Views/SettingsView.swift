import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: QuoteViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section("Pulses") {
                Picker("Frequency", selection: frequencyBinding) {
                    ForEach(NotificationFrequency.allCases) { frequency in
                        Text(frequency.title).tag(frequency)
                    }
                }

                Toggle("Enabled", isOn: notificationsEnabledBinding)

                Button {
                    Task { await viewModel.scheduleNotifications() }
                } label: {
                    if viewModel.isSchedulingNotifications {
                        ProgressView()
                            .controlSize(.small)
                        Text("Scheduling…")
                    } else {
                        Label("Schedule Pulses", systemImage: "bell.badge")
                    }
                }
                .disabled(viewModel.isSchedulingNotifications)

                Button("Clear Scheduled Notifications", role: .destructive) {
                    viewModel.clearNotifications()
                }
            }

            Section("Quotes") {
                Toggle("Randomise on Launch", isOn: randomiseOnLaunchBinding)
                Toggle("Show Author", isOn: showAuthorBinding)

                Button("Reset Favourites", role: .destructive) {
                    viewModel.settings.resetFavourites()
                }
            }

            if let message = viewModel.notificationMessage {
                Section {
                    Label(
                        message,
                        systemImage: message.contains("Unable") || message.contains("disabled")
                            ? "exclamationmark.triangle"
                            : "checkmark.circle"
                    )
                        .font(.footnote)
                        .foregroundStyle(message.contains("Unable") || message.contains("disabled") ? .orange : .green)
                }
            }
        }
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    private var frequencyBinding: Binding<NotificationFrequency> {
        Binding(
            get: { viewModel.settings.notificationFrequency },
            set: { frequency in
                viewModel.settings.notificationFrequency = frequency
                viewModel.notificationMessage = frequency.isEnabled ? "Updating pulse schedule…" : "Pulses disabled."
                rescheduleNotificationsIfNeeded()
            }
        )
    }

    private var notificationsEnabledBinding: Binding<Bool> {
        Binding(
            get: { viewModel.settings.notificationsEnabled },
            set: { isEnabled in
                viewModel.settings.notificationsEnabled = isEnabled
                if isEnabled, viewModel.settings.notificationFrequency == .disabled {
                    viewModel.settings.notificationFrequency = .everyHour
                }

                if isEnabled {
                    Task { await viewModel.scheduleNotifications() }
                } else {
                    viewModel.settings.notificationFrequency = .disabled
                    viewModel.clearNotifications()
                }
            }
        )
    }

    private var randomiseOnLaunchBinding: Binding<Bool> {
        Binding(
            get: { viewModel.settings.randomiseOnLaunch },
            set: { viewModel.settings.randomiseOnLaunch = $0 }
        )
    }

    private var showAuthorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.settings.showAuthor },
            set: {
                viewModel.settings.showAuthor = $0
                viewModel.settingsDidChange()
            }
        )
    }

    private func rescheduleNotificationsIfNeeded() {
        if viewModel.settings.notificationFrequency.isEnabled {
            Task { await viewModel.scheduleNotifications() }
        } else {
            viewModel.clearNotifications()
        }
    }
}
