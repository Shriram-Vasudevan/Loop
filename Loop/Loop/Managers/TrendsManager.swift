//
//  TrendsManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/19/25.
//

import Foundation
import SwiftUI
import CoreData

class TrendsManager: ObservableObject {
    static let shared = TrendsManager()
    
    private struct Constants {
        static let moodThreshold = 6.0
        static let minimumDataPoints = 3
        static let sadColor = "1E3D59"
        static let neutralColor = "94A7B7"
        static let happyColor = "B784A7"
    }
    
    @Published private(set) var insights: [MoodInsight] = []
    
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
        print("[TrendsManager] Refreshing insights")
        let timeframes: [Timeframe] = [.week, .month, .year]
        
        var newInsights: [MoodInsight] = []
        
        for timeframe in timeframes {
            if let averageMoodInsight = calculateAverageMoodInsight(timeframe) {
                newInsights.append(averageMoodInsight)
            }
            
            if let sleepInsight = calculateSleepImpactInsight(timeframe) {
                newInsights.append(sleepInsight)
            }
            
            if let topicInsight = calculateTopicCorrelationInsight(timeframe) {
                newInsights.append(topicInsight)
            }
            
            if let completionInsight = calculateEntryCompletionInsight(timeframe) {
                newInsights.append(completionInsight)
            }
            
            if let fillerInsight = calculateFillerTrendInsight(timeframe) {
                newInsights.append(fillerInsight)
            }
        }
        
        DispatchQueue.main.async {
            self.insights = newInsights
        }
    }
    
    // MARK: - Data Fetching
    private func fetchDayRatings(for timeframe: Timeframe) -> [DayRating] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: timeframe.dateRange, to: Date()) ?? Date()
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DailyCheckinEntity")
        fetchRequest.predicate = NSPredicate(format: "date >= %@", startDate as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.map { entity in
                DayRating(
                    rating: entity.value(forKey: "rating") as? Double ?? 0.0,
                    date: entity.value(forKey: "date") as? Date ?? Date()
                )
            }
        } catch {
            print("[TrendsManager] Failed to fetch day ratings: \(error)")
            return []
        }
    }
    
    private func fetchMetrics(for timeframe: Timeframe) -> [DayMetrics] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: timeframe.dateRange, to: Date()) ?? Date()
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DayMetrics")
        fetchRequest.predicate = NSPredicate(format: "date >= %@", startDate as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.compactMap { entity -> DayMetrics? in
                guard let date = entity.value(forKey: "date") as? Date else { return nil }
                return DayMetrics(
                    date: date,
                    sleepHours: entity.value(forKey: "sleepHours") as? Double,
                    entryCount: entity.value(forKey: "entryCount") as? Int ?? 0,
                    totalWords: entity.value(forKey: "totalWords") as? Int ?? 0,
                    totalDuration: entity.value(forKey: "totalDuration") as? Double ?? 0,
                    fillerWordCount: entity.value(forKey: "fillerWordCount") as? Int ?? 0,
                    primaryTopic: entity.value(forKey: "primaryTopic") as? String
                )
            }
        } catch {
            print("[TrendsManager] Failed to fetch metrics: \(error)")
            return []
        }
    }
    
    // MARK: - Insight Calculations
    private func calculateAverageMoodInsight(_ timeframe: Timeframe) -> MoodInsight? {
        let ratings = fetchDayRatings(for: timeframe)
        guard ratings.count >= timeframe.minimumDataPoints else { return nil }
        
        let averageRating = ratings.map(\.rating).reduce(0, +) / Double(ratings.count)
        let color = getColorForRating(averageRating)
        let moodLabel = getMoodDescription(for: averageRating)
        
        return MoodInsight(
            type: .averageMood,
            message: "You've been feeling \(moodLabel) (\(String(format: "%.1f", averageRating)) average)",
            value: averageRating,
            colorHex: color,
            isSignificant: true,
            timeframe: timeframe
        )
    }
    
    private func calculateSleepImpactInsight(_ timeframe: Timeframe) -> MoodInsight? {
        let ratings = fetchDayRatings(for: timeframe)
        let metrics = fetchMetrics(for: timeframe)
        
        guard ratings.count >= timeframe.minimumDataPoints,
              metrics.count >= timeframe.minimumDataPoints else { return nil }
        
        // Pair ratings with sleep data
        let pairs = zip(ratings, metrics).filter { $0.1.sleepHours != nil }
        let aboveThreshold = pairs.filter { $0.0.rating > Constants.moodThreshold }
        let belowThreshold = pairs.filter { $0.0.rating <= Constants.moodThreshold }
        
        guard aboveThreshold.count >= Constants.minimumDataPoints,
              belowThreshold.count >= Constants.minimumDataPoints else { return nil }
        
        let aboveAvgSleep = aboveThreshold.map { $0.1.sleepHours ?? 0 }.reduce(0, +) / Double(aboveThreshold.count)
        let belowAvgSleep = belowThreshold.map { $0.1.sleepHours ?? 0 }.reduce(0, +) / Double(belowThreshold.count)
        
        let percentDifference = ((aboveAvgSleep - belowAvgSleep) / belowAvgSleep) * 100
        
        return MoodInsight(
            type: .sleepImpact,
            message: "Your ratings are \(String(format: "%.0f", abs(percentDifference)))% \(percentDifference > 0 ? "higher" : "lower") when you sleep more",
            value: percentDifference,
            colorHex: Constants.happyColor,
            isSignificant: true,
            timeframe: timeframe
        )
    }
    
    private func calculateTopicCorrelationInsight(_ timeframe: Timeframe) -> MoodInsight? {
        let ratings = fetchDayRatings(for: timeframe)
        let metrics = fetchMetrics(for: timeframe)
        
        guard ratings.count >= timeframe.minimumDataPoints else { return nil }
        
        // Group by topic and calculate average rating
        var topicRatings: [String: [Double]] = [:]
        for (rating, metric) in zip(ratings, metrics) {
            guard let topic = metric.primaryTopic else { continue }
            topicRatings[topic, default: []].append(rating.rating)
        }
        
        // Find topic with highest average rating
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
        
        return MoodInsight(
            type: .topicCorrelation,
            message: "You rate highest when reflecting about '\(highestTopic)' (\(String(format: "%.1f", highestAvg)) average)",
            value: highestAvg,
            colorHex: getColorForRating(highestAvg),
            isSignificant: true,
            timeframe: timeframe
        )
    }
    
    private func calculateEntryCompletionInsight(_ timeframe: Timeframe) -> MoodInsight? {
        let ratings = fetchDayRatings(for: timeframe)
        let metrics = fetchMetrics(for: timeframe)
        
        guard ratings.count >= timeframe.minimumDataPoints else { return nil }
        
        let pairs = zip(ratings, metrics)
        let aboveThreshold = pairs.filter { $0.0.rating > Constants.moodThreshold }
        let belowThreshold = pairs.filter { $0.0.rating <= Constants.moodThreshold }
        
        guard aboveThreshold.count >= Constants.minimumDataPoints,
              belowThreshold.count >= Constants.minimumDataPoints else { return nil }
        
        let aboveAvgEntries = aboveThreshold.map { $0.1.entryCount }.reduce(0, +) / aboveThreshold.count
        let belowAvgEntries = belowThreshold.map { $0.1.entryCount }.reduce(0, +) / belowThreshold.count
        
        let ratio = Double(aboveAvgEntries) / Double(belowAvgEntries)
        
        return MoodInsight(
            type: .entryCompletion,
            message: "You make \(String(format: "%.1f", ratio))x more entries when rating above \(Constants.moodThreshold)",
            value: ratio,
            colorHex: Constants.happyColor,
            isSignificant: true,
            timeframe: timeframe
        )
    }
    
    private func calculateFillerTrendInsight(_ timeframe: Timeframe) -> MoodInsight? {
        let ratings = fetchDayRatings(for: timeframe)
        let metrics = fetchMetrics(for: timeframe)
        
        guard ratings.count >= timeframe.minimumDataPoints else { return nil }
        
        let pairs = zip(ratings, metrics)
        let aboveThreshold = pairs.filter { $0.0.rating > Constants.moodThreshold }
        let belowThreshold = pairs.filter { $0.0.rating <= Constants.moodThreshold }
        
        guard aboveThreshold.count >= Constants.minimumDataPoints,
              belowThreshold.count >= Constants.minimumDataPoints else { return nil }
        
        let aboveAvgFillers = aboveThreshold.map { $0.1.fillerWordCount }.reduce(0, +) / aboveThreshold.count
        let belowAvgFillers = belowThreshold.map { $0.1.fillerWordCount }.reduce(0, +) / belowThreshold.count
        
        let percentChange = ((Double(aboveAvgFillers) - Double(belowAvgFillers)) / Double(belowAvgFillers)) * 100
        
        return MoodInsight(
            type: .fillerTrend,
            message: "Your filler word usage \(percentChange > 0 ? "increases" : "drops") \(String(format: "%.0f", abs(percentChange)))% when you're feeling great",
            value: percentChange,
            colorHex: Constants.neutralColor,
            isSignificant: true,
            timeframe: timeframe
        )
    }
    
    func getDetailedTopicAnalysis(timeframe: Timeframe) -> [TopicStats]? {
        let ratings = fetchDayRatings(for: timeframe)
        let metrics = fetchMetrics(for: timeframe)
        
        guard ratings.count >= timeframe.minimumDataPoints else { return nil }
        
        var topicData: [String: (ratings: [Double], count: Int)] = [:]
        
        // Group data by topic
        for (rating, metric) in zip(ratings, metrics) {
            guard let topic = metric.primaryTopic else { continue }
            topicData[topic, default: ([], 0)].ratings.append(rating.rating)
            topicData[topic, default: ([], 0)].count += 1
        }
        
        // Convert to stats
        return topicData.compactMap { topic, data in
            guard data.ratings.count >= Constants.minimumDataPoints else { return nil }
            return TopicStats(
                topicName: topic,
                frequency: data.count,
                averageRating: data.ratings.reduce(0, +) / Double(data.ratings.count),
                totalEntries: data.count
            )
        }
        .sorted { $0.frequency > $1.frequency }
    }
    
    func getDetailedSleepAnalysis(timeframe: Timeframe) -> SleepStats? {
        let ratings = fetchDayRatings(for: timeframe)
        let metrics = fetchMetrics(for: timeframe)
        
        guard ratings.count >= timeframe.minimumDataPoints else { return nil }
        
        let pairs = zip(ratings, metrics)
            .filter { $0.1.sleepHours != nil }
            .sorted { $0.0.rating > $1.0.rating }
        
        guard pairs.count >= Constants.minimumDataPoints else { return nil }
        
        let avgHours = pairs.compactMap { $0.1.sleepHours }.reduce(0, +) / Double(pairs.count)
        let topRated = pairs.prefix(Constants.minimumDataPoints).compactMap { $0.1.sleepHours }.reduce(0, +) / Double(Constants.minimumDataPoints)
        let lowRated = pairs.suffix(Constants.minimumDataPoints).compactMap { $0.1.sleepHours }.reduce(0, +) / Double(Constants.minimumDataPoints)
        
        let correlation = ((topRated - lowRated) / lowRated) * 100
        
        return SleepStats(
            averageHours: avgHours,
            highestRatedHours: topRated,
            lowestRatedHours: lowRated,
            ratingCorrelation: correlation
        )
    }
    
    func getDetailedFillerAnalysis(timeframe: Timeframe) -> FillerStats? {
        let ratings = fetchDayRatings(for: timeframe)
        let metrics = fetchMetrics(for: timeframe)
        
        guard ratings.count >= timeframe.minimumDataPoints else { return nil }
        
        let pairs = zip(ratings, metrics).sorted { $0.1.date > $1.1.date }
        let highMoodPairs = pairs.filter { $0.0.rating > Constants.moodThreshold }
        let lowMoodPairs = pairs.filter { $0.0.rating <= Constants.moodThreshold }
        
        guard highMoodPairs.count >= Constants.minimumDataPoints,
              lowMoodPairs.count >= Constants.minimumDataPoints else { return nil }
        
        let avgCount = Double(pairs.map { $0.1.fillerWordCount }.reduce(0, +)) / Double(pairs.count)
        let highMoodAvg = Double(highMoodPairs.map { $0.1.fillerWordCount }.reduce(0, +)) / Double(highMoodPairs.count)
        let lowMoodAvg = Double(lowMoodPairs.map { $0.1.fillerWordCount }.reduce(0, +)) / Double(lowMoodPairs.count)
        
        let trend = FillerTrend(
            dates: pairs.map { $0.1.date },
            counts: pairs.map { $0.1.fillerWordCount }
        )
        
        return FillerStats(
            averageCount: avgCount,
            trend: trend,
            highMoodAverage: highMoodAvg,
            lowMoodAverage: lowMoodAvg
        )
    }
    
    // MARK: - Helper Functions
    private func getColorForRating(_ rating: Double) -> String {
        if rating <= 5 {
            let t = (rating - 1) / 4
            return interpolateColors(from: Constants.sadColor, to: Constants.neutralColor, with: t)
        } else {
            let t = (rating - 5) / 5
            return interpolateColors(from: Constants.neutralColor, to: Constants.happyColor, with: t)
        }
    }
    
    private func interpolateColors(from: String, to: String, with percentage: Double) -> String {
        func hexToRGB(_ hex: String) -> (r: Double, g: Double, b: Double) {
            let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            var hexInt: UInt64 = 0
            
            Scanner(string: hex).scanHexInt64(&hexInt)
            
            let r = Double((hexInt & 0xFF0000) >> 16) / 255.0
            let g = Double((hexInt & 0x00FF00) >> 8) / 255.0
            let b = Double(hexInt & 0x0000FF) / 255.0
            
            return (r, g, b)
        }
        
        func rgbToHex(_ r: Double, _ g: Double, _ b: Double) -> String {
            let r = Int(min(max(r * 255, 0), 255))
            let g = Int(min(max(g * 255, 0), 255))
            let b = Int(min(max(b * 255, 0), 255))
            
            return String(format: "%02X%02X%02X", r, g, b)
        }
        
        let fromRGB = hexToRGB(from)
        let toRGB = hexToRGB(to)
        
        let r = fromRGB.r + (toRGB.r - fromRGB.r) * percentage
        let g = fromRGB.g + (toRGB.g - fromRGB.g) * percentage
        let b = fromRGB.b + (toRGB.b - fromRGB.b) * percentage
        
        return rgbToHex(r, g, b)
    }
    
    private func getMoodDescription(for rating: Double) -> String {
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

struct MoodInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let message: String
    let value: Double
    let colorHex: String
    let isSignificant: Bool
    let timeframe: Timeframe
}

enum InsightType {
    case averageMood
    case sleepImpact
    case topicCorrelation
    case entryCompletion
    case fillerTrend
}

enum Timeframe {
    case week
    case month
    case year
    
    var minimumDataPoints: Int {
        return 3
    }
    
    var dateRange: DateComponents {
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

struct TopicStats {
    let topicName: String
    let frequency: Int
    let averageRating: Double
    let totalEntries: Int
}

struct SleepStats {
    let averageHours: Double
    let highestRatedHours: Double
    let lowestRatedHours: Double
    let ratingCorrelation: Double
}

struct FillerStats {
    let averageCount: Double
    let trend: FillerTrend
    let highMoodAverage: Double
    let lowMoodAverage: Double
}

struct FillerTrend {
    let dates: [Date]
    let counts: [Int]
}


