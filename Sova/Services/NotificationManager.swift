import Foundation
import SwiftData
import UserNotifications

enum NotificationManager {

    // MARK: - User Preferences

    private static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
    }

    /// How many days before the due date to send the "coming due" notification (default 3)
    static var advanceDays: Int {
        let val = UserDefaults.standard.object(forKey: "notificationAdvanceDays") as? Int
        return val ?? 3
    }

    /// Hour of day to fire notifications (0–23, default 9)
    static var notificationHour: Int {
        let val = UserDefaults.standard.object(forKey: "notificationHour") as? Int
        return val ?? 9
    }

    // MARK: - Schedule for a single item's reminders

    static func scheduleRemindersForItem(_ item: MaintenanceItem) {
        guard isEnabled else { return }
        let center = UNUserNotificationCenter.current()

        for reminder in item.activeReminders {
            // Cancel existing notifications for this reminder
            let dueID = dueDayIdentifier(for: reminder)
            let advanceID = advanceIdentifier(for: reminder)
            center.removePendingNotificationRequests(withIdentifiers: [dueID, advanceID])

            guard let dueDate = reminder.nextDueDate else { continue }

            let hour = notificationHour

            // 1) Due-day notification
            if dueDate > .now {
                let dueContent = UNMutableNotificationContent()
                dueContent.title = item.title
                dueContent.body = "\(reminder.name) is due today"
                dueContent.sound = .default

                var dueDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
                dueDateComponents.hour = hour
                dueDateComponents.minute = 0

                let dueTrigger = UNCalendarNotificationTrigger(dateMatching: dueDateComponents, repeats: false)
                center.add(UNNotificationRequest(identifier: dueID, content: dueContent, trigger: dueTrigger))
            }

            // 2) Advance "coming due" notification
            let days = advanceDays
            if days > 0, let advanceDate = Calendar.current.date(byAdding: .day, value: -days, to: dueDate),
               advanceDate > .now {
                let advanceContent = UNMutableNotificationContent()
                advanceContent.title = item.title
                advanceContent.body = "\(reminder.name) is due in \(days) day\(days == 1 ? "" : "s")"
                advanceContent.sound = .default

                var advDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: advanceDate)
                advDateComponents.hour = hour
                advDateComponents.minute = 0

                let advTrigger = UNCalendarNotificationTrigger(dateMatching: advDateComponents, repeats: false)
                center.add(UNNotificationRequest(identifier: advanceID, content: advanceContent, trigger: advTrigger))
            }
        }
    }

    // MARK: - Cancel notifications for a single item

    static func cancelRemindersForItem(_ item: MaintenanceItem) {
        let center = UNUserNotificationCenter.current()
        let ids = (item.reminders ?? []).flatMap { reminder in
            [dueDayIdentifier(for: reminder), advanceIdentifier(for: reminder)]
        }
        guard !ids.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Reschedule all (used on app launch)

    static func scheduleAllReminders(items: [MaintenanceItem]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        guard isEnabled else { return }

        for item in items {
            scheduleRemindersForItem(item)
        }
    }

    // MARK: - Cancel all

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Identifiers

    static func dueDayIdentifier(for reminder: ItemReminder) -> String {
        "sova-due-\(reminder.persistentModelID.hashValue)"
    }

    static func advanceIdentifier(for reminder: ItemReminder) -> String {
        "sova-advance-\(reminder.persistentModelID.hashValue)"
    }
}
