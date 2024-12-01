//
//  LocalLoopStorageUtility.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/29/24.
//

import Foundation
import CoreData
import CloudKit

class LoopLocalStorageUtility {
    static let shared = LoopLocalStorageUtility()
    
    // MARK: - File Management
    private let fileManager = FileManager.default
    
    private var mediaDirectory: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let mediaDir = paths[0].appendingPathComponent("LoopMedia")
        
        if !fileManager.fileExists(atPath: mediaDir.path) {
            try? fileManager.createDirectory(at: mediaDir, withIntermediateDirectories: true)
        }
        
        return mediaDir
    }
    
    private lazy var persistentContainer: NSPersistentContainer = {
        guard let modelURL = Bundle.main.url(forResource: "LoopData", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Core Data model not found") // This is okay as it's an app configuration error
        }
        
        let container = NSPersistentContainer(name: "LoopData")
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data store failed to load: \(error.localizedDescription)")
            }
        }
        return container
    }()

    private var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    // Modify addLoop function:
    func addLoop(loop: Loop) async {
        guard let entity = NSEntityDescription.entity(forEntityName: "LoopEntity", in: context) else {
            print("Failed to get LoopEntity")
            return
        }
        
        let loopEntity = NSManagedObject(entity: entity, insertInto: context)
        
        // Save media file to local storage
        if let assetURL = loop.data.fileURL {
            let fileExtension = loop.isVideo ? "mp4" : "m4a"
            let destinationURL = mediaDirectory.appendingPathComponent("\(loop.id).\(fileExtension)")
            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.copyItem(at: assetURL, to: destinationURL)
                loopEntity.setValue(destinationURL.path, forKey: "filePath")
            } catch {
                print("Failed to save media file: \(error.localizedDescription)")
                return
            }
        }
        
        loopEntity.setValue(loop.id, forKey: "id")
        loopEntity.setValue(loop.timestamp, forKey: "timestamp")
        loopEntity.setValue(loop.lastRetrieved, forKey: "lastRetrieved")
        loopEntity.setValue(loop.promptText, forKey: "promptText")
        loopEntity.setValue(loop.mood, forKey: "mood")
        loopEntity.setValue(loop.freeResponse, forKey: "freeResponse")
        loopEntity.setValue(loop.isVideo, forKey: "isVideo")
        loopEntity.setValue(loop.isDailyLoop, forKey: "isDailyLoop")
        
        do {
            try context.save()
            print("Loop saved successfully to local storage")
        } catch {
            print("Failed to save loop: \(error.localizedDescription)")
        }
    }

    // Add this helper function for converting managed objects to Loops:
    private func convertToLoop(from entity: NSManagedObject) -> Loop? {
        guard let id = entity.value(forKey: "id") as? String,
              let filePath = entity.value(forKey: "filePath") as? String,
              let timestamp = entity.value(forKey: "timestamp") as? Date,
              let promptText = entity.value(forKey: "promptText") as? String else {
            return nil
        }
        
        let fileURL = URL(fileURLWithPath: filePath)
        guard FileManager.default.fileExists(atPath: filePath) else {
            return nil
        }
        
        let asset = CKAsset(fileURL: fileURL)
        
        return Loop(
            id: id,
            data: asset,
            timestamp: timestamp,
            lastRetrieved: entity.value(forKey: "lastRetrieved") as? Date,
            promptText: promptText,
            mood: entity.value(forKey: "mood") as? String,
            freeResponse: entity.value(forKey: "freeResponse") as? Bool ?? false,
            isVideo: entity.value(forKey: "isVideo") as? Bool ?? false,
            isDailyLoop: entity.value(forKey: "isDailyLoop") as? Bool ?? false
        )
    }
    
    func fetchLoops(for date: Date) async throws -> [Loop] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "LoopEntity")
        fetchRequest.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp < %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        
        let results = try context.fetch(fetchRequest)
        return results.compactMap { convertToLoop(from: $0) }
    }

    
    // MARK: - Advanced Queries
    func checkThreeDayRequirement() async throws -> Bool {
        // Check for 3 consecutive days of loops
        let distinctDays = try await fetchDistinctLoopingDays()
        return distinctDays >= 3
    }
    
    func fetchDistinctLoopingDays() async throws -> Int {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "LoopEntity")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        let calendar = Calendar.current
        var distinctDates = Set<Date>()
        
        // Fetch all results and process
        let results = try context.fetch(fetchRequest)
        for result in results {
            if let timestamp = result.value(forKey: "timestamp") as? Date {
                let startOfDay = calendar.startOfDay(for: timestamp)
                distinctDates.insert(startOfDay)
            }
        }
        
        return distinctDates.count
    }
    
    func fetchPastLoop(
        forPrompts prompts: [String],
        minDaysAgo: Int,
        maxDaysAgo: Int,
        preferGeneralPrompts: Bool,
        category: PromptCategory? = nil
    ) async throws -> Loop? {
        let calendar = Calendar.current
        let now = Date()
        
        guard let minDate = calendar.date(byAdding: .day, value: -maxDaysAgo, to: now),
              let maxDate = calendar.date(byAdding: .day, value: -minDaysAgo, to: now) else {
            throw NSError(domain: "DateCalculationError", code: -1)
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "LoopEntity")
        fetchRequest.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp <= %@",
            minDate as NSDate,
            maxDate as NSDate
        )
        
        let results = try context.fetch(fetchRequest)
        var scoredLoops: [(Loop, Double)] = []
        
        for result in results {
            guard let loop = convertToLoop(from: result) else { continue }
            let score = calculateLoopScore(
                loop: loop,
                basedOn: prompts,
                category: category,
                preferGeneralPrompts: preferGeneralPrompts
            )
            scoredLoops.append((loop, score))
        }
        
        return scoredLoops
            .sorted { $0.1 > $1.1 }
            .first { $0.1 >= 0.3 }?
            .0
    }
    
    func calculateStreak() async throws -> LoopingStreak {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "LoopEntity")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        let results = try context.fetch(fetchRequest)
        let calendar = Calendar.current
        
        var dates = Set<Date>()
        var consecutiveDays = 0
        var longestStreak = 0
        var lastDate: Date?
        
        for result in results {
            guard let timestamp = result.value(forKey: "timestamp") as? Date else { continue }
            let startOfDay = calendar.startOfDay(for: timestamp)
            dates.insert(startOfDay)
            
            if let last = lastDate {
                let daysDifference = calendar.dateComponents([.day], from: startOfDay, to: last).day ?? 0
                if daysDifference == 1 {
                    consecutiveDays += 1
                    longestStreak = max(longestStreak, consecutiveDays)
                } else {
                    consecutiveDays = 0
                }
            }
            lastDate = startOfDay
        }
        
        return LoopingStreak(
            currentStreak: consecutiveDays,
            longestStreak: longestStreak,
            distinctDays: dates.count
        )
    }
    
    // Helper function for scoring loops
    private func calculateLoopScore(
        loop: Loop,
        basedOn prompts: [String],
        category: PromptCategory?,
        preferGeneralPrompts: Bool
    ) -> Double {
        var score: Double = 0
        
        // Age score
        let ageInDays = Double(Calendar.current.dateComponents([.day], from: loop.timestamp, to: Date()).day ?? 0)
        score += min(ageInDays / 365, 1.0) * 0.2
        
        // Category score
        if let category = category,
           let loopPrompt = LoopManager.shared.promptGroups.values
            .flatMap({ $0 })
            .first(where: { $0.text == loop.promptText }) {
            if loopPrompt.category == category {
                score += 0.3
            }
        }
        
        // Prompt type score
        if let loopPrompt = LoopManager.shared.promptGroups.values
            .flatMap({ $0 })
            .first(where: { $0.text == loop.promptText }) {
            if preferGeneralPrompts && !loopPrompt.isDailyPrompt {
                score += 0.3
            }
        }
        
        // Retrieval score
        if let lastRetrieved = loop.lastRetrieved {
            let daysSinceRetrieved = Double(Calendar.current.dateComponents([.day], from: lastRetrieved, to: Date()).day ?? 0)
            score += min(daysSinceRetrieved / 30, 1.0) * 0.2
        } else {
            score += 0.2
        }
        
        return score
    }
    
    // MARK: - Date-based Operations
    func fetchRecentLoopDates(
        startingFrom startDate: Date? = nil,
        limit: Int = 6
    ) async throws -> [Date] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "LoopEntity")
        if let startDate = startDate {
            fetchRequest.predicate = NSPredicate(format: "timestamp < %@", startDate as NSDate)
        }
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        let results = try context.fetch(fetchRequest)
        let calendar = Calendar.current
        
        var uniqueDates = Set<Date>()
        var dateArray: [Date] = []
        
        for result in results {
            if let timestamp = result.value(forKey: "timestamp") as? Date {
                let loopDate = calendar.startOfDay(for: timestamp)
                if uniqueDates.insert(loopDate).inserted {
                    dateArray.append(loopDate)
                    if dateArray.count >= limit {
                        break
                    }
                }
            }
        }
        
        return dateArray
    }
    
    func checkDailyCompletion(for dates: [Date]) async throws -> [Date: Bool] {
        var completionStatus: [Date: Bool] = [:]
        let calendar = Calendar.current
        
        for date in dates {
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "LoopEntity")
            fetchRequest.predicate = NSPredicate(
                format: "timestamp >= %@ AND timestamp < %@",
                startOfDay as NSDate,
                endOfDay as NSDate
            )
            
            let count = try context.count(for: fetchRequest)
            completionStatus[startOfDay] = count >= 3
        }
        
        return completionStatus
    }
    
    func fetchActiveMonths(year: Int? = nil) async throws -> [MonthIdentifier] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "LoopEntity")
        
        if let year = year {
            let calendar = Calendar.current
            var startComponents = DateComponents()
            startComponents.year = year
            startComponents.month = 1
            startComponents.day = 1
            
            var endComponents = DateComponents()
            endComponents.year = year + 1
            endComponents.month = 1
            endComponents.day = 1
            
            guard let startDate = calendar.date(from: startComponents),
                  let endDate = calendar.date(from: endComponents) else {
                throw NSError(domain: "DateError", code: -1)
            }
            
            fetchRequest.predicate = NSPredicate(
                format: "timestamp >= %@ AND timestamp < %@",
                startDate as NSDate,
                endDate as NSDate
            )
        }
        
        let results = try context.fetch(fetchRequest)
        let calendar = Calendar.current
        
        let monthIdentifiers = results.compactMap { result -> MonthIdentifier? in
            guard let timestamp = result.value(forKey: "timestamp") as? Date else { return nil }
            let components = calendar.dateComponents([.year, .month], from: timestamp)
            guard let year = components.year, let month = components.month else { return nil }
            return MonthIdentifier(year: year, month: month)
        }
        
        return Array(Set(monthIdentifiers)).sorted { first, second in
            if first.year != second.year {
                return first.year > second.year
            }
            return first.month > second.month
        }
    }
    
    func fetchMonthData(monthId: MonthIdentifier) async throws -> MonthSummary {
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.year = monthId.year
        dateComponents.month = monthId.month
        
        guard let startDate = calendar.date(from: dateComponents),
              let endDate = calendar.date(byAdding: DateComponents(month: 1), to: startDate) else {
            throw NSError(domain: "DateError", code: -1)
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "LoopEntity")
        fetchRequest.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp < %@",
            startDate as NSDate,
            endDate as NSDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        
        let results = try context.fetch(fetchRequest)
        let loops = results.compactMap { convertToLoop(from: $0) }
        
        return MonthSummary(
            year: monthId.year,
            month: monthId.month,
            totalEntries: loops.count,
            completionRate: calculateCompletionRate(loops: loops),
            loops: loops
        )
    }
    
    func saveAnalysis(loop: Loop, sentiment: Double, keywords: [String]) {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "LoopEntity")
        fetchRequest.predicate = NSPredicate(format: "id == %@", loop.id)
        
        do {
            if let existingLoop = try context.fetch(fetchRequest).first {
                existingLoop.setValue(sentiment, forKey: "sentimentScore")
                existingLoop.setValue(keywords, forKey: "keywords")
                try context.save()
            }
        } catch {
            print("Error saving analysis: \(error)")
        }
    }
    
    // MARK: - Helper Functions
    private func calculateCompletionRate(loops: [Loop]) -> Double {
        let calendar = Calendar.current
        let groupedByDay = Dictionary(grouping: loops) { loop in
            calendar.startOfDay(for: loop.timestamp)
        }
        
        if let firstLoop = loops.first,
           let daysInMonth = calendar.range(of: .day, in: .month, for: firstLoop.timestamp)?.count {
            return Double(groupedByDay.count) / Double(daysInMonth)
        }
        return 0.0
    }
}
