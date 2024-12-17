//
//  Graph.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/15/24.
//

import Foundation

struct GraphPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    var label: String  // Will be automatically set based on period
}

struct GraphData {
    let points: [GraphPoint]
    let maxY: Double
    let minY: Double
    let average: Double
    let metric: MetricType
    let period: TimePeriod
    
    enum MetricType: String, CaseIterable {
        case wpm = "Words per Minute"
        case duration = "Duration"
        case wordCount = "Word Count"
        case uniqueWords = "Unique Words"
        case selfReferences = "Self References"
        case vocabularyDiversity = "Vocabulary Diversity"
        
        var shortName: String {
            switch self {
            case .wpm: return "WPM"
            case .duration: return "Duration"
            case .wordCount: return "Words"
            case .uniqueWords: return "Unique"
            case .selfReferences: return "Self Refs"
            case .vocabularyDiversity: return "Vocabulary"
            }
        }
    }
    
    init(points: [GraphPoint], metric: MetricType, period: TimePeriod) {
        // Format points with correct labels based on period
        let formattedPoints = points.map { point in
            var newPoint = point
            newPoint.label = period.formatLabel(for: point.date)
            return newPoint
        }
        
        self.points = formattedPoints
        self.metric = metric
        self.period = period
        
        // Calculate statistics
        let values = points.map { $0.value }
        self.maxY = values.max() ?? 0
        self.minY = values.min() ?? 0
        self.average = values.reduce(0, +) / Double(values.count)
    }
}

enum TimePeriod {
    case week
    case month
    case year
    
    func formatLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        switch self {
        case .week:
            formatter.dateFormat = "EEEEE"
            return formatter.string(from: date)
        case .month:
            let calendar = Calendar.current
            let weekOfMonth = calendar.component(.weekOfMonth, from: date)
            return "\(weekOfMonth)"
        case .year:
            formatter.dateFormat = "MMM"
            return String(formatter.string(from: date).prefix(1))
        }
    }
}

struct TimelinePoint {
    let index: Int
    let label: String
    var value: Double?
    var date: Date?
}

extension TimePeriod {
    var allPoints: [TimelinePoint] {
        switch self {
        case .week:
            return [
                TimelinePoint(index: 0, label: "S", value: nil, date: nil),
                TimelinePoint(index: 1, label: "M", value: nil, date: nil),
                TimelinePoint(index: 2, label: "T", value: nil, date: nil),
                TimelinePoint(index: 3, label: "W", value: nil, date: nil),
                TimelinePoint(index: 4, label: "T", value: nil, date: nil),
                TimelinePoint(index: 5, label: "F", value: nil, date: nil),
                TimelinePoint(index: 6, label: "S", value: nil, date: nil)
            ]
        case .month:
            return (1...4).map { week in
                TimelinePoint(index: week - 1, label: "\(week)", value: nil, date: nil)
            }
        case .year:
            return [
                TimelinePoint(index: 0, label: "J", value: nil, date: nil),
                TimelinePoint(index: 1, label: "F", value: nil, date: nil),
                TimelinePoint(index: 2, label: "M", value: nil, date: nil),
                TimelinePoint(index: 3, label: "A", value: nil, date: nil),
                TimelinePoint(index: 4, label: "M", value: nil, date: nil),
                TimelinePoint(index: 5, label: "J", value: nil, date: nil),
                TimelinePoint(index: 6, label: "J", value: nil, date: nil),
                TimelinePoint(index: 7, label: "A", value: nil, date: nil),
                TimelinePoint(index: 8, label: "S", value: nil, date: nil),
                TimelinePoint(index: 9, label: "O", value: nil, date: nil),
                TimelinePoint(index: 10, label: "N", value: nil, date: nil),
                TimelinePoint(index: 11, label: "D", value: nil, date: nil)
            ]
        }
    }
}

