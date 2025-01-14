//
//  DayRating.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/26/24.
//

import Foundation

struct DayRating: Identifiable, Codable {
    var id: String = UUID().uuidString
    let rating: Double
    let date: Date
}
