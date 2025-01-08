//
//  AcitivtyLocalStorageUtility.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/6/25.
//

import Foundation
import CoreData
import CloudKit

class ActivityLocalStorageUtility {
    static let shared = ActivityLocalStorageUtility()
    
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "LoopData")
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func fetchLoopsForDate(_ date: Date) async throws -> [Loop] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw NSError(domain: "ActivityError", code: -1)
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "LoopEntity")
        fetchRequest.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp < %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        let results = try context.fetch(fetchRequest)
        return results.compactMap { entity -> Loop? in
            guard let id = entity.value(forKey: "id") as? String,
                  let filePath = entity.value(forKey: "filePath") as? String,
                  let timestamp = entity.value(forKey: "timestamp") as? Date,
                  let promptText = entity.value(forKey: "promptText") as? String else {
                return nil
            }
            
            let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("LoopMedia")
                .appendingPathComponent(filePath)
            
            guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
            
            let asset = CKAsset(fileURL: fileURL)
            let category = entity.value(forKey: "category") as? String ?? "Share Anything"
            
            return Loop(
                id: id,
                data: asset,
                timestamp: timestamp,
                lastRetrieved: entity.value(forKey: "lastRetrieved") as? Date,
                promptText: promptText,
                category: category,
                transcript: entity.value(forKey: "transcript") as? String,
                freeResponse: entity.value(forKey: "freeResponse") as? Bool ?? false,
                isVideo: entity.value(forKey: "isVideo") as? Bool ?? false,
                isDailyLoop: entity.value(forKey: "isDailyLoop") as? Bool ?? false,
                isFollowUp: entity.value(forKey: "isFollowUp") as? Bool ?? false,
                mood: entity.value(forKey: "mood") as? String
            )
        }
    }
}
