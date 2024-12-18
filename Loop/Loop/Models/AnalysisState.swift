//
//  AnalysisState.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/18/24.
//

import Foundation

enum AnalysisState {
    case noLoops
    case partial(count: Int)
    case analyzing
    case transcribing
    case analyzing_ai
    case completed(DailyAnalysis)
    case failed(AnalysisError)
    
    var description: String {
        switch self {
        case .noLoops:
            return "Record your first Loop to begin analysis"
        case .partial(let count):
            return "\(count)/3 Loops recorded. Complete all three to see your insights"
        case .analyzing:
            return "Analyzing your responses..."
        case .transcribing:
            return "Converting your speech to text..."
        case .analyzing_ai:
            return "Generating AI insights..."
        case .completed(_):
            return "Analysis complete"
        case .failed(let error):
            switch error {
            case .transcriptionFailed:
                return "Speech analysis failed. Please try again."
            case .aiAnalysisFailed:
                return "AI analysis unavailable. Other insights are still viewable."
            case .analysisFailure:
                return "Analysis incomplete. Some results may be unavailable."
            case .invalidData:
                return "Invalid data. Please contact us if the issue persists."
            }
        }
    }
}
