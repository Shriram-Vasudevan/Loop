//
//  DayMetrics .swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/20/25.
//

import Foundation

struct DayMetrics: Codable {
    var date: Date
    var sleepHours: Double?
    var entryCount: Int
    var totalWords: Int
    var totalDuration: Double
    var fillerWordCount: Int
    var primaryTopic: String?
}
