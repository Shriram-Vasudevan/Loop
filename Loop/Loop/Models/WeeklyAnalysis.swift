//
//  WeeklyAnalysis.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/23/24.
//

import Foundation

struct WeeklyAnalysis: Codable, Identifiable {
    let id = UUID()
    let weekStartDate: Date
    let weekEndDate: Date
    let loops: [LoopAnalysis]
    let keyMoments: [KeyMoment]
    let themes: [Theme]
    let aggregateMetrics: WeeklyMetrics
    let aiInsights: WeeklyAIInsights
}

struct KeyMoment: Codable {
    let date: Date
    let quote: String
    let context: String
    let significance: String
}

struct Theme: Codable {
    let name: String
    let description: String
    let relatedQuotes: [QuoteReference]
}

struct QuoteReference: Codable {
    let quote: String
    let date: Date
}

struct WeeklyMetrics: Codable {
    let totalWords: Int
    let averageDuration: TimeInterval
    let averageWordsPerMinute: Double
    let totalUniqueDays: Int
    let emotionalJourney: [Date: String]
    let weeklyWPMTrend: [Date: Double]
}

struct WeeklyAIInsights: Codable {
    let keyMoments: [KeyMoment]?
    let themes: [Theme]?
    let overallTone: String
    let progressNotes: String?
    let patterns: String?
    let suggestions: String?
}
