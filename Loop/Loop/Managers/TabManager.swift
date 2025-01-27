//
//  TabManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/25/25.
//

import Foundation

class TabManager: ObservableObject {
    static let shared = TabManager()
    
    @Published var insightsSelectedTab: String = "today"
}
