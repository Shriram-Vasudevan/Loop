//
//  TrendModels.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/9/24.
//

import Foundation
import CoreData



@objc(DailyStats)
public class DailyStats: NSManagedObject {
    @NSManaged public var date: Date?
    @NSManaged public var year: Int16
    @NSManaged public var month: Int16
    @NSManaged public var weekOfYear: Int16
    @NSManaged public var weekday: Int16
    @NSManaged public var averageWPM: Double
    @NSManaged public var averageDuration: Double
    @NSManaged public var averageWordCount: Double
    @NSManaged public var averageUniqueWordCount: Double
    @NSManaged public var averageSelfReferences: Double
    @NSManaged public var vocabularyDiversityRatio: Double
    @NSManaged public var averageWordLength: Double
    @NSManaged public var loopCount: Int16
    @NSManaged public var lastUpdated: Date?
}

@objc(AllTimeStats)
public class AllTimeStats: NSManagedObject {
    @NSManaged public var dataPointCount: Int64
    @NSManaged public var averageWPM: Double
    @NSManaged public var averageDuration: Double
    @NSManaged public var averageWordCount: Double
    @NSManaged public var averageUniqueWordCount: Double
    @NSManaged public var averageSelfReferences: Double
    @NSManaged public var vocabularyDiversityRatio: Double
    @NSManaged public var averageWordLength: Double
    @NSManaged public var lastUpdated: Date?
}

@objc(MonthlyStats)
public class MonthlyStats: NSManagedObject {
    @NSManaged public var dataPointCount: Int64
    @NSManaged public var averageWPM: Double
    @NSManaged public var averageDuration: Double
    @NSManaged public var averageWordCount: Double
    @NSManaged public var averageUniqueWordCount: Double
    @NSManaged public var averageSelfReferences: Double
    @NSManaged public var vocabularyDiversityRatio: Double
    @NSManaged public var averageWordLength: Double
    @NSManaged public var lastUpdated: Date?
    @NSManaged public var month: Int16
    @NSManaged public var year: Int16
}

@objc(WeeklyStats)
public class WeeklyStats: NSManagedObject {
    @NSManaged public var dataPointCount: Int64
    @NSManaged public var averageWPM: Double
    @NSManaged public var averageDuration: Double
    @NSManaged public var averageWordCount: Double
    @NSManaged public var averageUniqueWordCount: Double
    @NSManaged public var averageSelfReferences: Double
    @NSManaged public var vocabularyDiversityRatio: Double
    @NSManaged public var averageWordLength: Double
    @NSManaged public var lastUpdated: Date?
    @NSManaged public var weekNumber: Int16
    @NSManaged public var year: Int16
}

