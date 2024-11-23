//
//  MonthSummary.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/23/24.
//

import Foundation

struct MonthSummary: Identifiable {
    var id: String { "\(year)-\(month)" }
    let year: Int
    let month: Int
    let totalEntries: Int
    let completionRate: Double
    let loops: [Loop]
    
    var monthName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        var components = DateComponents()
        components.year = year
        components.month = month
        if let date = Calendar.current.date(from: components) {
            return dateFormatter.string(from: date)
        }
        return ""
    }
}

struct MonthIdentifier: Hashable {
    let year: Int
    let month: Int
}

