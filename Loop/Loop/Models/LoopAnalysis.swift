//
//  LoopAnalysis.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/9/24.
//

import Foundation

struct WordCount: Codable {
    let word: String
    let count: Int
}

struct MinMaxRange: Codable {
    let min: Double
    let max: Double
}

struct IntRange: Codable {
    let min: Int
    let max: Int
}

struct LoopAnalysis: Codable, Identifiable {
    let id: String
    let timestamp: Date
    let promptText: String
    let category: String
    let metrics: LoopMetrics
    let wordAnalysis: WordAnalysis
}

struct LoopMetrics: Codable {
    let duration: TimeInterval
    let wordCount: Int
    let uniqueWordCount: Int
    let wordsPerMinute: Double
    let selfReferenceCount: Int
    let uniqueSelfReferenceCount: Int
    let averageWordLength: Double
}

struct WordAnalysis: Codable {
    let words: [String]
    let uniqueWords: [String]  // Changed from Set to Array
    let mostUsedWords: [WordCount]
    let selfReferenceTypes: [String]  // Changed from Set to Array
}

struct DailyAnalysis: Codable {
    let date: Date
    let loops: [LoopAnalysis]
    let aggregateMetrics: AggregateMetrics
    let wordPatterns: WordPatterns
    let overlapAnalysis: OverlapAnalysis
    let rangeAnalysis: RangeAnalysis
}

struct AggregateMetrics: Codable {
    let averageDuration: TimeInterval
    let averageWordCount: Double
    let averageUniqueWordCount: Double
    let averageWPM: Double
    let averageSelfReferences: Double
    let vocabularyDiversityRatio: Double
}

struct WordPatterns: Codable {
    let totalUniqueWords: [String]  // Changed from Set to Array
    let wordsInAllResponses: [String]  // Changed from Set to Array
    let mostUsedWords: [WordCount]
}

struct OverlapAnalysis: Codable {
    let pairwiseOverlap: [String: Double]
    let commonWords: [String: [String]]  // Changed from Set to Array
    let overallSimilarity: Double
}

struct RangeAnalysis: Codable {
    let wpmRange: MinMaxRange
    let durationRange: MinMaxRange
    let wordCountRange: IntRange
    let selfReferenceRange: IntRange
}

enum AnalysisError: Error {
    case transcriptionFailed
    case invalidData
    case analysisFailure
    case insufficientData
}

struct MetricComparison: Codable {
    let direction: ComparisonDirection
    let percentageChange: Double
    
    
}
