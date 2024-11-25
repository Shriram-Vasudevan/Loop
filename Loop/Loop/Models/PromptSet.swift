//
//  PromptSet.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/24/24.
//

import Foundation
import CloudKit

struct PromptSet: Codable {
    let version: Int
    let categories: [String: CategoryPrompts]
    
    func getPromptGroups() -> [PromptCategory: [Prompt]] {
        var groups: [PromptCategory: [Prompt]] = [:]
        
        categories.forEach { key, categoryPrompts in
            if let category = PromptCategory(rawValue: key) {
                let allPrompts = categoryPrompts.daily.map { $0.toPrompt() } +
                               categoryPrompts.general.map { $0.toPrompt() }
                groups[category] = allPrompts
            }
        }
        
        return groups
    }
}

// Update the CloudKit extensions
extension PromptSet {
    static func from(record: CKRecord) -> PromptSet? {
        guard let version = record["version"] as? Int,
              let asset = record["promptData"] as? CKAsset,
              let fileURL = asset.fileURL,
              let data = try? Data(contentsOf: fileURL),
              let promptSet = try? JSONDecoder().decode(PromptSet.self, from: data) else {
            return nil
        }
        return promptSet
    }
    
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "PromptSet")
        record["version"] = version as CKRecordValue
        
        // Convert to JSON data and create asset
        if let data = try? JSONEncoder().encode(self) {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try? data.write(to: tempURL)
            record["promptData"] = CKAsset(fileURL: tempURL)
        }
        
        return record
    }
}

struct CategoryPrompts: Codable {
    let daily: [PromptData]
    let general: [PromptData]
}

struct PromptData: Codable {
    let text: String
    let category: String
    let isDailyPrompt: Bool
    
    func toPrompt() -> Prompt {
        guard let category = PromptCategory(rawValue: category) else {
            fatalError("Invalid category: \(category)")
        }
        return Prompt(text: text, category: category, isDailyPrompt: isDailyPrompt)
    }
}

enum PromptCacheKeys {
    static let promptSetKey = "CachedPromptSet"
    static let lastModifiedKey = "LastPromptModifiedKey"
}

enum PromptSetError: Error {
    case invalidData
    case decodingError
    case networkError
    case noDataFound
}

