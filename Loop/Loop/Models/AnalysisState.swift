//
//  AnalysisState.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/18/24.
//

import Foundation

enum AnalysisState: Equatable {
   case notStarted
   case retrievingResponses
   case analyzingQuantitative
   case analyzingAI
   case completed(DailyAnalysis)
   case failed(AnalysisError)
   
   static func == (lhs: AnalysisState, rhs: AnalysisState) -> Bool {
       switch (lhs, rhs) {
       case (.notStarted, .notStarted):
           return true
       case (.retrievingResponses, .retrievingResponses):
           return true
       case (.analyzingQuantitative, .analyzingQuantitative):
           return true
       case (.analyzingAI, .analyzingAI):
           return true
       case (.completed(let lhsAnalysis), .completed(let rhsAnalysis)):
           return lhsAnalysis.date == rhsAnalysis.date
       case (.failed(let lhsError), .failed(let rhsError)):
           return lhsError == rhsError
       default:
           return false
       }
   }
   
   var description: String {
       switch self {
       case .notStarted:
           return "Complete your daily reflections to begin analysis"
           
       case .retrievingResponses:
           return "Gathering today's reflections for analysis..."
           
       case .analyzingQuantitative:
           return "Calculating metrics from your responses..."
           
       case .analyzingAI:
           return "Analyzing patterns and generating insights..."
           
       case .completed(_):
           return "Analysis complete - view your insights below"
           
       case .failed(let error):
           switch error {
           case .noResponses:
               return "No reflections found for today. Complete your daily reflections to see insights."
               
           case .analysisError(_):
               return "We encountered an issue analyzing your reflections. Some insights may be unavailable. Please try again later."
           case .missingRequiredFields(fields: let fields):
               return "We encountered an issue analyzing your reflections. Some insights may be unavailable. Please try again later."
           case .aiAnalysisFailed(_):
               return "We encountered an issue analyzing your reflections. Some insights may be unavailable. Please try again later."
           case .transcriptionFailed(_):
               return "We encountered an issue analyzing your reflections. Some insights may be unavailable. Please try again later."
           }
       }
   }
   
   var isLoading: Bool {
       switch self {
       case .retrievingResponses, .analyzingQuantitative, .analyzingAI:
           return true
       default:
           return false
       }
   }
   
   var shouldShowProgress: Bool {
       switch self {
       case .retrievingResponses, .analyzingQuantitative, .analyzingAI:
           return true
       default:
           return false
       }
   }
   
   var progressMessage: String {
       switch self {
       case .retrievingResponses:
           return "Step 1/3: Gathering responses"
       case .analyzingQuantitative:
           return "Step 2/3: Calculating metrics"
       case .analyzingAI:
           return "Step 3/3: Generating insights"
       default:
           return ""
       }
   }
}
