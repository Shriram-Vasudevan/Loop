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
    private let reminderKey = "LoopReminderTime"
    
    private init() {
    }
    
    func saveReminderTime(_ time: Date) {
        UserDefaults.standard.set(time, forKey: reminderKey)
        scheduleDailyReminder(at: time)
    }
    
    func loadReminderTime() -> Date? {
        return UserDefaults.standard.object(forKey: reminderKey) as? Date
    }
    
    func scheduleDailyReminder(at time: Date) {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let content = UNMutableNotificationContent()
        content.title = "Time to Loop"
        content.body = "Don’t forget to reflect and capture your thoughts!"
        content.sound = UNNotificationSound.default
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: "LoopReminderTime", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling daily reminder: \(error.localizedDescription)")
            }
        }
    }
    
    func requestNotificationPermissions(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            completion(granted)
        }
    }
}
