import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var items: [MaintenanceItem]
    @AppStorage("sovaAppearance") private var appearance: String = SovaAppearance.system.rawValue
    @AppStorage("swipeToDeleteEnabled") private var swipeToDeleteEnabled: Bool = true
    @AppStorage("hiddenCategories") private var hiddenCategoriesRaw: String = ""
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("usesMetricUnits") private var usesMetricUnits: Bool = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(isOn: $swipeToDeleteEnabled) {
                        Label("Swipe to delete", systemImage: "hand.draw")
                            .font(SovaFont.body(.body))
                            .foregroundStyle(.sovaPrimaryText)
                    }

                    NavigationLink {
                        CategoryVisibilityView(hiddenCategoriesRaw: $hiddenCategoriesRaw)
                    } label: {
                        Label("Categories", systemImage: "square.grid.2x2")
                            .font(SovaFont.body(.body))
                            .foregroundStyle(.sovaPrimaryText)
                    }

                    NavigationLink {
                        NotificationSettingsView(items: items)
                    } label: {
                        HStack {
                            Label("Notifications", systemImage: "bell.badge")
                                .font(SovaFont.body(.body))
                                .foregroundStyle(.sovaPrimaryText)
                            Spacer()
                            Text(notificationsEnabled ? "On" : "Off")
                                .font(SovaFont.mono(.caption))
                                .foregroundStyle(.sovaSecondaryText)
                        }
                    }

                    NavigationLink {
                        AccessibilitySettingsView()
                    } label: {
                        Label("Accessibility", systemImage: "accessibility")
                            .font(SovaFont.body(.body))
                            .foregroundStyle(.sovaPrimaryText)
                    }

                } header: {
                    Text("General")
                        .font(SovaFont.mono(.caption2))
                }

                Section {
                    Picker(selection: $appearance) {
                        ForEach(SovaAppearance.allCases) { option in
                            Text(option.rawValue).tag(option.rawValue)
                        }
                    } label: {
                        Label("Appearance", systemImage: "circle.lefthalf.filled")
                            .font(SovaFont.body(.body))
                            .foregroundStyle(.sovaPrimaryText)
                    }

                    Picker(selection: $usesMetricUnits) {
                        Text("Imperial (mi)").tag(false)
                        Text("Metric (km)").tag(true)
                    } label: {
                        Label("Units", systemImage: "ruler")
                            .font(SovaFont.body(.body))
                            .foregroundStyle(.sovaPrimaryText)
                    }
                } header: {
                    Text("Display")
                        .font(SovaFont.mono(.caption2))
                }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("Sova")
                                .font(SovaFont.title(.title2))
                                .foregroundStyle(.sovaPrimaryText)
                            Spacer()
                            Text("v\(appVersion) (\(buildNumber))")
                                .font(SovaFont.mono(.caption))
                                .foregroundStyle(.sovaSecondaryText)
                        }

                        Text("Track the things you own. Cars, appliances, electronics, receipts, and everything in between. Keep maintenance history, photos, and upcoming service dates all in one place.")
                            .font(SovaFont.body(.subheadline))
                            .foregroundStyle(.sovaSecondaryText)
                    }
                    .padding(.vertical, 4)

                    Link(destination: URL(string: "https://getsova.app")!) {
                        HStack {
                            Label("Visit getsova.app", systemImage: "globe")
                                .font(SovaFont.body(.body))
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.sovaSecondaryText)
                        }
                    }
                } header: {
                    Text("About")
                        .font(SovaFont.mono(.caption2))
                }
            }
            .scrollContentBackground(.hidden)
            .background(.sovaBackground)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Notification Settings

private struct NotificationSettingsView: View {
    let items: [MaintenanceItem]
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true
    @AppStorage("notificationAdvanceDays") private var advanceDays: Int = 7
    @AppStorage("notificationHour") private var notificationHour: Int = 9

    private let advanceDayOptions = [1, 2, 3, 5, 7, 14]
    private let hourRange = 6...21

    private func hourLabel(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        let date = Calendar.current.date(from: components) ?? .now
        return formatter.string(from: date)
    }

    var body: some View {
        List {
            Section {
                Toggle(isOn: $notificationsEnabled) {
                    Label("Enable notifications", systemImage: "bell.badge")
                        .font(SovaFont.body(.body))
                        .foregroundStyle(.sovaPrimaryText)
                }
                .onChange(of: notificationsEnabled) { _, enabled in
                    if enabled {
                        NotificationManager.scheduleAllReminders(items: items)
                    } else {
                        NotificationManager.cancelAll()
                    }
                }
            } header: {
                Text("Notifications")
                    .font(SovaFont.mono(.caption2))
            }

            if notificationsEnabled {
                Section {
                    Button {
                        sendTestNotifications()
                    } label: {
                        Label("Send test notification", systemImage: "bell.and.waves.left.and.right")
                            .font(SovaFont.body(.body))
                            .foregroundStyle(.sovaPrimaryAccent)
                    }
                } header: {
                    Text("Test")
                        .font(SovaFont.mono(.caption2))
                } footer: {
                    Text("Sends two notifications: \"coming due\" in 5 seconds and \"due today\" in 10 seconds. Lock or background the app to see them.")
                        .font(SovaFont.mono(.caption2))
                }

                Section {
                    Picker(selection: $advanceDays) {
                        ForEach(advanceDayOptions, id: \.self) { days in
                            Text("\(days) day\(days == 1 ? "" : "s") before")
                                .tag(days)
                        }
                    } label: {
                        Label("Advance notice", systemImage: "calendar.badge.clock")
                            .font(SovaFont.body(.body))
                            .foregroundStyle(.sovaPrimaryText)
                    }

                    Picker(selection: $notificationHour) {
                        ForEach(Array(hourRange), id: \.self) { hour in
                            Text(hourLabel(hour)).tag(hour)
                        }
                    } label: {
                        Label("Time of day", systemImage: "clock")
                            .font(SovaFont.body(.body))
                            .foregroundStyle(.sovaPrimaryText)
                    }
                } header: {
                    Text("Timing")
                        .font(SovaFont.mono(.caption2))
                } footer: {
                    Text("You'll receive a reminder \(advanceDays) day\(advanceDays == 1 ? "" : "s") before each service is due, and again on the due date. Both notifications arrive at \(hourLabel(notificationHour)).")
                        .font(SovaFont.mono(.caption2))
                }
                .onChange(of: advanceDays) { _, _ in
                    NotificationManager.scheduleAllReminders(items: items)
                }
                .onChange(of: notificationHour) { _, _ in
                    NotificationManager.scheduleAllReminders(items: items)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(.sovaBackground)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sendTestNotifications() {
        let center = UNUserNotificationCenter.current()

        // "Coming due" — fires in 5 seconds
        let advanceContent = UNMutableNotificationContent()
        advanceContent.title = "2022 Subaru Outback"
        advanceContent.body = "Oil Change is due in \(advanceDays) day\(advanceDays == 1 ? "" : "s")"
        advanceContent.sound = .default
        let advanceTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        center.add(UNNotificationRequest(identifier: "sova-test-advance", content: advanceContent, trigger: advanceTrigger))

        // "Due today" — fires in 10 seconds
        let dueContent = UNMutableNotificationContent()
        dueContent.title = "2022 Subaru Outback"
        dueContent.body = "Oil Change is due today"
        dueContent.sound = .default
        let dueTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        center.add(UNNotificationRequest(identifier: "sova-test-due", content: dueContent, trigger: dueTrigger))
    }
}

// MARK: - Accessibility Settings

private struct AccessibilitySettingsView: View {
    @AppStorage("useSystemFonts") private var useSystemFonts: Bool = false
    @AppStorage("highContrastEnabled") private var highContrastEnabled: Bool = false
    @AppStorage("reduceMotionEnabled") private var reduceMotionEnabled: Bool = false

    var body: some View {
        List {
            Section {
                Toggle(isOn: $useSystemFonts) {
                    Label("Use system fonts", systemImage: "textformat.size")
                        .font(SovaFont.body(.body))
                        .foregroundStyle(.sovaPrimaryText)
                }
            } header: {
                Text("Fonts")
                    .font(SovaFont.mono(.caption2))
            } footer: {
                Text("Replaces custom fonts with the system font for improved readability at all sizes.")
                    .font(SovaFont.mono(.caption2))
            }

            Section {
                Toggle(isOn: $highContrastEnabled) {
                    Label("High contrast", systemImage: "circle.lefthalf.striped.horizontal")
                        .font(SovaFont.body(.body))
                        .foregroundStyle(.sovaPrimaryText)
                }
            } header: {
                Text("Display")
                    .font(SovaFont.mono(.caption2))
            } footer: {
                Text("Increases contrast between text and backgrounds for better visibility.")
                    .font(SovaFont.mono(.caption2))
            }

            Section {
                Toggle(isOn: $reduceMotionEnabled) {
                    Label("Reduce motion", systemImage: "hand.raised")
                        .font(SovaFont.body(.body))
                        .foregroundStyle(.sovaPrimaryText)
                }
            } header: {
                Text("Motion")
                    .font(SovaFont.mono(.caption2))
            } footer: {
                Text("Removes animations throughout the app for a calmer experience.")
                    .font(SovaFont.mono(.caption2))
            }
        }
        .scrollContentBackground(.hidden)
        .background(.sovaBackground)
        .navigationTitle("Accessibility")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Category Visibility

private struct CategoryVisibilityView: View {
    @Binding var hiddenCategoriesRaw: String

    private var hiddenSet: Set<String> {
        Set(hiddenCategoriesRaw.split(separator: ",").map(String.init))
    }

    private func isCategoryVisible(_ category: SovaCategory) -> Bool {
        !hiddenSet.contains(category.rawValue)
    }

    private func toggleCategory(_ category: SovaCategory) {
        var set = hiddenSet
        if set.contains(category.rawValue) {
            set.remove(category.rawValue)
        } else {
            set.insert(category.rawValue)
        }
        hiddenCategoriesRaw = set.sorted().joined(separator: ",")
    }

    var body: some View {
        List {
            Section {
                ForEach(SovaCategory.allCases) { category in
                    Button {
                        toggleCategory(category)
                    } label: {
                        HStack(spacing: 12) {
                            Label(category.rawValue, systemImage: category.symbolName)
                                .font(SovaFont.body(.body))
                                .foregroundStyle(.sovaPrimaryText)
                            Spacer()
                            Image(systemName: isCategoryVisible(category) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(isCategoryVisible(category) ? .sovaPrimaryAccent : .sovaSecondaryText)
                                .font(.title3)
                        }
                    }
                }
            } footer: {
                Text("Hidden categories won't appear in the browse menu or inventory.")
                    .font(SovaFont.mono(.caption2))
            }
        }
        .scrollContentBackground(.hidden)
        .background(.sovaBackground)
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.inline)
    }
}
