//
//  FrequencyModels.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/28/24.
//

import Foundation


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
