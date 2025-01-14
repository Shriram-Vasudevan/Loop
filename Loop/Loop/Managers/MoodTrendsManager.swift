//
//  MoodTrendsManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/11/25.
//

import Foundation
import CoreData

class MoodTrendsManager: ObservableObject {
//    @Published var weekData: [DailyColorHex] = []
//    @Published var monthData: [DailyColorHex] = []
//    @Published var yearData: [DailyColorHex] = []
//    
//    private lazy var persistentContainer: NSPersistentContainer = {
//        let container = NSPersistentContainer(name: "LoopData")
//        container.loadPersistentStores { _, error in
//            if let error = error as NSError? {
//                fatalError("Unresolved error \(error), \(error.userInfo)")
//            }
//        }
//        return container
//    }()
//    
//    private var context: NSManagedObjectContext {
//        return persistentContainer.viewContext
//    }
//    
//    func getMoodDataForTimeFrame(timeFrame: Timeframe) {
//        let data = fetchMoodDataFromCoreData(timeFrame: timeFrame)
//        
//        DispatchQueue.main.async {
//            switch timeFrame {
//            case .week:
//                self.weekData = data
//            case .month:
//                self.monthData = data
//            case .year:
//                self.yearData = data
//            }
//        }
//    }
//    
//    func fetchMoodDataFromCoreData(timeFrame: Timeframe) -> [DailyColorHex] {
//        let calendar = Calendar.current
//        let now = Date()
//        
//        let (startDate, endDate) = calculateDateRange(for: timeFrame, from: now)
//        
//        guard let startDate = startDate,
//              let endDate = endDate else { return [] }
//        
//        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DailyCheckinEntity")
//        fetchRequest.predicate = NSPredicate(
//            format: "date >= %@ AND date <= %@",
//            startDate as NSDate,
//            endDate as NSDate
//        )
//        
//        do {
//            let results = try context.fetch(fetchRequest)
//            let moodData = results.compactMap { convertToDailyAnalysis(entity: $0) }
//            return moodData
//        } catch {
//            print("Error fetching mood data: \(error)")
//            return []
//        }
//    }
//    
//    private func calculateDateRange(for timeFrame: Timeframe, from date: Date) -> (Date?, Date?) {
//        let calendar = Calendar.current
//        
//        switch timeFrame {
//        case .week:
//            guard let startDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) else {
//                return (nil, nil)
//            }
//            let endDate = calendar.date(byAdding: .day, value: 6, to: startDate)
//            return (startDate, endDate)
//            
//        case .month:
//            let components = calendar.dateComponents([.year, .month], from: date)
//            guard let startDate = calendar.date(from: components),
//                  let endDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startDate) else {
//                return (nil, nil)
//            }
//            return (startDate, endDate)
//            
//        case .year:
//            var components = calendar.dateComponents([.year], from: date)
//            guard let startDate = calendar.date(from: components),
//                  let currentYear = components.year else {
//                return (nil, nil)
//            }
//            
//            var endComponents = calendar.dateComponents([.year], from: date)
//            endComponents.year = currentYear + 1
//            endComponents.day = -1
//            guard let endDate = calendar.date(from: endComponents) else {
//                return (nil, nil)
//            }
//            return (startDate, endDate)
//        }
//    }
//    
//    func convertToDailyAnalysis(entity: NSManagedObject) -> DailyColorHex? {
//        guard let date = entity.value(forKey: "date") as? Date,
//              let colorHex = entity.value(forKey: "colorHex") as? String else {
//            return nil
//        }
//        
//        return DailyColorHex(colorHex: colorHex, date: date)
//    }
}

