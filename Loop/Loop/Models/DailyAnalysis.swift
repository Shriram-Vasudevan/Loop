//
//  DailyAnalysis.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/20/24.
//

import Foundation


struct DailyAnalysis: Codable {
    var date: Date
    var prompts: [String]
    var completedLoopCount: Int
    var keywords: [String]
    var names: [String]
    var averageSpeakingPace: Double  // WPM
    var totalDuration: TimeInterval
    var totalWordCount: Int
    var pastTensePercentage: Double
    var futureTensePercentage: Double
    var selfReferencePercentage: Double
    var isComplete: Bool
    
    init(date: Date) {
        self.date = date
        self.prompts = []
        self.completedLoopCount = 0
        self.keywords = []
        self.names = []
        self.averageSpeakingPace = 0
        self.totalDuration = 0
        self.totalWordCount = 0
        self.pastTensePercentage = 0
        self.futureTensePercentage = 0
        self.selfReferencePercentage = 0
        self.isComplete = false
    }
}
