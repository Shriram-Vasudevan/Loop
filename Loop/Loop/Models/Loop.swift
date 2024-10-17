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
    var mood: String?
    var freeResponse: Bool
    var isVideo: Bool  
    
    static func from(record: CKRecord) -> Loop? {
        guard let id = record["ID"] as? String,
              let data = record["Data"] as? CKAsset,  
              let timestamp = record["Timestamp"] as? Date,
              let promptText = record["Prompt"] as? String else {
            print("Error: Missing required fields in CKRecord.")
            return nil
        }

        let lastRetrieved = record["LastRetrieved"] as? Date
        let mood = record["Mood"] as? String
        let freeResponse = record["FreeResponse"] as? Bool ?? false
        let isVideo = record["IsVideo"] as? Bool ?? false

        return Loop(id: id,
                    data: data,
                    timestamp: timestamp,
                    lastRetrieved: lastRetrieved,
                    promptText: promptText,
                    mood: mood,
                    freeResponse: freeResponse,
                    isVideo: isVideo)
    }
}

