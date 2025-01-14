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
    
    @Published var emotions: [Date: String] = [:]
    @Published var emotionColors: [String: Color] = [:]
    
    @Published var weekEmotions: [Date: String] = [:]
    @Published var weekEmotionColors: [String: Color] = [:]
    
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
        
        if emotions[startOfDay] != nil || weekEmotions[startOfDay] != nil {
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
        
        let assignment = await withTaskGroup(of: ColorAssignment.self) { group in
            group.addTask {
                let frequencyCounts = Dictionary(grouping: weekData.values, by: { $0 })
                    .mapValues { $0.count }
                    .sorted { $0.value > $1.value }

                let colors = [
                    Color(hex: "A28497"),
                    Color(hex: "B5D5E2"),
                    Color(hex: "C2E5C9"),
                    Color(hex: "E2C9B5"),
                    Color(hex: "D5B5E2"),
                    Color(hex: "E2DCB5"),
                    Color(hex: "B5E2D5"),
                    Color(hex: "E2B5C9"),
                    Color(hex: "C9E2B5"),
                    Color(hex: "B5C9E2")
                ]

                var colorMap: [String: Color] = [:]
                for (index, emotion) in frequencyCounts.enumerated() {
                    let colorIndex = index % colors.count
                    colorMap[emotion.key] = colors[colorIndex]
                }

                return ColorAssignment(
                    emotions: weekData,
                    emotionColors: colorMap
                )
            }

            return await group.next() ?? ColorAssignment(emotions: [:], emotionColors: [:])
        }
        
        // Update published properties on the main thread with the final result
        await MainActor.run {
            self.weekEmotions = assignment.emotions
            self.weekEmotionColors = assignment.emotionColors
        }
    }
    
    func loadYearDataAndAssignColors() async {
        guard let yearData = try? await fetchEmotionsForPastYear() else {
            return
        }

        let assignment = await withTaskGroup(of: ColorAssignment.self) { group in
            group.addTask {
                let frequencyCounts = Dictionary(grouping: yearData.values, by: { $0 })
                    .mapValues { $0.count }
                    .sorted { $0.value > $1.value }

                let colors = [
                    Color(hex: "A28497"),
                    Color(hex: "B5D5E2"),
                    Color(hex: "C2E5C9"),
                    Color(hex: "E2C9B5"),
                    Color(hex: "D5B5E2"),
                    Color(hex: "E2DCB5"),
                    Color(hex: "B5E2D5"),
                    Color(hex: "E2B5C9"),
                    Color(hex: "C9E2B5"),
                    Color(hex: "B5C9E2") 
                ]

                var colorMap: [String: Color] = [:]
                for (index, emotion) in frequencyCounts.enumerated() {
                    let colorIndex = index % colors.count
                    colorMap[emotion.key] = colors[colorIndex]
                }

                return ColorAssignment(
                    emotions: yearData,
                    emotionColors: colorMap
                )
            }

            return await group.next() ?? ColorAssignment(emotions: [:], emotionColors: [:])
        }
        
        // Update published properties on the main thread with the final result
        await MainActor.run {
            self.emotions = assignment.emotions
            self.emotionColors = assignment.emotionColors
        }
    }
    
    func fetchEmotionsForPastYear() async throws -> [Date: String] {
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
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DailyEmotionEntity")
        fetchRequest.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            startDate as NSDate,
            endDate as NSDate
        )
        
        let results = try context.fetch(fetchRequest)
        let emotions = results.compactMap { result -> DailyEmotion? in
            guard let date = result.value(forKey: "date") as? Date,
                  let emotion = result.value(forKey: "emotion") as? String else {
                return nil
            }
            return DailyEmotion(emotion: emotion, date: date)
        }
        
        return Dictionary(uniqueKeysWithValues: emotions.map {
            (calendar.startOfDay(for: $0.date), $0.emotion)
        })
    }
    
    func fetchEmotionsForPastWeek()  async throws -> [Date: String] {
        guard let startDate = Calendar.current.date(byAdding: .day, value: -6, to: Date()) else { throw NSError(domain: "DateError", code: -1) }
        let endDate = Date()
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DailyEmotionEntity")
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        
        let results = try context.fetch(fetchRequest)
        
        let emotions = results.compactMap { result -> DailyEmotion? in
            guard let date = result.value(forKey: "date") as? Date,
                  let emotion = result.value(forKey: "emotion") as? String else {
                return nil
            }
            return DailyEmotion(emotion: emotion, date: date)
        }
        
        return Dictionary(uniqueKeysWithValues: emotions.map {
            (Calendar.current.startOfDay(for: $0.date), $0.emotion)
        })
    }
}

struct ColorAssignment {
    let emotions: [Date: String]
    let emotionColors: [String: Color]
}
