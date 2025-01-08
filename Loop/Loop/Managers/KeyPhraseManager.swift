//
//  KeyPhraseManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/7/25.
//

import Foundation
import CoreData

struct KeyMomentModel: Codable {
    let prompt: String
    let insight: String
    let date: Date
}

class KeyMomentManager {
    static let shared = KeyMomentManager()
    
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "LoopData")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    private var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveKeyMoment(_ moment: KeyMomentModel) {
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "KeyMomentEntity", in: context) else { return }
        
        let entity = NSManagedObject(entity: entityDescription, insertInto: context)
        entity.setValue(moment.date, forKey: "date")
        entity.setValue(moment.prompt, forKey: "prompt")
        entity.setValue(moment.insight, forKey: "insight")
        
        do {
            try context.save()
            print("✅ Saved key moment")
        } catch {
            print("❌ Failed to save key moment: \(error)")
            context.rollback()
        }
    }
    
    func fetchKeyMoments(timeframe: Timeframe = .week, count: Int = 3) -> [KeyMomentModel] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "KeyMomentEntity")
        
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate start date based on timeframe
        guard let startDate = calendar.date(byAdding: {
            switch timeframe {
            case .week:
                return DateComponents(day: -7)
            case .month:
                return DateComponents(month: -1)
            case .year:
                return DateComponents(year: -1)
            }
        }(), to: now) else {
            print("❌ Failed to calculate start date")
            return []
        }
        
        request.predicate = NSPredicate(format: "date >= %@", startDate as NSDate)
        
        do {
            let results = try context.fetch(request)
            let moments = results.compactMap { entity -> KeyMomentModel? in
                guard let date = entity.value(forKey: "date") as? Date,
                      let prompt = entity.value(forKey: "prompt") as? String,
                      let insight = entity.value(forKey: "insight") as? String else {
                    return nil
                }
                return KeyMomentModel(prompt: prompt, insight: insight, date: date)
            }
        
            if moments.isEmpty {
                return []
            } else {
                let shuffled = moments.shuffled()
                return Array(shuffled.prefix(count))
            }
        } catch {
            print("❌ Failed to fetch key moments: \(error)")
            return []
        }
    }
}

