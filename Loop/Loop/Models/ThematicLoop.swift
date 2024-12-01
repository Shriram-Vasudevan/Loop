//
//  ThematicLoop.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/22/24.
//

import Foundation
import CloudKit

struct ThematicPrompt: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let isPriority: Bool
    let prompts: [String]  // Array of prompt texts
    let createdAt: Date
}

// MARK: - CloudKit Extensions
extension ThematicPrompt {
    static func from(record: CKRecord) -> ThematicPrompt? {
        guard let id = record["id"] as? String,
              let name = record["name"] as? String,
              let description = record["description"] as? String,
              let isPriority = record["isPriority"] as? Bool,
              let prompts = record["prompts"] as? [String],
              let createdAt = record["createdAt"] as? Date else {
            return nil
        }
        
        return ThematicPrompt(
            id: id,
            name: name,
            description: description,
            isPriority: isPriority,
            prompts: prompts,
            createdAt: createdAt
        )
    }
    
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "ThematicPrompt")
        record["id"] = id
        record["name"] = name
        record["description"] = description
        record["isPriority"] = isPriority
        record["prompts"] = prompts
        record["createdAt"] = createdAt
        return record
    }
}

