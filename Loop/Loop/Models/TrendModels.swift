//
//  TrendModels.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/9/24.
//

import Foundation
import CoreData


struct DailyStats: Identifiable {
    var date: Date?
    var year: Int16
    var month: Int16
    var weekOfYear: Int16
    var weekday: Int16
    var averageWPM: Double
    var averageDuration: Double
    var averageWordCount: Double
    var averageUniqueWordCount: Double
    var vocabularyDiversityRatio: Double
    var loopCount: Int16
    var lastUpdated: Date?
    
    var id: String {
        return date?.description ?? UUID().uuidString
    }
}

// MARK: - Models
struct AllTimeStats: Identifiable {
   var dataPointCount: Int64
   var averageWPM: Double
   var averageDuration: Double
   var averageWordCount: Double
   var averageUniqueWordCount: Double
   var vocabularyDiversityRatio: Double
   var lastUpdated: Date?
   
   var id: String {
       return lastUpdated?.description ?? UUID().uuidString
   }
}

struct MonthlyStats: Identifiable {
   var dataPointCount: Int64
   var averageWPM: Double
   var averageDuration: Double
   var averageWordCount: Double
   var averageUniqueWordCount: Double
   var vocabularyDiversityRatio: Double
   var lastUpdated: Date?
   var month: Int16
   var year: Int16
   
   var id: String {
       return "\(year)-\(month)"
   }
}

struct WeeklyStats: Identifiable {
   var dataPointCount: Int64
   var averageWPM: Double
   var averageDuration: Double
   var averageWordCount: Double
   var averageUniqueWordCount: Double
   var vocabularyDiversityRatio: Double
   var lastUpdated: Date?
   var weekNumber: Int16
   var year: Int16
   
   var id: String {
       return "\(year)-\(weekNumber)"
   }
}

protocol StatsProtocol {
    var averageWPM: Double { get }
    var averageDuration: Double { get }
    var averageWordCount: Double { get }
    var averageUniqueWordCount: Double { get }
    var vocabularyDiversityRatio: Double { get }
}

// Make all stat types conform to it
extension DailyStats: StatsProtocol {}
extension WeeklyStats: StatsProtocol {}
extension MonthlyStats: StatsProtocol {}
