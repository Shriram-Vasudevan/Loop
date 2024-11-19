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
        loopRecord["Mood"] = loop.mood as CKRecordValue?
        loopRecord["FreeResponse"] = loop.freeResponse as CKRecordValue
        
        privateUserDB.save(loopRecord) { record, error in
            if let error = error {
                print("Error saving loop record: \(error.localizedDescription)")
            } else {
                print("Loop record saved successfully!")
            }
        }
    }

    static func checkSevenDayRequirement() async throws -> Bool {
        // Check cache first
        if let cached = distinctDaysCache,
           let lastUpdate = lastCacheUpdate,
           Date().timeIntervalSince(lastUpdate) < cacheValidityDuration {
            return cached >= 7
        }
        
        let distinctDays = try await fetchDistinctLoopingDays()
        
        // Update cache
        distinctDaysCache = distinctDays
        lastCacheUpdate = Date()
        
        return distinctDays >= 7
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
    
    
    static func fetchPastLoop(
            forPrompts prompts: [String],
            minDaysAgo: Int,
            maxDaysAgo: Int,
            preferGeneralPrompts: Bool,
            category: PromptCategory? = nil
        ) async throws -> Loop? {
            print("🔍 Starting loop search:")
            print("   Time window: \(minDaysAgo)-\(maxDaysAgo) days ago")
            print("   Category: \(category?.rawValue ?? "any")")
            print("   Preferring general prompts: \(preferGeneralPrompts)")
            
            let privateDB = container.privateCloudDatabase
            let calendar = Calendar.current
            
            // Calculate date range
            let now = Date()
            guard let minDate = calendar.date(byAdding: .day, value: -maxDaysAgo, to: now),
                  let maxDate = calendar.date(byAdding: .day, value: -minDaysAgo, to: now) else {
                print("❌ Date calculation failed")
                throw NSError(domain: "DateCalculationError", code: -1)
            }
            
            print("📅 Searching between:")
            print("   \(minDate.formatted()) and \(maxDate.formatted())")
            
            // Build predicate
            var predicates: [NSPredicate] = []
            
            // Date range predicate
            let datePredicate = NSPredicate(
                format: "Timestamp >= %@ AND Timestamp <= %@",
                minDate as NSDate,
                maxDate as NSDate
            )
            predicates.append(datePredicate)
            
            // Construct query
            let query = CKQuery(
                recordType: "LoopRecord",
                predicate: NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            )
            
            // Fetch records
            let records = try await privateDB.records(matching: query, inZoneWith: nil)
            
            if records.isEmpty {
                print("📭 No records found in time window")
                return nil
            }
            
            print("📊 Found \(records.count) potential loops")
            
            // Convert to loops and score them
            var scoredLoops: [(Loop, Double)] = []
            
            for record in records {
                guard let loop = Loop.from(record: record) else { continue }
                
                let score = calculateLoopScore(
                    loop: loop,
                    basedOn: prompts,
                    category: category,
                    preferGeneralPrompts: preferGeneralPrompts
                )
                
                print("   Loop from \(loop.timestamp.formatted()):")
                print("   - Prompt: \(loop.promptText)")
                print("   - Score: \(score)")
                printScoreBreakdown(
                    loop: loop,
                    prompts: prompts,
                    category: category,
                    preferGeneralPrompts: preferGeneralPrompts
                )
                
                scoredLoops.append((loop, score))
            }
            
            // Sort by score
            scoredLoops.sort { $0.1 > $1.1 }
            
            if let bestMatch = scoredLoops.first {
                if bestMatch.1 >= 0.3 { // Minimum acceptable score
                    print("✅ Selected best match:")
                    print("   Score: \(bestMatch.1)")
                    print("   Prompt: \(bestMatch.0.promptText)")
                    print("   Date: \(bestMatch.0.timestamp.formatted())")
                    return bestMatch.0
                } else {
                    print("⚠️ Best match score too low: \(bestMatch.1)")
                    print("   Required minimum: 0.3")
                    return nil
                }
            }
            
            print("❌ No suitable matches found")
            return nil
        }
        
        private static func printScoreBreakdown(
            loop: Loop,
            prompts: [String],
            category: PromptCategory?,
            preferGeneralPrompts: Bool
        ) {
            // Age score
            let ageInDays = Double(Calendar.current.dateComponents([.day], from: loop.timestamp, to: Date()).day ?? 0)
            let ageScore = min(ageInDays / 365, 1.0) * 0.2
            print("   - Age score: \(ageScore) (age: \(ageInDays) days)")
            
            // Category score
            if let category = category,
               let loopPrompt = LoopManager.shared.promptGroups.values
                .flatMap({ $0 })
                .first(where: { $0.text == loop.promptText }) {
                let categoryScore = loopPrompt.category == category ? 0.3 : 0.0
                print("   - Category score: \(categoryScore)")
            }
            
            // Prompt type score
            if let loopPrompt = LoopManager.shared.promptGroups.values
                .flatMap({ $0 })
                .first(where: { $0.text == loop.promptText }) {
                let promptTypeScore = preferGeneralPrompts && !loopPrompt.isDailyPrompt ? 0.3 : 0.0
                print("   - Prompt type score: \(promptTypeScore)")
            }
            
            // Retrieval score
            if let lastRetrieved = loop.lastRetrieved {
                let daysSinceRetrieved = Double(Calendar.current.dateComponents([.day], from: lastRetrieved, to: Date()).day ?? 0)
                let retrievalScore = min(daysSinceRetrieved / 30, 1.0) * 0.2
                print("   - Retrieval score: \(retrievalScore) (last retrieved: \(daysSinceRetrieved) days ago)")
            } else {
                print("   - Retrieval score: 0.2 (never retrieved)")
            }
        }
        
        private static func calculateLoopScore(
            loop: Loop,
            basedOn prompts: [String],
            category: PromptCategory?,
            preferGeneralPrompts: Bool
        ) -> Double {
            var score: Double = 0
            
            // Base score for time (older gets slight preference)
            let ageInDays = Double(Calendar.current.dateComponents([.day], from: loop.timestamp, to: Date()).day ?? 0)
            score += min(ageInDays / 365, 1.0) * 0.2 // Max 0.2 points for age
            
            // Category matching (if specified)
            if let category = category,
               let loopPrompt = LoopManager.shared.promptGroups.values
                .flatMap({ $0 })
                .first(where: { $0.text == loop.promptText }) {
                if loopPrompt.category == category {
                    score += 0.3 // Significant boost for category match
                }
            }
            
            // Prompt type matching
            if let loopPrompt = LoopManager.shared.promptGroups.values
                .flatMap({ $0 })
                .first(where: { $0.text == loop.promptText }) {
                if preferGeneralPrompts && !loopPrompt.isDailyPrompt {
                    score += 0.3 // Boost for general prompts when preferred
                }
            }
            
            // Last retrieved penalty (prefer less recently retrieved loops)
            if let lastRetrieved = loop.lastRetrieved {
                let daysSinceRetrieved = Double(Calendar.current.dateComponents([.day], from: lastRetrieved, to: Date()).day ?? 0)
                score += min(daysSinceRetrieved / 30, 1.0) * 0.2 // Max 0.2 points for retrieval age
            } else {
                score += 0.2 // Full points if never retrieved
            }
            
            return score
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

