//
//  LoopCloudKitUtility.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/1/24.
//

import Foundation
import CloudKit

class LoopCloudKitUtility {
    static let container = CloudKit.CKContainer(identifier: "iCloud.LoopContainer")
    
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
        
        loopRecord["ID"] = loop.loopID as CKRecordValue
        loopRecord["AudioData"] = loop.audioData
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
    
    // Fetch a limited number of loops that haven’t been retrieved within a threshold, or fallback to newer ones
    static func fetchFlexibleOlderLoops(thresholdDays: Int = 7, limit: Int = 15, completion: @escaping ([Loop]) -> Void) {
        let privateDB = container.privateCloudDatabase
        
        // Start by fetching loops older than the threshold
        fetchOlderLoops(thresholdDays: thresholdDays, limit: limit) { loops in
            if !loops.isEmpty {
                // If we found loops older than the threshold, return them
                completion(loops)
            } else {
                // If no loops are found, loosen the threshold and try again (e.g., use 0 days to get all loops)
                print("No loops found older than \(thresholdDays) days. Trying a smaller threshold.")
                fetchOlderLoops(thresholdDays: 0, limit: limit, completion: completion)
            }
        }
    }

    private static func fetchOlderLoops(thresholdDays: Int, limit: Int, completion: @escaping ([Loop]) -> Void) {
        let privateDB = container.privateCloudDatabase

        let thresholdDate = Calendar.current.date(byAdding: .day, value: -thresholdDays, to: Date())!

        let predicate = NSPredicate(format: "LastRetrieved == nil OR LastRetrieved < %@", thresholdDate as NSDate)

        let query = CKQuery(recordType: "LoopRecord", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "LastRetrieved", ascending: true)] // Oldest first
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = limit

        var fetchedLoops: [Loop] = []
        
        operation.recordFetchedBlock = { record in
            if let loopID = record["ID"] as? String,
               let audioData = record["AudioData"] as? CKAsset,
               let timestamp = record["Timestamp"] as? Date,
               let promptText = record["Prompt"] as? String {
                
                let lastRetrieved = record["LastRetrieved"] as? Date
                let mood = record["Mood"] as? String
                let freeResponse = record["FreeResponse"] as? Bool ?? false
                
                let loop = Loop(loopID: loopID, audioData: audioData, timestamp: timestamp, lastRetrieved: lastRetrieved, promptText: promptText, mood: mood, freeResponse: freeResponse)
                fetchedLoops.append(loop)
            }
        }
        
        operation.queryCompletionBlock = { _, error in
            if let error = error {
                print("Error fetching loops: \(error.localizedDescription)")
            }
            completion(fetchedLoops)
        }
        
        privateDB.add(operation)
    }

    static func getRandomPastLoop(completion: @escaping (Loop?) -> Void) {
        fetchFlexibleOlderLoops { loops in
            guard !loops.isEmpty else {
                completion(nil)
                return
            }
            
            let currentDate = Date()
            var loopScores: [(loop: Loop, score: Double)] = []

            for loop in loops {
                let lastRetrieved = loop.lastRetrieved ?? loop.timestamp
                let timeSinceRetrieved = currentDate.timeIntervalSince(lastRetrieved)
                let timeDecayScore = timeSinceRetrieved / (60 * 60 * 24)
                
                let score = exp(timeDecayScore)
                loopScores.append((loop, score))
            }

            let totalScore = loopScores.reduce(0) { $0 + $1.score }
            let randomValue = Double.random(in: 0..<totalScore)

            var cumulativeScore = 0.0
            for (loop, score) in loopScores {
                cumulativeScore += score
                if cumulativeScore >= randomValue {
                    completion(loop)
                    return
                }
            }
        }
    }
}
