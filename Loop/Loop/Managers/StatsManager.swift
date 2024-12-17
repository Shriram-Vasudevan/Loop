//
//  StatsManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/16/24.
//

import Foundation
import AVFoundation
import Speech
import NaturalLanguage
import Combine
import CoreData


class StatsManager {
    static let shared = StatsManager()
    
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
    
    
    
    private func fetchAllTimeStats() -> AllTimeStats? {
        let request = NSFetchRequest<NSManagedObject>(entityName: "AllTimeStatsEntity")
        
        guard let result = try? context.fetch(request).first else {
            return nil
        }
        
        return AllTimeStats(
            dataPointCount: result.value(forKey: "dataPointCount") as? Int64 ?? 0,
            averageWPM: result.value(forKey: "averageWPM") as? Double ?? 0,
            averageDuration: result.value(forKey: "averageDuration") as? Double ?? 0,
            averageWordCount: result.value(forKey: "averageWordCount") as? Double ?? 0,
            averageUniqueWordCount: result.value(forKey: "averageUniqueWordCount") as? Double ?? 0,
            averageSelfReferences: result.value(forKey: "averageSelfReferences") as? Double ?? 0,
            vocabularyDiversityRatio: result.value(forKey: "vocabularyDiversityRatio") as? Double ?? 0,
            averageWordLength: result.value(forKey: "averageWordLength") as? Double ?? 0,
            lastUpdated: result.value(forKey: "lastUpdated") as? Date
        )
    }

    private func fetchCurrentMonthStats() -> MonthlyStats? {
        let request = NSFetchRequest<NSManagedObject>(entityName: "MonthlyStatsEntity")
        let components = Calendar.current.dateComponents([.month, .year], from: Date())
        guard let month = components.month,
              let year = components.year else { return nil }
        
        request.predicate = NSPredicate(format: "month == %d AND year == %d", month, year)
        
        guard let result = try? context.fetch(request).first else {
            return nil
        }
        
        return MonthlyStats(
            dataPointCount: result.value(forKey: "dataPointCount") as? Int64 ?? 0,
            averageWPM: result.value(forKey: "averageWPM") as? Double ?? 0,
            averageDuration: result.value(forKey: "averageDuration") as? Double ?? 0,
            averageWordCount: result.value(forKey: "averageWordCount") as? Double ?? 0,
            averageUniqueWordCount: result.value(forKey: "averageUniqueWordCount") as? Double ?? 0,
            averageSelfReferences: result.value(forKey: "averageSelfReferences") as? Double ?? 0,
            vocabularyDiversityRatio: result.value(forKey: "vocabularyDiversityRatio") as? Double ?? 0,
            averageWordLength: result.value(forKey: "averageWordLength") as? Double ?? 0,
            lastUpdated: result.value(forKey: "lastUpdated") as? Date,
            month: result.value(forKey: "month") as? Int16 ?? 0,
            year: result.value(forKey: "year") as? Int16 ?? 0
        )
    }

    private func fetchCurrentWeekStats() -> WeeklyStats? {
        let request = NSFetchRequest<NSManagedObject>(entityName: "WeeklyStatsEntity")
        let components = Calendar.current.dateComponents([.weekOfYear, .year], from: Date())
        guard let week = components.weekOfYear,
              let year = components.year else { return nil }
        
        request.predicate = NSPredicate(format: "weekNumber == %d AND year == %d", week, year)
        
        guard let result = try? context.fetch(request).first else {
            return nil
        }
        
        return WeeklyStats(
            dataPointCount: result.value(forKey: "dataPointCount") as? Int64 ?? 0,
            averageWPM: result.value(forKey: "averageWPM") as? Double ?? 0,
            averageDuration: result.value(forKey: "averageDuration") as? Double ?? 0,
            averageWordCount: result.value(forKey: "averageWordCount") as? Double ?? 0,
            averageUniqueWordCount: result.value(forKey: "averageUniqueWordCount") as? Double ?? 0,
            averageSelfReferences: result.value(forKey: "averageSelfReferences") as? Double ?? 0,
            vocabularyDiversityRatio: result.value(forKey: "vocabularyDiversityRatio") as? Double ?? 0,
            averageWordLength: result.value(forKey: "averageWordLength") as? Double ?? 0,
            lastUpdated: result.value(forKey: "lastUpdated") as? Date,
            weekNumber: result.value(forKey: "weekNumber") as? Int16 ?? 0,
            year: result.value(forKey: "year") as? Int16 ?? 0
        )
    }
    
    private func createAllTimeStats() -> AllTimeStats? {
        guard let entity = NSEntityDescription.entity(forEntityName: "AllTimeStatsEntity", in: context) else {
            print("Failed to get AllTimeStatsEntity")
            return nil
        }
        
        let statsEntity = NSManagedObject(entity: entity, insertInto: context)
        
        // Set values like your Loop code
        statsEntity.setValue(0, forKey: "dataPointCount")
        statsEntity.setValue(0.0, forKey: "averageWPM")
        statsEntity.setValue(0.0, forKey: "averageDuration")
        statsEntity.setValue(0.0, forKey: "averageWordCount")
        statsEntity.setValue(0.0, forKey: "averageUniqueWordCount")
        statsEntity.setValue(0.0, forKey: "averageSelfReferences")
        statsEntity.setValue(0.0, forKey: "vocabularyDiversityRatio")
        statsEntity.setValue(0.0, forKey: "averageWordLength")
        statsEntity.setValue(Date(), forKey: "lastUpdated")
        
        do {
            try context.save()
            // Cast to AllTimeStats after saving
            return statsEntity as? AllTimeStats
        } catch {
            print("Failed to save AllTimeStats: \(error)")
            return nil
        }
    }
    
    private func createMonthlyStats() -> MonthlyStats? {
        let components = Calendar.current.dateComponents([.month, .year], from: Date())
        guard let month = components.month,
              let year = components.year,
              let entity = NSEntityDescription.entity(forEntityName: "MonthlyStatsEntity", in: context) else {
            print("Failed to get MonthlyStatsEntity")
            return nil
        }
        
        let statsEntity = NSManagedObject(entity: entity, insertInto: context)
        
        statsEntity.setValue(0, forKey: "dataPointCount")
        statsEntity.setValue(0.0, forKey: "averageWPM")
        statsEntity.setValue(0.0, forKey: "averageDuration")
        statsEntity.setValue(0.0, forKey: "averageWordCount")
        statsEntity.setValue(0.0, forKey: "averageUniqueWordCount")
        statsEntity.setValue(0.0, forKey: "averageSelfReferences")
        statsEntity.setValue(0.0, forKey: "vocabularyDiversityRatio")
        statsEntity.setValue(0.0, forKey: "averageWordLength")
        statsEntity.setValue(Date(), forKey: "lastUpdated")
        statsEntity.setValue(Int16(month), forKey: "month")
        statsEntity.setValue(Int16(year), forKey: "year")
        
        do {
            try context.save()
            return statsEntity as? MonthlyStats
        } catch {
            print("Failed to save MonthlyStats: \(error)")
            return nil
        }
    }

    private func createWeeklyStats() -> WeeklyStats? {
        let components = Calendar.current.dateComponents([.weekOfYear, .year], from: Date())
        guard let week = components.weekOfYear,
              let year = components.year,
              let entity = NSEntityDescription.entity(forEntityName: "WeeklyStatsEntity", in: context) else {
            print("Failed to get WeeklyStatsEntity")
            return nil
        }
        
        let statsEntity = NSManagedObject(entity: entity, insertInto: context)
        
        statsEntity.setValue(0, forKey: "dataPointCount")
        statsEntity.setValue(0.0, forKey: "averageWPM")
        statsEntity.setValue(0.0, forKey: "averageDuration")
        statsEntity.setValue(0.0, forKey: "averageWordCount")
        statsEntity.setValue(0.0, forKey: "averageUniqueWordCount")
        statsEntity.setValue(0.0, forKey: "averageSelfReferences")
        statsEntity.setValue(0.0, forKey: "vocabularyDiversityRatio")
        statsEntity.setValue(0.0, forKey: "averageWordLength")
        statsEntity.setValue(Date(), forKey: "lastUpdated")
        statsEntity.setValue(Int16(week), forKey: "weekNumber")
        statsEntity.setValue(Int16(year), forKey: "year")
        
        do {
            try context.save()
            return statsEntity as? WeeklyStats
        } catch {
            print("Failed to save WeeklyStats: \(error)")
            return nil
        }
    }
    
    private func updateRunningAverage(currentAvg: Double, currentCount: Int, newValue: Double) -> Double {
        let newCount = currentCount + 1
        return ((currentAvg * Double(currentCount)) + newValue) / Double(newCount)
    }
    
    func updateStats(with analysis: DailyAnalysis) {
        let allTimeStats = fetchAllTimeStats() ?? createAllTimeStats()
        let monthlyStats = fetchCurrentMonthStats() ?? createMonthlyStats()
        let weeklyStats = fetchCurrentWeekStats() ?? createWeeklyStats()
        
        if var allTimeStats = allTimeStats {
            allTimeStats.averageWPM = updateRunningAverage(currentAvg: allTimeStats.averageWPM,
                                                            currentCount: Int(allTimeStats.dataPointCount),
                                                           newValue: analysis.aggregateMetrics.averageWPM)
            allTimeStats.averageDuration = updateRunningAverage(currentAvg: allTimeStats.averageDuration,
                                                                currentCount: Int(allTimeStats.dataPointCount),
                                                                newValue: analysis.aggregateMetrics.averageDuration)
            allTimeStats.averageWordCount = updateRunningAverage(currentAvg: allTimeStats.averageWordCount,
                                                                 currentCount: Int(allTimeStats.dataPointCount),
                                                                 newValue: analysis.aggregateMetrics.averageWordCount)
            allTimeStats.averageUniqueWordCount = updateRunningAverage(currentAvg: allTimeStats.averageUniqueWordCount,
                                                                       currentCount: Int(allTimeStats.dataPointCount),
                                                                       newValue: analysis.aggregateMetrics.averageUniqueWordCount)
            allTimeStats.averageSelfReferences = updateRunningAverage(currentAvg: allTimeStats.averageSelfReferences,
                                                                      currentCount: Int(allTimeStats.dataPointCount),
                                                                      newValue: analysis.aggregateMetrics.averageSelfReferences)
            allTimeStats.vocabularyDiversityRatio = updateRunningAverage(currentAvg: allTimeStats.vocabularyDiversityRatio,
                                                                         currentCount: Int(allTimeStats.dataPointCount),
                                                                         newValue: analysis.aggregateMetrics.vocabularyDiversityRatio)
            allTimeStats.averageWordLength = updateRunningAverage(currentAvg: allTimeStats.averageWordLength,
                                                                  currentCount: Int(allTimeStats.dataPointCount),
                                                                  newValue: analysis.loops.reduce(0.0) { $0 + $1.metrics.averageWordLength } / Double(analysis.loops.count))
            allTimeStats.dataPointCount += 1
            allTimeStats.lastUpdated = Date()
        }
        
        if var monthlyStats = monthlyStats {
            monthlyStats.averageWPM = updateRunningAverage(currentAvg: monthlyStats.averageWPM,
                                                           currentCount: Int(monthlyStats.dataPointCount),
                                                           newValue: analysis.aggregateMetrics.averageWPM)
            monthlyStats.averageDuration = updateRunningAverage(currentAvg: monthlyStats.averageDuration,
                                                                currentCount: Int(monthlyStats.dataPointCount),
                                                                newValue: analysis.aggregateMetrics.averageDuration)
            monthlyStats.averageWordCount = updateRunningAverage(currentAvg: monthlyStats.averageWordCount,
                                                                 currentCount: Int(monthlyStats.dataPointCount),
                                                                 newValue: analysis.aggregateMetrics.averageWordCount)
            monthlyStats.averageUniqueWordCount = updateRunningAverage(currentAvg: monthlyStats.averageUniqueWordCount,
                                                                       currentCount: Int(monthlyStats.dataPointCount),
                                                                       newValue: analysis.aggregateMetrics.averageUniqueWordCount)
            monthlyStats.averageSelfReferences = updateRunningAverage(currentAvg: monthlyStats.averageSelfReferences,
                                                                      currentCount: Int(monthlyStats.dataPointCount),
                                                                      newValue: analysis.aggregateMetrics.averageSelfReferences)
            monthlyStats.vocabularyDiversityRatio = updateRunningAverage(currentAvg: monthlyStats.vocabularyDiversityRatio,
                                                                         currentCount: Int(monthlyStats.dataPointCount),
                                                                         newValue: analysis.aggregateMetrics.vocabularyDiversityRatio)
            monthlyStats.averageWordLength = updateRunningAverage(currentAvg: monthlyStats.averageWordLength,
                                                                  currentCount: Int(monthlyStats.dataPointCount),
                                                                  newValue: analysis.loops.reduce(0.0) { $0 + $1.metrics.averageWordLength } / Double(analysis.loops.count))
            monthlyStats.dataPointCount += 1
            monthlyStats.lastUpdated = Date()
        }
        
        if var weeklyStats = weeklyStats {
            weeklyStats.averageWPM = updateRunningAverage(currentAvg: weeklyStats.averageWPM,
                                                          currentCount: Int(weeklyStats.dataPointCount),
                                                          newValue: analysis.aggregateMetrics.averageWPM)
            weeklyStats.averageDuration = updateRunningAverage(currentAvg: weeklyStats.averageDuration,
                                                               currentCount: Int(weeklyStats.dataPointCount),
                                                               newValue: analysis.aggregateMetrics.averageDuration)
            weeklyStats.averageWordCount = updateRunningAverage(currentAvg: weeklyStats.averageWordCount,
                                                                currentCount: Int(weeklyStats.dataPointCount),
                                                                newValue: analysis.aggregateMetrics.averageWordCount)
            weeklyStats.averageUniqueWordCount = updateRunningAverage(currentAvg: weeklyStats.averageUniqueWordCount,
                                                                      currentCount: Int(weeklyStats.dataPointCount),
                                                                      newValue: analysis.aggregateMetrics.averageUniqueWordCount)
            weeklyStats.averageSelfReferences = updateRunningAverage(currentAvg: weeklyStats.averageSelfReferences,
                                                                     currentCount: Int(weeklyStats.dataPointCount),
                                                                     newValue: analysis.aggregateMetrics.averageSelfReferences)
            weeklyStats.vocabularyDiversityRatio = updateRunningAverage(currentAvg: weeklyStats.vocabularyDiversityRatio,
                                                                        currentCount: Int(weeklyStats.dataPointCount),
                                                                        newValue: analysis.aggregateMetrics.vocabularyDiversityRatio)
            weeklyStats.averageWordLength = updateRunningAverage(currentAvg: weeklyStats.averageWordLength,
                                                                 currentCount: Int(weeklyStats.dataPointCount),
                                                                 newValue: analysis.loops.reduce(0.0) { $0 + $1.metrics.averageWordLength } / Double(analysis.loops.count))
            weeklyStats.dataPointCount += 1
            weeklyStats.lastUpdated = Date()
        }
        
        try? context.save()
    }
    
    func compareWithCurrentStats(_ analysis: DailyAnalysis) -> LoopComparison? {
        let allTimeStats = fetchAllTimeStats() ?? createAllTimeStats()
        let monthlyStats = fetchCurrentMonthStats()
        let weeklyStats = fetchCurrentWeekStats()
        
        func createComparison(current: Double, past: Double) -> MetricComparison {
            let percentChange = ((current - past) / past) * 100
            let direction: ComparisonDirection
            if abs(percentChange) < 1 {
                direction = .same
            } else if percentChange > 0 {
                direction = .increase
            } else {
                direction = .decrease
            }
            return MetricComparison(direction: direction, percentageChange: abs(percentChange))
        }
        
        if let allTimeStats = allTimeStats {
            return LoopComparison(
                date: analysis.date,
                pastLoopDate: allTimeStats.lastUpdated ?? Date(),
                durationComparison: createComparison(
                    current: analysis.aggregateMetrics.averageDuration,
                    past: allTimeStats.averageDuration
                ),
                wpmComparison: createComparison(
                    current: analysis.aggregateMetrics.averageWPM,
                    past: allTimeStats.averageWPM
                ),
                wordCountComparison: createComparison(
                    current: analysis.aggregateMetrics.averageWordCount,
                    past: allTimeStats.averageWordCount
                ),
                uniqueWordComparison: createComparison(
                    current: analysis.aggregateMetrics.averageUniqueWordCount,
                    past: allTimeStats.averageUniqueWordCount
                ),
                vocabularyDiversityComparison: createComparison(
                    current: analysis.aggregateMetrics.vocabularyDiversityRatio,
                    past: allTimeStats.vocabularyDiversityRatio
                ),
                averageWordLengthComparison: createComparison(
                    current: analysis.loops.reduce(0.0) { $0 + $1.metrics.averageWordLength } / Double(analysis.loops.count),
                    past: allTimeStats.averageWordLength
                ),
                selfReferenceComparison: createComparison(
                    current: analysis.aggregateMetrics.averageSelfReferences,
                    past: allTimeStats.averageSelfReferences
                ),
                similarityScore: 0,
                commonWords: []
            )
        }
        
        return nil
    }
    
    func compareWithAllTimeStats(_ analysis: DailyAnalysis) -> LoopComparison? {
        guard let allTimeStats = fetchAllTimeStats() else { return nil }
        
        func createComparison(current: Double, past: Double) -> MetricComparison {
            let percentChange = ((current - past) / past) * 100
            let direction: ComparisonDirection
            if abs(percentChange) < 1 {
                direction = .same
            } else if percentChange > 0 {
                direction = .increase
            } else {
                direction = .decrease
            }
            return MetricComparison(direction: direction, percentageChange: abs(percentChange))
        }
        
        return LoopComparison(
            date: analysis.date,
            pastLoopDate: allTimeStats.lastUpdated ?? Date(),
            durationComparison: createComparison(
                current: analysis.aggregateMetrics.averageDuration,
                past: allTimeStats.averageDuration
            ),
            wpmComparison: createComparison(
                current: analysis.aggregateMetrics.averageWPM,
                past: allTimeStats.averageWPM
            ),
            wordCountComparison: createComparison(
                current: analysis.aggregateMetrics.averageWordCount,
                past: allTimeStats.averageWordCount
            ),
            uniqueWordComparison: createComparison(
                current: analysis.aggregateMetrics.averageUniqueWordCount,
                past: allTimeStats.averageUniqueWordCount
            ),
            vocabularyDiversityComparison: createComparison(
                current: analysis.aggregateMetrics.vocabularyDiversityRatio,
                past: allTimeStats.vocabularyDiversityRatio
            ),
            averageWordLengthComparison: createComparison(
                current: analysis.loops.reduce(0.0) { $0 + $1.metrics.averageWordLength } / Double(analysis.loops.count),
                past: allTimeStats.averageWordLength
            ),
            selfReferenceComparison: createComparison(
                current: analysis.aggregateMetrics.averageSelfReferences,
                past: allTimeStats.averageSelfReferences
            ),
            similarityScore: 0,
            commonWords: []
        )
    }
    
    func compareWithMonthlyStats(_ analysis: DailyAnalysis) -> LoopComparison? {
        guard let monthlyStats = fetchCurrentMonthStats() else { return nil }
        
        func createComparison(current: Double, past: Double) -> MetricComparison {
            let percentChange = ((current - past) / past) * 100
            let direction: ComparisonDirection
            if abs(percentChange) < 1 {
                direction = .same
            } else if percentChange > 0 {
                direction = .increase
            } else {
                direction = .decrease
            }
            return MetricComparison(direction: direction, percentageChange: abs(percentChange))
        }
        
        return LoopComparison(
            date: analysis.date,
            pastLoopDate: monthlyStats.lastUpdated ?? Date(),
            durationComparison: createComparison(
                current: analysis.aggregateMetrics.averageDuration,
                past: monthlyStats.averageDuration
            ),
            wpmComparison: createComparison(
                current: analysis.aggregateMetrics.averageWPM,
                past: monthlyStats.averageWPM
            ),
            wordCountComparison: createComparison(
                current: analysis.aggregateMetrics.averageWordCount,
                past: monthlyStats.averageWordCount
            ),
            uniqueWordComparison: createComparison(
                current: analysis.aggregateMetrics.averageUniqueWordCount,
                past: monthlyStats.averageUniqueWordCount
            ),
            vocabularyDiversityComparison: createComparison(
                current: analysis.aggregateMetrics.vocabularyDiversityRatio,
                past: monthlyStats.vocabularyDiversityRatio
            ),
            averageWordLengthComparison: createComparison(
                current: analysis.loops.reduce(0.0) { $0 + $1.metrics.averageWordLength } / Double(analysis.loops.count),
                past: monthlyStats.averageWordLength
            ),
            selfReferenceComparison: createComparison(
                current: analysis.aggregateMetrics.averageSelfReferences,
                past: monthlyStats.averageSelfReferences
            ),
            similarityScore: 0,
            commonWords: []
        )
    }
    
    func compareWithWeeklyStats(_ analysis: DailyAnalysis) -> LoopComparison? {
        guard let weeklyStats = fetchCurrentWeekStats() else { return nil }
        
        func createComparison(current: Double, past: Double) -> MetricComparison {
            let percentChange = ((current - past) / past) * 100
            let direction: ComparisonDirection
            if abs(percentChange) < 1 {
                direction = .same
            } else if percentChange > 0 {
                direction = .increase
            } else {
                direction = .decrease
            }
            return MetricComparison(direction: direction, percentageChange: abs(percentChange))
        }
        
        return LoopComparison(
            date: analysis.date,
            pastLoopDate: weeklyStats.lastUpdated ?? Date(),
            durationComparison: createComparison(
                current: analysis.aggregateMetrics.averageDuration,
                past: weeklyStats.averageDuration
            ),
            wpmComparison: createComparison(
                current: analysis.aggregateMetrics.averageWPM,
                past: weeklyStats.averageWPM
            ),
            wordCountComparison: createComparison(
                current: analysis.aggregateMetrics.averageWordCount,
                past: weeklyStats.averageWordCount
            ),
            uniqueWordComparison: createComparison(
                current: analysis.aggregateMetrics.averageUniqueWordCount,
                past: weeklyStats.averageUniqueWordCount
            ),
            vocabularyDiversityComparison: createComparison(
                current: analysis.aggregateMetrics.vocabularyDiversityRatio,
                past: weeklyStats.vocabularyDiversityRatio
            ),
            averageWordLengthComparison: createComparison(
                current: analysis.loops.reduce(0.0) { $0 + $1.metrics.averageWordLength } / Double(analysis.loops.count),
                past: weeklyStats.averageWordLength
            ),
            selfReferenceComparison: createComparison(
                current: analysis.aggregateMetrics.averageSelfReferences,
                past: weeklyStats.averageSelfReferences
            ),
            similarityScore: 0,
            commonWords: []
        )
    }
}
