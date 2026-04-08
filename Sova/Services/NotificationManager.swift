import Foundation
import SwiftData
import UserNotifications

enum NotificationManager {

    private static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
    }

    // MARK: - Schedule for a single item's reminders

    static func scheduleRemindersForItem(_ item: MaintenanceItem) {
        guard isEnabled else { return }
        let center = UNUserNotificationCenter.current()

        for reminder in item.activeReminders {
            let id = notificationIdentifier(for: reminder)
            // Cancel any existing notification for this reminder first
            center.removePendingNotificationRequests(withIdentifiers: [id])

            guard let dueDate = reminder.nextDueDate, dueDate > .now else { continue }

            let content = UNMutableNotificationContent()
            content.title = item.title
            content.body = "\(reminder.name) is due today"
            content.sound = .default

            // Schedule at 9:00 AM on the due date
            var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
            dateComponents.hour = 9
            dateComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

            center.add(request)
        }
    }

    // MARK: - Cancel notifications for a single item

    static func cancelRemindersForItem(_ item: MaintenanceItem) {
        let center = UNUserNotificationCenter.current()
        let ids = (item.reminders ?? []).map { notificationIdentifier(for: $0) }
        guard !ids.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Reschedule all (used on app launch)

    static func scheduleAllReminders(items: [MaintenanceItem]) {
        let center = UNUserNotificationCenter.current()
        // Clear all pending Sova notifications and reschedule from scratch
        center.removeAllPendingNotificationRequests()

        guard isEnabled else { return }

        for item in items {
            for reminder in item.activeReminders {
                guard let dueDate = reminder.nextDueDate, dueDate > .now else { continue }

                let content = UNMutableNotificationContent()
                content.title = item.title
                content.body = "\(reminder.name) is due today"
                content.sound = .default

                var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
                dateComponents.hour = 9
                dateComponents.minute = 0

                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                let request = UNNotificationRequest(
                    identifier: notificationIdentifier(for: reminder),
                    content: content,
                    trigger: trigger
                )

                center.add(request)
            }
        }
    }

    // MARK: - Cancel all

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Identifier

    static func notificationIdentifier(for reminder: ItemReminder) -> String {
        "sova-reminder-\(reminder.persistentModelID.hashValue)"
    }
}
