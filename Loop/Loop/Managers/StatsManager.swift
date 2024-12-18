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
    
    func updateStats(with analysis: DailyAnalysis) {
        guard let allTimeEntity = createOrFetchEntity(type: "AllTimeStatsEntity"),
              let monthlyEntity = createOrFetchMonthlyEntity(),
              let weeklyEntity = createOrFetchWeeklyEntity() else {
            return
        }
        
        updateEntityStats(allTimeEntity, with: analysis)
        updateEntityStats(monthlyEntity, with: analysis)
        updateEntityStats(weeklyEntity, with: analysis)
        
        do {
            try context.save()
        } catch {
            print("Failed to save stats updates: \(error)")
        }
    }
    
    private func createOrFetchEntity(type: String) -> NSManagedObject? {
        let request = NSFetchRequest<NSManagedObject>(entityName: type)
        
        if let existing = try? context.fetch(request).first {
            return existing
        }
        
        guard let entity = NSEntityDescription.entity(forEntityName: type, in: context) else {
            return nil
        }
        
        let new = NSManagedObject(entity: entity, insertInto: context)
        initializeEntity(new)
        return new
    }
    
    private func createOrFetchMonthlyEntity() -> NSManagedObject? {
        let request = NSFetchRequest<NSManagedObject>(entityName: "MonthlyStatsEntity")
        let components = Calendar.current.dateComponents([.month, .year], from: Date())
        
        guard let month = components.month,
              let year = components.year else {
            return nil
        }
        
        request.predicate = NSPredicate(format: "month == %d AND year == %d", month, year)
        
        if let existing = try? context.fetch(request).first {
            return existing
        }
        
        guard let entity = NSEntityDescription.entity(forEntityName: "MonthlyStatsEntity", in: context) else {
            return nil
        }
        
        let new = NSManagedObject(entity: entity, insertInto: context)
        initializeEntity(new)
        new.setValue(Int16(month), forKey: "month")
        new.setValue(Int16(year), forKey: "year")
        return new
    }
    
    private func createOrFetchWeeklyEntity() -> NSManagedObject? {
        let request = NSFetchRequest<NSManagedObject>(entityName: "WeeklyStatsEntity")
        let components = Calendar.current.dateComponents([.weekOfYear, .year], from: Date())
        
        guard let week = components.weekOfYear,
              let year = components.year else {
            return nil
        }
        
        request.predicate = NSPredicate(format: "weekNumber == %d AND year == %d", week, year)
        
        if let existing = try? context.fetch(request).first {
            return existing
        }
        
        guard let entity = NSEntityDescription.entity(forEntityName: "WeeklyStatsEntity", in: context) else {
            return nil
        }
        
        let new = NSManagedObject(entity: entity, insertInto: context)
        initializeEntity(new)
        new.setValue(Int16(week), forKey: "weekNumber")
        new.setValue(Int16(year), forKey: "year")
        return new
    }
    
    private func initializeEntity(_ entity: NSManagedObject) {
        entity.setValue(0, forKey: "dataPointCount")
        entity.setValue(0.0, forKey: "averageWPM")
        entity.setValue(0.0, forKey: "averageDuration")
        entity.setValue(0.0, forKey: "averageWordCount")
        entity.setValue(0.0, forKey: "averageUniqueWordCount")
        entity.setValue(0.0, forKey: "averageSelfReferences")
        entity.setValue(0.0, forKey: "vocabularyDiversityRatio")
        entity.setValue(0.0, forKey: "averageWordLength")
        entity.setValue(Date(), forKey: "lastUpdated")
    }
    
    private func updateEntityStats(_ entity: NSManagedObject, with analysis: DailyAnalysis) {
        let currentCount = entity.value(forKey: "dataPointCount") as? Int64 ?? 0
        
        entity.setValue(updateRunningAverage(currentAvg: entity.value(forKey: "averageWPM") as? Double ?? 0,
                                          currentCount: Int(currentCount),
                                          newValue: analysis.aggregateMetrics.averageWPM),
                       forKey: "averageWPM")
        
        entity.setValue(updateRunningAverage(currentAvg: entity.value(forKey: "averageDuration") as? Double ?? 0,
                                          currentCount: Int(currentCount),
                                          newValue: analysis.aggregateMetrics.averageDuration),
                       forKey: "averageDuration")
        
        entity.setValue(updateRunningAverage(currentAvg: entity.value(forKey: "averageWordCount") as? Double ?? 0,
                                          currentCount: Int(currentCount),
                                          newValue: analysis.aggregateMetrics.averageWordCount),
                       forKey: "averageWordCount")
        
        entity.setValue(updateRunningAverage(currentAvg: entity.value(forKey: "averageUniqueWordCount") as? Double ?? 0,
                                          currentCount: Int(currentCount),
                                          newValue: analysis.aggregateMetrics.averageUniqueWordCount),
                       forKey: "averageUniqueWordCount")
        
        entity.setValue(updateRunningAverage(currentAvg: entity.value(forKey: "averageSelfReferences") as? Double ?? 0,
                                          currentCount: Int(currentCount),
                                          newValue: analysis.aggregateMetrics.averageSelfReferences),
                       forKey: "averageSelfReferences")
        
        entity.setValue(updateRunningAverage(currentAvg: entity.value(forKey: "vocabularyDiversityRatio") as? Double ?? 0,
                                          currentCount: Int(currentCount),
                                          newValue: analysis.aggregateMetrics.vocabularyDiversityRatio),
                       forKey: "vocabularyDiversityRatio")
        
        entity.setValue(updateRunningAverage(currentAvg: entity.value(forKey: "averageWordLength") as? Double ?? 0,
                                          currentCount: Int(currentCount),
                                          newValue: analysis.loops.reduce(0.0) { $0 + $1.metrics.averageWordLength } / Double(analysis.loops.count)),
                       forKey: "averageWordLength")
        
        entity.setValue(currentCount + 1, forKey: "dataPointCount")
        entity.setValue(Date(), forKey: "lastUpdated")
    }
    
    private func updateRunningAverage(currentAvg: Double, currentCount: Int, newValue: Double) -> Double {
        let newCount = currentCount + 1
        return ((currentAvg * Double(currentCount)) + newValue) / Double(newCount)
    }
    
    func compareWithAllTimeStats(_ analysis: DailyAnalysis) -> LoopComparison? {
        guard let entity = createOrFetchEntity(type: "AllTimeStatsEntity") else { return nil }
        return createComparison(for: analysis, with: entity)
    }
    
    func compareWithMonthlyStats(_ analysis: DailyAnalysis) -> LoopComparison? {
        guard let entity = createOrFetchMonthlyEntity() else { return nil }
        return createComparison(for: analysis, with: entity)
    }
    
    func compareWithWeeklyStats(_ analysis: DailyAnalysis) -> LoopComparison? {
        guard let entity = createOrFetchWeeklyEntity() else { return nil }
        return createComparison(for: analysis, with: entity)
    }
    
    private func createComparison(for analysis: DailyAnalysis, with entity: NSManagedObject) -> LoopComparison {
        func createMetricComparison(current: Double, past: Double) -> MetricComparison {
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
            pastLoopDate: entity.value(forKey: "lastUpdated") as? Date ?? Date(),
            durationComparison: createMetricComparison(
                current: analysis.aggregateMetrics.averageDuration,
                past: entity.value(forKey: "averageDuration") as? Double ?? 0
            ),
            wpmComparison: createMetricComparison(
                current: analysis.aggregateMetrics.averageWPM,
                past: entity.value(forKey: "averageWPM") as? Double ?? 0
            ),
            wordCountComparison: createMetricComparison(
                current: analysis.aggregateMetrics.averageWordCount,
                past: entity.value(forKey: "averageWordCount") as? Double ?? 0
            ),
            uniqueWordComparison: createMetricComparison(
                current: analysis.aggregateMetrics.averageUniqueWordCount,
                past: entity.value(forKey: "averageUniqueWordCount") as? Double ?? 0
            ),
            vocabularyDiversityComparison: createMetricComparison(
                current: analysis.aggregateMetrics.vocabularyDiversityRatio,
                past: entity.value(forKey: "vocabularyDiversityRatio") as? Double ?? 0
            ),
            averageWordLengthComparison: createMetricComparison(
                current: analysis.loops.reduce(0.0) { $0 + $1.metrics.averageWordLength } / Double(analysis.loops.count),
                past: entity.value(forKey: "averageWordLength") as? Double ?? 0
            ),
            selfReferenceComparison: createMetricComparison(
                current: analysis.aggregateMetrics.averageSelfReferences,
                past: entity.value(forKey: "averageSelfReferences") as? Double ?? 0
            ),
            similarityScore: 0,
            commonWords: []
        )
    }
}
