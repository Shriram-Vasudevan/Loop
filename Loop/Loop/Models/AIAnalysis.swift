//
//  AIAnalysis.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/27/24.
//

import Foundation

struct EmotionAnalysis: Codable {
    let emotion: String
    let description: String
}

struct ExpressionStyle: Codable {
    let fillerWords: String // minimal/moderate/frequent
    let pattern: String // analytical, practical, emotional, action-focused, reflective
    let note: String
}

struct SocialLandscape: Codable {
    let focus: String // self-centered/relationship-focused/balanced
    let context: String // work/personal/mixed
    let connections: String
}

struct NextSteps: Codable {
    let actions: [String]
    let hasActions: Bool
}

struct Challenges: Codable {
    let items: [String]
    let hasChallenges: Bool
}

struct FollowUp: Codable {
    let question: String
    let purpose: String
}

struct AIAnalysisResult: Codable {
    let emotion: EmotionAnalysis
    let expression: ExpressionStyle
    let social: SocialLandscape
    let nextSteps: NextSteps
    let challenges: Challenges
    let followUp: FollowUp
}
