//
//  SpeakingHighlight.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/30/24.
//

import Foundation

struct SpeakingHighlight {
    let date: Date
    let wpm: Double
    let emotion: String
    let wordCount: Double
    let duration: Double
    
    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    var timeString: String {
        let seconds = Int(duration)
        return "\(seconds)s"
    }
}
