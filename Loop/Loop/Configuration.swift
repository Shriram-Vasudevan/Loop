//
//  Configuration.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/21/24.
//

import Foundation

enum ConfigurationKey {
    enum Error: Swift.Error {
        case missingKey
    }
    
    static let apiKey: String = {
        #if DEBUG
        return ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "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"
        #else
        return "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"
        #endif
    }()
}
