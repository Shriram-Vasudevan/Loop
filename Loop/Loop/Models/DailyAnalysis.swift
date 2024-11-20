//
//  DailyAnalysis.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/20/24.
//

import Foundation

struct PromptAnalysis: Codable, Identifiable {
    let id = UUID()
    let promptText: String
    let wordCount: Int
    let duration: TimeInterval
    let speakingPace: Double
    let pastTensePercentage: Double
    let futureTensePercentage: Double
    let selfReferencePercentage: Double
    let keywords: [String]
    let names: [String]
    let timestamp: Date
}

struct DailyAnalysis: Codable, Identifiable {
    let id = UUID()
    let date: Date
    var promptAnalyses: [PromptAnalysis]
    var isComplete: Bool
    
    var averageDuration: TimeInterval {
        promptAnalyses.map { $0.duration }.reduce(0, +) / Double(promptAnalyses.count)
    }
    
    var averageSpeakingPace: Double {
        promptAnalyses.map { $0.speakingPace }.reduce(0, +) / Double(promptAnalyses.count)
    }
    
    var averagePastTensePercentage: Double {
        promptAnalyses.map { $0.pastTensePercentage }.reduce(0, +) / Double(promptAnalyses.count)
    }
    
    var averageFutureTensePercentage: Double {
        promptAnalyses.map { $0.futureTensePercentage }.reduce(0, +) / Double(promptAnalyses.count)
    }
    
    var averageSelfReferencePercentage: Double {
        promptAnalyses.map { $0.selfReferencePercentage }.reduce(0, +) / Double(promptAnalyses.count)
    }
    
    var totalWordCount: Int {
        promptAnalyses.map { $0.wordCount }.reduce(0, +)
    }
    
    var allKeywords: [String] {
        Array(Set(promptAnalyses.flatMap { $0.keywords }))
    }
    
    var allNames: [String] {
        Array(Set(promptAnalyses.flatMap { $0.names }))
    }
}
