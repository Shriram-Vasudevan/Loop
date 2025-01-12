//
//  DailyEmotion.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/4/25.
//

import Foundation

struct DailyColorHex: Identifiable {
    let id: String = UUID().uuidString
    var colorHex: String
    let date: Date
}
