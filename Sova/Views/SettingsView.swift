import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var items: [MaintenanceItem]
    @AppStorage("sovaAppearance") private var appearance: String = SovaAppearance.system.rawValue
    @AppStorage("swipeToDeleteEnabled") private var swipeToDeleteEnabled: Bool = true
    @AppStorage("hiddenCategories") private var hiddenCategoriesRaw: String = ""
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = true

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

                    Toggle(isOn: $notificationsEnabled) {
                        Label("Notifications", systemImage: "bell.badge")
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
                } header: {
                    Text("Theme")
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
