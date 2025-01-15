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
    
    @Published var ratings: [Date: Double] = [:]
    @Published var ratingColors: [Double: Color] = [:]
    
    @Published var weekRatings: [Date: Double] = [:]
    @Published var weekRatingColors: [Double: Color] = [:]
    
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
    
    private func getColorForRating(_ rating: Double) -> Color {
        switch rating {
        case 9.0...10.0:
            return Color(hex: "C2E5C9")  // Bright positive color
        case 8.0..<9.0:
            return Color(hex: "B5E2D5")  // Light positive color
        case 6.0..<8.0:
            return Color(hex: "B5D5E2")  // Neutral positive color
        case 4.0..<6.0:
            return Color(hex: "E2DCB5")  // Neutral color
        case 2.0..<4.0:
            return Color(hex: "E2C9B5")  // Light negative color
        default:
            return Color(hex: "A28497")  // Dark negative color
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
        
        if ratings[startOfDay] != nil || weekRatings[startOfDay] != nil {
            return true
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "ActivityForToday")
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                           startOfDay as NSDate,
                                           endOfDay as NSDate)
        
        do {
            let activities = try context.fetch(fetchRequest)
            return !activities.isEmpty
        } catch {
            print("Error fetching activities for streak: \(error)")
            return false
        }
    }
    
    func loadWeekDataAndAssignColors() async {
        guard let weekData = try? await fetchRatingsForPastWeek() else { return }
        
        let assignment = await withTaskGroup(of: ColorAssignment.self) { group in
            group.addTask {
                var colorMap: [Double: Color] = [:]
                for rating in weekData.values {
                    colorMap[rating] = self.getColorForRating(rating)
                }
                
                return ColorAssignment(
                    ratings: weekData,
                    ratingColors: colorMap
                )
            }
            
            return await group.next() ?? ColorAssignment(ratings: [:], ratingColors: [:])
        }
        
        await MainActor.run {
            self.weekRatings = assignment.ratings
            self.weekRatingColors = assignment.ratingColors
        }
    }
    
    func loadYearDataAndAssignColors() async {
        guard let yearData = try? await fetchRatingsForPastYear() else { return }
        
        let assignment = await withTaskGroup(of: ColorAssignment.self) { group in
            group.addTask {
                var colorMap: [Double: Color] = [:]
                for rating in yearData.values {
                    colorMap[rating] = self.getColorForRating(rating)
                }
                
                return ColorAssignment(
                    ratings: yearData,
                    ratingColors: colorMap
                )
            }
            
            return await group.next() ?? ColorAssignment(ratings: [:], ratingColors: [:])
        }
        
        await MainActor.run {
            self.ratings = assignment.ratings
            self.ratingColors = assignment.ratingColors
        }
    }
    
    func fetchRatingsForPastYear() async throws -> [Date: Double] {
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
        let ratings = results.compactMap { result -> DailyCheckin? in
            guard let date = result.value(forKey: "date") as? Date,
                  let rating = result.value(forKey: "rating") as? Double else {
                return nil
            }
            return DailyCheckin(rating: rating, date: date)
        }
        
        return Dictionary(uniqueKeysWithValues: ratings.map {
            (calendar.startOfDay(for: $0.date), $0.rating)
        })
    }
    
    func fetchRatingsForPastWeek() async throws -> [Date: Double] {
        guard let startDate = Calendar.current.date(byAdding: .day, value: -6, to: Date()) else {
            throw NSError(domain: "DateError", code: -1)
        }
        let endDate = Date()
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DailyCheckinEntity")
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date <= %@",
                                           startDate as NSDate,
                                           endDate as NSDate)
        
        let results = try context.fetch(fetchRequest)
        let ratings = results.compactMap { result -> DailyCheckin? in
            guard let date = result.value(forKey: "date") as? Date,
                  let rating = result.value(forKey: "rating") as? Double else {
                return nil
            }
            return DailyCheckin(rating: rating, date: date)
        }
        
        return Dictionary(uniqueKeysWithValues: ratings.map {
            (Calendar.current.startOfDay(for: $0.date), $0.rating)
        })
    }
}

struct ColorAssignment {
    let ratings: [Date: Double]
    let ratingColors: [Double: Color]
}
