//
//  TrendsManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/19/25.
//

import Foundation
import SwiftUI
import CoreData

import Foundation
import SwiftUI
import CoreData

class TrendsManager: ObservableObject {
    static let shared = TrendsManager()
    
    private struct Constants {
        static let moodThreshold = 6.0
        static let minimumDataPoints = 3
        static let significantCorrelation = 0.3
        static let sadColor = "1E3D59"
        static let neutralColor = "94A7B7"
        static let happyColor = "B784A7"
        static let significantChangeThreshold = 15.0
    }
    
    @Published private(set) var insights: [ReflectionInsight] = []
    @Published private(set) var topicStats: [TopicStat] = []
    @Published private(set) var trendStats: TrendStats?
    
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
    
    func refreshInsights() {
        let timeframes: [Timeframe] = [.week, .month, .year]
        var newInsights: [ReflectionInsight] = []
        
        for timeframe in timeframes {
            if let moodTrend = analyzeMoodTrend(timeframe) {
                newInsights.append(moodTrend)
            }
            
            if let sleepCorrelation = analyzeSleepCorrelation(timeframe) {
                newInsights.append(sleepCorrelation)
            }
            
            if let topicMood = analyzeTopicMoodCorrelation(timeframe) {
                newInsights.append(topicMood)
            }
            
            if let completionPattern = analyzeCompletionPattern(timeframe) {
                newInsights.append(completionPattern)
            }
            
            if let fillerPattern = analyzeFillerWordPattern(timeframe) {
                newInsights.append(fillerPattern)
            }
            
            if let timePattern = analyzeTimeOfDayPattern(timeframe) {
                newInsights.append(timePattern)
            }
            
            if let wordCountTrend = analyzeWordCountTrend(timeframe) {
                newInsights.append(wordCountTrend)
            }
            
            if let momentPattern = analyzeKeyMomentPattern(timeframe) {
                newInsights.append(momentPattern)
            }
            
            if let lengthPattern = analyzeReflectionLength(timeframe) {
                newInsights.append(lengthPattern)
            }
            
            if let detailedTopics = analyzeDetailedTopics(timeframe) {
                newInsights.append(detailedTopics)
            }
            
            if let commonTimes = analyzeMostCommonTimes(timeframe) {
                newInsights.append(commonTimes)
            }
    
        }
        
        analyzeTopicFrequency()
        calculateTrendStats()
        
        DispatchQueue.main.async {
            self.insights = newInsights.filter { $0.isSignificant }
        }
    }
    
    private func analyzeMoodTrend(_ timeframe: Timeframe) -> ReflectionInsight? {
        let ratings = fetchDayRatings(timeframe)
        guard ratings.count >= Constants.minimumDataPoints else { return nil }
        
        let averageRating = ratings.map(\.rating).reduce(0, +) / Double(ratings.count)
        let moodLabel = getMoodLabel(for: averageRating)
        
        return ReflectionInsight(
            type: .moodTrend,
            message: "You've been feeling \(moodLabel)",
            value: averageRating,
            timeframe: timeframe,
            isSignificant: true
        )
    }
    
    private func analyzeSleepCorrelation(_ timeframe: Timeframe) -> ReflectionInsight? {
        let metrics = fetchMetricsWithRatings(timeframe)
        let sleepData = metrics.compactMap { metric -> (sleep: Double, rating: Double)? in
            guard let sleep = metric.sleepHours else { return nil }
            return (sleep, metric.rating)
        }
        
        guard sleepData.count >= Constants.minimumDataPoints else { return nil }
        
        let correlation = calculateCorrelation(
            sleepData.map(\.sleep),
            sleepData.map(\.rating)
        )
        
        guard correlation > Constants.significantCorrelation else { return nil }
        
        return ReflectionInsight(
            type: .sleepPattern,
            message: "Your outlook tends to improve with more sleep",
            value: correlation,
            timeframe: timeframe,
            isSignificant: true
        )
    }
    
    private func analyzeTopicMoodCorrelation(_ timeframe: Timeframe) -> ReflectionInsight? {
        let keyMoments = fetchKeyMoments(timeframe)
        var topicRatings: [String: [Double]] = [:]
        
        for moment in keyMoments where moment.type == "standout" {
            guard let topic = moment.topic else { continue }
            if let rating = moment.associatedMood {
                topicRatings[topic, default: []].append(rating)
            }
        }
        
        var highestTopic = ""
        var highestAvg = 0.0
        
        for (topic, ratings) in topicRatings where ratings.count >= Constants.minimumDataPoints {
            let avg = ratings.reduce(0, +) / Double(ratings.count)
            if avg > highestAvg {
                highestAvg = avg
                highestTopic = topic
            }
        }
        
        guard !highestTopic.isEmpty else { return nil }
        
        return ReflectionInsight(
            type: .topicCorrelation,
            message: "Your reflections tend to be more positive when discussing \(highestTopic)",
            value: highestAvg,
            timeframe: timeframe,
            isSignificant: true
        )
    }
    
    private func analyzeCompletionPattern(_ timeframe: Timeframe) -> ReflectionInsight? {
        let metrics = fetchMetricsWithRatings(timeframe)
        let aboveThreshold = metrics.filter { $0.rating > Constants.moodThreshold }
        let belowThreshold = metrics.filter { $0.rating <= Constants.moodThreshold }
        
        guard aboveThreshold.count >= Constants.minimumDataPoints,
              belowThreshold.count >= Constants.minimumDataPoints else { return nil }
        
        let aboveAvg = Double(aboveThreshold.map(\.entryCount).reduce(0, +)) / Double(aboveThreshold.count)
        let belowAvg = Double(belowThreshold.map(\.entryCount).reduce(0, +)) / Double(belowThreshold.count)
        
        let percentChange = ((aboveAvg - belowAvg) / belowAvg) * 100
        
        guard percentChange > Constants.significantChangeThreshold else { return nil }
        
        return ReflectionInsight(
            type: .completionPattern,
            message: "You tend to reflect more thoroughly when feeling better",
            value: percentChange,
            timeframe: timeframe,
            isSignificant: true
        )
    }
    
    private func analyzeFillerWordPattern(_ timeframe: Timeframe) -> ReflectionInsight? {
        let metrics = fetchMetricsWithRatings(timeframe)
        guard metrics.count >= Constants.minimumDataPoints else { return nil }
        
        let averageFillers = Double(metrics.map(\.fillerWordCount).reduce(0, +)) / Double(metrics.count)
        
        return ReflectionInsight(
            type: .fillerPattern,
            message: "Average of \(Int(round(averageFillers))) filler words per reflection",
            value: averageFillers,
            timeframe: timeframe,
            isSignificant: true
        )
    }
    
    private func analyzeTimeOfDayPattern(_ timeframe: Timeframe) -> ReflectionInsight? {
        let metrics = fetchMetricsWithRatings(timeframe)
        var timeRatings: [Int: [Double]] = [:]
        
        for metric in metrics {
            let hour = Calendar.current.component(.hour, from: metric.timeOfEntry ?? Date())
            timeRatings[hour, default: []].append(metric.rating)
        }
        
        var bestHour = 0
        var bestAvg = 0.0
        
        for (hour, ratings) in timeRatings where ratings.count >= Constants.minimumDataPoints {
            let avg = ratings.reduce(0, +) / Double(ratings.count)
            if avg > bestAvg {
                bestAvg = avg
                bestHour = hour
            }
        }
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "ha"
        let hourDate = Calendar.current.date(bySettingHour: bestHour, minute: 0, second: 0, of: Date()) ?? Date()
        let timeString = timeFormatter.string(from: hourDate).lowercased()
        
        return ReflectionInsight(
            type: .timePattern,
            message: "Your reflections tend to be more positive around \(timeString)",
            value: Double(bestHour),
            timeframe: timeframe,
            isSignificant: true
        )
    }
    
    private func analyzeWordCountTrend(_ timeframe: Timeframe) -> ReflectionInsight? {
        let metrics = fetchMetricsWithRatings(timeframe)
        guard metrics.count >= Constants.minimumDataPoints else { return nil }
        
        let averageWords = Double(metrics.map(\.totalWords).reduce(0, +)) / Double(metrics.count)
        
        return ReflectionInsight(
            type: .wordCount,
            message: "Average reflection length: \(Int(round(averageWords))) words",
            value: averageWords,
            timeframe: timeframe,
            isSignificant: true
        )
    }
    
    private func analyzeKeyMomentPattern(_ timeframe: Timeframe) -> ReflectionInsight? {
        let moments = fetchKeyMoments(timeframe)
        var categoryCount: [String: Int] = [:]
        
        for moment in moments where moment.type == "standout" {
            if let category = moment.category {
                categoryCount[category, default: 0] += 1
            }
        }
        
        guard let (topCategory, count) = categoryCount.max(by: { $0.value < $1.value }) else { return nil }
        
        return ReflectionInsight(
            type: .momentPattern,
            message: "Your significant moments often involve \(topCategory)",
            value: Double(count),
            timeframe: timeframe,
            isSignificant: true
        )
    }
    
    private func analyzeTopicFrequency() {
        let moments = fetchKeyMoments(.month)
        var topicFrequency: [String: Int] = [:]
        
        for moment in moments {
            if let topic = moment.topic {
                topicFrequency[topic, default: 0] += 1
            }
        }
        
        let sortedTopics = topicFrequency.sorted { $0.value > $1.value }
        
        DispatchQueue.main.async {
            self.topicStats = sortedTopics.map { topic, count in
                TopicStat(name: topic, frequency: count)
            }
        }
    }
    
    private func calculateTrendStats() {
        let metrics = fetchMetricsWithRatings(.month)
        let totalEntries = metrics.count
        let totalWords = metrics.map(\.totalWords).reduce(0, +)
        let averageDuration = metrics.map(\.totalDuration).reduce(0, +) / Double(max(1, totalEntries))
        
        DispatchQueue.main.async {
            self.trendStats = TrendStats(
                totalEntries: totalEntries,
                totalWords: totalWords,
                averageDuration: averageDuration
            )
        }
    }
    
    private func fetchDayRatings(_ timeframe: Timeframe) -> [(rating: Double, date: Date)] {
        let startDate = Calendar.current.date(byAdding: timeframe.dateComponent, to: Date()) ?? Date()
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DayMetricsEntity")
        fetchRequest.predicate = NSPredicate(format: "date >= %@", startDate as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.compactMap { entity -> (Double, Date)? in
                guard let date = entity.value(forKey: "date") as? Date,
                      let rating = entity.value(forKey: "moodRating") as? Double else { return nil }
                return (rating, date)
            }
        } catch {
            return []
        }
    }
    
    private func fetchMetricsWithRatings(_ timeframe: Timeframe) -> [MetricData] {
        let startDate = Calendar.current.date(byAdding: timeframe.dateComponent, to: Date()) ?? Date()
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DayMetricsEntity")
        fetchRequest.predicate = NSPredicate(format: "date >= %@", startDate as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.compactMap { entity -> MetricData? in
                guard let date = entity.value(forKey: "date") as? Date,
                      let rating = entity.value(forKey: "moodRating") as? Double else { return nil }
                
                return MetricData(
                    date: date,
                    rating: rating,
                    sleepHours: entity.value(forKey: "sleepHours") as? Double,
                    entryCount: entity.value(forKey: "entryCount") as? Int ?? 0,
                    totalWords: entity.value(forKey: "totalWords") as? Int ?? 0,
                    totalDuration: entity.value(forKey: "totalDuration") as? Double ?? 0,
                    fillerWordCount: entity.value(forKey: "fillerWordCount") as? Int ?? 0,
                    timeOfEntry: entity.value(forKey: "timeOfEntry") as? Date
                )
            }
        } catch {
            return []
        }
    }
    
    private func fetchKeyMoments(_ timeframe: Timeframe) -> [KeyMomentData] {
        let startDate = Calendar.current.date(byAdding: timeframe.dateComponent, to: Date()) ?? Date()
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "KeyMomentEntity")
        fetchRequest.predicate = NSPredicate(format: "date >= %@", startDate as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.compactMap { entity -> KeyMomentData? in
                guard let date = entity.value(forKey: "date") as? Date else { return nil }
                
                return KeyMomentData(
                    date: date,
                    content: entity.value(forKey: "content") as? String,
                    associatedMood: entity.value(forKey: "associatedMood") as? Double,
                    topic: entity.value(forKey: "topic") as? String,
                    category: entity.value(forKey: "category") as? String,
                    type: entity.value(forKey: "momentType") as? String ?? ""
                )
            }
        } catch {
            return []
        }
    }
    
    private func analyzeReflectionLength(_ timeframe: Timeframe) -> ReflectionInsight? {
        let metrics = fetchMetricsWithRatings(timeframe)
        let aboveThreshold = metrics.filter { $0.rating > Constants.moodThreshold }
        let belowThreshold = metrics.filter { $0.rating <= Constants.moodThreshold }
        
        guard aboveThreshold.count >= Constants.minimumDataPoints,
              belowThreshold.count >= Constants.minimumDataPoints else { return nil }
        
        let aboveAvgWords = Double(aboveThreshold.map(\.totalWords).reduce(0, +)) / Double(aboveThreshold.count)
        let belowAvgWords = Double(belowThreshold.map(\.totalWords).reduce(0, +)) / Double(belowThreshold.count)
        
        let percentChange = ((aboveAvgWords - belowAvgWords) / belowAvgWords) * 100
        
        // Only return insight if reflections are longer during better moods
        guard percentChange > Constants.significantChangeThreshold else { return nil }
        
        return ReflectionInsight(
            type: .reflectionLength,
            message: "Your reflections tend to be more detailed when feeling better",
            value: percentChange,
            timeframe: timeframe,
            isSignificant: true
        )
    }

    private func analyzeDetailedTopics(_ timeframe: Timeframe) -> ReflectionInsight? {
        let metrics = fetchMetricsWithRatings(timeframe)
        let moments = fetchKeyMoments(timeframe)
        var topicWordCounts: [String: [Int]] = [:]
        
        // Match moments with their corresponding metrics
        for moment in moments {
            guard let topic = moment.topic else { continue }
            if let metric = metrics.first(where: { Calendar.current.isDate($0.date, inSameDayAs: moment.date) }) {
                topicWordCounts[topic, default: []].append(metric.totalWords)
            }
        }
        
        var mostDetailedTopic = ""
        var highestAvgWords = 0.0
        
        for (topic, wordCounts) in topicWordCounts where wordCounts.count >= Constants.minimumDataPoints {
            let avg = Double(wordCounts.reduce(0, +)) / Double(wordCounts.count)
            if avg > highestAvgWords {
                highestAvgWords = avg
                mostDetailedTopic = topic
            }
        }
        
        guard !mostDetailedTopic.isEmpty else { return nil }
        
        return ReflectionInsight(
            type: .topicDetail,
            message: "You share most thoroughly when reflecting on \(mostDetailedTopic)",
            value: highestAvgWords,
            timeframe: timeframe,
            isSignificant: true
        )
    }

    private func analyzeMostCommonTimes(_ timeframe: Timeframe) -> ReflectionInsight? {
        let metrics = fetchMetricsWithRatings(timeframe)
        var hourCounts: [Int: Int] = [:]
        
        for metric in metrics {
            let hour = Calendar.current.component(.hour, from: metric.timeOfEntry ?? Date())
            hourCounts[hour, default: 0] += 1
        }
        
        guard let (mostCommonHour, _) = hourCounts.max(by: { $0.value < $1.value }) else { return nil }
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "ha"
        let hourDate = Calendar.current.date(bySettingHour: mostCommonHour, minute: 0, second: 0, of: Date()) ?? Date()
        let timeString = timeFormatter.string(from: hourDate).lowercased()
        
        return ReflectionInsight(
            type: .commonTime,
            message: "You most often reflect around \(timeString)",
            value: Double(mostCommonHour),
            timeframe: timeframe,
            isSignificant: true
        )
    }
    
    
    private func calculateCorrelation(_ x: [Double], _ y: [Double]) -> Double {
        guard x.count == y.count, x.count > 1 else { return 0 }
        
        let mx = x.reduce(0, +) / Double(x.count)
        let my = y.reduce(0, +) / Double(y.count)
        
        var num = 0.0
        var denx = 0.0
        var deny = 0.0
        
        for i in 0..<x.count {
            let dx = x[i] - mx
            let dy = y[i] - my
            num += dx * dy
            denx += dx * dx
            deny += dy * dy
        }
        
        return num / (sqrt(denx) * sqrt(deny))
    }
    
    private func getMoodLabel(for rating: Double) -> String {
        switch rating {
        case 0...3:
            return "feeling down"
        case 3...4:
            return "not great"
        case 4...6:
            return "okay"
        case 6...8:
            return "pretty good"
        case 8...10:
            return "feeling great"
        default:
            return "okay"
        }
    }
}

struct ReflectionInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let message: String
    let value: Double
    let timeframe: Timeframe
    let isSignificant: Bool
}

enum InsightType {
    case moodTrend
    case sleepPattern
    case topicCorrelation
    case completionPattern
    case fillerPattern
    case timePattern
    case wordCount
    case momentPattern
    case reflectionLength
    case topicDetail
    case commonTime
}

enum Timeframe {
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
}

struct MetricData {
    let date: Date
    let rating: Double
    let sleepHours: Double?
    let entryCount: Int
    let totalWords: Int
    let totalDuration: Double
    let fillerWordCount: Int
    let timeOfEntry: Date?
}

struct KeyMomentData {
    let date: Date
    let content: String?
    let associatedMood: Double?
    let topic: String?
    let category: String?
    let type: String
}

struct TopicStat: Identifiable {
    let id = UUID()
    let name: String
    let frequency: Int
}

struct TrendStats {
    let totalEntries: Int
    let totalWords: Int
    let averageDuration: Double
}
