//
//  DailyEmotion.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/4/25.
//

import Foundation

struct DailyCheckin: Identifiable {
    let id: String = UUID().uuidString
    let rating: Double
    let date: Date
}
