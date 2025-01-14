//
//  DailyEmotion.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/4/25.
//

import Foundation

struct DailyEmotion: Identifiable {
    let id: String = UUID().uuidString
    let emotion: String
    let date: Date
}
