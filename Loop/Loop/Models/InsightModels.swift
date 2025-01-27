//
//  InsightModels.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/16/24.
//

import Foundation

struct MoodScore: Identifiable {
    let id = UUID()
    let mood: String
    let percentage: Double
}

struct LoopSummary: Identifiable {
    let id = UUID()
    let date: Date
    let topMood: String
    let moodScores: [MoodScore]
}

struct Insights {
    let recentLoop: LoopSummary? // Most recent loop summary
    let topMentionedWord: String // A word frequently mentioned in loops
    let monthlyMoodDistribution: [MoodScore] // Aggregated mood trends for the month
    let goalSuggestion: String // A suggested action based on insights
}
