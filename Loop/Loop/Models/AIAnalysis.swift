//
//  AIAnalysis.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/27/24.
//

import Foundation

enum TimeOrientation: String, Codable {
    case past
    case present
    case future
    case mixed
}

struct EmotionAnalysis: Codable {
    let primary: String
    let intensity: Int
    let tone: String
    let description: String
}

struct TimeFocus: Codable {
    let orientation: TimeOrientation
    let description: String
}

struct SelfReferenceAnalysis: Codable {
    let frequency: String // "high", "moderate", "low"
    let pattern: String  // How self-references are used (e.g., "reflective", "action-oriented")
    let description: String // What this reveals about self-focus
}

struct SignificantPhrases: Codable {
    let insightPhrases: [String]
    let reflectionPhrases: [String]
    let decisionPhrases: [String]
    let description: String
}

struct FollowUp: Codable, Identifiable {
    let id: String = UUID().uuidString
    let question: String
    let context: String
    let focus: String
}

struct AIAnalysisResult: Codable {
    let emotion: EmotionAnalysis
    let timeFocus: TimeFocus
    let selfReference: SelfReferenceAnalysis
    let phrases: SignificantPhrases
    let followUp: FollowUp
}
