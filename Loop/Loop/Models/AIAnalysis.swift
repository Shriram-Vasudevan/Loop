//
//  AIAnalysis.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/27/24.
//

import Foundation

struct DailyAIAnalysisResult: Codable {
    let date: Date
    let moodData: MoodData?
    let sleepData: SleepData?
    let standoutAnalysis: StandoutAnalysis?
    let summaryAnalysis: SummaryAnalysis?
    let freeformAnalysis: FreeformAnalysis?
    let fillerAnalysis: FillerAnalysis
}
struct MoodData: Codable {
    let exists: Bool
    let rating: Double?
}

struct SleepData: Codable {
    let exists: Bool
    let hours: Double?
}

struct StandoutAnalysis: Codable {
    let exists: Bool
    let primaryTopic: TopicCategory?
    let sentiment: SentimentCategory?
    let keyMoment: String?
}

struct SummaryAnalysis: Codable {
    let exists: Bool
    let primaryTopic: TopicCategory?
    let sentiment: SentimentCategory?
}

struct FreeformAnalysis: Codable {
    let exists: Bool
    let primaryTopic: TopicCategory?
    let sentiment: SentimentCategory?
}

struct FillerAnalysis: Codable {
    let totalCount: Int
}

enum TopicCategory: String, Codable {
    case work
    case relationships
    case health
    case growth
    case creativity
    case purpose
}

enum SentimentCategory: String, Codable {
    case positive
    case neutral
    case negative
}
