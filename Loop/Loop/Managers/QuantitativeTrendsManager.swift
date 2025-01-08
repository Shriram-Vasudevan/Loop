//
//  QuantitativeTrendsManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/28/24.
//

import Foundation
import CoreData
import Combine

class QuantitativeTrendsManager: ObservableObject {
    static let shared = QuantitativeTrendsManager()
    
    @Published var weeklyStats: [DailyStats]? = nil
    @Published var monthlyStats: [WeeklyStats]? = nil
    @Published var yearlyStats: [MonthlyStats]? = nil
    
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
    
    func saveDailyStats(_ analysis: DailyAnalysis) {
        print("\n📊 Saving daily stats for \(analysis.date)")
        
        saveDailyToDaily(analysis)
        updateWeeklyStats(with: analysis)
        updateMonthlyStats(with: analysis)
        
        Task {
            await fetchAllTimeframes()
        }
    }
    
    private func saveDailyToDaily(_ analysis: DailyAnalysis) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "DailyStatsEntity")
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                      Calendar.current.startOfDay(for: analysis.date) as NSDate,
                                      Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: analysis.date)!) as NSDate)
        
        do {
            let entity: NSManagedObject
            if let existing = try context.fetch(request).first {
                entity = existing
            } else {
                guard let entityDescription = NSEntityDescription.entity(forEntityName: "DailyStatsEntity", in: context) else {
                    return
                }
                entity = NSManagedObject(entity: entityDescription, insertInto: context)
            }
            
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .weekOfYear, .weekday], from: analysis.date)
            
            entity.setValue(analysis.date, forKey: "date")
            entity.setValue(Int16(components.year ?? 0), forKey: "year")
            entity.setValue(Int16(components.month ?? 0), forKey: "month")
            entity.setValue(Int16(components.weekOfYear ?? 0), forKey: "weekOfYear")
            entity.setValue(Int16(components.weekday ?? 0), forKey: "weekday")
            entity.setValue(analysis.aggregateMetrics.averageWPM, forKey: "averageWPM")
            entity.setValue(analysis.aggregateMetrics.averageDuration, forKey: "averageDuration")
            entity.setValue(analysis.aggregateMetrics.averageWordCount, forKey: "averageWordCount")
            entity.setValue(analysis.aggregateMetrics.vocabularyDiversity, forKey: "vocabularyDiversityRatio")
            entity.setValue(Int16(analysis.loops.count), forKey: "loopCount")
            entity.setValue(Date(), forKey: "lastUpdated")
            
            try context.save()
            print("✅ Saved daily stats")
        } catch {
            print("❌ Failed to save daily stats: \(error)")
            context.rollback()
        }
    }
    
    private func updateWeeklyStats(with analysis: DailyAnalysis) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekOfYear, .year], from: analysis.date)
        
        guard let week = components.weekOfYear,
              let year = components.year else { return }
        
        let request = NSFetchRequest<NSManagedObject>(entityName: "WeeklyStatsEntity")
        request.predicate = NSPredicate(format: "weekNumber == %d AND year == %d", week, year)
        
        do {
            let entity: NSManagedObject
            if let existing = try context.fetch(request).first {
                entity = existing
            } else {
                guard let entityDescription = NSEntityDescription.entity(forEntityName: "WeeklyStatsEntity", in: context) else {
                    return
                }
                entity = NSManagedObject(entity: entityDescription, insertInto: context)
                entity.setValue(Int16(week), forKey: "weekNumber")
                entity.setValue(Int16(year), forKey: "year")
                entity.setValue(Int64(0), forKey: "dataPointCount")
            }
            
            updateRunningAverages(entity: entity, with: analysis)
            try context.save()
            print("✅ Updated weekly stats")
        } catch {
            print("❌ Failed to update weekly stats: \(error)")
            context.rollback()
        }
    }
    
    private func updateMonthlyStats(with analysis: DailyAnalysis) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .year], from: analysis.date)
        
        guard let month = components.month,
              let year = components.year else { return }
        
        let request = NSFetchRequest<NSManagedObject>(entityName: "MonthlyStatsEntity")
        request.predicate = NSPredicate(format: "month == %d AND year == %d", month, year)
        
        do {
            let entity: NSManagedObject
            if let existing = try context.fetch(request).first {
                entity = existing
            } else {
                guard let entityDescription = NSEntityDescription.entity(forEntityName: "MonthlyStatsEntity", in: context) else {
                    return
                }
                entity = NSManagedObject(entity: entityDescription, insertInto: context)
                entity.setValue(Int16(month), forKey: "month")
                entity.setValue(Int16(year), forKey: "year")
                entity.setValue(Int64(0), forKey: "dataPointCount")
            }
            
            updateRunningAverages(entity: entity, with: analysis)
            try context.save()
            print("✅ Updated monthly stats")
        } catch {
            print("❌ Failed to update monthly stats: \(error)")
            context.rollback()
        }
    }
    
    private func updateRunningAverages(entity: NSManagedObject, with analysis: DailyAnalysis) {
        let currentCount = entity.value(forKey: "dataPointCount") as? Int64 ?? 0
        
        func updateAverage(forKey key: String, newValue: Double) {
            let currentAvg = entity.value(forKey: key) as? Double ?? 0
            let newAvg = ((currentAvg * Double(currentCount)) + newValue) / Double(currentCount + 1)
            entity.setValue(newAvg, forKey: key)
        }
        
        updateAverage(forKey: "averageWPM", newValue: analysis.aggregateMetrics.averageWPM)
        updateAverage(forKey: "averageDuration", newValue: analysis.aggregateMetrics.averageDuration)
        updateAverage(forKey: "averageWordCount", newValue: analysis.aggregateMetrics.averageWordCount)
        updateAverage(forKey: "vocabularyDiversityRatio", newValue: analysis.aggregateMetrics.vocabularyDiversity)
        
        entity.setValue(currentCount + 1, forKey: "dataPointCount")
        entity.setValue(Date(), forKey: "lastUpdated")
    }
    
    // MARK: - Fetch Methods
    func fetchAllTimeframes() async {
        await fetchCurrentWeekStats()
        await fetchCurrentMonthStats()
        await fetchCurrentYearStats()
    }
    
    func fetchCurrentWeekStats() async {
        let calendar = Calendar.current
        let today = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)),
              let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            await MainActor.run { self.weeklyStats = nil }
            return
        }
        
        let request = NSFetchRequest<NSManagedObject>(entityName: "DailyStatsEntity")
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", weekStart as NSDate, weekEnd as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        do {
            let results = try context.fetch(request)
            let stats = results.compactMap { convertToDailyStats(from: $0) }
            await MainActor.run { self.weeklyStats = stats }
        } catch {
            print("❌ Error fetching weekly stats: \(error)")
            await MainActor.run { self.weeklyStats = nil }
        }
    }
    
    func fetchCurrentMonthStats() async {
        let calendar = Calendar.current
        let today = Date()
        guard let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)),
              let firstWeek = calendar.dateComponents([.weekOfYear], from: firstDayOfMonth).weekOfYear,
              let lastDayOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstDayOfMonth),
              let lastWeek = calendar.dateComponents([.weekOfYear], from: lastDayOfMonth).weekOfYear,
              let year = calendar.dateComponents([.year], from: today).year else {
            await MainActor.run { self.monthlyStats = nil }
            return
        }
        
        let request = NSFetchRequest<NSManagedObject>(entityName: "WeeklyStatsEntity")
        request.predicate = NSPredicate(format: "year == %d AND weekNumber >= %d AND weekNumber <= %d",
                                      year, firstWeek, lastWeek)
        request.sortDescriptors = [NSSortDescriptor(key: "weekNumber", ascending: true)]
        
        do {
            let results = try context.fetch(request)
            let stats = results.compactMap { convertToWeeklyStats(from: $0) }
            await MainActor.run { self.monthlyStats = stats }
        } catch {
            print("❌ Error fetching monthly stats: \(error)")
            await MainActor.run { self.monthlyStats = nil }
        }
    }
    
    func fetchCurrentYearStats() async {
        let calendar = Calendar.current
        guard let year = calendar.dateComponents([.year], from: Date()).year else {
            await MainActor.run { self.yearlyStats = nil }
            return
        }
        
        let request = NSFetchRequest<NSManagedObject>(entityName: "MonthlyStatsEntity")
        request.predicate = NSPredicate(format: "year == %d", year)
        request.sortDescriptors = [NSSortDescriptor(key: "month", ascending: true)]
        
        do {
            let results = try context.fetch(request)
            let stats = results.compactMap { convertToMonthlyStats(from: $0) }
            await MainActor.run { self.yearlyStats = stats }
        } catch {
            print("❌ Error fetching yearly stats: \(error)")
            await MainActor.run { self.yearlyStats = nil }
        }
    }
    
    // MARK: - Conversion Methods
    private func convertToDailyStats(from entity: NSManagedObject) -> DailyStats? {
        guard let date = entity.value(forKey: "date") as? Date else { return nil }
        
        return DailyStats(
            date: date,
            year: entity.value(forKey: "year") as? Int16 ?? 0,
            month: entity.value(forKey: "month") as? Int16 ?? 0,
            weekOfYear: entity.value(forKey: "weekOfYear") as? Int16 ?? 0,
            weekday: entity.value(forKey: "weekday") as? Int16 ?? 0,
            averageWPM: entity.value(forKey: "averageWPM") as? Double ?? 0,
            averageDuration: entity.value(forKey: "averageDuration") as? Double ?? 0,
            averageWordCount: entity.value(forKey: "averageWordCount") as? Double ?? 0,
            averageUniqueWordCount: entity.value(forKey: "averageUniqueWordCount") as? Double ?? 0,
            vocabularyDiversityRatio: entity.value(forKey: "vocabularyDiversityRatio") as? Double ?? 0,
            loopCount: entity.value(forKey: "loopCount") as? Int16 ?? 0,
            lastUpdated: entity.value(forKey: "lastUpdated") as? Date
        )
    }
    
    private func convertToWeeklyStats(from entity: NSManagedObject) -> WeeklyStats? {
        guard let lastUpdated = entity.value(forKey: "lastUpdated") as? Date else { return nil }
        
        return WeeklyStats(
            dataPointCount: entity.value(forKey: "dataPointCount") as? Int64 ?? 0,
            averageWPM: entity.value(forKey: "averageWPM") as? Double ?? 0,
            averageDuration: entity.value(forKey: "averageDuration") as? Double ?? 0,
            averageWordCount: entity.value(forKey: "averageWordCount") as? Double ?? 0,
            averageUniqueWordCount: entity.value(forKey: "averageUniqueWordCount") as? Double ?? 0,
            vocabularyDiversityRatio: entity.value(forKey: "vocabularyDiversityRatio") as? Double ?? 0,
            lastUpdated: lastUpdated,
            weekNumber: entity.value(forKey: "weekNumber") as? Int16 ?? 0,
            year: entity.value(forKey: "year") as? Int16 ?? 0
        )
    }
    
    private func convertToMonthlyStats(from entity: NSManagedObject) -> MonthlyStats? {
        guard let lastUpdated = entity.value(forKey: "lastUpdated") as? Date else { return nil }
        
        return MonthlyStats(
            dataPointCount: entity.value(forKey: "dataPointCount") as? Int64 ?? 0,
            averageWPM: entity.value(forKey: "averageWPM") as? Double ?? 0,
            averageDuration: entity.value(forKey: "averageDuration") as? Double ?? 0,
            averageWordCount: entity.value(forKey: "averageWordCount") as? Double ?? 0,
            averageUniqueWordCount: entity.value(forKey: "averageUniqueWordCount") as? Double ?? 0,
            vocabularyDiversityRatio: entity.value(forKey: "vocabularyDiversityRatio") as? Double ?? 0,
            lastUpdated: lastUpdated,
            month: entity.value(forKey: "month") as? Int16 ?? 0,
            year: entity.value(forKey: "year") as? Int16 ?? 0
        )
    }
    
    func compareWithToday(_ analysis: DailyAnalysis) -> [MetricComparison] {
        var comparisons: [MetricComparison] = []
        
        // WPM Comparison
        if let weeklyWPM = getAverageWPM(from: weeklyStats) {
            let todayWPM = analysis.aggregateMetrics.averageWPM
            let wpmDiff = ((todayWPM - weeklyWPM) / weeklyWPM) * 100
            let comparison = ComparisonResult.compare(todayWPM, with: weeklyWPM)
            
            let trend = switch comparison {
                case .higher: "Your speaking pace today was faster than your weekly average"
                case .lower: "Your speaking pace today was slower than your weekly average"
                case .equal: "Your speaking pace today was consistent with your weekly average"
            }
            
            comparisons.append(MetricComparison(
                metric: "WPM",
                trend: trend,
                percentageDiff: abs(wpmDiff),
                isSignificant: abs(wpmDiff) >= 15.0
            ))
        }
        
        // Duration Comparison
        if let weeklyDuration = getAverageDuration(from: weeklyStats) {
            let todayDuration = analysis.aggregateMetrics.averageDuration
            let durationDiff = ((todayDuration - weeklyDuration) / weeklyDuration) * 100
            let comparison = ComparisonResult.compare(todayDuration, with: weeklyDuration)
            
            let trend = switch comparison {
                case .higher: "Your responses today were longer than your typical length"
                case .lower: "Your responses today were shorter than your typical length"
                case .equal: "Your response lengths today were about average"
            }
            
            comparisons.append(MetricComparison(
                metric: "Duration",
                trend: trend,
                percentageDiff: abs(durationDiff),
                isSignificant: abs(durationDiff) >= 15.0
            ))
        }
        
        // Word Count Comparison
        if let weeklyWordCount = getAverageWordCount(from: weeklyStats) {
            let todayWordCount = analysis.aggregateMetrics.averageWordCount
            let wordCountDiff = ((todayWordCount - weeklyWordCount) / weeklyWordCount) * 100
            let comparison = ComparisonResult.compare(todayWordCount, with: weeklyWordCount)
            
            let trend = switch comparison {
                case .higher: "You used more words than usual today"
                case .lower: "You used fewer words than usual today"
                case .equal: "Your word count today was about average"
            }
            
            comparisons.append(MetricComparison(
                metric: "Word Count",
                trend: trend,
                percentageDiff: abs(wordCountDiff),
                isSignificant: abs(wordCountDiff) >= 15.0
            ))
        }
        
        // Vocabulary Diversity Comparison
        if let weeklyDiversity = getAverageVocabDiversity(from: weeklyStats) {
            let todayDiversity = analysis.aggregateMetrics.vocabularyDiversity
            let diversityDiff = ((todayDiversity - weeklyDiversity) / weeklyDiversity) * 100
            let comparison = ComparisonResult.compare(todayDiversity, with: weeklyDiversity)
            
            let trend = switch comparison {
                case .higher: "Your vocabulary today was more varied than your weekly average"
                case .lower: "Your vocabulary today was less varied than your weekly average"
                case .equal: "Your vocabulary variety was consistent with your weekly average"
            }
            
            comparisons.append(MetricComparison(
                metric: "Vocabulary",
                trend: trend,
                percentageDiff: abs(diversityDiff),
                isSignificant: abs(diversityDiff) >= 15.0
            ))
        }
        
        return comparisons
    }

    func getAverageWPM(from stats: [DailyStats]?) -> Double? {
        guard let stats = stats, !stats.isEmpty else { return nil }
        return stats.reduce(0.0) { $0 + $1.averageWPM } / Double(stats.count)
    }
    
    func getAverageDuration(from stats: [DailyStats]?) -> Double? {
        guard let stats = stats, !stats.isEmpty else { return nil }
        return stats.reduce(0.0) { $0 + $1.averageDuration } / Double(stats.count)
    }
    
    func getAverageWordCount(from stats: [DailyStats]?) -> Double? {
        guard let stats = stats, !stats.isEmpty else { return nil }
        return stats.reduce(0.0) { $0 + $1.averageWordCount } / Double(stats.count)
    }
    
    func getAverageVocabDiversity(from stats: [DailyStats]?) -> Double? {
        guard let stats = stats, !stats.isEmpty else { return nil }
        return stats.reduce(0.0) { $0 + $1.vocabularyDiversityRatio } / Double(stats.count)
    }
    
    // Get only significant changes
    func getSignificantChanges(_ analysis: DailyAnalysis) -> [MetricComparison] {
        return compareWithToday(analysis).filter { $0.isSignificant }
    }

}


extension QuantitativeTrendsManager {
    func getFastestSpeakingDay() -> SpeakingHighlight? {
        guard let weeklyStats = weeklyStats else { return nil }
        guard let maxWPMEntry = weeklyStats.max(by: { $0.averageWPM < $1.averageWPM }), let date = maxWPMEntry.date else { return nil }
        
        
        guard let emotion = AITrendsManager.shared.getEmotionForDate(maxWPMEntry.date ?? Date(timeIntervalSince1970: .pi)) else { return nil }
        
        return SpeakingHighlight(
            date: date,
            wpm: maxWPMEntry.averageWPM,
            emotion: emotion,
            wordCount: maxWPMEntry.averageWordCount,
            duration: maxWPMEntry.averageDuration
        )
    }
    
    func getLongestDurationDay() -> SpeakingHighlight? {
        guard let weeklyStats = weeklyStats else { return nil }
        guard let maxDurationEntry = weeklyStats.max(by: { $0.averageDuration < $1.averageDuration }), let date = maxDurationEntry.date else { return nil }
        
        guard let emotion = AITrendsManager.shared.getEmotionForDate(maxDurationEntry.date ?? Date(timeIntervalSince1970: .pi)) else { return nil }
        
        return SpeakingHighlight(
            date: date,
            wpm: maxDurationEntry.averageWPM,
            emotion: emotion,
            wordCount: maxDurationEntry.averageWordCount,
            duration: maxDurationEntry.averageDuration
        )
    }
    
    func getMostWordsDay() -> SpeakingHighlight? {
        guard let weeklyStats = weeklyStats else { return nil }
        guard let maxWordsEntry = weeklyStats.max(by: { $0.averageWordCount < $1.averageWordCount }), let date = maxWordsEntry.date else { return nil }
        
        guard let emotion = AITrendsManager.shared.getEmotionForDate(maxWordsEntry.date ?? Date(timeIntervalSince1970: .pi)) else { return nil }
        
        return SpeakingHighlight(
            date: date,
            wpm: maxWordsEntry.averageWPM,
            emotion: emotion,
            wordCount: maxWordsEntry.averageWordCount,
            duration: maxWordsEntry.averageDuration
        )
    }

    func getDurationComparison(for timeframe: Timeframe) -> (current: [DailyStats]?, previous: [DailyStats]?) {
        switch timeframe {
        case .week:
            return getWeekComparison()
        case .month:
            return getMonthComparison()
        case .year:
            return getYearComparison()
        }
    }
    
    private func getWeekComparison() -> (current: [DailyStats]?, previous: [DailyStats]?) {
        let calendar = Calendar.current
        let now = Date()
        
        // Get current week's start
        guard let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)),
              let lastWeekStart = calendar.date(byAdding: .day, value: -7, to: currentWeekStart) else {
            return (nil, nil)
        }
        
        // Fetch current week's data
        let request = NSFetchRequest<NSManagedObject>(entityName: "DailyStatsEntity")
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@",
            currentWeekStart as NSDate,
            now as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        // Fetch last week's data
        let lastWeekRequest = NSFetchRequest<NSManagedObject>(entityName: "DailyStatsEntity")
        lastWeekRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@",
            lastWeekStart as NSDate,
            currentWeekStart as NSDate
        )
        lastWeekRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        do {
            let currentResults = try context.fetch(request).compactMap { convertToDailyStats(from: $0) }
            let previousResults = try context.fetch(lastWeekRequest).compactMap { convertToDailyStats(from: $0) }
            
            return (
                currentResults.isEmpty ? nil : currentResults,
                previousResults.isEmpty ? nil : previousResults
            )
        } catch {
            print("❌ Failed to fetch comparison data: \(error)")
            return (nil, nil)
        }
    }
    
    private func getMonthComparison() -> (current: [DailyStats]?, previous: [DailyStats]?) {
        let calendar = Calendar.current
        let now = Date()
        
        // Get current month's start
        guard let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: currentMonthStart) else {
            return (nil, nil)
        }
        
        // Fetch current month's data
        let request = NSFetchRequest<NSManagedObject>(entityName: "DailyStatsEntity")
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@",
            currentMonthStart as NSDate,
            now as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        // Fetch last month's data
        let lastMonthRequest = NSFetchRequest<NSManagedObject>(entityName: "DailyStatsEntity")
        lastMonthRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@",
            lastMonthStart as NSDate,
            currentMonthStart as NSDate
        )
        lastMonthRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        do {
            let currentResults = try context.fetch(request).compactMap { convertToDailyStats(from: $0) }
            let previousResults = try context.fetch(lastMonthRequest).compactMap { convertToDailyStats(from: $0) }
            
            return (
                currentResults.isEmpty ? nil : currentResults,
                previousResults.isEmpty ? nil : previousResults
            )
        } catch {
            print("❌ Failed to fetch comparison data: \(error)")
            return (nil, nil)
        }
    }
    
    private func getYearComparison() -> (current: [DailyStats]?, previous: [DailyStats]?) {
        let calendar = Calendar.current
        let now = Date()
        
        // Get current year's start
        guard let currentYearStart = calendar.date(from: calendar.dateComponents([.year], from: now)),
              let lastYearStart = calendar.date(byAdding: .year, value: -1, to: currentYearStart) else {
            return (nil, nil)
        }
        
        // Fetch current year's data
        let request = NSFetchRequest<NSManagedObject>(entityName: "DailyStatsEntity")
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@",
            currentYearStart as NSDate,
            now as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        // Fetch last year's data
        let lastYearRequest = NSFetchRequest<NSManagedObject>(entityName: "DailyStatsEntity")
        lastYearRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@",
            lastYearStart as NSDate,
            currentYearStart as NSDate
        )
        lastYearRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        do {
            let currentResults = try context.fetch(request).compactMap { convertToDailyStats(from: $0) }
            let previousResults = try context.fetch(lastYearRequest).compactMap { convertToDailyStats(from: $0) }
            
            return (
                currentResults.isEmpty ? nil : currentResults,
                previousResults.isEmpty ? nil : previousResults
            )
        } catch {
            print("❌ Failed to fetch comparison data: \(error)")
            return (nil, nil)
        }
    }
    
}
