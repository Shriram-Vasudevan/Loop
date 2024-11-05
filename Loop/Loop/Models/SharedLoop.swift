//
//  SharedLoop.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/4/24.
//

import Foundation

struct SharedLoop: Codable {
    var id: String
    var senderID: String
    var recipientID: String
    var prompt: String
    var availableAt: Date
    var timestamp: Date
    var isVideo: Bool
    var anonymous: Bool
}
