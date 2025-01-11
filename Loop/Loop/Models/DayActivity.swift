//
//  DayActivity.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/6/25.
//

import Foundation
import CoreData
import CloudKit
import SwiftUI

struct DayActivity {
    let colorHex: String?
    let dailyLoops: [Loop]
    let thematicLoops: [Loop]
    let followUpLoops: [Loop]
    
    static func categorize(_ loops: [Loop], colorHex: String?) -> DayActivity {
        let (daily, thematic, followUp) = loops.reduce(into: ([Loop](), [Loop](), [Loop]())) { result, loop in
            if loop.isDailyLoop {
                result.0.append(loop)
            } else if loop.isFollowUp {
                result.2.append(loop)
            } else {
                result.1.append(loop)
            }
        }
        
        return DayActivity(
            colorHex: colorHex,
            dailyLoops: daily.sorted { $0.timestamp > $1.timestamp },
            thematicLoops: thematic.sorted { $0.timestamp > $1.timestamp },
            followUpLoops: followUp.sorted { $0.timestamp > $1.timestamp }
        )
    }
}
