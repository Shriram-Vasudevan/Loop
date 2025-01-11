//
//  DailyCheckinManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/14/24.
//

import Foundation
import CoreData

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
    
    func saveDailyCheckin(colorHex: String) {
        print("\n💾 Starting to save daily check-in...")
        print("Color to save: \(colorHex)")
        
        do {
            guard let entityDescription = NSEntityDescription.entity(forEntityName: "DailyCheckinEntity", in: context) else {
                print("❌ Failed to get DailyCheckinEntity description")
                return
            }
            print("✅ Got entity description for DailyCheckinEntity")
            
            let entity = NSManagedObject(entity: entityDescription, insertInto: context)
            print("Created new managed object")
            
            entity.setValue(colorHex, forKey: "colorHex")
            entity.setValue(Date(), forKey: "date")
            print("Set values - Color: \(colorHex), Date: \(Date())")
            
            try context.save()
            print("✅ Successfully saved to Core Data")
            
            self.todaysCheckIn = DayRating(colorHex: colorHex, date: Date())
            print("Updated todaysCheckIn in memory")
            
            cacheCheckinCompletion(colorHex: colorHex)
            print("✅ Daily check-in save completed")
            
        } catch {
            print("❌ Failed to save daily check-in: \(error)")
            print("Detailed error: \(error.localizedDescription)")
        }
    }
    
    func cacheCheckinCompletion(colorHex: String) {
        print("\n📦 Starting to cache check-in completion...")
        print("Color to cache: \(colorHex)")
        
        do {
            let dayRating = DayRating(colorHex: colorHex, date: Date())
            print("Created DayRating object")
            
            let dayRatingEncoded = try JSONEncoder().encode(dayRating)
            print("Successfully encoded DayRating")
            
            UserDefaults.standard.set(dayRatingEncoded, forKey: checkInKey)
            print("Saved encoded color to UserDefaults with key: \(checkInKey)")
            
            UserDefaults.standard.set(Date(), forKey: dateKey)
            print("Saved date to UserDefaults with key: \(dateKey)")
            
            print("✅ Successfully cached check-in completion")
            
        } catch {
            print("❌ Failed to cache check-in completion: \(error)")
            print("Detailed error: \(error.localizedDescription)")
        }
    }
    
    func checkIfCheckinCompleted() {
        print("\n🔍 Checking if check-in is completed for today...")
        
        do {
            if let date = UserDefaults.standard.object(forKey: dateKey) as? Date {
                print("Found saved date: \(date)")
                
                let isToday = Calendar.current.isDate(date, equalTo: Date(), toGranularity: .day)
                print("Is date today? \(isToday)")
                
                if isToday {
                    if let colorData = UserDefaults.standard.data(forKey: checkInKey) {
                        print("Found cached color data")
                        let rating = try JSONDecoder().decode(DayRating.self, from: colorData)
                        print("Successfully decoded color: \(rating.colorHex)")
                        self.todaysCheckIn = rating
                        print("✅ Updated todaysCheckIn with cached data")
                    }
                }
            }
        } catch {
            print("❌ Error checking completion status: \(error)")
            print("Detailed error: \(error.localizedDescription)")
        }
    }
}
