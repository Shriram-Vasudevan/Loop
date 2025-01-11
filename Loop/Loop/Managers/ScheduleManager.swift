//
//  ScheduleManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/4/25.
//

import Foundation
import SwiftUI
import CoreData

class ScheduleManager: ObservableObject {
    static let shared = ScheduleManager()
    
    @Published var dailyColors: [DailyColorHex] = []
    
    @Published var weekColors: [DailyColorHex] = []

    @Published var currentStreak: Int = 0
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "LoopData")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    init() {
        Task {
            await calculateStreak()
        }
    }
    
    
    func calculateStreak() async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let streakDays = await withTaskGroup(of: Int.self) { group in
            group.addTask {
                var count = 0
                for dayOffset in 1...365 {
                    guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { break }
                    
                    let hasActivity = await self.checkForActivity(on: date)
                    if hasActivity {
                        count += 1
                    } else {
                        break
                    }
                }
                return count
            }
            
            let result = await group.next() ?? 0
            return result
        }
        
        await MainActor.run {
            self.currentStreak = streakDays
        }
    }

    private func checkForActivity(on date: Date) async -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return false
        }
        
        if dailyColors.contains(where: { DailyColorHex in
            Calendar.current.isDate(startOfDay, inSameDayAs: DailyColorHex.date)
        }) || weekColors.contains(where: { DailyColorHex in
            Calendar.current.isDate(startOfDay, inSameDayAs: DailyColorHex.date)
        }) {
            return true
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "ActivityForToday")
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                           startOfDay as NSDate,
                                           endOfDay as NSDate)
        
        do {                let activities = try context.fetch(fetchRequest)
            return !activities.isEmpty
        } catch {
            print("Error fetching activities for streak: \(error)")
            return false
        }
    }
    
    func loadWeekDataAndAssignColors() async {
        guard let weekData = try? await fetchEmotionsForPastWeek() else { return }
        
        
        await MainActor.run {
            self.weekColors = weekData
        }
    }
    
    func loadYearDataAndAssignColors() async {
        guard let yearData = try? await fetchEmotionsForPastYear() else {
            return
        }

        await MainActor.run {
            self.dailyColors = yearData
        }
    }
    
    func fetchEmotionsForPastYear() async throws -> [DailyColorHex] {
        let calendar = Calendar.current
        let now = Date()
        
        guard let twelveMonthsAgo = calendar.date(byAdding: .month, value: -11, to: now),
              let startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: twelveMonthsAgo)) else {
            throw NSError(domain: "DateError", code: -1)
        }
        
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: now),
              let endDate = calendar.date(from: calendar.dateComponents([.year, .month], from: nextMonth)) else {
            throw NSError(domain: "DateError", code: -1)
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DailyCheckinEntity")
        fetchRequest.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            startDate as NSDate,
            endDate as NSDate
        )
        
        let results = try context.fetch(fetchRequest)
        let emotions = results.compactMap { result -> DailyColorHex? in
            guard let date = result.value(forKey: "date") as? Date,
                  let colorHex = result.value(forKey: "colorHex") as? String else {
                return nil
            }
            return DailyColorHex(colorHex: colorHex, date: Calendar.current.startOfDay(for: date))
        }
        
        return emotions
    }
    
    func fetchEmotionsForPastWeek()  async throws -> [DailyColorHex] {
        guard let startDate = Calendar.current.date(byAdding: .day, value: -6, to: Date()) else { throw NSError(domain: "DateError", code: -1) }
        let endDate = Date()
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DailyCheckinEntity")
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        
        let results = try context.fetch(fetchRequest)
        
        let emotions = results.compactMap { result -> DailyColorHex? in
            guard let date = result.value(forKey: "date") as? Date,
                  let colorHex = result.value(forKey: "colorHex") as? String else {
                return nil
            }
            return DailyColorHex(colorHex: colorHex, date: Calendar.current.startOfDay(for: date))
        }
        
        return emotions
    }
}

struct ColorAssignment {
    let emotions: [Date: String]
    let emotionColors: [String: Color]
}
