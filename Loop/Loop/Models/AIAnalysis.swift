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
    let additionalKeyMoments: AdditionalKeyMoments?
    let goalsAnalysis: GoalsAnalysis?
    let winsAnalysis: WinsAnalysis?
    let positiveBeliefs: PositiveBeliefs?
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

enum GoalCategory: String, Codable {
    case career
    case personal
    case health
    case relationship
    case financial
    case learning
}

enum GoalTimeframe: String, Codable {
    case immediate
    case shortTerm = "short_term"
    case longTerm = "long_term"
    case unspecified
}

enum AchievementCategory: String, Codable {
    case accomplishment
    case progress
    case realization
    case breakthrough
}

enum AffirmationTheme: String, Codable {
    case selfWorth = "self_worth"
    case capability
    case growth
    case future
    case relationships
}

// New Models
struct Goal: Codable {
    let goal: String
    let category: GoalCategory
    let timeframe: GoalTimeframe
    let context: String?
}

struct GoalsAnalysis: Codable {
    let exists: Bool
    let items: [Goal]?
}

struct Achievement: Codable {
    let win: String
    let category: AchievementCategory
    let associatedTopic: String
    let sentimentIntensity: Double
}

struct WinsAnalysis: Codable {
    let exists: Bool
    let achievements: [Achievement]?
}

struct Affirmation: Codable {
    let affirmation: String
    let theme: AffirmationTheme
    let context: String?
}

struct PositiveBeliefs: Codable {
    let exists: Bool
    let statements: [Affirmation]?
}
