import Foundation
import SwiftData

@Model
final class ItemReminder {
    var name: String = ""
    var nextDueDate: Date?
    var intervalMonths: Int?
    var lastServiceDate: Date?
    var isComplete: Bool = false
    var createdAt: Date = Date()
    @Relationship var item: MaintenanceItem?

    init(
        name: String,
        nextDueDate: Date? = nil,
        intervalMonths: Int? = nil,
        lastServiceDate: Date? = nil,
        isComplete: Bool = false,
        item: MaintenanceItem? = nil
    ) {
        self.name = name
        self.nextDueDate = nextDueDate
        self.intervalMonths = intervalMonths
        self.lastServiceDate = lastServiceDate
        self.isComplete = isComplete
        self.item = item
    }

    var status: MaintenanceStatus {
        if isComplete { return .tracking }
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

    var nextDueLabel: String {
        guard let nextDueDate else { return "No due date" }
        return nextDueDate.formatted(date: .abbreviated, time: .omitted)
    }
}
