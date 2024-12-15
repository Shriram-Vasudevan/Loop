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
    let label: String  // For x-axis display
}

struct GraphData {
    let points: [GraphPoint]
    let maxY: Double
    let minY: Double
    let average: Double
    let metric: MetricType
    
    enum MetricType: String, CaseIterable {
        case wpm = "Words per Minute"
        case duration = "Duration"
        case wordCount = "Word Count"
        case uniqueWords = "Unique Words"
        case selfReferences = "Self References"
        case vocabularyDiversity = "Vocabulary Diversity"
    }
}
