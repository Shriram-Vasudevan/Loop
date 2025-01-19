//
//  DailyCheckinManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/14/24.
//

import Foundation
import CoreData

//
//  DailyCheckinManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/14/24.
//

import Foundation
import CoreData

class DailyCheckinManager: ObservableObject {
    static let shared = DailyCheckinManager()
        
    @Published var todaysCheckIn: DayRating?
    
    let dateKey: String = "checkinDateKey"
    let checkInKey: String = "checkinKey"
    
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
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DailyCheckinEntity")
        fetchRequest.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.first
        } catch {
            print("❌ Failed to fetch today's check-in: \(error)")
            return nil
        }
    }
    
    func saveDailyCheckin(rating: Double) {
        print("\n💾 Starting to save daily check-in...")
        print("Rating to save: \(rating)")
        
        do {
            // Check if we already have an entry for today
            if let existingCheckin = fetchTodaysCheckin() {
                print("📝 Found existing check-in for today, updating...")
                existingCheckin.setValue(rating, forKey: "rating")
                existingCheckin.setValue(Date(), forKey: "date")
            } else {
                print("➕ No existing check-in found, creating new entry...")
                guard let entityDescription = NSEntityDescription.entity(forEntityName: "DailyCheckinEntity", in: context) else {
                    print("❌ Failed to get DailyCheckinEntity description")
                    return
                }
                
                let entity = NSManagedObject(entity: entityDescription, insertInto: context)
                entity.setValue(rating, forKey: "rating")
                entity.setValue(Date(), forKey: "date")
            }
            
            try context.save()
            print("✅ Successfully saved to Core Data")
            
            self.todaysCheckIn = DayRating(rating: rating, date: Date())
            print("Updated todaysCheckIn in memory")
            
            cacheCheckinCompletion(rating: rating)
            print("✅ Daily check-in save completed")
            
        } catch {
            print("❌ Failed to save daily check-in: \(error)")
            print("Detailed error: \(error.localizedDescription)")
        }
    }

    func cacheCheckinCompletion(rating: Double) {
        print("\n📦 Starting to cache check-in completion...")
        print("Rating to cache: \(rating)")
        
        do {
            let dayRating = DayRating(rating: rating, date: Date())
            print("Created DayRating object")
            
            let dayRatingEncoded = try JSONEncoder().encode(dayRating)
            print("Successfully encoded DayRating")
            
            UserDefaults.standard.set(dayRatingEncoded, forKey: checkInKey)
            print("Saved encoded rating to UserDefaults with key: \(checkInKey)")
            
            UserDefaults.standard.set(Date(), forKey: dateKey)
            print("Saved date to UserDefaults with key: \(dateKey)")
            
            print("✅ Successfully cached check-in completion")
            
            // Verify cache
            if let savedData = UserDefaults.standard.data(forKey: checkInKey) {
                print("Verified: Found cached data")
            } else {
                print("⚠️ Warning: Could not verify cached data")
            }
            
        } catch {
            print("❌ Failed to cache check-in completion: \(error)")
            print("Detailed error: \(error.localizedDescription)")
        }
    }

    func checkIfCheckinCompleted() -> Double? {
        print("\n🔍 Checking if check-in is completed for today...")
        
        do {
            if let date = UserDefaults.standard.object(forKey: dateKey) as? Date {
                print("Found saved date: \(date)")
                
                let isToday = Calendar.current.isDate(date, equalTo: Date(), toGranularity: .day)
                print("Is date today? \(isToday)")
                
                if isToday {
                    if let ratingData = UserDefaults.standard.data(forKey: checkInKey) {
                        print("Found cached rating data")
                        let rating = try JSONDecoder().decode(DayRating.self, from: ratingData)
                        print("Successfully decoded rating: \(rating.rating)")
                        self.todaysCheckIn = rating
                        print("✅ Updated todaysCheckIn with cached data")
                        return rating.rating
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
