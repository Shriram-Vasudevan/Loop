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
    
    @Published private(set) var isLoading = false
        
    private var cachedMetrics: [Timeframe: [(date: Date, mood: Double, sleep: Double?, wordCount: Int, topic: String?)]] = [:]
    
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
    
    func fetchAllCorrelations(for timeframe: Timeframe) async {
        await MainActor.run {
            isLoading = true
        }
        
        // Fetch metrics once and reuse
        let metrics = await getDailyMetrics(for: timeframe)
        
        async let sleepCorr = fetchSleepCorrelations(for: timeframe, metrics: metrics)
        async let wordCountCorr = fetchWordCountCorrelations(for: timeframe, metrics: metrics)
        async let timeCorr = fetchTimeCorrelations(for: timeframe, metrics: metrics)
        async let topicCorr = fetchTopicCorrelations(for: timeframe, metrics: metrics)
        
        // Wait for all correlations to complete
        let _ = await [sleepCorr, wordCountCorr, timeCorr, topicCorr]
        
        await MainActor.run {
            isLoading = false
        }
    }


    func fetchAllCorrelations() async {
        for timeframe in Timeframe.allCases {
            await fetchAllCorrelations(for: timeframe)
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
    
    func hasEnoughDataPoints(_ metrics: [(date: Date, mood: Double, sleep: Double?, wordCount: Int, topic: String?)], category: AnalysisCategory) -> Bool {
        switch category {
            case .topics:
                let topicCounts = Dictionary(grouping: metrics.compactMap { $0.topic }, by: { $0 })
                return topicCounts.values.contains { $0.count >= 3 }
                
            case .sleep:
                return metrics.compactMap { $0.sleep }.count >= 3
                
            case .timeOfDay:
                return metrics.count >= 3
            case .wordCount:
                return metrics.count >= 3
        }
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
    
    private func getAverageMoodRatings(_ timeframe: Timeframe) -> [Date: Double] {
        let calendar = Calendar.current
        let now = Date()
        
        guard let startDate = calendar.date(byAdding: timeframe.dateComponent, to: now) else {
            return [:]
        }
        
        var currentDate = startDate
        var moodsByDate: [Date: Double] = [:]
        
        while currentDate <= now {
            if let averageMood = getAverageMoodRating(for: currentDate, context: self.context) {
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
    
    func getDailyMetrics(for timeframe: Timeframe) async -> [(date: Date, mood: Double, sleep: Double?, wordCount: Int, topic: String?)] {
        if let cached = cachedMetrics[timeframe] {
            return cached
        }
        
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
                        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                            continue
                        }
                        
                        let dayMetricsFetch = NSFetchRequest<NSManagedObject>(entityName: "DayMetricsEntity")
                        dayMetricsFetch.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                                           startOfDay as NSDate,
                                                           endOfDay as NSDate)
                        
                        let topicFetch = NSFetchRequest<NSManagedObject>(entityName: "StandoutTopicEntity")
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
                    }
                    
                    guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                        break
                    }
                    currentDate = nextDate
                }
                
                // Cache the results
                self.cachedMetrics[timeframe] = metrics
                continuation.resume(returning: metrics)
            }
        }
    }
    
    private func fetchSleepCorrelations(for timeframe: Timeframe, metrics: [(date: Date, mood: Double, sleep: Double?, wordCount: Int, topic: String?)]) async {
        guard needsToFetchData(for: timeframe, category: "sleep") else {
            return
        }
    
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
        
        await MainActor.run {
            updateCorrelations(for: timeframe, category: "sleep", data: correlations)
        }
    }
    
    private func fetchWordCountCorrelations(for timeframe: Timeframe, metrics: [(date: Date, mood: Double, sleep: Double?, wordCount: Int, topic: String?)]) async {
        guard needsToFetchData(for: timeframe, category: "wordCount") else { return }
        guard metrics.count >= 3 else { return }
        
        let wordCounts = metrics.map { $0.wordCount }.sorted()
        let thirtyThreePercentile = wordCounts[max(0, wordCounts.count / 3 - 1)]
        let sixtySevenPercentile = wordCounts[max(0, 2 * wordCounts.count / 3 - 1)]
        
        var shortEntries: [Double] = []
        var mediumEntries: [Double] = []
        var longEntries: [Double] = []
        
        for metric in metrics {
            if metric.wordCount <= thirtyThreePercentile {
                shortEntries.append(metric.mood)
            } else if metric.wordCount <= sixtySevenPercentile {
                mediumEntries.append(metric.mood)
            } else {
                longEntries.append(metric.mood)
            }
        }

        guard shortEntries.count >= 1 && mediumEntries.count >= 1 && longEntries.count >= 1 else { return }
        
        let baselineMood = metrics.map { $0.mood }.reduce(0, +) / Double(metrics.count)
        
        let correlations = [
            CorrelationData(
                name: "Brief",
                effect: (shortEntries.reduce(0, +) / Double(shortEntries.count)) - baselineMood,
                color: Color(hex: "B5D5E2")
            ),
            CorrelationData(
                name: "Medium",
                effect: (mediumEntries.reduce(0, +) / Double(mediumEntries.count)) - baselineMood,
                color: Color(hex: "A28497")
            ),
            CorrelationData(
                name: "Detailed",
                effect: (longEntries.reduce(0, +) / Double(longEntries.count)) - baselineMood,
                color: Color(hex: "93A7BB")
            )
        ]
        
        await MainActor.run {
            updateCorrelations(for: timeframe, category: "wordCount", data: correlations)
        }
    }
    
    private func fetchTimeCorrelations(for timeframe: Timeframe, metrics: [(date: Date, mood: Double, sleep: Double?, wordCount: Int, topic: String?)]) async {
        guard needsToFetchData(for: timeframe, category: "timeOfDay") else { return }
        guard hasEnoughDataPoints(metrics, category: .timeOfDay) else { return }


        guard metrics.count >= 3 else { return }
        
        let calendar = Calendar.current
        var hourlyMoods: [Int: [Double]] = [:]

        for metric in metrics {
            let hour = calendar.component(.hour, from: metric.date)
            hourlyMoods[hour, default: []].append(metric.mood)
        }
        
        var hourlyEffects: [(hour: Int, effect: Double)] = []
        let baselineMood = metrics.map { $0.mood }.reduce(0, +) / Double(metrics.count)

        for (hour, moods) in hourlyMoods {
            let avgMood = moods.reduce(0, +) / Double(moods.count)
            let effect = avgMood - baselineMood
            hourlyEffects.append((hour: hour, effect: effect))
        }
        
        hourlyEffects.sort { $0.effect < $1.effect }
        
        let correlations: [CorrelationData]
        
        if hourlyEffects.count == 1 {
            correlations = [
                CorrelationData(
                    name: formatHour(hourlyEffects[0].hour),
                    effect: hourlyEffects[0].effect,
                    color: Color(hex: "A28497")
                )
            ]
        } else if hourlyEffects.count == 2 {
            correlations = [
                CorrelationData(
                    name: formatHour(hourlyEffects[0].hour),
                    effect: hourlyEffects[0].effect,
                    color: Color(hex: "B5D5E2")
                ),
                CorrelationData(
                    name: formatHour(hourlyEffects[1].hour),
                    effect: hourlyEffects[1].effect,
                    color: Color(hex: "93A7BB")
                )
            ]
        } else {
            correlations = [
                CorrelationData(
                    name: formatHour(hourlyEffects.first?.hour ?? 0),
                    effect: hourlyEffects.first?.effect ?? 0,
                    color: Color(hex: "B5D5E2")
                ),
                CorrelationData(
                    name: formatHour(hourlyEffects[hourlyEffects.count / 2].hour),
                    effect: hourlyEffects[hourlyEffects.count / 2].effect,
                    color: Color(hex: "A28497")
                ),
                CorrelationData(
                    name: formatHour(hourlyEffects.last?.hour ?? 0),
                    effect: hourlyEffects.last?.effect ?? 0,
                    color: Color(hex: "93A7BB")
                )
            ]
        }
        
        await MainActor.run {
            updateCorrelations(for: timeframe, category: "timeOfDay", data: correlations)
        }
    }
    
    func formatHour(_ hour: Int) -> String {
        let dateComponents = DateComponents(hour: hour)
        if let date = Calendar.current.date(from: dateComponents) {
            let formatter = DateFormatter()
            formatter.dateFormat = "ha"
            return formatter.string(from: date).lowercased()
        }
        return "\(hour)am"
    }
    
    private func fetchTopicCorrelations(for timeframe: Timeframe, metrics: [(date: Date, mood: Double, sleep: Double?, wordCount: Int, topic: String?)]) async {
        guard needsToFetchData(for: timeframe, category: "topics") else { return }
        guard hasEnoughDataPoints(metrics, category: .topics) else { return }
        
        var topicMoods: [String: [Double]] = [:]
        for metric in metrics {
            guard let topic = metric.topic else { continue }
            topicMoods[topic, default: []].append(metric.mood)
        }
        
        let baselineMood = metrics.map { $0.mood }.reduce(0, +) / Double(metrics.count)

        var topicEffects: [(topic: String, effect: Double)] = []
        for (topic, moods) in topicMoods {
            let avgMood = moods.reduce(0, +) / Double(moods.count)
            let effect = avgMood - baselineMood
            topicEffects.append((topic: topic, effect: effect))
        }

        topicEffects.sort { $0.effect < $1.effect }

        let correlations: [CorrelationData]
        
        if topicEffects.count == 1 {
            correlations = [
                CorrelationData(
                    name: topicEffects[0].topic,
                    effect: topicEffects[0].effect,
                    color: Color(hex: "A28497")
                )
            ]
        } else if topicEffects.count == 2 {
            correlations = [
                CorrelationData(
                    name: topicEffects[0].topic,
                    effect: topicEffects[0].effect,
                    color: Color(hex: "B5D5E2")
                ),
                CorrelationData(
                    name: topicEffects[1].topic,
                    effect: topicEffects[1].effect,
                    color: Color(hex: "93A7BB")
                )
            ]
        } else {
            correlations = [
                CorrelationData(
                    name: topicEffects.first?.topic ?? "",
                    effect: topicEffects.first?.effect ?? 0,
                    color: Color(hex: "B5D5E2")
                ),
                CorrelationData(
                    name: topicEffects[topicEffects.count / 2].topic,
                    effect: topicEffects[topicEffects.count / 2].effect,
                    color: Color(hex: "A28497")
                ),
                CorrelationData(
                    name: topicEffects.last?.topic ?? "",
                    effect: topicEffects.last?.effect ?? 0,
                    color: Color(hex: "93A7BB")
                )
            ]
        }
        
        await MainActor.run {
            updateCorrelations(for: timeframe, category: "topics", data: correlations)
        }
    }
    
    func analyzeSleepEffect(for timeframe: Timeframe) async -> (message: String, effectLine: String)? {
        let metrics = await getDailyMetrics(for: timeframe)
        
        var belowRecommended: [Double] = []
        var recommended: [Double] = []
        var aboveRecommended: [Double] = []
        
        for metric in metrics {
            guard let sleep = metric.sleep else { continue }
            let mood = metric.mood
            
            if sleep < 7 {
                belowRecommended.append(mood)
            } else if sleep <= 9 {
                recommended.append(mood)
            } else {
                aboveRecommended.append(mood)
            }
        }
        
        let totalEntries = belowRecommended.count + recommended.count + aboveRecommended.count
        guard totalEntries >= 3 else {
            return (
                message: "Not enough sleep data",
                effectLine: "Track more sleep to see insights"
            )
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
        
        guard !ranges.isEmpty else { return nil }
        
        let bestRange = ranges.max(by: { $0.effect < $1.effect })!
        let effectPercentage = abs(Int(round(bestRange.effect)))
        
        switch bestRange.name {
        case "insufficient":
            if bestRange.effect > 0 {
                return (
                    message: "Sleep patterns need attention",
                    effectLine: "While your mood is \(effectPercentage)% higher with less sleep, 7-9 hours is recommended for health"
                )
            } else {
                return (
                    message: "Less sleep affects your mood",
                    effectLine: "Your mood is \(effectPercentage)% lower with insufficient sleep"
                )
            }
            
        case "recommended":
            return (
                message: "Optimal sleep = better mood",
                effectLine: "Your mood is \(effectPercentage)% higher with 7-9 hours of sleep"
            )
            
        case "excessive":
            if bestRange.effect > 0 {
                return (
                    message: "More sleep, better mood?",
                    effectLine: "While your mood is \(effectPercentage)% higher with extra sleep, aim for 7-9 hours for best health"
                )
            } else {
                return (
                    message: "Too much sleep may affect mood",
                    effectLine: "Your mood is \(effectPercentage)% lower with excessive sleep"
                )
            }
        default:
            let avgSleep = average(metrics.compactMap { $0.sleep }) ?? 0
            return (
                message: "Your average sleep",
                effectLine: "\(String(format: "%.1f", avgSleep)) hours per night"
            )
        }
    }
    
    func getPositiveTopics(for timeframe: Timeframe) async -> [String] {
        let metrics = await getDailyMetrics(for: timeframe)
        var topicMoods: [String: [Double]] = [:]
        
        for metric in metrics {
            guard let topic = metric.topic else { continue }
            topicMoods[topic, default: []].append(metric.mood)
        }
        
        return topicMoods.compactMap { topic, moods in
            let avgMood = moods.reduce(0, +) / Double(moods.count)
            return avgMood > 5 ? topic : nil
        }
    }
    
    func getNegativeTopics(for timeframe: Timeframe) async -> [String] {
        let metrics = await getDailyMetrics(for: timeframe)
        var topicMoods: [String: [Double]] = [:]
        
        for metric in metrics {
            guard let topic = metric.topic else { continue }
            topicMoods[topic, default: []].append(metric.mood)
        }
        
        return topicMoods.compactMap { topic, moods in
            let avgMood = moods.reduce(0, +) / Double(moods.count)
            return avgMood <= 5 ? topic : nil
        }
    }

    
    private func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
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
