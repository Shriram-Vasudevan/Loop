//
//  TrendsManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/19/25.
//

import Foundation
import SwiftUI
import CoreData

struct TopicSentimentSummary {
    let topic: String
    let averageSentiment: Double
    let mentionCount: Int
}

struct TopicTimelinePoint {
    let date: Date
    let sentiment: Double
    let frequency: Int
}


enum Timeframe: CaseIterable {
    case week
    case month
    case year
    
    var dateComponent: DateComponents {
        switch self {
        case .week:
            return DateComponents(day: -7)
        case .month:
            return DateComponents(month: -1)
        case .year:
            return DateComponents(year: -1)
        }
    }
    
    var displayText: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        }
    }
}

class TrendsManager: ObservableObject {
    static let shared = TrendsManager()
    @Published private(set) var isLoading = false
    
    private struct DataRequirements {
        static let topicAnalysis = 1
        static let sleepAnalysis = 3
        static let moodAnalysis = 3
    }
    
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "LoopData")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    private var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    private var cachedMetrics: [Timeframe: [(date: Date, mood: Double, sleep: Double?, wordCount: Int, topic: String?)]] = [:]
    
    func getDailyMetrics(for timeframe: Timeframe) async -> [(date: Date, mood: Double, sleep: Double?, wordCount: Int, topic: String?)] {
        return await withCheckedContinuation { continuation in
            let context = persistentContainer.newBackgroundContext()
            context.perform {
                let calendar = Calendar.current
                let now = Date()
                guard let startDate = calendar.date(byAdding: timeframe.dateComponent, to: now) else {
                    continuation.resume(returning: [])
                    return
                }
                
                var metrics: [(date: Date, mood: Double, sleep: Double?, wordCount: Int, topic: String?)] = []
                var currentDate = startDate
                
                while currentDate <= now {
                    if let averageMood = self.getAverageMoodRating(for: currentDate, context: context) {
                        let startOfDay = calendar.startOfDay(for: currentDate)
                        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { continue }
                        
                        let dayMetricsFetch = NSFetchRequest<NSManagedObject>(entityName: "DayMetricsEntity")
                        dayMetricsFetch.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
                        
                        let topicFetch = NSFetchRequest<NSManagedObject>(entityName: "TopicEntity")
                        topicFetch.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
                        
                        do {
                            let dayResults = try context.fetch(dayMetricsFetch)
                            let sleep = dayResults.first?.value(forKey: "sleepHours") as? Double
                            let wordCount = dayResults.first?.value(forKey: "totalWords") as? Int ?? 0
                            
                            metrics.append((
                                date: startOfDay,
                                mood: averageMood,
                                sleep: sleep,
                                wordCount: wordCount,
                                topic: nil
                            ))
                        } catch {
                            print("Error fetching metrics: \(error)")
                        }
                    }
                    
                    guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
                    currentDate = nextDate
                }
                
                self.cachedMetrics[timeframe] = metrics
                continuation.resume(returning: metrics)
            }
        }
    }
    
    func analyzeSleepEffect(for timeframe: Timeframe) async -> (message: String, effectLine: String)? {
        let metrics = await getDailyMetrics(for: timeframe)
        
        var belowRecommended: [Double] = []
        var recommended: [Double] = []
        var aboveRecommended: [Double] = []
        
        for metric in metrics {
            guard let sleep = metric.sleep else { continue }
            if sleep < 7 {
                belowRecommended.append(metric.mood)
            } else if sleep <= 9 {
                recommended.append(metric.mood)
            } else {
                aboveRecommended.append(metric.mood)
            }
        }
        
        let totalEntries = belowRecommended.count + recommended.count + aboveRecommended.count
        guard totalEntries >= DataRequirements.sleepAnalysis else {
            return (message: "Not enough sleep data", effectLine: "Track more sleep to see insights")
        }
        
        let belowMood = average(belowRecommended)
        let recommendedMood = average(recommended)
        let aboveMood = average(aboveRecommended)
        
        let allMoods = belowRecommended + recommended + aboveRecommended
        let baselineMood = average(allMoods) ?? 0
        
        let ranges = [
            ("insufficient", belowMood.map { (($0 - baselineMood) / baselineMood) * 100 }),
            ("recommended", recommendedMood.map { (($0 - baselineMood) / baselineMood) * 100 }),
            ("excessive", aboveMood.map { (($0 - baselineMood) / baselineMood) * 100 })
        ]
        .compactMap { name, effect in
            effect.map { (name: name, effect: $0) }
        }
        
        guard let bestRange = ranges.max(by: { $0.effect < $1.effect }) else { return nil }
        let effectPercentage = abs(Int(round(bestRange.effect)))
        
        switch bestRange.name {
        case "insufficient":
            return bestRange.effect > 0
                ? (message: "Sleep patterns need attention",
                   effectLine: "While your mood is \(effectPercentage)% higher with less sleep, 7-9 hours is recommended for health")
                : (message: "Less sleep affects your mood",
                   effectLine: "Your mood is \(effectPercentage)% lower with insufficient sleep")
            
        case "recommended":
            return (message: "Optimal sleep = better mood",
                    effectLine: "Your mood is \(effectPercentage)% higher with 7-9 hours of sleep")
            
        case "excessive":
            return bestRange.effect > 0
                ? (message: "More sleep, better mood?",
                   effectLine: "While your mood is \(effectPercentage)% higher with extra sleep, aim for 7-9 hours for best health")
                : (message: "Too much sleep may affect mood",
                   effectLine: "Your mood is \(effectPercentage)% lower with excessive sleep")
            
        default:
            let avgSleep = average(metrics.compactMap { $0.sleep }) ?? 0
            return (message: "Your average sleep",
                    effectLine: "\(String(format: "%.1f", avgSleep)) hours per night")
        }
    }
    
    func getTopicSentiments(for timeframe: Timeframe) async -> [TopicSentimentSummary] {
        print("getting topic sentiment")
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "TopicEntity")
        let calendar = Calendar.current
        let now = Date()
        
        guard let startDate = calendar.date(byAdding: timeframe.dateComponent, to: now) else {
            print("Failed to calculate start date")
            return []
        }
        
        fetchRequest.predicate = NSPredicate(format: "date >= %@", startDate as NSDate)
        print("Fetching topics from \(startDate) to \(now)")
        
        do {
            let results = try context.fetch(fetchRequest)
            print("Found \(results.count) total records")
            
            let groupedResults = Dictionary(grouping: results) { entity -> String in
                entity.value(forKey: "topic") as? String ?? ""
            }
            print("Grouped into \(groupedResults.count) topics")
            
            return groupedResults.compactMap { topic, entities in
                let sentiments = entities.compactMap { entity -> Double? in
                    let rawSentiment = entity.value(forKey: "sentiment") as? Double
                    print("Raw sentiment value from DB: \(entity.value(forKey: "sentiment"))")
                    return rawSentiment
                }
                guard !sentiments.isEmpty else {
                    print("No sentiments found for topic: \(topic)")
                    return nil
                }
                
                let avgSentiment = sentiments.reduce(0.0, +) / Double(sentiments.count)
                print("Topic: \(topic) - Count: \(entities.count) - Avg Sentiment: \(avgSentiment)")
                return TopicSentimentSummary(
                    topic: topic,
                    averageSentiment: avgSentiment,
                    mentionCount: entities.count
                )
            }
        } catch {
            print("Failed to fetch topic sentiments: \(error)")
            return []
        }
    }

    func getTopicTimeline(topic: String, timeframe: Timeframe) async -> [TopicTimelinePoint] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "TopicEntity")
        let calendar = Calendar.current
        let now = Date()
        
        guard let startDate = calendar.date(byAdding: timeframe.dateComponent, to: now) else {
            return []
        }
        
        fetchRequest.predicate = NSPredicate(
            format: "date >= %@ AND topic == %@",
            startDate as NSDate,
            topic
        )
        
        do {
            let results = try context.fetch(fetchRequest)
            let groupedResults = Dictionary(grouping: results) { entity -> Date in
                let date = entity.value(forKey: "date") as? Date ?? Date()
                return calendar.startOfDay(for: date)
            }
            
            return groupedResults.map { date, entities in
                let sentiments = entities.compactMap { $0.value(forKey: "sentiment") as? Double }
                let avgSentiment = sentiments.reduce(0.0, +) / Double(sentiments.count)
                
                return TopicTimelinePoint(
                    date: date,
                    sentiment: avgSentiment,
                    frequency: entities.count
                )
            }.sorted { $0.date < $1.date }
        } catch {
            print("Failed to fetch topic timeline: \(error)")
            return []
        }
    }
    
    func getMoodByWeekday(for timeframe: Timeframe) async -> [(weekday: Int, averageMood: Double)] {
        let metrics = await getDailyMetrics(for: timeframe)
        guard metrics.count >= DataRequirements.moodAnalysis else { return [] }
        
        let calendar = Calendar.current
        var weekdayMoods: [Int: [Double]] = [:]
        
        for metric in metrics {
            let weekday = calendar.component(.weekday, from: metric.date)
            weekdayMoods[weekday, default: []].append(metric.mood)
        }
        
        return weekdayMoods.map { weekday, moods in
            let average = moods.reduce(0, +) / Double(moods.count)
            return (weekday: weekday, averageMood: average)
        }.sorted { $0.weekday < $1.weekday }
    }
    
    private func getAverageMoodRating(for date: Date, context: NSManagedObjectContext) -> Double? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return nil
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DailyCheckinEntity")
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@ AND rating != nil",
                                           startOfDay as NSDate,
                                           endOfDay as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            let ratings = results.compactMap { entity -> Double? in
                return entity.value(forKey: "rating") as? Double
            }
            
            guard !ratings.isEmpty else { return nil }
            return ratings.reduce(0, +) / Double(ratings.count)
        } catch {
            print("Error fetching mood ratings: \(error)")
            return nil
        }
    }
    
    private func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    func getPositiveTopics(for timeframe: Timeframe) async -> [String] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "TopicEntity")
        let calendar = Calendar.current
        let now = Date()
        
        guard let startDate = calendar.date(byAdding: timeframe.dateComponent, to: now) else {
            return []
        }
        
        fetchRequest.predicate = NSPredicate(format: "date >= %@", startDate as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            let groupedResults = Dictionary(grouping: results) { entity -> String in
                entity.value(forKey: "topic") as? String ?? ""
            }
            
            return groupedResults.compactMap { topic, entities in
                let sentiments = entities.compactMap { $0.value(forKey: "sentiment") as? Double }
                guard !sentiments.isEmpty else { return nil }
                
                let avgSentiment = sentiments.reduce(0.0, +) / Double(sentiments.count)
                return avgSentiment > 0 ? topic : nil
            }
        } catch {
            print("Failed to fetch positive topics: \(error)")
            return []
        }
    }

    func getNegativeTopics(for timeframe: Timeframe) async -> [String] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "TopicEntity")
        let calendar = Calendar.current
        let now = Date()
        
        guard let startDate = calendar.date(byAdding: timeframe.dateComponent, to: now) else {
            return []
        }
        
        fetchRequest.predicate = NSPredicate(format: "date >= %@", startDate as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            let groupedResults = Dictionary(grouping: results) { entity -> String in
                entity.value(forKey: "topic") as? String ?? ""
            }
            
            return groupedResults.compactMap { topic, entities in
                let sentiments = entities.compactMap { $0.value(forKey: "sentiment") as? Double }
                guard !sentiments.isEmpty else { return nil }
                
                let avgSentiment = sentiments.reduce(0.0, +) / Double(sentiments.count)
                return avgSentiment < 0 ? topic : nil
            }
        } catch {
            print("Failed to fetch negative topics: \(error)")
            return []
        }
    }
    
    func getSleepAverages(for timeframe: Timeframe) async -> [Double] {
        let calendar = Calendar.current
        let now = Date()
        
        switch timeframe {
        case .week:
            // Initialize array for whole week
            var weekData = Array(repeating: 0.0, count: 7)
            
            // Get start of current week (Sunday)
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear, .weekday], from: now)
            components.weekday = 1  // 1 = Sunday
            guard let currentWeekStart = calendar.date(from: components) else {
                return weekData
            }
            
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "SleepCheckinEntity")
            fetchRequest.predicate = NSPredicate(
                format: "date >= %@ AND date <= %@",
                currentWeekStart as NSDate,
                now as NSDate
            )
            
            do {
                let results = try context.fetch(fetchRequest)
                
                for result in results {
                    guard let date = result.value(forKey: "date") as? Date,
                          let hours = result.value(forKey: "hours") as? Double else { continue }
                    
                    // Get the weekday index (1-7, where 1 is Sunday)
                    let weekday = calendar.component(.weekday, from: date)
                    let index = weekday - 1  // Convert to 0-based index
                    
                    if index >= 0 && index < 7 {
                        weekData[index] = hours
                    }
                }
                
                // Zero out future days
                let currentWeekday = calendar.component(.weekday, from: now)
                for i in currentWeekday..<7 {
                    weekData[i] = 0.0
                }
                
                return weekData
            } catch {
                print("Error fetching sleep data: \(error)")
                return weekData
            }
            
        case .month:
            // Initialize array for weeks in current month
            var monthData = Array(repeating: 0.0, count: 4)
            
            // Get start of current month
            guard let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
                return monthData
            }
            
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "SleepCheckinEntity")
            fetchRequest.predicate = NSPredicate(
                format: "date >= %@ AND date <= %@",
                currentMonthStart as NSDate,
                now as NSDate
            )
            
            do {
                let results = try context.fetch(fetchRequest)
                var weeklyData: [Int: [Double]] = [:]
                
                for result in results {
                    guard let date = result.value(forKey: "date") as? Date,
                          let hours = result.value(forKey: "hours") as? Double else { continue }
                    
                    let weekOfMonth = calendar.component(.weekOfMonth, from: date) - 1  // 0-based index
                    if weekOfMonth >= 0 && weekOfMonth < 4 {
                        weeklyData[weekOfMonth, default: []].append(hours)
                    }
                }
                
                // Calculate averages for weeks with data
                for (week, hours) in weeklyData {
                    monthData[week] = hours.reduce(0.0, +) / Double(hours.count)
                }
                
                // Zero out future weeks
                let currentWeek = calendar.component(.weekOfMonth, from: now) - 1
                for i in currentWeek + 1..<4 {
                    monthData[i] = 0.0
                }
                
                return monthData
            } catch {
                print("Error fetching sleep data: \(error)")
                return monthData
            }
            
        case .year:
            var yearData = Array(repeating: 0.0, count: 12)
            
            // Get date 11 months ago from start of current month
            let components = calendar.dateComponents([.year, .month], from: now)
            guard let currentMonthStart = calendar.date(from: components),
                  let yearAgoStart = calendar.date(byAdding: .month, value: -11, to: currentMonthStart) else {
                return yearData
            }
            
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "SleepCheckinEntity")
            fetchRequest.predicate = NSPredicate(
                format: "date >= %@ AND date <= %@",
                yearAgoStart as NSDate,
                now as NSDate
            )
            
            do {
                let results = try context.fetch(fetchRequest)
                var monthlyData: [Int: [Double]] = [:]
                
                for result in results {
                    guard let date = result.value(forKey: "date") as? Date,
                          let hours = result.value(forKey: "hours") as? Double else { continue }
                    
                    let monthsFromStart = calendar.dateComponents([.month], from: yearAgoStart, to: date).month ?? 0
                    if monthsFromStart >= 0 && monthsFromStart < 12 {
                        monthlyData[monthsFromStart, default: []].append(hours)
                    }
                }
                
                // Calculate averages for months with data
                for (month, hours) in monthlyData {
                    yearData[month] = hours.reduce(0.0, +) / Double(hours.count)
                }
                
                // Zero out any future days in current month
                if let lastMonthWithData = monthlyData.keys.max(), lastMonthWithData < 11 {
                    for i in (lastMonthWithData + 1)...11 {
                        yearData[i] = 0.0
                    }
                }
                
                return yearData
            } catch {
                print("Error fetching sleep data: \(error)")
                return yearData
            }
        }
    }
    
    func getMoodAverages(for timeframe: Timeframe) async -> [Double] {
        let calendar = Calendar.current
        let now = Date()
        
        switch timeframe {
        case .week:
            // Initialize array for whole week
            var weekData = Array(repeating: 0.0, count: 7)
            
            // Get start of current week (Sunday)
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear, .weekday], from: now)
            components.weekday = 1  // 1 = Sunday
            guard let currentWeekStart = calendar.date(from: components) else {
                return weekData
            }

            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DailyCheckinEntity")
            fetchRequest.predicate = NSPredicate(
                format: "date >= %@ AND date <= %@",
                currentWeekStart as NSDate,
                now as NSDate
            )
            
            do {
                let results = try context.fetch(fetchRequest)
                var dailyRatings: [Int: [Double]] = [:]

                for result in results {
                    guard let date = result.value(forKey: "date") as? Date,
                          let rating = result.value(forKey: "rating") as? Double else { continue }
                    
                    // Get the weekday index (1-7, where 1 is Sunday)
                    let weekday = calendar.component(.weekday, from: date)
                    let index = weekday - 1  // Convert to 0-based index
                    
                    if index >= 0 && index < 7 {
                        dailyRatings[index, default: []].append(rating)
                    }
                }
                
                // Calculate averages for days with data
                for (day, ratings) in dailyRatings {
                    weekData[day] = ratings.reduce(0.0, +) / Double(ratings.count)
                }
                
                // Zero out future days
                let currentWeekday = calendar.component(.weekday, from: now)
                for i in currentWeekday..<7 {
                    weekData[i] = 0.0
                }
                
                return weekData
            } catch {
                print("Error fetching mood data: \(error)")
                return weekData
            }
            
        case .month:
            var monthData = Array(repeating: 0.0, count: 4)
            
            // Get start of current month
            guard let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
                return monthData
            }
            
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DailyCheckinEntity")
            fetchRequest.predicate = NSPredicate(
                format: "date >= %@ AND date <= %@",
                currentMonthStart as NSDate,
                now as NSDate
            )
            
            do {
                let results = try context.fetch(fetchRequest)
                var weeklyRatings: [Int: [Double]] = [:]
                
                for result in results {
                    guard let date = result.value(forKey: "date") as? Date,
                          let rating = result.value(forKey: "rating") as? Double else { continue }
                    
                    let weekOfMonth = calendar.component(.weekOfMonth, from: date) - 1  // 0-based index
                    if weekOfMonth >= 0 && weekOfMonth < 4 {
                        weeklyRatings[weekOfMonth, default: []].append(rating)
                    }
                }
                
                // Calculate averages for weeks with data
                for (week, ratings) in weeklyRatings {
                    monthData[week] = ratings.reduce(0.0, +) / Double(ratings.count)
                }
                
                // Zero out future weeks
                let currentWeek = calendar.component(.weekOfMonth, from: now) - 1
                for i in currentWeek + 1..<4 {
                    monthData[i] = 0.0
                }
                
                return monthData
            } catch {
                print("Error fetching mood data: \(error)")
                return monthData
            }
            
        case .year:
            var yearData = Array(repeating: 0.0, count: 12)
            
            // Get date 11 months ago from start of current month
            let components = calendar.dateComponents([.year, .month], from: now)
            guard let currentMonthStart = calendar.date(from: components),
                  let yearAgoStart = calendar.date(byAdding: .month, value: -11, to: currentMonthStart) else {
                return yearData
            }
            
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DailyCheckinEntity")
            fetchRequest.predicate = NSPredicate(
                format: "date >= %@ AND date <= %@",
                yearAgoStart as NSDate,
                now as NSDate
            )
            
            do {
                let results = try context.fetch(fetchRequest)
                var monthlyRatings: [Int: [Double]] = [:]
                
                for result in results {
                    guard let date = result.value(forKey: "date") as? Date,
                          let rating = result.value(forKey: "rating") as? Double else { continue }
                    
                    let monthsFromStart = calendar.dateComponents([.month], from: yearAgoStart, to: date).month ?? 0
                    if monthsFromStart >= 0 && monthsFromStart < 12 {
                        monthlyRatings[monthsFromStart, default: []].append(rating)
                    }
                }

                for (month, ratings) in monthlyRatings {
                    yearData[month] = ratings.reduce(0.0, +) / Double(ratings.count)
                }

                if let lastMonthWithData = monthlyRatings.keys.max(), lastMonthWithData < 11 {
                    for i in (lastMonthWithData + 1)...11 {
                        yearData[i] = 0.0
                    }
                }
                
                return yearData
            } catch {
                print("Error fetching mood data: \(error)")
                return yearData
            }
        }
    }
}
