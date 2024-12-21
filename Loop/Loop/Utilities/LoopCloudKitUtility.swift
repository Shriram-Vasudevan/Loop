//
//  LoopCloudKitUtility.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/1/24.
//

import Foundation
import CloudKit
import Contacts

class LoopCloudKitUtility {
    static let container = CloudKit.CKContainer(identifier: "iCloud.LoopContainer")
    
    static let fetchLimit = 25
    
    static private var distinctDaysCache: Int?
    static private var lastCacheUpdate: Date?
    static private let cacheValidityDuration: TimeInterval = 3600 // 1 hour
    
    static func fetchPromptSetIfNeeded() async throws -> PromptSet? {
        let publicDB = container.publicCloudDatabase
        
        let query = CKQuery(recordType: "PromptSet", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: false)]
        
        let (matchResults, _) = try await publicDB.records(matching: query, desiredKeys: ["modificationDate"], resultsLimit: 1)
        
        guard let recordID = matchResults.first?.0,
              let record = try? matchResults.first?.1.get() else {
            throw PromptSetError.noDataFound
        }
        
        if let cachedModificationDate = UserDefaults.standard.object(forKey: PromptCacheKeys.lastModifiedKey) as? Date,
           let recordModificationDate = record.modificationDate,
           cachedModificationDate >= recordModificationDate {
            print("📝 Prompts cache is up to date")
            return nil
        }
        
        print("📝 Fetching new prompts from CloudKit")
        let ckRecord = try await publicDB.record(for: recordID)
        
        guard let promptSet = PromptSet.from(record: ckRecord) else {
            throw PromptSetError.invalidData
        }
        
        UserDefaults.standard.set(ckRecord.modificationDate, forKey: PromptCacheKeys.lastModifiedKey)
        
        return promptSet
    }
    
    static func fetchThematicPrompts() async throws -> [ThematicPrompt] {
        let publicDB = container.publicCloudDatabase
        let query = CKQuery(
            recordType: "ThematicPrompt",
            predicate: NSPredicate(value: true)
        )
        query.sortDescriptors = [
            NSSortDescriptor(key: "isPriority", ascending: false),
            NSSortDescriptor(key: "createdAt", ascending: false)
        ]
        
        let (matchResults, _) = try await publicDB.records(matching: query, desiredKeys: nil, resultsLimit: 50)
        
        return matchResults.compactMap { record -> ThematicPrompt? in
            guard let record = try? record.1.get() else { return nil }
            return ThematicPrompt.from(record: record)
        }
    }
    
    static func addThematicPrompt(_ prompt: ThematicPrompt) async throws {
        let record = prompt.toRecord()
        let publicDb = container.publicCloudDatabase
        try await publicDb.save(record)
    }
    
    static func checkDailyCompletion(for dates: [Date]) async throws -> [Date: Bool] {
        let privateDB = container.privateCloudDatabase
        var completionStatus: [Date: Bool] = [:]
        let calendar = Calendar.current
        
        for date in dates {
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let predicate = NSPredicate(format: "Timestamp >= %@ AND Timestamp < %@",
                                      startOfDay as NSDate,
                                      endOfDay as NSDate)
            
            let query = CKQuery(recordType: "LoopRecord", predicate: predicate)
            let records = try await privateDB.records(matching: query, inZoneWith: nil)
            completionStatus[startOfDay] = records.count >= 3
        }
        
        return completionStatus
    }
    
    static func getLoopRevealDate(completion: @escaping (LoopRevealDate?) -> Void) {
        let publicDB = container.publicCloudDatabase

        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "LoopRevealDate", predicate: predicate)
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.resultsLimit = 1

        queryOperation.recordFetchedBlock = { record in
            if let recordDate = record["Date"] as? Date {
                let loopRevealDate = LoopRevealDate(date: recordDate)
                print("the loop reveal date \(loopRevealDate)")
                completion(loopRevealDate)
            } else {
                completion(nil)
            }
        }

        queryOperation.queryCompletionBlock = { cursor, error in
            if let error = error {
                print("Error fetching LoopRevealDate: \(error.localizedDescription)")
                completion(nil)
            }
        }

        publicDB.add(queryOperation)
    }

    
    static func addLoop(loop: Loop) {
        let privateUserDB = container.privateCloudDatabase
        
        let loopRecord = CKRecord(recordType: "LoopRecord")
        
        loopRecord["ID"] = loop.id as CKRecordValue
        loopRecord["Data"] = loop.data
        loopRecord["Timestamp"] = loop.timestamp as CKRecordValue
        loopRecord["LastRetrieved"] = loop.lastRetrieved as CKRecordValue?
        loopRecord["Prompt"] = loop.promptText as CKRecordValue
        loopRecord["Category"] = loop.category as CKRecordValue
        loopRecord["Mood"] = loop.mood as CKRecordValue?
        loopRecord["FreeResponse"] = loop.freeResponse as CKRecordValue
        loopRecord["IsDailyLoop"] = loop.isDailyLoop as CKRecordValue
        
        privateUserDB.save(loopRecord) { record, error in
            if let error = error {
                print("Error saving loop record: \(error.localizedDescription)")
            } else {
                print("Loop record saved successfully!")
            }
        }
    }

    static func checkThreeDayRequirement() async throws -> (Bool, Int) {
        // Check cache first
        if let cached = distinctDaysCache,
           let lastUpdate = lastCacheUpdate,
           Date().timeIntervalSince(lastUpdate) < cacheValidityDuration {
            return (cached >= 3, cached)
        }
        
        let distinctDays = try await fetchDistinctLoopingDays()
        
        // Update cache
        distinctDaysCache = distinctDays
        lastCacheUpdate = Date()
        
        return (distinctDays >= 3, distinctDays)
    }
    
    static func fetchDistinctLoopingDays() async throws -> Int {
        let privateDB = container.privateCloudDatabase
        
        // Create a query for all loops
        let query = CKQuery(recordType: "LoopRecord", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "Timestamp", ascending: false)]
        
        // Use calendar for date comparison
        let calendar = Calendar.current
        var distinctDates = Set<Date>()
        
        // Fetch records
        let records = try await privateDB.records(matching: query, inZoneWith: nil)
        
        // Process records to find distinct days
        for record in records {
            if let timestamp = record["Timestamp"] as? Date {
                let startOfDay = calendar.startOfDay(for: timestamp)
                distinctDates.insert(startOfDay)
            }
        }
        
        print("days is \(distinctDates.count)")
        // Return count after processing all records
        return distinctDates.count
    }
    
    // In LoopCloudKitUtility
    static func fetchPastLoop(
        forPrompts prompts: [String],
        minDaysAgo: Int,
        maxDaysAgo: Int,
        preferGeneralPrompts: Bool,
        category: PromptCategory? = nil
    ) async throws -> Loop? {
        let privateDB = container.privateCloudDatabase
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate date range
        guard let minDate = calendar.date(byAdding: .day, value: -maxDaysAgo, to: now),
              let maxDate = calendar.date(byAdding: .day, value: -minDaysAgo, to: now) else {
            throw NSError(domain: "DateCalculationError", code: -1)
        }
        
        print("🔍 Searching for loops between \(minDate) and \(maxDate)")
        
        // First, just try to get ANY loops in the date range
        let datePredicate = NSPredicate(
            format: "Timestamp >= %@ AND Timestamp <= %@",
            minDate as NSDate,
            maxDate as NSDate
        )
        
        let query = CKQuery(recordType: "LoopRecord", predicate: datePredicate)
        query.sortDescriptors = [NSSortDescriptor(key: "Timestamp", ascending: false)]
        
        let (matchResults, _) = try await privateDB.records(matching: query)
        
        print("📊 Found \(matchResults.count) total loops in date range")
        
        // Convert results to Loops
        let loops = matchResults.compactMap { result -> Loop? in
            guard let record = try? result.1.get() else { return nil }
            return Loop.from(record: record)
        }
        
        print("🎯 Successfully converted \(loops.count) records to Loops")
        
        // If we have loops, then apply filters
        if !loops.isEmpty {
            // Score and sort loops
            let scoredLoops = loops.map { loop -> (Loop, Double) in
                let score = calculateLoopScore(
                    loop: loop,
                    prompts: prompts,
                    category: category,
                    preferGeneralPrompts: preferGeneralPrompts,
                    now: now
                )
                return (loop, score)
            }.sorted { $0.1 > $1.1 }
            
            print("⭐️ Top scoring loops:")
            scoredLoops.prefix(3).forEach { loop, score in
                print("   Score: \(score) - Prompt: \(loop.promptText)")
            }
            

            if let bestMatch = scoredLoops.first {
                print("📈 Selected best matching loop - Score: \(bestMatch.1) - Prompt: \(bestMatch.0.promptText)")
                try await updateLastRetrieved(for: bestMatch.0)
                return bestMatch.0
            }
        }
        
        print("❌ No loops found in date range")
        return nil
    }
    
    private static func calculateLoopScore(
        loop: Loop,
        prompts: [String],
        category: PromptCategory?,
        preferGeneralPrompts: Bool,
        now: Date
    ) -> Double {
        var score: Double = 0
        let calendar = Calendar.current
        
        // Cache prompt lookup
        let loopPrompt = LoopManager.shared.promptGroups.values
            .flatMap({ $0 })
            .first(where: { $0.text == loop.promptText })
        
        // 1. Exact Prompt Match (0.6)
        if prompts.contains(loop.promptText) {
            score += 0.6  // Increased from 0.4
            print("📝 Exact prompt match: +0.6")
        }
        
        // 2. Category Match (0.3)
        if let category = category,
           let promptCategory = loopPrompt?.category,
           promptCategory == category {
            score += 0.3
            print("📂 Category match: +0.3")
        }
        
        // 3. Last Retrieved Penalty
        if let lastRetrieved = loop.lastRetrieved {
            let daysAgo = calendar.dateComponents([.day], from: lastRetrieved, to: now).day ?? 0
            if daysAgo < 30 {  // Penalty for recently retrieved loops
                let penalty = Double(30 - daysAgo) / 100.0  // Max penalty of 0.3 for very recent retrievals
                score -= penalty
                print("⏱️ Recent retrieval penalty: -\(penalty)")
            }
        }
        
        // 4. Time Relevance
        let monthsAgo = Double(calendar.dateComponents([.month], from: loop.timestamp, to: now).month ?? 0)
        
        if monthsAgo >= 3 && monthsAgo <= 6 {
            score += 0.2
            print("📅 Ideal time range (3-6 months): +0.2")
        } else if monthsAgo >= 1 && monthsAgo <= 3 {
            score += 0.15
            print("📅 Good time range (1-3 months): +0.15")
        } else if monthsAgo >= 6 && monthsAgo <= 12 {
            score += 0.1
            print("📅 Acceptable time range (6-12 months): +0.1")
        }
        
        // 5. Anniversary bonus
        let dayOfMonth = calendar.component(.day, from: loop.timestamp)
        let currentDay = calendar.component(.day, from: now)
        if dayOfMonth == currentDay {
            if [3, 6, 9, 12].contains(monthsAgo) {
                score += 0.3
                print("🎉 Significant anniversary: +0.2")
            } else {
                score += 0.15
                print("📆 Monthly anniversary: +0.1")
            }
        }
        
        print("🎯 Final score for '\(loop.promptText)': \(score)")
        return min(score, 1.0)
    }

    private static func processAndScoreLoops(
        records: [CKRecord],
        prompts: [String],
        category: PromptCategory?,
        preferGeneralPrompts: Bool,
        now: Date
    ) async throws -> [(Loop, Double)] {
        var scoredLoops: [(Loop, Double)] = []
        
        for record in records {
            guard let loop = Loop.from(record: record) else { continue }
            let score = calculateLoopScore(
                loop: loop,
                prompts: prompts,
                category: category,
                preferGeneralPrompts: preferGeneralPrompts,
                now: now
            )
            scoredLoops.append((loop, score))
        }
        
        return scoredLoops.sorted { $0.1 > $1.1 }
    }

    private static func checkForAnniversaryMatches(
        prompts: [String],
        category: PromptCategory?,
        now: Date,
        in database: CKDatabase
    ) async throws -> Loop? {
        let calendar = Calendar.current
        let currentDay = calendar.component(.day, from: now)
        let currentMonth = calendar.component(.month, from: now)
        
        // Check 3, 6, 9, and 12 month anniversaries
        for monthsAgo in [3, 6, 9, 12] {
            guard let targetDate = calendar.date(byAdding: .month, value: -monthsAgo, to: now) else { continue }
            
            // Only look at dates with same day of month
            let startOfDay = calendar.startOfDay(for: targetDate)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let datePredicate = NSPredicate(
                format: "Timestamp >= %@ AND Timestamp < %@",
                startOfDay as NSDate,
                endOfDay as NSDate
            )
            
            var predicates: [NSPredicate] = [datePredicate]
            
            // Add category predicate if specified
            if let category = category {
                predicates.append(NSPredicate(format: "Category == %@", category.rawValue))
            }
            
            let query = CKQuery(
                recordType: "LoopRecord",
                predicate: NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            )
            
            let records = try await database.records(matching: query, inZoneWith: nil)
            
            // Process and score anniversary matches
            let scoredLoops = try await processAndScoreLoops(
                records: records,
                prompts: prompts,
                category: category,
                preferGeneralPrompts: false, // Not relevant for anniversary matches
                now: now
            )
            
            // Return first match above threshold with anniversary bonus
            if let bestMatch = scoredLoops.first, bestMatch.1 >= 0.5 { // Higher threshold for anniversary matches
                return bestMatch.0
            }
        }
        
        return nil
    }

    static func updateLastRetrieved(for loop: Loop) async throws {
        let privateDB = container.privateCloudDatabase
        
        let predicate = NSPredicate(format: "ID == %@", loop.id)
        let query = CKQuery(recordType: "LoopRecord", predicate: predicate)
        
        let records = try await privateDB.records(matching: query, inZoneWith: nil)
        if let record = records.first {
            record["LastRetrieved"] = Date() as CKRecordValue
            _ = try await privateDB.save(record)
        }
    }
    
    static func calculateStreak() async throws -> LoopingStreak {
        let privateDB = container.privateCloudDatabase
        let query = CKQuery(recordType: "LoopRecord", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "Timestamp", ascending: false)]
        
        let records = try await privateDB.records(matching: query, inZoneWith: nil)
        
        let calendar = Calendar.current
        var dates = Set<Date>()
        var consecutiveDays = 0
        var longestStreak = 0
        var lastDate: Date?
        
        // Process records
        for record in records {
            if let timestamp = record["Timestamp"] as? Date {
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
        }
        
        return LoopingStreak(
            currentStreak: consecutiveDays,
            longestStreak: longestStreak,
            distinctDays: dates.count
        )
    }
    
    static func fetchRecentLoopDates(
        startingFrom startDate: Date? = nil,
        limit: Int = 6,
        completion: @escaping (Result<[Date], Error>) -> Void
    ) {
        let privateDB = container.privateCloudDatabase

        // Predicate to fetch loops starting from the given date or all dates if startDate is nil.
        var predicate: NSPredicate
        if let startDate = startDate {
            predicate = NSPredicate(format: "Timestamp < %@", startDate as NSDate)
        } else {
            predicate = NSPredicate(value: true) // No filter for the first batch.
        }

        let query = CKQuery(recordType: "LoopRecord", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "Timestamp", ascending: false)] // Most recent first.

        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = limit * 10 // Adjust to account for multiple loops per day.

        var uniqueDates: Set<Date> = [] // Store unique days only.
        var dateArray: [Date] = [] // Maintain the order of dates.

        operation.recordFetchedBlock = { record in
            if let timestamp = record["Timestamp"] as? Date {
                let loopDate = Calendar.current.startOfDay(for: timestamp) // Extract only the date part.
                
                // Add to the set if it doesn't already exist.
                if uniqueDates.insert(loopDate).inserted {
                    dateArray.append(loopDate)
                }
            }
        }

        operation.queryCompletionBlock = { _, error in
            if let error = error {
                completion(.failure(error))
            } else {
                // Return exactly `limit` most recent unique dates.
                let sortedDates = Array(dateArray.prefix(limit))
                completion(.success(sortedDates))
            }
        }

        privateDB.add(operation)
    }
    

    static func fetchLoops(for date: Date, completion: @escaping (Result<[Loop], Error>) -> Void) {
        let privateDB = container.privateCloudDatabase
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = NSPredicate(format: "Timestamp >= %@ AND Timestamp < %@", startOfDay as NSDate, endOfDay as NSDate)

        let query = CKQuery(recordType: "LoopRecord", predicate: predicate)
        let operation = CKQueryOperation(query: query)

        var loops: [Loop] = []

        operation.recordFetchedBlock = { record in
            if let loop = Loop.from(record: record) {
                loops.append(loop)
            }
        }

        operation.queryCompletionBlock = { _, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(loops))
            }
        }

        privateDB.add(operation)
    }
    
    static func saveAnalysisToCloudKit(loop: Loop, sentiment: Double, keywords: [String]) {
        let recordID = CKRecord.ID(recordName: loop.id)
        let record = CKRecord(recordType: "Loop", recordID: recordID)
        record["sentimentScore"] = sentiment
        record["keywords"] = keywords
        
        let container = CKContainer.default()
        let privateDatabase = container.privateCloudDatabase
        
        privateDatabase.save(record) { _, error in
            if let error = error {
                print("Error saving analysis: \(error)")
            }
        }
    }
    
    static func fetchActiveMonths(year: Int? = nil) async throws -> [MonthIdentifier] {
        let privateDB = container.privateCloudDatabase
        
        var predicate: NSPredicate
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
            
            predicate = NSPredicate(format: "Timestamp >= %@ AND Timestamp < %@",
                                  startDate as NSDate,
                                  endDate as NSDate)
        } else {
            predicate = NSPredicate(value: true)
        }
        
        let query = CKQuery(recordType: "LoopRecord", predicate: predicate)
        let records = try await privateDB.records(matching: query, inZoneWith: nil)
        
        let calendar = Calendar.current
        let monthIdentifiers = records.compactMap { record -> MonthIdentifier? in
            guard let timestamp = record["Timestamp"] as? Date else { return nil }
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
    
    static func fetchMonthData(monthId: MonthIdentifier) async throws -> MonthSummary {
        let privateDB = container.privateCloudDatabase
        
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.year = monthId.year
        dateComponents.month = monthId.month
        
        guard let startDate = calendar.date(from: dateComponents),
              let endDate = calendar.date(byAdding: DateComponents(month: 1), to: startDate) else {
            throw NSError(domain: "DateError", code: -1)
        }
        
        let predicate = NSPredicate(format: "Timestamp >= %@ AND Timestamp < %@",
                                  startDate as NSDate,
                                  endDate as NSDate)
        
        let query = CKQuery(recordType: "LoopRecord", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "Timestamp", ascending: true)]
        
        let records = try await privateDB.records(matching: query, inZoneWith: nil)
        let loops = records.compactMap { Loop.from(record: $0) }
        
        return MonthSummary(
            year: monthId.year,
            month: monthId.month,
            totalEntries: loops.count,
            completionRate: calculateCompletionRate(loops: loops),
            loops: loops
        )
    }
    
    private static func calculateCompletionRate(loops: [Loop]) -> Double {
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
    
    static func deleteLoop(withID loopID: String) async throws {
        let privateDB = container.privateCloudDatabase
        
        // First find the record via a query
        let predicate = NSPredicate(format: "ID == %@", loopID)
        let query = CKQuery(recordType: "LoopRecord", predicate: predicate)
        let (matchResults, _) = try await privateDB.records(matching: query)
        
        guard let firstMatch = matchResults.first else {
            throw NSError(domain: "LoopCloudKitUtilityError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No CloudKit record found for loop ID \(loopID)."])
        }
        
        // Extract the record ID and delete it
        let record = try firstMatch.1.get()
        try await privateDB.deleteRecord(withID: record.recordID)
    }
    
}
enum FetchResult {
    case success(Loop)
    case noLoopsInTimeWindow
    case lowScores(bestScore: Double)
    case noRecordsFound
    case error(Error)
    
    var logMessage: String {
        switch self {
        case .success(let loop):
            return "✅ Selected loop from \(loop.timestamp.formatted()) with prompt: \(loop.promptText)"
        case .noLoopsInTimeWindow:
            return "⚠️ No loops found in specified time window"
        case .lowScores(let bestScore):
            return "ℹ️ Found loops but scores too low (best: \(bestScore))"
        case .noRecordsFound:
            return "❌ No records found in CloudKit query"
        case .error(let error):
            return "🚫 Error: \(error.localizedDescription)"
        }
    }
}

