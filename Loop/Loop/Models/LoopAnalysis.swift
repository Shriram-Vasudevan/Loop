//
//  LoopAnalysis.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/9/24.
//

import Foundation

struct LoopMetrics: Codable {
    let duration: TimeInterval
    let wordCount: Int
    let uniqueWordCount: Int
    let wordsPerMinute: Double
    let vocabularyDiversity: Double
}

struct LoopAnalysis: Codable, Identifiable {
    let id: String
    let timestamp: Date
    let promptText: String
    let category: String
    let transcript: String
    let metrics: LoopMetrics
}

struct AggregateMetrics: Codable {
    let averageDuration: TimeInterval
    let averageWordCount: Double
    let averageWPM: Double
    let vocabularyDiversity: Double
}

struct DailyAnalysis: Codable {
    let date: Date
    let loops: [LoopAnalysis]
    let aggregateMetrics: AggregateMetrics
    let aiAnalysis: AIAnalysisResult?
}

enum AnalysisError: Error {
    case transcriptionFailed(String)
    case aiAnalysisFailed(String)
    case analysisFailure(Error)
    case invalidData(String)
    case missingFields(fields: [String])
}
//
//struct MetricComparison: Codable {
//    let direction: ComparisonDirection
//    let percentageChange: Double
//    
//    
//}

extension LoopMetrics {
    static let fallback = LoopMetrics(
        duration: 0,
        wordCount: 0,
        uniqueWordCount: 0,
        wordsPerMinute: 0,
        vocabularyDiversity: 0.0
    )
}


extension LoopAnalysis {
    static func createFallback(id: String = UUID().uuidString, timestamp: Date = Date(), promptText: String = "") -> LoopAnalysis {
        LoopAnalysis(
            id: id,
            timestamp: timestamp,
            promptText: promptText,
            category: "",
            transcript: "",
            metrics: .fallback
        )
    }
}
