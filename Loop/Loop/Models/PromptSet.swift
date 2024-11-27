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
        print("\n🔄 Converting categories to prompt groups")
        var groups: [PromptCategory: [Prompt]] = [:]
        
        categories.forEach { key, categoryPrompts in
            print("\n📦 Processing category: \(key)")
            if let category = PromptCategory(rawValue: key) {
                let dailyPrompts = categoryPrompts.daily.map { $0.toPrompt() }
                let generalPrompts = categoryPrompts.general.map { $0.toPrompt() }
                let allPrompts = dailyPrompts + generalPrompts
                
                print("✅ Added \(dailyPrompts.count) daily prompts")
                print("✅ Added \(generalPrompts.count) general prompts")
                
                groups[category] = allPrompts
            } else {
                print("❌ Failed to map category: \(key)")
                print("Available categories: \(PromptCategory.allCases.map { $0.rawValue })")
            }
        }
        
        print("\n📊 Final prompt counts per category:")
        groups.forEach { category, prompts in
            print("\(category.rawValue): \(prompts.count) total prompts")
        }
        
        return groups
    }
}

// Update the CloudKit extensions
extension PromptSet {
    static func from(record: CKRecord) -> PromptSet? {
        print("\n🔄 Starting PromptSet decoding from CKRecord")
        
        guard let version = record["version"] as? Int else {
            print("❌ Failed to get version from record")
            return nil
        }
        print("✅ Version: \(version)")
        
        guard let asset = record["promptData"] as? CKAsset else {
            print("❌ Failed to get promptData asset from record")
            return nil
        }
        print("✅ Got CKAsset")
        
        guard let fileURL = asset.fileURL else {
            print("❌ Failed to get fileURL from asset")
            return nil
        }
        print("✅ Got fileURL: \(fileURL)")
        
        guard let data = try? Data(contentsOf: fileURL) else {
            print("❌ Failed to read data from fileURL")
            return nil
        }
        print("✅ Got data of size: \(data.count) bytes")
        
        // Print raw JSON
        if let jsonString = String(data: data, encoding: .utf8) {
            print("\n📝 Raw JSON data:")
            print(jsonString)
        }
        
        guard let promptSet = try? JSONDecoder().decode(PromptSet.self, from: data) else {
            print("❌ Failed to decode JSON into PromptSet")
            // Try to decode with detailed error
            do {
                _ = try JSONDecoder().decode(PromptSet.self, from: data)
            } catch {
                print("Detailed decode error: \(error)")
            }
            return nil
        }
        
        print("✅ Successfully decoded PromptSet!")
        print("Categories found: \(promptSet.categories.keys.joined(separator: ", "))")
        
        return promptSet
    }
    
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "PromptSet")
        record["version"] = version as CKRecordValue
        
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

