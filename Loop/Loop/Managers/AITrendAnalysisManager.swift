//
//  AITrendAnalysisManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/28/24.
//

import Foundation
import CoreData

import Foundation
import CoreData
import Combine

class AITrendsManager: ObservableObject {
    static let shared = AITrendsManager()
    
    @Published private(set) var weeklyAnalyses: [DailyAIAnalysis]? = nil
    @Published private(set) var monthlyAnalyses: [DailyAIAnalysis]? = nil
    @Published private(set) var yearlyAnalyses: [DailyAIAnalysis]? = nil
    
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
    
    func saveDailyAnalysis(_ aiAnalysis: AIAnalysisResult, date: Date) {
        print("\n💾 Saving AI Analysis for \(date)")
        
        let request = NSFetchRequest<NSManagedObject>(entityName: "DailyAIAnalysisEntity")
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@",
                                      Calendar.current.startOfDay(for: date) as NSDate,
                                      Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: date)!) as NSDate)
        
        do {
            let entity: NSManagedObject
            if let existing = try context.fetch(request).first {
                print("Updating existing analysis for \(date)")
                entity = existing
            } else {
                print("Creating new analysis for \(date)")
                guard let entityDescription = NSEntityDescription.entity(forEntityName: "DailyAIAnalysisEntity", in: context) else {
                    print("❌ Failed to get entity description")
                    return
                }
                entity = NSManagedObject(entity: entityDescription, insertInto: context)
            }
            
            // Set values
            entity.setValue(date, forKey: "date")
            entity.setValue(aiAnalysis.emotion.primary, forKey: "feeling")
            entity.setValue(aiAnalysis.selfReference.pattern, forKey: "focus")
            entity.setValue(aiAnalysis.timeFocus.description, forKey: "time")
            
            try context.save()
            print("✅ Successfully saved AI analysis")
            
            // Refresh analyses after save
            Task {
                await fetchCurrentWeekAnalyses()
                await fetchCurrentMonthAnalyses()
                await fetchCurrentYearAnalyses()
            }
        } catch {
            print("❌ Failed to save AI analysis: \(error)")
            context.rollback()
        }
    }
    
    private func convertToAnalysis(from entity: NSManagedObject) -> DailyAIAnalysis? {
        guard let date = entity.value(forKey: "date") as? Date,
              let feeling = entity.value(forKey: "feeling") as? String,
              let focus = entity.value(forKey: "focus") as? String,
              let time = entity.value(forKey: "time") as? String else {
            return nil
        }
        
        return DailyAIAnalysis(
            feeling: feeling,
            focus: focus,
            time: time,
            date: date
        )
    }
    
    // MARK: - Fetch Methods
    func fetchCurrentWeekAnalyses() async {
        let calendar = Calendar.current
        let today = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)),
              let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            await MainActor.run {
                self.weeklyAnalyses = nil
            }
            return
        }
        
        if let analyses = await fetchAnalyses(from: weekStart, to: weekEnd) {
            await MainActor.run {
                self.weeklyAnalyses = analyses
            }
        }
    }
    
    func fetchCurrentMonthAnalyses() async {
        let calendar = Calendar.current
        let today = Date()
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today)),
              let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
            await MainActor.run {
                self.monthlyAnalyses = nil
            }
            return
        }
        
        if let analyses = await fetchAnalyses(from: monthStart, to: monthEnd),
           analyses.count >= 5 {
            await MainActor.run {
                self.monthlyAnalyses = analyses
            }
        } else {
            await MainActor.run {
                self.monthlyAnalyses = nil
            }
        }
    }
    
    func fetchCurrentYearAnalyses() async {
        let calendar = Calendar.current
        let today = Date()
        guard let yearStart = calendar.date(from: calendar.dateComponents([.year], from: today)),
              let yearEnd = calendar.date(byAdding: .year, value: 1, to: yearStart) else {
            await MainActor.run {
                self.yearlyAnalyses = nil
            }
            return
        }
        
        if let analyses = await fetchAnalyses(from: yearStart, to: yearEnd),
           analyses.count >= 40 {
            await MainActor.run {
                self.yearlyAnalyses = analyses
            }
        } else {
            await MainActor.run {
                self.yearlyAnalyses = nil
            }
        }
    }
    
    private func fetchAnalyses(from startDate: Date, to endDate: Date) async -> [DailyAIAnalysis]? {
        let request = NSFetchRequest<NSManagedObject>(entityName: "DailyAIAnalysisEntity")
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        do {
            let results = try context.fetch(request)
            return results.compactMap { convertToAnalysis(from: $0) }
        } catch {
            print("❌ Error fetching analyses: \(error)")
            return nil
        }
    }
    
    private func calculateFrequencies(from analyses: [DailyAIAnalysis]) -> TimeframeFrequencies {
        var emotionCounts: [String: Int] = [:]
        var focusCounts: [String: Int] = [:]
        var timeCounts: [String: Int] = [:]
        
        let totalCount = analyses.count
        
        // Count frequencies (case insensitive)
        for analysis in analyses {
            let emotion = analysis.feeling.lowercased()
            let focus = analysis.focus.lowercased()
            let time = analysis.time.lowercased()
            
            emotionCounts[emotion, default: 0] += 1
            focusCounts[focus, default: 0] += 1
            timeCounts[time, default: 0] += 1
        }
        
        // Convert to FrequencyResults and sort
        func createFrequencyResults(_ counts: [String: Int]) -> [FrequencyResult] {
            return counts.map { key, count in
                FrequencyResult(
                    value: key,
                    count: count,
                    percentage: Double(count) / Double(totalCount) * 100
                )
            }.sorted { $0.count > $1.count }
        }
        
        return TimeframeFrequencies(
            topEmotions: createFrequencyResults(emotionCounts),
            topFocuses: createFrequencyResults(focusCounts),
            topTimeOrientations: createFrequencyResults(timeCounts)
        )
    }
    
    // MARK: - Public Frequency Methods
    func getWeeklyFrequencies() -> TimeframeFrequencies? {
        guard let analyses = weeklyAnalyses, !analyses.isEmpty else { return nil }
        return calculateFrequencies(from: analyses)
    }
    
    func getMonthlyFrequencies() -> TimeframeFrequencies? {
        guard let analyses = monthlyAnalyses, !analyses.isEmpty else { return nil }
        return calculateFrequencies(from: analyses)
    }
    
    func getYearlyFrequencies() -> TimeframeFrequencies? {
        guard let analyses = yearlyAnalyses, !analyses.isEmpty else { return nil }
        return calculateFrequencies(from: analyses)
    }
    
    // MARK: - Convenience Methods
    func getMostFrequent(from frequencies: TimeframeFrequencies, count: Int = 3) -> (emotions: [FrequencyResult], focuses: [FrequencyResult], times: [FrequencyResult]) {
        return (
            emotions: Array(frequencies.topEmotions.prefix(count)),
            focuses: Array(frequencies.topFocuses.prefix(count)),
            times: Array(frequencies.topTimeOrientations.prefix(count))
        )
    }
    
    // Get single most common for quick access
    func getMostCommonEmotion(timeframe: TimeframeFrequencies) -> FrequencyResult? {
        timeframe.topEmotions.first
    }
    
    func getMostCommonFocus(timeframe: TimeframeFrequencies) -> FrequencyResult? {
        timeframe.topFocuses.first
    }
    
    func getMostCommonTimeOrientation(timeframe: TimeframeFrequencies) -> FrequencyResult? {
        timeframe.topTimeOrientations.first
    }
}
