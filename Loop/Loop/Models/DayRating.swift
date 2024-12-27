//
//  DayRating.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/26/24.
//

import Foundation

struct DayRating: Identifiable, Codable {
    var id: String = UUID().uuidString
    public var rating: Double
    public var date: Date
}
