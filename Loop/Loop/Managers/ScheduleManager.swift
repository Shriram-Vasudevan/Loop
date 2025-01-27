//
//  ScheduleManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/4/25.
//

import Foundation
import SwiftUI
import CoreData
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
    
    private let sadColor = Color(hex: "1E3D59")
    private let neutralColor = Color(hex: "94A7B7")
    private let happyColor = Color(hex: "B784A7")
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "LoopData")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                print("🔴 Failed to load persistent stores: \(error)")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            print("✅ Successfully loaded persistent stores")
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    init() {
        print("📱 Initializing ScheduleManager")
        Task {
            await calculateStreak()
        }
    }
    
    private func getColorForRating(_ rating: Double) -> Color {
        print("🎨 Getting color for rating: \(rating)")
        
        if rating <= 5 {
            let t = (rating - 1) / 4
            return interpolateColor(from: sadColor, to: neutralColor, with: t)
        } else {
            let t = (rating - 5) / 5
            return interpolateColor(from: neutralColor, to: happyColor, with: t)
        }
    }
    
    private func interpolateColor(from: Color, to: Color, with percentage: Double) -> Color {
        let fromUIColor = UIColor(from)
        let toUIColor = UIColor(to)
        
        var fromR: CGFloat = 0
        var fromG: CGFloat = 0
        var fromB: CGFloat = 0
        var fromA: CGFloat = 0
        fromUIColor.getRed(&fromR, green: &fromG, blue: &fromB, alpha: &fromA)
        
        var toR: CGFloat = 0
        var toG: CGFloat = 0
        var toB: CGFloat = 0
        var toA: CGFloat = 0
        toUIColor.getRed(&toR, green: &toG, blue: &toB, alpha: &toA)
        
        let r = fromR + (toR - fromR) * CGFloat(percentage)
        let g = fromG + (toG - fromG) * CGFloat(percentage)
        let b = fromB + (toB - fromB) * CGFloat(percentage)
        let a = fromA + (toA - fromA) * CGFloat(percentage)
        
        return Color(UIColor(red: r, green: g, blue: b, alpha: a))
    }
    
    private func fetchRatingsInDateRange(startDate: Date, endDate: Date) throws -> [Date: [Double]] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DailyCheckinEntity")
        fetchRequest.predicate = NSPredicate(
            format: "date >= %@ AND date < %@ AND rating != nil",
            startDate as NSDate,
            endDate as NSDate
        )
        
        let results = try context.fetch(fetchRequest)
        var dailyRatings: [Date: [Double]] = [:]
        let calendar = Calendar.current
        
        for result in results {
            guard let date = result.value(forKey: "date") as? Date,
                  let rating = result.value(forKey: "rating") as? Double else {
                continue
            }
            
            let dayStart = calendar.startOfDay(for: date)
            if dailyRatings[dayStart] == nil {
                dailyRatings[dayStart] = []
            }
            dailyRatings[dayStart]?.append(rating)
        }
        
        return dailyRatings
    }
    
    func fetchRatingsForPastYear() async throws -> [Date: Double] {
        print("📅 Fetching ratings for past year")
        let calendar = Calendar.current
        let now = Date()
        
        guard let twelveMonthsAgo = calendar.date(byAdding: .month, value: -11, to: now),
              let startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: twelveMonthsAgo)),
              let nextMonth = calendar.date(byAdding: .month, value: 1, to: now),
              let endDate = calendar.date(from: calendar.dateComponents([.year, .month], from: nextMonth)) else {
            print("🔴 Failed to calculate date range for past year")
            throw NSError(domain: "DateError", code: -1)
        }
        
        let ratings = try fetchRatingsInDateRange(startDate: startDate, endDate: endDate)
        print("✅ Fetched \(ratings.count) ratings for past year")
        
        let formattedRatings = ratings.reduce(into: [Date: Double]()) { result, entry in
            let (key, value) = entry
            let average = value.reduce(0.0, +) / Double(value.count)
            result[key] = average
        }
        
        return formattedRatings
    }
    
    func fetchRatingsForPastWeek() async throws -> [Date: Double] {
        print("📅 Fetching ratings for past week")
        let calendar = Calendar.current
        let now = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -6, to: now) else {
            print("🔴 Failed to calculate start date for past week")
            throw NSError(domain: "DateError", code: -1)
        }
        
        let endDate = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        let ratings = try fetchRatingsInDateRange(startDate: startDate, endDate: endDate)
        print("✅ Fetched \(ratings.count) ratings for past week")
        
        let formattedRatings = ratings.reduce(into: [Date: Double]()) { partialResult, element in
            let average = element.value.reduce(0.0, +) / Double(element.value.count)
            partialResult[element.key] = average
        }
        
        return formattedRatings
    }
    
    func calculateStreak() async {
        print("🎯 Calculating current streak")
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
                print("📈 Calculated streak: \(count) days")
                return count
            }
            
            let result = await group.next() ?? 0
            return result
        }
        
        await MainActor.run {
            self.currentStreak = streakDays
            print("✅ Updated current streak to \(streakDays)")
        }
    }
    
    private func checkForActivity(on date: Date) async -> Bool {
        print("🔍 Checking for activity on \(date)")
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            print("🔴 Failed to calculate end of day")
            return false
        }
        
        if ratings[startOfDay] != nil || weekRatings[startOfDay] != nil {
            print("✅ Found activity in cached ratings")
            return true
        }
        
        do {
            let dailyRatings = try fetchRatingsInDateRange(startDate: startOfDay, endDate: endOfDay)
            print(dailyRatings.isEmpty ? "❌ No activity found" : "✅ Activity found")
            return !dailyRatings.isEmpty
        } catch {
            print("🔴 Error fetching activities for streak: \(error)")
            return false
        }
    }
    
    func loadWeekDataAndAssignColors() async {
        print("📊 Loading week data and assigning colors")
        guard let weekData = try? await fetchRatingsForPastWeek() else {
            print("🔴 Failed to fetch week data")
            return
        }
        
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
            print("✅ Updated week data with \(assignment.ratings.count) entries")
        }
    }
    
    func loadYearDataAndAssignColors() async {
        print("📊 Loading year data and assigning colors")
        guard let yearData = try? await fetchRatingsForPastYear() else {
            print("🔴 Failed to fetch year data")
            return
        }
        
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
            print("✅ Updated year data with \(assignment.ratings.count) entries")
        }
    }
}

struct ColorAssignment {
    let ratings: [Date: Double]
    let ratingColors: [Double: Color]
}
