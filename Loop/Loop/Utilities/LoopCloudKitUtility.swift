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

    static func computePriority(loop: Loop) -> Double {
        let now = Date()
        let timeSinceCreated = now.timeIntervalSince(loop.timestamp)
        let timeSinceLastRetrieved = loop.lastRetrieved != nil ? now.timeIntervalSince(loop.lastRetrieved!) : timeSinceCreated

        let ageFactor = timeSinceCreated / (60 * 60 * 24)
        let recencyFactor = timeSinceLastRetrieved / (60 * 60 * 24)

        return ageFactor * 0.5 + recencyFactor * 0.5
    }

    static func getRandomLoop(completion: @escaping (Loop?) -> Void) {
        let privateUserDB = container.privateCloudDatabase
        
        var allLoops: [Loop] = []

        let queryOld = CKQuery(recordType: "LoopRecord", predicate: NSPredicate(value: true))
        queryOld.sortDescriptors = [
            NSSortDescriptor(key: "Timestamp", ascending: true),
        ]
        let oldRecordsOperation = CKQueryOperation(query: queryOld)
        oldRecordsOperation.resultsLimit = fetchLimit
        
        oldRecordsOperation.recordFetchedBlock = { record in
            if let loop = self.loopFromRecord(record) {
                allLoops.append(loop)
            }
        }
        
        oldRecordsOperation.queryCompletionBlock = { cursor, error in
            guard error == nil else {
                print("Error fetching old records: \(String(describing: error))")
                completion(nil)
                return
            }

            let queryNew = CKQuery(recordType: "LoopRecord", predicate: NSPredicate(value: true))
            queryNew.sortDescriptors = [
                NSSortDescriptor(key: "Timestamp", ascending: false)
            ]
            let newRecordsOperation = CKQueryOperation(query: queryNew)
            newRecordsOperation.resultsLimit = self.fetchLimit
            
            newRecordsOperation.recordFetchedBlock = { record in
                if let loop = self.loopFromRecord(record) {
                    allLoops.append(loop)
                }
            }
            
            newRecordsOperation.queryCompletionBlock = { cursor, error in
                guard error == nil else {
                    print("Error fetching new records: \(String(describing: error))")
                    completion(nil)
                    return
                }
                
                if allLoops.isEmpty {
                    completion(nil)
                    return
                }

                let weightedLoops = allLoops.map { loop -> (Loop, Double) in
                    return (loop, self.computePriority(loop: loop))
                }

                if let selectedLoop = weightedRandomSelection(weightedLoops: weightedLoops) {
                    completion(selectedLoop)
                } else {
                    completion(nil)
                }
            }
            
            privateUserDB.add(newRecordsOperation)
        }

        privateUserDB.add(oldRecordsOperation)
    }

    static func loopFromRecord(_ record: CKRecord) -> Loop? {
        guard let loopID = record["ID"] as? String,
              let data = record["Data"] as? CKAsset,
              let timestamp = record["Timestamp"] as? Date,
              let promptText = record["Prompt"] as? String else {
            return nil
        }
        
        let lastRetrieved = record["LastRetrieved"] as? Date
        let mood = record["Mood"] as? String
        let freeResponse = record["FreeResponse"] as? Bool ?? false
        let isVideo = record["IsVideo"] as? Bool ?? false
        
        return Loop(id: loopID, data: data, timestamp: timestamp, lastRetrieved: lastRetrieved, promptText: promptText, mood: mood, freeResponse: freeResponse, isVideo: isVideo)
    }

    static func weightedRandomSelection(weightedLoops: [(Loop, Double)]) -> Loop? {
        let totalWeight = weightedLoops.reduce(0) { $0 + $1.1 }
        let randomWeight = Double.random(in: 0..<totalWeight)
        
        var cumulativeWeight: Double = 0
        for (loop, weight) in weightedLoops {
            cumulativeWeight += weight
            if randomWeight < cumulativeWeight {
                return loop
            }
        }
        return nil
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
