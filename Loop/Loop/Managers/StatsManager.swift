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

import Foundation
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
        print("\n📊 Updating stats with analysis from \(analysis.date)")
        
        // Create or fetch all required entities
        guard let allTimeEntity = createOrFetchEntity(type: "AllTimeStatsEntity"),
              let monthlyEntity = createOrFetchMonthlyEntity(),
              let weeklyEntity = createOrFetchWeeklyEntity() else {
            print("❌ Failed to create/fetch required entities")
            return
        }
        
        // First entry handling and updates
        updateEntityStats(allTimeEntity, with: analysis, isFirstEntry: allTimeEntity.value(forKey: "dataPointCount") as? Int64 == 0)
        updateEntityStats(monthlyEntity, with: analysis, isFirstEntry: monthlyEntity.value(forKey: "dataPointCount") as? Int64 == 0)
        updateEntityStats(weeklyEntity, with: analysis, isFirstEntry: weeklyEntity.value(forKey: "dataPointCount") as? Int64 == 0)
        
        // Save context
        do {
            try context.save()
            print("✅ Successfully saved all stats updates")
            printEntityStats(allTimeEntity, label: "All Time")
            printEntityStats(monthlyEntity, label: "Monthly")
            printEntityStats(weeklyEntity, label: "Weekly")
        } catch {
            print("❌ Failed to save stats updates: \(error)")
            context.rollback()
        }
    }
    
    private func createOrFetchEntity(type: String) -> NSManagedObject? {
        print("📝 Creating/Fetching entity of type: \(type)")
        let request = NSFetchRequest<NSManagedObject>(entityName: type)
        
        do {
            if let existing = try context.fetch(request).first {
                print("✅ Found existing \(type)")
                return existing
            }
        } catch {
            print("❌ Error fetching \(type): \(error)")
            return nil
        }
        
        guard let entity = NSEntityDescription.entity(forEntityName: type, in: context) else {
            print("❌ Failed to get entity description for \(type)")
            return nil
        }
        
        let new = NSManagedObject(entity: entity, insertInto: context)
        print("✅ Created new \(type)")
        return new
    }
    
    private func createOrFetchMonthlyEntity() -> NSManagedObject? {
        let components = Calendar.current.dateComponents([.month, .year], from: Date())
        guard let month = components.month,
              let year = components.year else {
            print("❌ Failed to get current month/year")
            return nil
        }
        
        print("📅 Looking for monthly entity: Month \(month), Year \(year)")
        
        let request = NSFetchRequest<NSManagedObject>(entityName: "MonthlyStatsEntity")
        request.predicate = NSPredicate(format: "month == %d AND year == %d", month, year)
        
        do {
            if let existing = try context.fetch(request).first {
                print("✅ Found existing monthly entity")
                return existing
            }
        } catch {
            print("❌ Error fetching monthly entity: \(error)")
            return nil
        }
        
        guard let entity = NSEntityDescription.entity(forEntityName: "MonthlyStatsEntity", in: context) else {
            print("❌ Failed to get MonthlyStatsEntity description")
            return nil
        }
        
        let new = NSManagedObject(entity: entity, insertInto: context)
        new.setValue(Int16(month), forKey: "month")
        new.setValue(Int16(year), forKey: "year")
        print("✅ Created new monthly entity")
        return new
    }
    
    private func createOrFetchWeeklyEntity() -> NSManagedObject? {
        let components = Calendar.current.dateComponents([.weekOfYear, .year], from: Date())
        guard let week = components.weekOfYear,
              let year = components.year else {
            print("❌ Failed to get current week/year")
            return nil
        }
        
        print("📅 Looking for weekly entity: Week \(week), Year \(year)")
        
        let request = NSFetchRequest<NSManagedObject>(entityName: "WeeklyStatsEntity")
        request.predicate = NSPredicate(format: "weekNumber == %d AND year == %d", week, year)
        
        do {
            if let existing = try context.fetch(request).first {
                print("✅ Found existing weekly entity")
                return existing
            }
        } catch {
            print("❌ Error fetching weekly entity: \(error)")
            return nil
        }
        
        guard let entity = NSEntityDescription.entity(forEntityName: "WeeklyStatsEntity", in: context) else {
            print("❌ Failed to get WeeklyStatsEntity description")
            return nil
        }
        
        let new = NSManagedObject(entity: entity, insertInto: context)
        new.setValue(Int16(week), forKey: "weekNumber")
        new.setValue(Int16(year), forKey: "year")
        print("✅ Created new weekly entity")
        return new
    }
    
    private func updateEntityStats(_ entity: NSManagedObject, with analysis: DailyAnalysis, isFirstEntry: Bool) {
        if isFirstEntry {
            // For first entry, use the values directly
            print("📈 First entry - setting initial values")
            entity.setValue(analysis.aggregateMetrics.averageWPM, forKey: "averageWPM")
            entity.setValue(analysis.aggregateMetrics.averageDuration, forKey: "averageDuration")
            entity.setValue(analysis.aggregateMetrics.averageWordCount, forKey: "averageWordCount")
            entity.setValue(analysis.aggregateMetrics.vocabularyDiversity, forKey: "vocabularyDiversityRatio")
            entity.setValue(1, forKey: "dataPointCount")
        } else {
            // For subsequent entries, calculate running averages
            let currentCount = entity.value(forKey: "dataPointCount") as? Int64 ?? 0
            print("📊 Updating existing entry - current count: \(currentCount)")
            
            entity.setValue(
                updateRunningAverage(
                    currentAvg: entity.value(forKey: "averageWPM") as? Double ?? 0,
                    currentCount: Int(currentCount),
                    newValue: analysis.aggregateMetrics.averageWPM
                ),
                forKey: "averageWPM"
            )
            
            entity.setValue(
                updateRunningAverage(
                    currentAvg: entity.value(forKey: "averageDuration") as? Double ?? 0,
                    currentCount: Int(currentCount),
                    newValue: analysis.aggregateMetrics.averageDuration
                ),
                forKey: "averageDuration"
            )
            
            entity.setValue(
                updateRunningAverage(
                    currentAvg: entity.value(forKey: "averageWordCount") as? Double ?? 0,
                    currentCount: Int(currentCount),
                    newValue: analysis.aggregateMetrics.averageWordCount
                ),
                forKey: "averageWordCount"
            )
            
            entity.setValue(
                updateRunningAverage(
                    currentAvg: entity.value(forKey: "vocabularyDiversityRatio") as? Double ?? 0,
                    currentCount: Int(currentCount),
                    newValue: analysis.aggregateMetrics.vocabularyDiversity
                ),
                forKey: "vocabularyDiversityRatio"
            )
            
            entity.setValue(currentCount + 1, forKey: "dataPointCount")
        }
        
        entity.setValue(Date(), forKey: "lastUpdated")
    }
    
    private func updateRunningAverage(currentAvg: Double, currentCount: Int, newValue: Double) -> Double {
        let newCount = currentCount + 1
        return ((currentAvg * Double(currentCount)) + newValue) / Double(newCount)
    }
    
    private func printEntityStats(_ entity: NSManagedObject, label: String) {
        print("\n📊 \(label) Stats:")
        print("Count: \(entity.value(forKey: "dataPointCount") as? Int64 ?? 0)")
        print("WPM: \(entity.value(forKey: "averageWPM") as? Double ?? 0)")
        print("Duration: \(entity.value(forKey: "averageDuration") as? Double ?? 0)")
        print("Word Count: \(entity.value(forKey: "averageWordCount") as? Double ?? 0)")
        print("Vocabulary Diversity: \(entity.value(forKey: "vocabularyDiversityRatio") as? Double ?? 0)")
    }
}
