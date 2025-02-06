//
//  AIAnalysis.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/27/24.
//

import Foundation

import Foundation

struct DailyAIAnalysisResult: Codable {
    let date: Date
    let moodData: MoodData?
    let sleepData: SleepData?
    let standoutAnalysis: StandoutAnalysis?
    let additionalKeyMoments: AdditionalKeyMoments?
    let topicSentiments: [TopicSentiment]?
    let dailySummary: DailySummary?
}

struct DailySummary: Codable {
    let exists: Bool
    let summary: String?
}

struct TopicSentiment: Codable {
    let topic: String
    let sentiment: Double
}

struct FollowUpSuggestion: Codable {
    let exists: Bool
    let suggestion: String?
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
    let category: MomentCategory?
    let sentiment: Double? 
    let keyMoment: String?
}

struct AdditionalKeyMoments: Codable {
    let exists: Bool
    let moments: [KeyMomentModel]?
}

struct KeyMomentModel: Codable {
    let keyMoment: String
    let category: MomentCategory
    let sourceType: SourceType
    
    enum CodingKeys: String, CodingKey {
        case keyMoment = "key_moment"
        case category
        case sourceType = "source_type"
    }
}

struct RecurringThemes: Codable {
    let exists: Bool
    let themes: [String]?
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

enum TopicCategory: String, Codable, CaseIterable {
    case work
    case relationships
    case health
    case learning
    case creativity
    case purpose
    case relaxation
    case finances
    case growth
    case school
}


enum MomentCategory: String, Codable {
    case realization
    case learning
    case success
    case challenge
    case connection
    case decision
    case plan
}

enum SourceType: String, Codable {
    case summary
    case freeform
}

enum SentimentCategory: String, Codable {
    case positive
    case neutral
    case negative
}
