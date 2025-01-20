//
//  SleepCheckinManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/19/25.
//

import CoreData

class SleepCheckinManager: ObservableObject {
    static let shared = SleepCheckinManager()
        
    @Published var todaysSleep: SleepRating?
    
    let dateKey: String = "sleepCheckinDateKey"
    let checkInKey: String = "sleepCheckinKey"
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "LoopData")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    init() {
        checkIfCheckinCompleted()
    }
    
    private func fetchTodaysCheckin() -> NSManagedObject? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return nil
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "SleepCheckinEntity")
        fetchRequest.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.first
        } catch {
            print("❌ Failed to fetch today's sleep check-in: \(error)")
            return nil
        }
    }
    
    func saveDailyCheckin(hours: Double) {
        print("\n💾 Starting to save sleep check-in...")
        print("Hours to save: \(hours)")
        
        do {
            if let existingCheckin = fetchTodaysCheckin() {
                print("📝 Found existing check-in for today, updating...")
                existingCheckin.setValue(hours, forKey: "hours")
                existingCheckin.setValue(Date(), forKey: "date")
            } else {
                print("➕ No existing check-in found, creating new entry...")
                guard let entityDescription = NSEntityDescription.entity(forEntityName: "SleepCheckinEntity", in: context) else {
                    print("❌ Failed to get SleepCheckinEntity description")
                    return
                }
                
                let entity = NSManagedObject(entity: entityDescription, insertInto: context)
                entity.setValue(hours, forKey: "hours")
                entity.setValue(Date(), forKey: "date")
            }
            
            try context.save()
            print("✅ Successfully saved to Core Data")
            
            self.todaysSleep = SleepRating(hours: hours, date: Date())
            print("Updated todaysSleep in memory")
            
            cacheCheckinCompletion(hours: hours)
            print("✅ Sleep check-in save completed")
            
        } catch {
            print("❌ Failed to save sleep check-in: \(error)")
            print("Detailed error: \(error.localizedDescription)")
        }
    }

    func cacheCheckinCompletion(hours: Double) {
        print("\n📦 Starting to cache check-in completion...")
        print("Hours to cache: \(hours)")
        
        do {
            let sleepRating = SleepRating(hours: hours, date: Date())
            print("Created SleepRating object")
            
            let sleepRatingEncoded = try JSONEncoder().encode(sleepRating)
            print("Successfully encoded SleepRating")
            
            UserDefaults.standard.set(sleepRatingEncoded, forKey: checkInKey)
            print("Saved encoded hours to UserDefaults with key: \(checkInKey)")
            
            UserDefaults.standard.set(Date(), forKey: dateKey)
            print("Saved date to UserDefaults with key: \(dateKey)")
            
            print("✅ Successfully cached check-in completion")
            
        } catch {
            print("❌ Failed to cache check-in completion: \(error)")
            print("Detailed error: \(error.localizedDescription)")
        }
    }

    func checkIfCheckinCompleted() -> Double? {
        print("\n🔍 Checking if sleep check-in is completed for today...")
        
        do {
            if let date = UserDefaults.standard.object(forKey: dateKey) as? Date {
                print("Found saved date: \(date)")
                
                let isToday = Calendar.current.isDate(date, equalTo: Date(), toGranularity: .day)
                print("Is date today? \(isToday)")
                
                if isToday {
                    if let ratingData = UserDefaults.standard.data(forKey: checkInKey) {
                        print("Found cached rating data")
                        let rating = try JSONDecoder().decode(SleepRating.self, from: ratingData)
                        print("Successfully decoded rating: \(rating.hours)")
                        self.todaysSleep = rating
                        print("✅ Updated todaysSleep with cached data")
                        return rating.hours
                    } else {
                        print("⚠️ No rating data found for today's date")
                    }
                } else {
                    print("📅 Saved date is not today")
                }
            } else {
                print("ℹ️ No saved date found in UserDefaults")
            }
        } catch {
            print("❌ Error checking completion status: \(error)")
            print("Detailed error: \(error.localizedDescription)")
        }
        
        return nil
    }
}

// SleepRating.swift
struct SleepRating: Codable {
    let hours: Double
    let date: Date
}
