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
    
    @Published var todaysCheckIn: DayRating? {
        didSet {
            objectWillChange.send()
        }
    }
    
    private let dateKey = "checkinDateKey"
    private let checkInKey = "checkinKey"
    
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
        loadTodaysCheckin()
    }
    
    func getAverageDailyRating() -> Double? {
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
           
           // If no ratings found, return nil
           guard !results.isEmpty else {
               print("ℹ️ No ratings found for today")
               return nil
           }
           
           // Calculate the average
           let totalRating = results.reduce(0.0) { sum, checkin in
               sum + (checkin.value(forKey: "rating") as? Double ?? 0.0)
           }
           
           let averageRating = totalRating / Double(results.count)
           print("📊 Average rating for today: \(averageRating)")
           
           return averageRating
           
       } catch {
           print("❌ Failed to fetch daily ratings: \(error)")
           print("Detailed error: \(error.localizedDescription)")
           return nil
       }
   }
    
    private func loadTodaysCheckin() {
        if let rating = checkIfDailyCheckinCompleted() {
            DispatchQueue.main.async {
                self.todaysCheckIn = DayRating(rating: rating, date: Date())
            }
        }
    }
    
    func saveDailyCheckin(rating: Double, isThroughDailySession: Bool) {
        do {
            if isThroughDailySession {
                if let existingCheckin = fetchTodaysCheckin() {
                    existingCheckin.setValue(rating, forKey: "rating")
                    existingCheckin.setValue(Date(), forKey: "date")
                    existingCheckin.setValue(isThroughDailySession, forKey: "isDailySession")
                } else {
                    createNewCheckin(rating: rating, isThroughDailySession: isThroughDailySession)
                }
            } else {
                createNewCheckin(rating: rating, isThroughDailySession: isThroughDailySession)
            }
            
            try context.save()
            
            DispatchQueue.main.async {
                self.todaysCheckIn = DayRating(rating: rating, date: Date())
            }
            
            cacheCheckinCompletion(rating: rating)
            
        } catch {
            print("❌ Failed to save daily check-in: \(error)")
        }
    }
    
    private func createNewCheckin(rating: Double, isThroughDailySession: Bool) {
        guard let entity = NSEntityDescription.entity(forEntityName: "DailyCheckinEntity", in: context) else {
            return
        }
        
        let newCheckin = NSManagedObject(entity: entity, insertInto: context)
        newCheckin.setValue(rating, forKey: "rating")
        newCheckin.setValue(Date(), forKey: "date")
        newCheckin.setValue(isThroughDailySession, forKey: "isDailySession")
    }
    
    private func cacheCheckinCompletion(rating: Double) {
        do {
            let dayRating = DayRating(rating: rating, date: Date())
            let encoded = try JSONEncoder().encode(dayRating)
            
            UserDefaults.standard.set(encoded, forKey: checkInKey)
            UserDefaults.standard.set(Date(), forKey: dateKey)
            
        } catch {
            print("❌ Failed to cache check-in: \(error)")
        }
    }
    
    func checkIfDailyCheckinCompleted() -> Double? {
        if let existingCheckin = fetchTodaysCheckin() {
            return existingCheckin.value(forKey: "rating") as? Double
        }

        if let date = UserDefaults.standard.object(forKey: dateKey) as? Date,
           Calendar.current.isDate(date, equalTo: Date(), toGranularity: .day),
           let ratingData = UserDefaults.standard.data(forKey: checkInKey) {
            do {
                let rating = try JSONDecoder().decode(DayRating.self, from: ratingData)
                return rating.rating
            } catch {
                print("❌ Failed to decode cached rating: \(error)")
            }
        }
        
        return nil
    }
    
    private func fetchTodaysCheckin() -> NSManagedObject? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return nil
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DailyCheckinEntity")
        fetchRequest.predicate = NSPredicate(
            format: "date >= %@ AND date < %@ AND isDailySession == %@",
            startOfDay as NSDate,
            endOfDay as NSDate,
            NSNumber(value: true)
        )
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.first
        } catch {
            print("❌ Failed to fetch today's check-in: \(error)")
            return nil
        }
    }
}
