//
//  InsightModels.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/16/24.
//

import Foundation

struct MoodScore: Identifiable {
    let id = UUID()
    let mood: String // Example: "Happy", "Sad", "Stressed"
    let percentage: Double // Example: 75.0 for 75% Happy
}

struct LoopSummary: Identifiable {
    let id = UUID()
    let date: Date // Timestamp of the loop
    let topMood: String // Main mood from sentiment analysis
    let moodScores: [MoodScore] // All sentiment analysis results
}

struct Insights {
    let recentLoop: LoopSummary? // Most recent loop summary
    let topMentionedWord: String // A word frequently mentioned in loops
    let monthlyMoodDistribution: [MoodScore] // Aggregated mood trends for the month
    let goalSuggestion: String // A suggested action based on insights
}
