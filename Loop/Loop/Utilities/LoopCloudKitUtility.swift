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
    
    static private func fetchDistinctLoopingDays() async throws -> Int {
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
        
        // Return count after processing all records
        return distinctDates.count
    }
    
    static func fetchPastLoopForPrompt(_ promptText: String) async throws -> Loop? {
        guard try await checkSevenDayRequirement() else {
            return nil
        }
        
        let privateDB = container.privateCloudDatabase

        let predicate = NSPredicate(format: "Prompt == %@ AND Timestamp < %@", promptText, Date() as NSDate)
        let query = CKQuery(recordType: "LoopRecord", predicate: predicate)

        let records = try await privateDB.records(matching: query, inZoneWith: nil)
        
        var pastLoops: [Loop] = []
        for record in records {
            if let loop = Loop.from(record: record) {
                pastLoops.append(loop)
            }
        }
        
        if let selectedLoop = selectAppropriateLoop(from: pastLoops) {
            let recordID = CKRecord.ID(recordName: selectedLoop.id)
            let record = try await privateDB.record(for: recordID)
            record["LastRetrieved"] = Date()
            
            _ = try await privateDB.save(record)
            
            return Loop(
                id: selectedLoop.id,
                data: selectedLoop.data,
                timestamp: selectedLoop.timestamp,
                lastRetrieved: Date(),
                promptText: selectedLoop.promptText,
                mood: selectedLoop.mood,
                freeResponse: selectedLoop.freeResponse,
                isVideo: selectedLoop.isVideo
            )
        }
        
        return nil
    }

    static func selectAppropriateLoop(from loops: [Loop]) -> Loop? {
        guard !loops.isEmpty else { return nil }
        
        let weightedLoops = loops.map { loop -> (Loop, Double) in
            let priority = computeLoopPriority(loop)
            return (loop, priority)
        }
        
        return weightedRandomSelection(from: weightedLoops)
    }
    
    static func computeLoopPriority(_ loop: Loop) -> Double {
        let now = Date()
        let calendar = Calendar.current

        let daysSinceCreation = calendar.dateComponents([.day], from: loop.timestamp, to: now).day ?? 0

        let daysSinceRetrieval = calendar.dateComponents(
            [.day],
            from: loop.lastRetrieved ?? loop.timestamp,
            to: now
        ).day ?? 0
        
        let agePriority = 1.0 / Double(max(daysSinceCreation, 1))
        let retrievalPriority = Double(daysSinceRetrieval)
        
        return (agePriority * 0.3) + (retrievalPriority * 0.7)
    }
    
    static func weightedRandomSelection(from weightedLoops: [(Loop, Double)]) -> Loop? {
        let totalWeight = weightedLoops.reduce(0.0) { $0 + $1.1 }
        let randomValue = Double.random(in: 0..<totalWeight)
        
        var accumulatedWeight = 0.0
        for (loop, weight) in weightedLoops {
            accumulatedWeight += weight
            if randomValue <= accumulatedWeight {
                return loop
            }
        }
        
        return weightedLoops.first?.0
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
