//
//  MetricComparison.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/28/24.
//

import Foundation

struct MetricComparison {
    let metric: String
    let trend: String
    let percentageDiff: Double
    let isSignificant: Bool
}

enum ComparisonResult {
   case higher
   case lower
   case equal
   
   static func compare(_ today: Double, with average: Double, threshold: Double = 1.0) -> ComparisonResult {
       let percentDiff = ((today - average) / average) * 100
       if abs(percentDiff) < threshold {
           return .equal
       }
       return today > average ? .higher : .lower
   }
}

extension AITrendsManager {
    struct FrequencyResult: Equatable {
        let value: String
        let count: Int
        let percentage: Double
    }
    
    struct TimeframeFrequencies {
        let topEmotions: [FrequencyResult]
        let topFocuses: [FrequencyResult]
        let topTimeOrientations: [FrequencyResult]
    }
}

extension QuantitativeTrendsManager {
    struct MetricComparison {
        let metric: String
        let trend: String
        let percentageDiff: Double
        let isSignificant: Bool
    }
}
