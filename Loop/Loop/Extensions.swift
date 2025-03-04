//
//  Extensions.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/3/24.
//

import Foundation
import SwiftUI
import AVFoundation
import Speech
import NaturalLanguage

// Helper extension for hex color support (unchanged)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension Array {
    var array: [Element] {
        return self
    }
}


extension NLTokenizer {
    func tokenizeWords(_ text: String) -> [String] {
        self.string = text
        return self.tokens(for: text.startIndex..<text.endIndex).map { String(text[$0]) }
    }
}

extension String {
    var nilIfEmpty: String? {
        self.isEmpty ? nil : self
    }
}

extension SFSpeechRecognizer {
    static func hasAuthorizationToRecognize() async -> Bool {
        await withCheckedContinuation { continuation in
            requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
}

extension CMSampleBuffer {
    var audioBufferList: AudioBufferList? {
        var audioBufferList = AudioBufferList()
        var blockBuffer: CMBlockBuffer?
        
        guard CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            self,
            bufferListSizeNeededOut: nil,
            bufferListOut: &audioBufferList,
            bufferListSize: MemoryLayout<AudioBufferList>.size,
            blockBufferAllocator: nil,
            blockBufferMemoryAllocator: nil,
            flags: kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
            blockBufferOut: &blockBuffer
        ) == noErr else {
            return nil
        }
        
        return audioBufferList
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Helper Extensions
extension Color {
    static func random(opacity: Double = 1.0) -> Color {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        ).opacity(opacity)
    }
}

extension View {
    func cardStyle() -> some View {
        self.padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color(hex: "2C3E50").opacity(0.04), radius: 20, x: 0, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(hex: "A28497").opacity(0.05), lineWidth: 1)
            )
    }
}


extension Color {
    func adjustedHue(by amount: Double) -> Color {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        UIColor(self).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        return Color(hue: Double(hue) + amount / 360, saturation: Double(saturation), brightness: Double(brightness))
    }
}

extension Sequence {
    func asyncMap<T>(_ transform: (Element) async throws -> T) async throws -> [T] {
        var values = [T]()
        for element in self {
            try await values.append(transform(element))
        }
        return values
    }
}

extension String {
    func extractMood() -> String? {
        let lowercased = self.lowercased()
        let happyIndicators = ["happy", "joy", "excited", "great", "wonderful"]
        let sadIndicators = ["sad", "down", "depressed", "upset", "frustrated"]
        let neutralIndicators = ["okay", "fine", "normal", "neutral"]
        
        if happyIndicators.contains(where: lowercased.contains) {
            return "Positive"
        } else if sadIndicators.contains(where: lowercased.contains) {
            return "Negative"
        } else if neutralIndicators.contains(where: lowercased.contains) {
            return "Neutral"
        }
        return nil
    }
}

extension UserDefaults {
    var hasSetupDailyReflection: Bool {
        get {
            if let lastSetupDate = object(forKey: "LastReflectionSetupDate") as? Date {
                return Calendar.current.isDateInToday(lastSetupDate)
            }
            return false
        }
        set {
            if newValue {
                set(Date(), forKey: "LastReflectionSetupDate")
            } else {
                removeObject(forKey: "LastReflectionSetupDate")
            }
        }
    }
}


extension UserDefaults {
    @objc dynamic var hasCompletedMorningReflection: Bool {
        get { bool(forKey: "HasCompletedMorningForToday") }
        set { set(newValue, forKey: "HasCompletedMorningForToday") }
    }
    
    @objc dynamic var lastMorningReflectionDate: Date? {
        get { object(forKey: "MorningReflectionDate") as? Date }
        set { set(newValue, forKey: "MorningReflectionDate") }
    }
    
    var shouldShowMorningReflection: Bool {
        guard let lastDate = lastMorningReflectionDate else {
            return true
        }
        
        // Check if we've already done a morning reflection today
        return !Calendar.current.isDateInToday(lastDate)
    }
}
