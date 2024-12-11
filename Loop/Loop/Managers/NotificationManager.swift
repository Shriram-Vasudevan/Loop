//
//  NotificationManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/1/24.
//

import Foundation
import UserNotifications
import SwiftUI

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published private(set) var isNotificationsEnabled = false
    @Published private(set) var currentPermissionStatus: UNAuthorizationStatus = .notDetermined
    
    private let reminderTimeKey = "LoopReminderTime"
    private let reminderEnabledKey = "LoopReminderEnabled"
    private let notificationIdentifier = "LoopDailyReminder"
    private let defaults = UserDefaults.standard
    
    private init() {
        isNotificationsEnabled = defaults.bool(forKey: reminderEnabledKey)
        updateNotificationPermissionStatus()
    }
    
    func updateNotificationPermissionStatus() {
        checkNotificationPermissions { status in
            DispatchQueue.main.async {
                self.currentPermissionStatus = status
                if status != .authorized {
                    self.isNotificationsEnabled = false
                    self.defaults.set(false, forKey: self.reminderEnabledKey)
                }
            }
        }
    }
    
    func requestNotificationPermissions() async -> Bool {
        do {
            let center = UNUserNotificationCenter.current()
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            
            await MainActor.run {
                self.isNotificationsEnabled = granted
                self.defaults.set(granted, forKey: self.reminderEnabledKey)
                if granted {
                    if let savedTime = self.loadReminderTime() {
                        self.scheduleDailyReminder(at: savedTime)
                    }
                }
            }
            
            return granted
        } catch {
            print("Error requesting notification permissions: \(error.localizedDescription)")
            return false
        }
    }
    
    func checkNotificationPermissions(_ completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            completion(settings.authorizationStatus)
        }
    }
    
    func toggleNotifications(enabled: Bool) {
        Task {
            if enabled {
                let granted = await requestNotificationPermissions()
                if !granted {
                    await MainActor.run {
                        self.isNotificationsEnabled = false
                        self.defaults.set(false, forKey: self.reminderEnabledKey)
                    }
                }
            } else {
                await MainActor.run {
                    self.disableReminders()
                }
            }
        }
    }
    
    func saveAndScheduleReminder(at time: Date) {
        defaults.set(time, forKey: reminderTimeKey)
        defaults.set(true, forKey: reminderEnabledKey)
        isNotificationsEnabled = true
        
        cancelReminders()
        scheduleDailyReminder(at: time)
    }
    
    func loadReminderTime() -> Date? {
        return defaults.object(forKey: reminderTimeKey) as? Date
    }
    
    func scheduleDailyReminder(at time: Date) {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "Time to Loop"
        content.body = "Don't forget to reflect and capture your thoughts!"
        content.sound = UNNotificationSound.default
        content.badge = 1
        
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.hour, .minute], from: time)
        dateComponents.second = 0
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: notificationIdentifier,
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling reminder: \(error.localizedDescription)")
            }
        }
    }
    
    func rescheduleRemindersIfNeeded() {
        if isNotificationsEnabled,
           let savedTime = loadReminderTime() {
            scheduleDailyReminder(at: savedTime)
        }
    }
    
    func cancelReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
    }
    
    func disableReminders() {
        cancelReminders()
        defaults.removeObject(forKey: reminderTimeKey)
        defaults.set(false, forKey: reminderEnabledKey)
        isNotificationsEnabled = false
    }
    
    func getNextReminderDate() -> Date? {
        guard let savedTime = loadReminderTime() else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        
        let hour = calendar.component(.hour, from: savedTime)
        let minute = calendar.component(.minute, from: savedTime)
        
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = minute
        components.second = 0
        
        guard let reminderTime = calendar.date(from: components) else { return nil }
        
        if reminderTime <= now {
            return calendar.date(byAdding: .day, value: 1, to: reminderTime)
        }
        
        return reminderTime
    }
    
    func formatReminderTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    func formatNextReminderDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func handleNotification(_ response: UNNotificationResponse) {
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            print("User opened the notification")
        case UNNotificationDismissActionIdentifier:
            print("User dismissed the notification")
        default:
            break
        }
    }
    
    func resetBadgeCount() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}

extension NotificationManager {
    func setupNotificationCategories() {
        let center = UNUserNotificationCenter.current()
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Snooze for 1 hour",
            options: []
        )
        
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_ACTION",
            title: "Complete",
            options: [.foreground]
        )
        
        let category = UNNotificationCategory(
            identifier: "REMINDER_CATEGORY",
            actions: [snoozeAction, completeAction],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([category])
    }
    
    func scheduleSnoozeReminder(from originalDate: Date) {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "Time to Loop"
        content.body = "Don't forget to reflect and capture your thoughts!"
        content.sound = UNNotificationSound.default
        content.badge = 1
        content.categoryIdentifier = "REMINDER_CATEGORY"
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 3600,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "\(notificationIdentifier)_snooze",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling snooze reminder: \(error.localizedDescription)")
            }
        }
    }
}
