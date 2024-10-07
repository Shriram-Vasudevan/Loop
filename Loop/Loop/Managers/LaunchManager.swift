//
//  LaunchManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/7/24.
//

import Foundation

class LaunchManager {
    static let shared = LaunchManager()
    
    func isFirstLaunchOfDay() -> Bool {
        let currentDate = Date()
        let calendar = Calendar.current

        let lastLaunchDate = UserDefaults.standard.object(forKey: "lastLaunchDate") as? Date

        if let lastDate = lastLaunchDate {
            if calendar.isDate(lastDate, inSameDayAs: currentDate) {
                return false
            }
        }

        UserDefaults.standard.set(currentDate, forKey: "lastLaunchDate")
        return true
    }

}
