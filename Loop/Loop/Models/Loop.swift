//
//  Loop.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/1/24.
//

import Foundation
import CloudKit

struct Loop: Hashable, Identifiable {
    var id: String
    var data: CKAsset
    var timestamp: Date
    var lastRetrieved: Date?
    var promptText: String
    var mood: String?
    var freeResponse: Bool
    var isVideo: Bool  
}

