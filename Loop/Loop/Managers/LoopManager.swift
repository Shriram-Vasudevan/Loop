//
//  LoopManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/1/24.
//

import Foundation
import CloudKit

class LoopManager: ObservableObject {
    static let shared = LoopManager()
    
    @Published var loopRevealDate: Date?
    @Published var retrieveUserLoops: Bool = false
    
    @Published var prompts: [String] = []
    @Published var currentPromptIndex: Int = 0
    
    private let availablePrompts = [
        "What’s something you’re grateful for today?",
        "Describe a challenge you faced recently.",
        "What’s a goal you’re working towards?",
        "How are you feeling emotionally?",
        "What’s something you’re looking forward to?",
        "Reflect on a recent accomplishment.",
        "Describe your current mood in one word.",
        "What did you learn today?",
        "What’s one thing that made you smile today?",
        "What’s a personal strength you’ve relied on lately?",
        "How can you improve tomorrow?",
        "What’s been on your mind lately?",
        "What’s something you’re proud of?",
        "How did you overcome a recent obstacle?",
        "What motivates you?",
        "Who’s someone that inspires you?",
        "What’s something you need to let go of?",
        "What’s a recent positive experience?",
        "How do you handle stress?",
        "What’s one thing you want to focus on tomorrow?",
        "What’s something that challenged you today?",
        "Describe your ideal day.",
        "What’s something you appreciate about yourself?",
        "What’s a habit you want to develop?",
        "What makes you feel energized?"
    ]
        
    init() {
        selectRandomPrompts()
    }

    func selectRandomPrompts() {
        var selectedPrompts = availablePrompts.shuffled().prefix(3)
        prompts = ["Free Response"] + selectedPrompts
    }
        
    func resetPromptProgress() {
        currentPromptIndex = 0
    }

    func nextPrompt() {
        if currentPromptIndex < prompts.count - 1 {
            currentPromptIndex += 1
        }
    }

    func areAllPromptsDone() -> Bool {
        return currentPromptIndex >= prompts.count
    }
    
    func getCurrentPrompt() -> String {
        if areAllPromptsDone() {
            return "Nothing to record for now."
        }
        return prompts[currentPromptIndex]
    }
    
    func getLoopRevealDate() {
        if loopRevealDate == nil {
            print("Fetching loop reveal date...")
            LoopCloudKitUtility.getLoopRevealDate { loopRevealDate in
                if let date = loopRevealDate?.date {
                    print("Received loop reveal date from CloudKit: \(date)")
                    
                    let localRevealDate = Calendar.current.date(byAdding: .second, value: TimeZone.current.secondsFromGMT(), to: date)
                    
                    DispatchQueue.main.sync {
                        self.loopRevealDate = localRevealDate
                        print("Set local reveal date: \(String(describing: self.loopRevealDate))")
                    }
                } else {
                    print("Failed to retrieve loop reveal date.")
                }
            }
        }
    }

    
    func getTodaysLoops() {
        
    }
    
    func addLoop(audioURL: URL, prompt: String) {
        let ckAsset = CKAsset(fileURL: audioURL)
        
        
    }
}
