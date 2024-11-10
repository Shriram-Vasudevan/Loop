//
//  CachedLoop.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/10/24.
//

import Foundation

private struct CachedLoop {
    let id: String
    let timestamp: Date
    let promptText: String
    let mood: String?
    let freeResponse: Bool
    let isVideo: Bool
    let assetURL: URL?
    let cacheDate: Date
}
