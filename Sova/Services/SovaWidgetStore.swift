import Foundation
import WidgetKit

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

enum SovaWidgetStore {
    static let appGroupID: String = "group.app.unlogged.sova.shared"
    static let widgetKind: String = "SovaWidget"
    private static let snapshotKey: String = "sova_widget_snapshot"

    static func save(items: [MaintenanceItem]) {
        let encoder: JSONEncoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let actionableItems: [MaintenanceItem] = items
            .filter { $0.status == .overdue || $0.status == .dueSoon }
            .sorted { ($0.nextDueDate ?? .distantFuture) < ($1.nextDueDate ?? .distantFuture) }

        let overdueItems = actionableItems.filter { $0.status == .overdue }
        let dueSoonItems = actionableItems.filter { $0.status == .dueSoon }

        let nextItem: MaintenanceItem? = actionableItems.first
        let widgetItems: [SovaWidgetItem] = actionableItems.prefix(8).map { item in
            SovaWidgetItem(
                title: item.title,
                category: item.category.rawValue,
                categorySymbol: item.category.symbolName,
                dueText: item.nextDueLabel,
                isOverdue: item.status == .overdue
            )
        }

        let snapshot: SovaWidgetSnapshot = .init(
            dueCount: actionableItems.count,
            overdueCount: overdueItems.count,
            dueSoonCount: dueSoonItems.count,
            nextTitle: nextItem?.title ?? "All set",
            nextCategory: nextItem?.category.rawValue ?? "Sova",
            nextDueText: nextItem?.nextDueLabel ?? "Nothing due soon",
            items: widgetItems,
            updatedAt: .now
        )

        guard let data = try? encoder.encode(snapshot) else { return }
        let defaults: UserDefaults? = UserDefaults(suiteName: appGroupID)
        defaults?.set(data, forKey: snapshotKey)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }

    static func load() -> SovaWidgetSnapshot {
        let defaults: UserDefaults? = UserDefaults(suiteName: appGroupID)
        guard let data = defaults?.data(forKey: snapshotKey) else { return .empty }
        let decoder: JSONDecoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode(SovaWidgetSnapshot.self, from: data)) ?? .empty
    }
}
