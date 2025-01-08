//
//  ActivityCloudKidUtility.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/6/25.
//

import Foundation
import CloudKit

class ActivityCloudKitUtility {
    static let container = CloudKit.CKContainer(identifier: "iCloud.LoopContainer")
    
    static func fetchLoopsForDate(_ date: Date) async throws -> [Loop] {
        let privateDB = container.privateCloudDatabase
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw NSError(domain: "ActivityError", code: -1)
        }
        
        let predicate = NSPredicate(
            format: "Timestamp >= %@ AND Timestamp < %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        
        let query = CKQuery(recordType: "LoopRecord", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "Timestamp", ascending: false)]
        
        let (matchResults, _) = try await privateDB.records(matching: query)
        return matchResults.compactMap { result -> Loop? in
            guard let record = try? result.1.get() else { return nil }
            return Loop.from(record: record)
        }
    }
}
