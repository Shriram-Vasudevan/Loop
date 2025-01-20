//
//  AIAnalysis.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/27/24.
//

import Foundation

enum CommunicationStyle: String, Codable {
    case analytical
    case emotional
    case practical
    case reflective
}

enum TopicCategory: String, Codable, CaseIterable {
    case work
    case personal
    case relationships
    case health
    case learning
    case creativity
    case purpose
    case wellbeing
    case growth
}

enum ToneCategory: String, Codable {
    case positive
    case neutral
    case reflective
    case challenging
}

// MARK: - Daily Analysis Models

struct DailyExpression: Codable {
    let style: CommunicationStyle
    let topics: Set<TopicCategory>
    let tone: ToneCategory
}

struct NotableElement: Codable {
    let type: ElementType
    let content: String
    
    enum ElementType: String, Codable {
        case insight
        case win
        case challenge
        case positive
        case strategy
        case intention
    }
}

struct MoodCorrelation: Codable {
    let rating: Double?
    let sleep: Int?
}

struct FollowUp: Codable, Identifiable {
    let id: String = UUID().uuidString
    let question: String
    let purpose: String
}

struct DailyAIAnalysisResult: Codable {
    let date: Date
    let expression: DailyExpression
    let notableElements: [NotableElement]
    let mood: MoodCorrelation
    let followUp: FollowUp  // New field
}
