//
//  ThematicLoop.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/22/24.
//

import Foundation

struct ThematicLoop: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let prompts: [String]
}
