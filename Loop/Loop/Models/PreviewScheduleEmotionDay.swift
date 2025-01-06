//
//  PreviewScheduleEmotionDay.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/4/25.
//

import SwiftUI

struct EmotionDay: Identifiable {
    let id = UUID()
    let date: Date
    let emotion: String?
    let abbreviation: String
}
