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
    static private let cacheValidityDuration: TimeInterval = 3600
    
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
        loopRecord["Transcript"] = loop.transcript as CKRecordValue?
        loopRecord["FreeResponse"] = loop.freeResponse as CKRecordValue
        loopRecord["IsDailyLoop"] = loop.isDailyLoop as CKRecordValue
        loopRecord["Mood"] = loop.mood as CKRecordValue?
        
        privateUserDB.save(loopRecord) { record, error in
            if let error = error {
                print("Error saving loop record: \(error.localizedDescription)")
            } else {
                print("Loop record saved successfully!")
            }
        }
    }

    static func checkThreeDayRequirement() async throws -> (Bool, Int) {
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

        let query = CKQuery(recordType: "LoopRecord", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "Timestamp", ascending: false)]

        let calendar = Calendar.current
        var distinctDates = Set<Date>()

        let records = try await privateDB.records(matching: query, inZoneWith: nil)

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
    
    static func fetchPastLoop(
        forPrompts prompts: [String],
        minDaysAgo: Int,
        maxDaysAgo: Int?,
        categoryFrequencies: [PromptCategory: Double],
        limitToFields fields: [String]
    ) async throws -> Loop? {
        let privateDB = container.privateCloudDatabase
        let calendar = Calendar.current
        let now = Date()

        guard let minDaysAgoValue = maxDaysAgo,
              let minDate = calendar.date(byAdding: .day, value: -minDaysAgoValue, to: now),
              let maxDate = calendar.date(byAdding: .day, value: -minDaysAgo, to: now) else {
            throw NSError(domain: "DateCalculationError", code: -1)
        }


        print("🔍 Searching CloudKit between \(minDate) and \(maxDate) with fields: \(fields)")

        let predicate = maxDaysAgo != nil
            ? NSPredicate(format: "Timestamp >= %@ AND Timestamp <= %@", minDate as NSDate, maxDate as NSDate)
            : NSPredicate(format: "Timestamp >= %@", minDate as NSDate)

        let query = CKQuery(recordType: "LoopRecord", predicate: predicate)

        // Desired fields
        let desiredKeys = fields

        let (results, _) = try await privateDB.records(matching: query, desiredKeys: desiredKeys)
        print("📊 Found \(results.count) loops in CloudKit query")

        let loops = results.compactMap { result -> Loop? in
            guard let record = try? result.1.get() else { return nil }
            return Loop.from(record: record)
        }

        if !loops.isEmpty {
            let scoredLoops = loops.map { loop -> (Loop, Double) in
                let score = calculateLoopScore(loop: loop, prompts: prompts, categoryFrequencies: categoryFrequencies, now: now)
                return (loop, score)
            }

            if let bestMatch = scoredLoops.max(by: { $0.1 < $1.1 }), bestMatch.1 > 0.3 {
                print("⭐️ Selected loop: \(bestMatch.0.promptText) with score: \(bestMatch.1)")
                return bestMatch.0
            }
        }

        print("❌ No suitable loops found in CloudKit")
        return nil
    }

    
    static private func calculateLoopScore(
        loop: Loop,
        prompts: [String],
        categoryFrequencies: [PromptCategory: Double],
        now: Date
    ) -> Double {
        var score: Double = 0.0
        let calendar = Calendar.current

        // Exact Prompt Match
        if prompts.contains(loop.promptText) {
            score += 0.6
            print("☁️ Exact prompt match: +0.6")
        }

        // Category Match
        if let loopCategory = PromptCategory(rawValue: loop.category) {
            if loopCategory == .freeform {
                score -= 0.1
                print("☁️ Freeform penalty: -0.1")
            } else {
                for (category, frequency) in categoryFrequencies {
                    if category == loopCategory {
                        let categoryBoost = 0.3 * frequency
                        score += categoryBoost
                        print("☁️ Category frequency boost (\(category)): +\(categoryBoost)")
                    }
                }
            }
        }

        // Time-Based Scoring
        let daysAgo = Double(calendar.dateComponents([.day], from: loop.timestamp, to: now).day ?? 0)
        switch daysAgo {
        case 1...7:
            score += 0.2
            print("☁️ 1-7 days ago: +0.2")
        case 7...30:
            score += 0.1
            print("☁️ 1-4 weeks ago: +0.1")
        case 30...180:
            score += 0.4
            print("☁️ 2-6 months ago: +0.4")
        case 180...365:
            score += 0.1
            print("☁️ 6-12 months ago: +0.1")
        case 365...:
            score += 0.05
            print("☁️ Older than 1 year: +0.05")
        default:
            break
        }

        // Recent Retrieval Penalty
        if let lastRetrieved = loop.lastRetrieved {
            let daysSinceRetrieved = calendar.dateComponents([.day], from: lastRetrieved, to: now).day ?? 0
            let penalty: Double = daysSinceRetrieved < 7 ? 0.8 : (daysSinceRetrieved < 30 ? 0.4 : 0.0)
            score -= penalty
            print("☁️ Retrieval penalty: -\(penalty)")
        }

        let finalScore = max(0.0, min(1.0, score))
        print("☁️ Final score: \(finalScore)")
        return finalScore
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
    
    static func fetchLoopsInDateRange(start: Date, end: Date) async throws -> [Loop] {
        let privateDB = container.privateCloudDatabase
        
        let predicate = NSPredicate(
            format: "Timestamp >= %@ AND Timestamp <= %@ AND IsDailyLoop == true",
            start as NSDate,
            end as NSDate
        )
        
        let query = CKQuery(recordType: "LoopRecord", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "Timestamp", ascending: false)]
        
        let (matchResults, _) = try await privateDB.records(matching: query)
        let loops = matchResults.compactMap { result -> Loop? in
            guard let record = try? result.1.get() else { return nil }
            return Loop.from(record: record)
        }
        
        print("📱 Found \(loops.count) daily loops in CloudKit")
        return loops
    }
    
    static func findAndUpdateTranscript(forLoopId id: String, newTranscript: String) async throws -> Bool {
       let privateDB = container.privateCloudDatabase
       
       let predicate = NSPredicate(format: "ID == %@", id)
       let query = CKQuery(recordType: "LoopRecord", predicate: predicate)
       
       let (matchResults, _) = try await privateDB.records(matching: query, desiredKeys: ["ID"])
       
       guard let firstMatch = matchResults.first else {
           return false
       }
       
       let record = try firstMatch.1.get()
       record["Transcript"] = newTranscript as CKRecordValue
       
       _ = try await privateDB.save(record)
       print("☁️ Updated transcript in CloudKit")
       return true
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

