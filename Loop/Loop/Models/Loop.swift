//
//  Loop.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/1/24.
//

import Foundation
import CloudKit

struct Loop: Hashable, Identifiable {
    var id: String
    var data: CKAsset
    var timestamp: Date
    var lastRetrieved: Date?
    var promptText: String
    var category: String
    var transcript: String?
    var freeResponse: Bool
    var isVideo: Bool
    var isDailyLoop: Bool
    var isFollowUp: Bool
    var isSuccessJournal: Bool?
    var mood: String?
    
    static func from(record: CKRecord) -> Loop? {
        guard let id = record["ID"] as? String,
              let data = record["Data"] as? CKAsset,
              let timestamp = record["Timestamp"] as? Date,
              let promptText = record["Prompt"] as? String else {
            print("Error: Missing required fields in CKRecord.")
            return nil
        }

        return Loop(
            id: id,
            data: data,
            timestamp: timestamp,
            lastRetrieved: record["LastRetrieved"] as? Date,
            promptText: promptText,
            category: record["Category"] as? String ?? "Share Anything", // Default to freeform
            transcript: record["Transcript"] as? String,
            freeResponse: record["FreeResponse"] as? Bool ?? false,
            isVideo: record["IsVideo"] as? Bool ?? false,
            isDailyLoop: record["IsDailyLoop"] as? Bool ?? false, isFollowUp: record["isFollowUp"] as? Bool ?? false, mood: record["Mood"] as? String
        )
    }
}
