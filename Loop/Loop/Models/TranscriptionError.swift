//
//  TranscriptionError.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/23/24.
//

import Foundation

enum TranscriptionError: Error {
    case authorizationFailed
    case recognizerUnavailable
    case transcriptionFailed(String)
}
