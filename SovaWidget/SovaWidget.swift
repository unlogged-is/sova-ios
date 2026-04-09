import AppIntents
import CoreText
import Foundation
import SwiftUI
import WidgetKit

private let _registerFont: Void = {
    // Widget extensions are at App.app/PlugIns/Widget.appex
    // Navigate up to the main app bundle to find the font
    let bundlePath = Bundle.main.bundlePath as NSString
    let plugInsDir = bundlePath.deletingLastPathComponent
    let appDir = (plugInsDir as NSString).deletingLastPathComponent
    let fontPath = (appDir as NSString).appendingPathComponent("CormorantGaramond-Italic-Variable.ttf")
    let url = URL(fileURLWithPath: fontPath)
    if FileManager.default.fileExists(atPath: fontPath) {
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
}()

// MARK: - Widget Appearance Intent

enum WidgetAppearance: String, CaseIterable, AppEnum {
    case system = "system"
    case light = "light"
    case dark = "dark"

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Appearance"
    }

    static var caseDisplayRepresentations: [WidgetAppearance: DisplayRepresentation] {
        [
            .system: "System",
            .light: "Light",
            .dark: "Dark"
        ]
    }
}

struct SovaWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Sova Widget"
    static var description: IntentDescription = "Configure the appearance of your Sova widget."

    @Parameter(title: "Appearance", default: .system)
    var appearance: WidgetAppearance
}

// MARK: - Shared snapshot types (must match the main app's SovaWidgetStore encoding)

nonisolated struct SovaWidgetItem: Codable, Sendable {
    let title: String
    let category: String
    let categorySymbol: String
    let dueText: String
    let isOverdue: Bool
}

nonisolated struct SovaWidgetSnapshot: Codable, Sendable {
    let dueCount: Int
    let overdueCount: Int
    let dueSoonCount: Int
    let nextTitle: String
    let nextCategory: String
    let nextDueText: String
    let items: [SovaWidgetItem]
    let updatedAt: Date

    static let empty: SovaWidgetSnapshot = .init(
        dueCount: 0,
        overdueCount: 0,
        dueSoonCount: 0,
        nextTitle: "All set",
        nextCategory: "Sova",
        nextDueText: "Nothing due soon",
        items: [],
        updatedAt: .now
    )
}

// MARK: - Store reader (reads from the shared app group)

nonisolated enum SovaWidgetStoreReader {
    static let appGroupID: String = "group.app.unlogged.sova.shared"
    private static let snapshotKey: String = "sova_widget_snapshot"

    static func load() -> SovaWidgetSnapshot {
        let defaults: UserDefaults? = UserDefaults(suiteName: appGroupID)
        guard let data = defaults?.data(forKey: snapshotKey) else { return .empty }
        let decoder: JSONDecoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode(SovaWidgetSnapshot.self, from: data)) ?? .empty
    }
}

// MARK: - Timeline

nonisolated struct SovaWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: SovaWidgetSnapshot
    let appearance: WidgetAppearance
}

nonisolated struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SovaWidgetEntry {
        SovaWidgetEntry(date: .now, snapshot: .empty, appearance: .system)
    }

    func snapshot(for configuration: SovaWidgetIntent, in context: Context) async -> SovaWidgetEntry {
        SovaWidgetEntry(date: .now, snapshot: SovaWidgetStoreReader.load(), appearance: configuration.appearance)
    }

    func timeline(for configuration: SovaWidgetIntent, in context: Context) async -> Timeline<SovaWidgetEntry> {
        let entry = SovaWidgetEntry(date: .now, snapshot: SovaWidgetStoreReader.load(), appearance: configuration.appearance)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 4, to: .now) ?? .now
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
}

// MARK: - Color palette

private struct WidgetPalette {
    let background: Color
    let surface: Color
    let textPrimary: Color
    let textSecondary: Color
    let accentGreen: Color
    let accentWarm: Color
    let accentGold: Color
    let accentRed: Color

    static let light = WidgetPalette(
        background: Color(hex: 0xF5F0E8),
        surface: Color(hex: 0xEDE7DB),
        textPrimary: Color(hex: 0x1C1A17),
        textSecondary: Color(hex: 0x8C8478),
        accentGreen: Color(hex: 0x4A5C45),
        accentWarm: Color(hex: 0xA0735A),
        accentGold: Color(hex: 0xC8923A),
        accentRed: Color(hex: 0xBF4545)
    )

    static let dark = WidgetPalette(
        background: Color(hex: 0x211D19),
        surface: Color(hex: 0x2D2722),
        textPrimary: Color(hex: 0xF4EEE4),
        textSecondary: Color(hex: 0xB5AA9B),
        accentGreen: Color(hex: 0x7F9676),
        accentWarm: Color(hex: 0xC0937B),
        accentGold: Color(hex: 0xD6A64C),
        accentRed: Color(hex: 0xD46A6A)
    )

    /// Adaptive palette that responds to system appearance.
    static let system = WidgetPalette(
        background: Color(light: WidgetPalette.light.background, dark: WidgetPalette.dark.background),
        surface: Color(light: WidgetPalette.light.surface, dark: WidgetPalette.dark.surface),
        textPrimary: Color(light: WidgetPalette.light.textPrimary, dark: WidgetPalette.dark.textPrimary),
        textSecondary: Color(light: WidgetPalette.light.textSecondary, dark: WidgetPalette.dark.textSecondary),
        accentGreen: Color(light: WidgetPalette.light.accentGreen, dark: WidgetPalette.dark.accentGreen),
        accentWarm: Color(light: WidgetPalette.light.accentWarm, dark: WidgetPalette.dark.accentWarm),
        accentGold: Color(light: WidgetPalette.light.accentGold, dark: WidgetPalette.dark.accentGold),
        accentRed: Color(light: WidgetPalette.light.accentRed, dark: WidgetPalette.dark.accentRed)
    )

    static func palette(for appearance: WidgetAppearance) -> WidgetPalette {
        switch appearance {
        case .system: .system
        case .light: .light
        case .dark: .dark
        }
    }
}

// MARK: - Widget view

struct WidgetView: View {
    @Environment(\.widgetFamily) private var widgetFamily
    var entry: Provider.Entry

    private var palette: WidgetPalette {
        .palette(for: entry.appearance)
    }

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            smallView
        case .systemLarge:
            largeView
        default:
            mediumView
        }
    }

    // MARK: - Small

    private var sovaTitle: some View {
        let _ = _registerFont
        return Text("Sova")
            .font(.custom("CormorantGaramond-Italic", size: 28))
            .foregroundStyle(palette.accentGreen)
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            sovaTitle

            // Next upcoming item
            if let next = entry.snapshot.items.first {
                VStack(alignment: .leading, spacing: 3) {
                    Text(next.title)
                        .font(.system(.subheadline, design: .default, weight: .semibold))
                        .foregroundStyle(palette.textPrimary)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Image(systemName: next.categorySymbol)
                            .font(.caption2)
                        Text(next.dueText)
                            .font(.system(.caption2, design: .monospaced))
                    }
                    .foregroundStyle(next.isOverdue ? palette.accentRed : palette.accentGold)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(palette.surface, in: .rect(cornerRadius: 10))
            }

            Spacer(minLength: 0)

            // Counts
            HStack(spacing: 12) {
                if entry.snapshot.overdueCount > 0 {
                    HStack(spacing: 4) {
                        Text("\(entry.snapshot.overdueCount)")
                            .font(.system(.title3, design: .serif, weight: .bold))
                            .foregroundStyle(palette.accentRed)
                        Text("overdue")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(palette.textSecondary)
                    }
                }

                HStack(spacing: 4) {
                    Text("\(entry.snapshot.dueSoonCount)")
                        .font(.system(.title3, design: .serif, weight: .bold))
                        .foregroundStyle(palette.accentGold)
                    Text("due")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(palette.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(palette.background, for: .widget)
    }

    // MARK: - Medium

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            sovaTitle
                .padding(.bottom, 10)

            if entry.snapshot.items.isEmpty {
                Spacer()
                VStack(spacing: 4) {
                    Text("All set")
                        .font(.system(.headline, design: .serif, weight: .semibold))
                        .foregroundStyle(palette.textPrimary)
                    Text("Nothing due soon")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(palette.textSecondary)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                HStack(alignment: .top, spacing: 12) {
                    // Overdue column
                    if !overdueItems.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            sectionHeader(title: "Overdue", count: overdueItems.count, color: palette.accentRed)
                            ForEach(Array(overdueItems.prefix(2).enumerated()), id: \.offset) { _, item in
                                compactItemRow(item: item, accent: palette.accentRed)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Coming due column
                    if !dueSoonItems.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            sectionHeader(title: "Coming due", count: dueSoonItems.count, color: palette.accentGold)
                            ForEach(Array(dueSoonItems.prefix(2).enumerated()), id: \.offset) { _, item in
                                compactItemRow(item: item, accent: palette.accentGold)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Prevent a single section from stretching the full width
                    if overdueItems.isEmpty || dueSoonItems.isEmpty {
                        Spacer(minLength: 0)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(palette.background, for: .widget)
    }

    // MARK: - Large

    private var overdueItems: [SovaWidgetItem] {
        entry.snapshot.items.filter { $0.isOverdue }
    }

    private var dueSoonItems: [SovaWidgetItem] {
        entry.snapshot.items.filter { !$0.isOverdue }
    }

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .firstTextBaseline) {
                sovaTitle
                Spacer()
                if entry.snapshot.dueCount > 0 {
                    Text("\(entry.snapshot.dueCount) item\(entry.snapshot.dueCount == 1 ? "" : "s")")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(palette.textSecondary)
                }
            }
            .padding(.bottom, 14)

            if entry.snapshot.items.isEmpty {
                Spacer()
                VStack(spacing: 6) {
                    Text("All set")
                        .font(.system(.headline, design: .serif, weight: .semibold))
                        .foregroundStyle(palette.textPrimary)
                    Text("Nothing due soon")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(palette.textSecondary)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                // Overdue section
                if !overdueItems.isEmpty {
                    sectionHeader(
                        title: "Overdue",
                        count: overdueItems.count,
                        color: palette.accentRed
                    )
                    .padding(.bottom, 8)

                    ForEach(Array(overdueItems.prefix(3).enumerated()), id: \.offset) { _, item in
                        itemRow(item: item, accent: palette.accentRed)
                    }

                    if !dueSoonItems.isEmpty {
                        Spacer().frame(height: 14)
                    }
                }

                // Due soon section
                if !dueSoonItems.isEmpty {
                    sectionHeader(
                        title: "Due soon",
                        count: dueSoonItems.count,
                        color: palette.accentGold
                    )
                    .padding(.bottom, 8)

                    let maxDueSoon = overdueItems.isEmpty ? 5 : (overdueItems.count <= 2 ? 3 : 2)
                    ForEach(Array(dueSoonItems.prefix(maxDueSoon).enumerated()), id: \.offset) { _, item in
                        itemRow(item: item, accent: palette.accentGold)
                    }
                }

                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(palette.background, for: .widget)
    }

    private func sectionHeader(title: String, count: Int, color: Color) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(.subheadline, design: .default, weight: .semibold))
                .foregroundStyle(color)
            Spacer()
            Text("\(count)")
                .font(.system(.caption2, design: .monospaced, weight: .medium))
                .foregroundStyle(palette.textSecondary)
        }
    }

    private func compactItemRow(item: SovaWidgetItem, accent: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: item.categorySymbol)
                .font(.caption2)
                .foregroundStyle(accent)
                .frame(width: 20, height: 20)
                .background(accent.opacity(0.14), in: .circle)

            VStack(alignment: .leading, spacing: 1) {
                Text(item.title)
                    .font(.system(.caption, design: .default, weight: .medium))
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(1)
                Text(item.dueText)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.surface, in: .rect(cornerRadius: 10))
    }

    private func itemRow(item: SovaWidgetItem, accent: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: item.categorySymbol)
                .font(.caption)
                .foregroundStyle(accent)
                .frame(width: 26, height: 26)
                .background(accent.opacity(0.14), in: .circle)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(.subheadline, design: .default, weight: .medium))
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(1)
                Text("\(item.category) · \(item.dueText)")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
        .background(palette.surface, in: .rect(cornerRadius: 12))
        .padding(.bottom, 2)
    }
}

// MARK: - Widget declaration

struct SovaWidget: Widget {
    let kind: String = "SovaWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SovaWidgetIntent.self, provider: Provider()) { entry in
            WidgetView(entry: entry)
        }
        .configurationDisplayName("Upcoming maintenance")
        .description("See what's coming due across your things.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Helpers

private extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }

    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}
