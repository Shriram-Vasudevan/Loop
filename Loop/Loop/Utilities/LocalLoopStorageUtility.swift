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
        let container = NSPersistentContainer(name: "LoopData")
        
        let options = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true
        ]
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("Persistent store failed to load: \(error.localizedDescription)")
                print("Detailed error: \(error)")
                print("Error user info: \(error.userInfo)")
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        return container
    }()

    private var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    func addLoop(loop: Loop) async {
        await MainActor.run {
            guard let entity = NSEntityDescription.entity(forEntityName: "LoopEntity", in: context) else {
                print("Failed to get LoopEntity")
                return
            }
            
            let loopEntity = NSManagedObject(entity: entity, insertInto: context)
            
            if let assetURL = loop.data.fileURL {
                let fileExtension = loop.isVideo ? "mp4" : "m4a"
                let fileName = "\(loop.id).\(fileExtension)"
                let destinationURL = mediaDirectory.appendingPathComponent(fileName)
                do {
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                    try FileManager.default.copyItem(at: assetURL, to: destinationURL)
                    loopEntity.setValue(fileName, forKey: "filePath")
                } catch {
                    print("Failed to save media file: \(error.localizedDescription)")
                    return
                }
            }
            
            loopEntity.setValue(loop.id, forKey: "id")
            loopEntity.setValue(loop.timestamp, forKey: "timestamp")
            loopEntity.setValue(loop.lastRetrieved, forKey: "lastRetrieved")
            loopEntity.setValue(loop.promptText, forKey: "promptText")
            loopEntity.setValue(loop.category, forKey: "category")
            loopEntity.setValue(loop.transcript, forKey: "transcript")
            loopEntity.setValue(loop.mood, forKey: "mood")
            loopEntity.setValue(loop.freeResponse, forKey: "freeResponse")
            loopEntity.setValue(loop.isVideo, forKey: "isVideo")
            loopEntity.setValue(loop.isDailyLoop, forKey: "isDailyLoop")
            loopEntity.setValue(loop.isFollowUp, forKey: "isFollowUp")
            
            do {
                try context.save()
                print("Loop saved successfully to local storage")
            } catch {
                print("Failed to save loop: \(error.localizedDescription)")
            }
        }
    }
    
    private func convertToLoop(from entity: NSManagedObject) -> Loop? {
        guard let id = entity.value(forKey: "id") as? String,
                  let fileName = entity.value(forKey: "filePath") as? String,  // Now just getting filename
                  let timestamp = entity.value(forKey: "timestamp") as? Date,
                  let promptText = entity.value(forKey: "promptText") as? String else {
                return nil
            }
            
        let fileURL = mediaDirectory.appendingPathComponent(fileName)  // Construct full path here
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        let asset = CKAsset(fileURL: fileURL)
        
        // Get category from LoopManager using the promptText
        let category = LoopManager.shared.getCategoryForPrompt(promptText)?.rawValue ?? "Share Anything"
        
        return Loop(
            id: id,
            data: asset,
            timestamp: timestamp,
            lastRetrieved: entity.value(forKey: "lastRetrieved") as? Date,
            promptText: promptText,
            category: category,
            transcript: entity.value(forKey: "transcript") as? String,
            freeResponse: entity.value(forKey: "freeResponse") as? Bool ?? false,
            isVideo: entity.value(forKey: "isVideo") as? Bool ?? false,
            isDailyLoop: entity.value(forKey: "isDailyLoop") as? Bool ?? false, 
            isFollowUp: entity.value(forKey: "isFollowUp") as? Bool ?? false,
            mood: entity.value(forKey: "mood") as? String
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
    func checkThreeDayRequirement() async throws -> (Bool, Int) {
        // Check for 3 consecutive days of loops
        let distinctDays = try await fetchDistinctLoopingDays()
        return (distinctDays >= 3, distinctDays)
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
        maxDaysAgo: Int?,
        categoryFrequencies: [PromptCategory: Double]
    ) async throws -> Loop? {
        let calendar = Calendar.current
        let now = Date()
        
        // Handle optional maxDaysAgo
        let maxDaysAgoValue = maxDaysAgo ?? Int.max

        // Calculate the date range
        guard let minDate = calendar.date(byAdding: .day, value: -maxDaysAgoValue, to: now),
              let maxDate = calendar.date(byAdding: .day, value: -minDaysAgo, to: now) else {
            throw NSError(domain: "DateCalculationError", code: -1)
        }

        print("🔍 Searching local storage between \(minDate) and \(maxDate)")
        
        // Query for loops in the date range
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "LoopEntity")
        fetchRequest.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp <= %@",
            minDate as NSDate,
            maxDate as NSDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)] // Newest first
        
        // Fetch the records
        let results = try context.fetch(fetchRequest)
        print("📊 Found \(results.count) loops in the specified time window")
        
        // Convert records to Loop objects
        let loops = results.compactMap { convertToLoop(from: $0) }
        
        if loops.isEmpty {
            print("❌ No loops found in local storage")
            return nil
        }

        // Score the loops
        let scoredLoops = loops.map { loop -> (Loop, Double) in
            let score = calculateLoopScore(
                loop: loop,
                prompts: prompts,
                categoryFrequencies: categoryFrequencies,
                now: now
            )
            return (loop, score)
        }

        // Log top-scoring loops
        print("⭐️ Top scoring loops in this time window:")
        scoredLoops.sorted { $0.1 > $1.1 }
            .prefix(3)
            .forEach { loop, score in
                print("   Score: \(score) - Prompt: \(loop.promptText) - Date: \(loop.timestamp.formatted())")
            }

        // Return the best match above the threshold
        if let bestMatch = scoredLoops.max(by: { $0.1 < $1.1 }), bestMatch.1 > 0.3 {
            return bestMatch.0
        }
        
        print("❌ No suitable loops found in local storage")
        return nil
    }

    private func calculateLoopScore(
        loop: Loop,
        prompts: [String],
        categoryFrequencies: [PromptCategory: Double],
        now: Date
    ) -> Double {
        var score: Double = 0.0
        let calendar = Calendar.current

        // Prompt match bonus
        if prompts.contains(loop.promptText) {
            score += 0.6
            print("💾 Local - Exact prompt match: +0.6")
        }

        // Category frequency boost
        if let loopCategory = PromptCategory(rawValue: loop.category) {
            if loopCategory == .freeform {
                score -= 0.1
                print("💾 Local - Share Anything penalty: -0.1")
            } else {
                for (category, frequency) in categoryFrequencies {
                    if category == loopCategory {
                        let categoryBoost = 0.3 * frequency
                        score += categoryBoost
                        print("💾 Local - Category frequency boost (\(category)): +\(categoryBoost)")
                    }
                }
            }
        }

        // Anniversary bonus
        let monthsAgo = Double(calendar.dateComponents([.month], from: loop.timestamp, to: now).month ?? 0)
        let dayOfMonth = calendar.component(.day, from: loop.timestamp)
        let currentDay = calendar.component(.day, from: now)
        if dayOfMonth == currentDay {
            if [3, 6, 9, 12].contains(monthsAgo) {
                score += 0.4
                print("💾 Local - Significant anniversary: +0.4")
            } else {
                score += 0.2
                print("💾 Local - Monthly anniversary: +0.2")
            }
        }

        // Time range bonus
        if monthsAgo >= 3 && monthsAgo <= 6 {
            score += 0.2
            print("💾 Local - Ideal time range (3-6 months): +0.2")
        } else if monthsAgo >= 1 && monthsAgo <= 3 {
            score += 0.1
            print("💾 Local - Good time range (1-3 months): +0.1")
        } else if monthsAgo >= 6 && monthsAgo <= 12 {
            score += 0.05
            print("💾 Local - Acceptable time range (6-12 months): +0.05")
        }

        // Last retrieved penalty
        if let lastRetrieved = loop.lastRetrieved {
            let daysAgo = calendar.dateComponents([.day], from: lastRetrieved, to: now).day ?? 0
            var penalty: Double = 0.0
            
            switch daysAgo {
            case 0...7:     penalty = 0.8
            case 8...14:    penalty = 0.6
            case 15...30:   penalty = 0.4
            case 31...60:   penalty = 0.2
            default:        penalty = 0.0
            }
            
            if penalty > 0 {
                score -= penalty
                print("💾 Local - Recent retrieval penalty: -\(penalty)")
            }
        }

        return max(0.0, min(1.0, score))
    }


    func updateLastRetrieved(for loop: Loop) throws {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "LoopEntity")
        fetchRequest.predicate = NSPredicate(format: "id == %@", loop.id)
        
        if let entity = try context.fetch(fetchRequest).first {
            entity.setValue(Date(), forKey: "lastRetrieved")
            try context.save()
        }
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
    
    func deleteLoop(withID loopID: String) async throws {
        // Assuming Core Data setup
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<LoopEntity> = LoopEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", loopID)
        
        let results = try context.fetch(fetchRequest)
        
        guard let entityToDelete = results.first else {
            throw NSError(domain: "LoopLocalStorageUtilityError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No local record found for loop ID \(loopID)."])
        }
        
        context.delete(entityToDelete)
        try context.save()
    }
    
    func fetchLoopsInDateRange(start: Date, end: Date) async throws -> [Loop] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "LoopEntity")
        fetchRequest.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp <= %@ AND isDailyLoop == true",
            start as NSDate,
            end as NSDate
        )
        
        let results = try context.fetch(fetchRequest)
        let loops = results.compactMap { convertToLoop(from: $0) }
        
        print("💾 Found \(loops.count) daily loops in Local Storage")
        return loops
    }
    
    func findAndUpdateTranscript(forLoopId id: String, newTranscript: String) async throws -> Bool {
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "LoopEntity")
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)
            
            let results = try context.fetch(fetchRequest)
            
            if let loopEntity = results.first {
                await MainActor.run {
                    loopEntity.setValue(newTranscript, forKey: "transcript")
                    do {
                        try context.save()
                        print("💾 Updated transcript in local storage")
                    } catch {
                        print("Error saving transcript update: \(error)")
                    }
                }
                return true
            }
            return false
        }
}
