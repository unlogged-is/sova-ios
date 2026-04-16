import Foundation
import SwiftData

@Model
final class MaintenanceItem {
    var title: String = ""
    var itemDescription: String = ""
    var categoryRawValue: String = SovaCategory.car.rawValue
    var locationName: String?
    var purchaseDate: Date?
    var lastServiceDate: Date?
    var nextDueDate: Date?
    var serviceIntervalMonths: Int?
    var notes: String = ""
    var customFieldsJSON: String?
    var coverPhotoIndex: Int?
    var customCategoryID: UUID?
    var customCategoryName: String?
    var customCategorySymbol: String?
    var customCategoryTint: String?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    @Relationship(deleteRule: .cascade, inverse: \ItemPhoto.item) var photos: [ItemPhoto]?
    @Relationship(deleteRule: .cascade, inverse: \ItemReminder.item) var reminders: [ItemReminder]?

    init(
        title: String,
        itemDescription: String,
        categoryRawValue: String,
        locationName: String? = nil,
        purchaseDate: Date? = nil,
        lastServiceDate: Date? = nil,
        nextDueDate: Date? = nil,
        serviceIntervalMonths: Int? = nil,
        notes: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.title = title
        self.itemDescription = itemDescription
        self.categoryRawValue = categoryRawValue
        self.locationName = locationName
        self.purchaseDate = purchaseDate
        self.lastServiceDate = lastServiceDate
        self.nextDueDate = nextDueDate
        self.serviceIntervalMonths = serviceIntervalMonths
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var category: SovaCategory {
        get { SovaCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }

    var isCustomCategory: Bool {
        customCategoryID != nil
    }

    var displayCategoryName: String {
        customCategoryName ?? category.rawValue
    }

    var displayCategorySymbol: String {
        customCategorySymbol ?? category.symbolName
    }

    var displayCategoryTint: String {
        customCategoryTint ?? category.tintName
    }

    var photoData: [Data] {
        (photos ?? []).compactMap { $0.data }
    }

    var coverPhotoData: Data? {
        guard let index = coverPhotoIndex else { return nil }
        let allPhotos = photoData
        guard index >= 0 && index < allPhotos.count else { return nil }
        return allPhotos[index]
    }

    var customFields: [String: String] {
        get {
            guard let json = customFieldsJSON,
                  let data = json.data(using: .utf8),
                  let dict = try? JSONDecoder().decode([String: String].self, from: data)
            else { return [:] }
            return dict
        }
        set {
            if newValue.isEmpty {
                customFieldsJSON = nil
            } else if let data = try? JSONEncoder().encode(newValue),
                      let json = String(data: data, encoding: .utf8) {
                customFieldsJSON = json
            }
        }
    }

    var activeReminders: [ItemReminder] {
        (reminders ?? []).filter { !$0.isComplete }
    }

    /// The soonest-due active reminder, if any
    var nextUpcomingReminder: ItemReminder? {
        activeReminders
            .filter { $0.nextDueDate != nil }
            .sorted { ($0.nextDueDate ?? .distantFuture) < ($1.nextDueDate ?? .distantFuture) }
            .first
    }

    /// Earliest due date across all active reminders (or the item-level fallback)
    var earliestDueDate: Date? {
        if let upcoming = nextUpcomingReminder?.nextDueDate {
            return upcoming
        }
        return nextDueDate
    }

    var status: MaintenanceStatus {
        let active = activeReminders
        if !active.isEmpty {
            // Return worst status among active reminders
            if active.contains(where: { $0.status == .overdue }) { return .overdue }
            if active.contains(where: { $0.status == .dueSoon }) { return .dueSoon }
            if active.contains(where: { $0.status == .scheduled }) { return .scheduled }
            return .tracking
        }
        // Fallback to single nextDueDate for items without reminders
        guard let nextDueDate else { return .tracking }
        let calendar: Calendar = .current
        if calendar.startOfDay(for: nextDueDate) < calendar.startOfDay(for: .now) {
            return .overdue
        }
        if let soonDate = calendar.date(byAdding: .day, value: 30, to: .now), nextDueDate <= soonDate {
            return .dueSoon
        }
        return .scheduled
    }

    /// A label like "Oil Change — Apr 15, 2026" for the next upcoming service
    var nextUpcomingServiceLabel: String {
        if let reminder = nextUpcomingReminder, let date = reminder.nextDueDate {
            return "\(reminder.name) — \(date.formatted(date: .abbreviated, time: .omitted))"
        }
        guard let nextDueDate else { return "No upcoming service" }
        return nextDueDate.formatted(date: .abbreviated, time: .omitted)
    }

    /// Just the date portion for the next due service
    var nextDueLabel: String {
        if let date = earliestDueDate {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
        return "No due date"
    }
}

nonisolated enum SovaCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case car = "Car"
    case appliance = "Appliance"
    case hvac = "HVAC"
    case roof = "Roof"
    case bike = "Bike"
    case home = "Home"
    case garden = "Garden"
    case warranty = "Warranty"
    case receipt = "Receipt"
    case other = "Other"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .car:
            "car.fill"
        case .appliance:
            "washer.fill"
        case .hvac:
            "wind"
        case .roof:
            "house.lodge.fill"
        case .bike:
            "bicycle"
        case .home:
            "house.fill"
        case .garden:
            "leaf.fill"
        case .warranty:
            "checkmark.shield.fill"
        case .receipt:
            "doc.text.fill"
        case .other:
            "square.grid.2x2.fill"
        }
    }

    var tintName: String {
        switch self {
        case .car, .bike:
            "accentPrimary"
        case .appliance, .home:
            "accentWarm"
        case .hvac, .garden:
            "dueSoon"
        case .warranty:
            "accentPrimary"
        case .receipt:
            "accentWarm"
        case .roof, .other:
            "textSecondary"
        }
    }
}

nonisolated enum MaintenanceStatus: String, Codable, Sendable {
    case overdue
    case dueSoon
    case scheduled
    case tracking

    var title: String {
        switch self {
        case .overdue:
            "Overdue"
        case .dueSoon:
            "Due soon"
        case .scheduled:
            "Scheduled"
        case .tracking:
            "Tracking"
        }
    }

    var symbolName: String {
        switch self {
        case .overdue:
            "exclamationmark.triangle.fill"
        case .dueSoon:
            "clock.badge.exclamationmark.fill"
        case .scheduled:
            "calendar.badge.clock"
        case .tracking:
            "checkmark.seal.fill"
        }
    }
}
