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
    
    struct CorrelationData: Equatable {
        let name: String
        let effect: Double
        let color: Color
        
        static func == (lhs: CorrelationData, rhs: CorrelationData) -> Bool {
            return lhs.name == rhs.name && lhs.effect == rhs.effect
        }
    }
    
    struct TimeframedCorrelations {
        var topics: [CorrelationData]?
        var sleep: [CorrelationData]?
        var timeOfDay: [CorrelationData]?
        var wordCount: [CorrelationData]?
    }

    @Published private(set) var weekCorrelations = TimeframedCorrelations()
    @Published private(set) var monthCorrelations = TimeframedCorrelations()
    @Published private(set) var yearCorrelations = TimeframedCorrelations()
    
    
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
    
    func fetchAllCorrelations(for timeframe: Timeframe) {
        fetchSleepCorrelations(for: timeframe)
        fetchWordCountCorrelations(for: timeframe)
        fetchTimeCorrelations(for: timeframe)
        fetchTopicCorrelations(for: timeframe)
    }

    func fetchAllCorrelations() {
        for timeframe in Timeframe.allCases {
            fetchAllCorrelations(for: timeframe)
        }
    }
    
    func getCorrelations(for timeframe: Timeframe) -> TimeframedCorrelations {
        switch timeframe {
        case .week:
            return weekCorrelations
        case .month:
            return monthCorrelations
        case .year:
            return yearCorrelations
        }
    }
    
    private func needsToFetchData(for timeframe: Timeframe, category: String) -> Bool {
        let correlations = getCorrelations(for: timeframe)
        switch category {
        case "topics":
            return correlations.topics == nil
        case "sleep":
            return correlations.sleep == nil
        case "timeOfDay":
            return correlations.timeOfDay == nil
        case "wordCount":
            return correlations.wordCount == nil
        default:
            return false
        }
    }
    
    private func updateCorrelations(for timeframe: Timeframe, category: String, data: [CorrelationData]) {
        DispatchQueue.main.async {
            switch timeframe {
            case .week:
                switch category {
                case "topics":
                    self.weekCorrelations.topics = data
                case "sleep":
                    self.weekCorrelations.sleep = data
                case "timeOfDay":
                    self.weekCorrelations.timeOfDay = data
                case "wordCount":
                    self.weekCorrelations.wordCount = data
                default:
                    break
                }
            case .month:
                switch category {
                case "topics":
                    self.monthCorrelations.topics = data
                case "sleep":
                    self.monthCorrelations.sleep = data
                case "timeOfDay":
                    self.monthCorrelations.timeOfDay = data
                case "wordCount":
                    self.monthCorrelations.wordCount = data
                default:
                    break
                }
            case .year:
                switch category {
                case "topics":
                    self.yearCorrelations.topics = data
                case "sleep":
                    self.yearCorrelations.sleep = data
                case "timeOfDay":
                    self.yearCorrelations.timeOfDay = data
                case "wordCount":
                    self.yearCorrelations.wordCount = data
                default:
                    break
                }
            }
        }
    }

    func refreshInsights() {
        let timeframes: [Timeframe] = [.week, .month, .year]
        var newInsights: [ReflectionInsight] = []
        
//        for timeframe in timeframes {
//            if let moodTrend = analyzeMoodTrend(timeframe) {
//                newInsights.append(moodTrend)
//            }
//            
//            if let sleepCorrelation = analyzeSleepCorrelation(timeframe) {
//                newInsights.append(sleepCorrelation)
//            }
//            
//            if let topicMood = analyzeTopicMoodCorrelation(timeframe) {
//                newInsights.append(topicMood)
//            }
//            
//            if let completionPattern = analyzeCompletionPattern(timeframe) {
//                newInsights.append(completionPattern)
//            }
//            
//            if let fillerPattern = analyzeFillerWordPattern(timeframe) {
//                newInsights.append(fillerPattern)
//            }
//            
//            if let timePattern = analyzeTimeOfDayPattern(timeframe) {
//                newInsights.append(timePattern)
//            }
//            
//            if let wordCountTrend = analyzeWordCountTrend(timeframe) {
//                newInsights.append(wordCountTrend)
//            }
//            
//            if let momentPattern = analyzeKeyMomentPattern(timeframe) {
//                newInsights.append(momentPattern)
//            }
//            
//            if let lengthPattern = analyzeReflectionLength(timeframe) {
//                newInsights.append(lengthPattern)
//            }
//            
//            if let detailedTopics = analyzeDetailedTopics(timeframe) {
//                newInsights.append(detailedTopics)
//            }
//            
//            if let commonTimes = analyzeMostCommonTimes(timeframe) {
//                newInsights.append(commonTimes)
//            }
//    
//        }
//        
//        analyzeTopicFrequency()
//        calculateTrendStats()
        
    }
    
    private func getAverageMoodRating(for date: Date) -> Double? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return nil
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "ReflectionEntity")
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@ AND moodRating != nil",
                                           startOfDay as NSDate,
                                           endOfDay as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            let ratings = results.compactMap { entity -> Double? in
                return entity.value(forKey: "moodRating") as? Double
            }
            
            guard !ratings.isEmpty else { return nil }
            return ratings.reduce(0, +) / Double(ratings.count)
        } catch {
            print("Error fetching mood ratings: \(error)")
            return nil
        }
    }
    
    private func getAverageMoodRatings(_ timeframe: Timeframe) -> [Date: Double] {
        let calendar = Calendar.current
        let now = Date()
        
        guard let startDate = calendar.date(byAdding: timeframe.dateComponent, to: now) else {
            return [:]
        }
        
        var currentDate = startDate
        var moodsByDate: [Date: Double] = [:]
        
        while currentDate <= now {
            if let averageMood = getAverageMoodRating(for: currentDate) {
                let normalizedDate = calendar.startOfDay(for: currentDate)
                moodsByDate[normalizedDate] = averageMood
            }
            
            // Advance to next day
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }
        
        return moodsByDate
    }
    
    private func getDailyMetrics(for timeframe: Timeframe) -> [(date: Date, mood: Double, sleep: Double?, wordCount: Int, topic: String?)] {
        let calendar = Calendar.current
        let now = Date()
        guard let startDate = calendar.date(byAdding: timeframe.dateComponent, to: now) else {
            return []
        }
        
        var metrics: [(date: Date, mood: Double, sleep: Double?, wordCount: Int, topic: String?)] = []
        var currentDate = startDate
        
        while currentDate <= now {
            if let averageMood = getAverageMoodRating(for: currentDate) {

                let startOfDay = calendar.startOfDay(for: currentDate)
                guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                    continue
                }
                
                let dayMetricsFetch = NSFetchRequest<NSManagedObject>(entityName: "DayMetricsEntity")
                dayMetricsFetch.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                                   startOfDay as NSDate,
                                                   endOfDay as NSDate)
                
                // Fetch StandoutTopic
                let topicFetch = NSFetchRequest<NSManagedObject>(entityName: "StandoutTopicMetric")
                topicFetch.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                                 startOfDay as NSDate,
                                                 endOfDay as NSDate)
                
                do {
                    let dayResults = try context.fetch(dayMetricsFetch)
                    let topicResults = try context.fetch(topicFetch)
                    
                    let sleep = dayResults.first?.value(forKey: "sleepHours") as? Double
                    let wordCount = dayResults.first?.value(forKey: "totalWords") as? Int ?? 0
                    let topic = topicResults.first?.value(forKey: "topic") as? String
                    
                    metrics.append((
                        date: startOfDay,
                        mood: averageMood,
                        sleep: sleep,
                        wordCount: wordCount,
                        topic: topic
                    ))
                } catch {
                    print("Error fetching metrics: \(error)")
                }
                
                guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                    break
                }
                currentDate = nextDate
            }
        }
        
        return metrics
    }
    
    // MARK: - Correlation Analysis Methods
    private func fetchSleepCorrelations(for timeframe: Timeframe) {
        guard needsToFetchData(for: timeframe, category: "sleep") else {
            return
        }
        
        let metrics = getDailyMetrics(for: timeframe)
        
        // Group metrics by sleep duration categories
        var lessThan5: [Double] = []
        var between6And8: [Double] = []
        var moreThan9: [Double] = []
        
        for metric in metrics {
            guard let sleep = metric.sleep else { continue }
            
            if sleep < 5 {
                lessThan5.append(metric.mood)
            } else if sleep >= 6 && sleep <= 8 {
                between6And8.append(metric.mood)
            } else if sleep > 9 {
                moreThan9.append(metric.mood)
            }
        }
        
        // Calculate average mood effect for each category
        let correlations = [
            CorrelationData(
                name: "< 5 hours",
                effect: lessThan5.isEmpty ? 0 : (lessThan5.reduce(0, +) / Double(lessThan5.count) - 7),
                color: Color(hex: "B5D5E2")
            ),
            CorrelationData(
                name: "6-8 hours",
                effect: between6And8.isEmpty ? 0 : (between6And8.reduce(0, +) / Double(between6And8.count) - 7),
                color: Color(hex: "A28497")
            ),
            CorrelationData(
                name: "9+ hours",
                effect: moreThan9.isEmpty ? 0 : (moreThan9.reduce(0, +) / Double(moreThan9.count) - 7),
                color: Color(hex: "93A7BB")
            )
        ]
        
        updateCorrelations(for: timeframe, category: "sleep", data: correlations)
    }
    
    private func fetchWordCountCorrelations(for timeframe: Timeframe) {
        guard needsToFetchData(for: timeframe, category: "wordCount") else {
            return
        }
        
        let metrics = getDailyMetrics(for: timeframe)
        
        // Group metrics by word count categories
        var shortEntries: [Double] = []
        var mediumEntries: [Double] = []
        var longEntries: [Double] = []
        
        // First find percentile thresholds for better categorization
        let wordCounts = metrics.map { $0.wordCount }.sorted()
        guard !wordCounts.isEmpty else { return }
        
        let thirtyThreePercentile = wordCounts[wordCounts.count / 3]
        let sixtySevenPercentile = wordCounts[2 * wordCounts.count / 3]
        
        for metric in metrics {
            // Categorize based on percentiles for more even distribution
            if metric.wordCount <= thirtyThreePercentile {
                shortEntries.append(metric.mood)
            } else if metric.wordCount <= sixtySevenPercentile {
                mediumEntries.append(metric.mood)
            } else {
                longEntries.append(metric.mood)
            }
        }
        
        // Calculate average mood effect for each category (relative to neutral mood of 7)
        let correlations = [
            CorrelationData(
                name: "Brief",
                effect: shortEntries.isEmpty ? 0 : (shortEntries.reduce(0, +) / Double(shortEntries.count) - 7),
                color: Color(hex: "B5D5E2")
            ),
            CorrelationData(
                name: "Medium",
                effect: mediumEntries.isEmpty ? 0 : (mediumEntries.reduce(0, +) / Double(mediumEntries.count) - 7),
                color: Color(hex: "A28497")
            ),
            CorrelationData(
                name: "Detailed",
                effect: longEntries.isEmpty ? 0 : (longEntries.reduce(0, +) / Double(longEntries.count) - 7),
                color: Color(hex: "93A7BB")
            )
        ]
        
        updateCorrelations(for: timeframe, category: "wordCount", data: correlations)
    }
    
    private func fetchTimeCorrelations(for timeframe: Timeframe) {
        guard needsToFetchData(for: timeframe, category: "timeOfDay") else {
            return
        }
        
        let metrics = getDailyMetrics(for: timeframe)
        var hourlyMoods: [Int: [Double]] = [:]
        
        for metric in metrics {
            let timeOfEntry = metric.date
            
            // Round to nearest hour (0-23)
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: timeOfEntry)
            let minute = calendar.component(.minute, from: timeOfEntry)
            let roundedHour = (minute >= 30) ?
                (hour + 1) % 24 :
                hour
            
            hourlyMoods[roundedHour, default: []].append(metric.mood)
        }
        
        // Calculate average mood for each hour
        var hourlyEffects: [(hour: Int, effect: Double)] = []
        for (hour, moods) in hourlyMoods {
            let avgMood = moods.reduce(0, +) / Double(moods.count)
            let effect = avgMood - 7  // Effect relative to neutral mood
            hourlyEffects.append((hour: hour, effect: effect))
        }
        
        // Sort by effect
        hourlyEffects.sort { $0.effect < $1.effect }
        
        guard !hourlyEffects.isEmpty else { return }
        
        // Get worst, middle, and best times
        let worst = hourlyEffects.first!
        let best = hourlyEffects.last!
        let middle = hourlyEffects[hourlyEffects.count / 2]
        
        // Format hours for display
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        
        func formatHour(_ hour: Int) -> String {
            let date = Calendar.current.date(from: DateComponents(hour: hour))!
            return formatter.string(from: date).lowercased()
        }
        
        let correlations = [
            CorrelationData(
                name: formatHour(worst.hour),
                effect: worst.effect,
                color: Color(hex: "B5D5E2")
            ),
            CorrelationData(
                name: formatHour(middle.hour),
                effect: middle.effect,
                color: Color(hex: "A28497")
            ),
            CorrelationData(
                name: formatHour(best.hour),
                effect: best.effect,
                color: Color(hex: "93A7BB")
            )
        ]
        
        updateCorrelations(for: timeframe, category: "timeOfDay", data: correlations)
    }
    
    private func fetchTopicCorrelations(for timeframe: Timeframe) {
        guard needsToFetchData(for: timeframe, category: "topics") else {
            return
        }
        
        let metrics = getDailyMetrics(for: timeframe)
        var topicMoods: [String: [Double]] = [:] // [topic: [moods]]
        
        // Collect moods for each topic
        for metric in metrics {
            guard let topic = metric.topic else { continue }
            topicMoods[topic, default: []].append(metric.mood)
        }
        
        // Calculate average effect for each topic
        var topicEffects: [(topic: String, effect: Double)] = []
        for (topic, moods) in topicMoods {
            guard moods.count >= 3 else { continue } // Need minimum sample size
            let avgMood = moods.reduce(0, +) / Double(moods.count)
            let effect = avgMood - 7  // Effect relative to neutral mood
            topicEffects.append((topic: topic, effect: effect))
        }
        
        // Sort by effect
        topicEffects.sort { $0.effect < $1.effect }
        
        guard topicEffects.count >= 3 else { return }
        
        // Get worst, middle, and best topics
        let worst = topicEffects.first!
        let best = topicEffects.last!
        
        // For middle, find the topic with effect closest to 0 (neutral)
        let middle = topicEffects.min { abs($0.effect) < abs($1.effect) } ?? topicEffects[topicEffects.count / 2]
        
        let correlations = [
            CorrelationData(
                name: worst.topic,
                effect: worst.effect,
                color: Color(hex: "B5D5E2")
            ),
            CorrelationData(
                name: middle.topic,
                effect: middle.effect,
                color: Color(hex: "A28497")
            ),
            CorrelationData(
                name: best.topic,
                effect: best.effect,
                color: Color(hex: "93A7BB")
            )
        ]
        
        updateCorrelations(for: timeframe, category: "topics", data: correlations)
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
