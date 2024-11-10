//
//  NotificationManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/1/24.
//

import Foundation
import UserNotifications

class ReminderManager {
    static let shared = ReminderManager()

    private let reminderTimeKey = "LoopReminderTime"
    private let reminderEnabledKey = "LoopReminderEnabled"
    private let notificationIdentifier = "LoopDailyReminder"
    
    private init() {
  
    }

    func saveAndScheduleReminder(at time: Date) {
        UserDefaults.standard.set(time, forKey: reminderTimeKey)
        UserDefaults.standard.set(true, forKey: reminderEnabledKey)
        

        cancelReminders()
        

        scheduleDailyReminder(at: time)
    }
    
    func loadReminderTime() -> Date? {
        return UserDefaults.standard.object(forKey: reminderTimeKey) as? Date
    }
    
    func isReminderEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: reminderEnabledKey)
    }
    
    func scheduleDailyReminder(at time: Date) {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "Time to Loop"
        content.body = "Don't forget to reflect and capture your thoughts!"
        content.sound = UNNotificationSound.default
        
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
            } else {
                print("Successfully scheduled daily reminder for \(dateComponents.hour ?? 0):\(dateComponents.minute ?? 0)")
            }
        }
    }
    
    func requestNotificationPermissions(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error requesting notification permissions: \(error.localizedDescription)")
                    completion(false)
                } else {
                    completion(granted)
                }
            }
        }
    }
    
    func checkNotificationPermissions(completion: @escaping (UNAuthorizationStatus) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }
    
    func cancelReminders() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
        UserDefaults.standard.set(false, forKey: reminderEnabledKey)
    }
    
    func disableReminder() {
        cancelReminders()
        UserDefaults.standard.removeObject(forKey: reminderTimeKey)
        UserDefaults.standard.set(false, forKey: reminderEnabledKey)
    }
    
    func rescheduleReminderIfNeeded() {
        if isReminderEnabled(),
           let savedTime = loadReminderTime() {
            scheduleDailyReminder(at: savedTime)
        }
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
}
