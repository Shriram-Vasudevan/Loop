//
//  LoopAnalysis.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/9/24.
//

import Foundation

struct DailyAnalysis: Codable {
    let date: Date
    let quantitativeMetrics: QuantitativeMetrics
    let aiAnalysis: DailyAIAnalysisResult
}

struct QuantitativeMetrics: Codable {
    let totalWordCount: Int
    let totalDurationSeconds: Double
    let averageWordsPerRecording: Double
    let averageDurationPerRecording: Double
}

struct MetricDayModel {
    let date: Date
    let totalWords: Int
    let recordingSeconds: Double
    let wordsPerMinute: Double
    let moodRating: Double?
    let sleepHours: Int?
    let primaryTopic: String?
}

struct SignificantMomentModel {
    let date: Date
    let loopId: String
    let content: String
    let momentType: String
    let associatedMood: Int
    let topic: String
    let lastRetrieved: Date?
    let isWin: Bool
}

enum AnalysisError: Error, Equatable {
    case noResponses
    case analysisError(Error)
    case missingRequiredFields(fields: [String])
    case aiAnalysisFailed(String)
    case transcriptionFailed(String)
    
    static func == (lhs: AnalysisError, rhs: AnalysisError) -> Bool {
        switch (lhs, rhs) {
        case (.noResponses, .noResponses):
            return true
        case (.analysisError, .analysisError):
            return true
        case (.missingRequiredFields(let lFields), .missingRequiredFields(let rFields)):
            return lFields == rFields
        case (.aiAnalysisFailed(let lMessage), .aiAnalysisFailed(let rMessage)):
            return lMessage == rMessage
        default:
            return false
        }
    }
    
    var description: String {
        switch self {
        case .noResponses:
            return "No reflections found. Complete today's reflections to see your insights."
        case .analysisError(let error):
            return "Analysis error: \(error.localizedDescription). Some insights may be unavailable."
        case .missingRequiredFields(let fields):
            return "Missing required fields: \(fields.joined(separator: ", ")). Some insights may be unavailable."
        case .aiAnalysisFailed(let message):
            return "AI analysis failed: \(message). Some insights may be unavailable."
        case .transcriptionFailed(let error):
            return error
        }
    }
    
    var recoveryMessage: String {
        switch self {
        case .noResponses:
            return "Record your daily reflections to begin seeing insights."
        case .analysisError(_):
            return "Try again later. If the issue persists, please contact support."
        case .missingRequiredFields(_):
            return "Try again later. If the issue persists, please contact support."
        case .aiAnalysisFailed(_):
            return "Try again later. Your other insights are still available."
        case .transcriptionFailed(_):
            return "Try again later. If the issue persists, please contact support."
        }
    }
}

