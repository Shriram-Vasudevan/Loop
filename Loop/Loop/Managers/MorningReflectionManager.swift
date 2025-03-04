//
//  MorningReflectionManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 2/25/25.
//

import Foundation
import SwiftUI

class MorningReflectionManager: ObservableObject {
    static let shared = MorningReflectionManager()
    
    @Published var prompts: [MorningPrompt] = []
    @Published var completedPrompts: Set<Int> = []
    @Published private(set) var hasCompletedForToday: Bool = false
    @Published var isRecording: Bool = false
    @Published var isSavingLoop: Bool = false
    @Published var currentAffirmation: String = ""

    private let promptsKey = "MorningReflectionPrompts"
    private let completedPromptsKey = "CompletedMorningPrompts"
    private let hasCompletedForTodayKey = "HasCompletedMorningForToday"
    private let reflectionDateKey = "MorningReflectionDate"
    private let affirmationsKey = "MorningAffirmations"

    private let morningAffirmations = [
        "I am capable of handling whatever comes my way today.",
        "Today I choose peace over worry and joy over fear.",
        "I embrace this new day with gratitude and optimism.",
        "My potential is limitless, and today I take one step closer to it.",
        "I trust my intuition and make decisions with confidence.",
        "I am exactly where I need to be on my journey.",
        "Every challenge I face is an opportunity to grow stronger.",
        "I deserve happiness and create it in my daily life.",
        "My body is healthy, my mind is brilliant, my soul is tranquil.",
        "I release yesterday's struggles and welcome today's possibilities.",
        "I am in charge of how I feel today, and I choose happiness.",
        "My thoughts are positive and full of light and possibility.",
        "I begin today with strength, purpose, and clear intention.",
        "I am becoming the best version of myself every day.",
        "I am grateful for this fresh start and new beginning.",
        "My energy creates my reality, and today my energy is vibrant.",
        "I attract positive experiences and people into my life.",
        "Today, I choose to focus on progress, not perfection.",
        "I radiate confidence, certainty, and optimism.",
        "I am present in each moment and find joy in the small things.",
        "I honor my needs and take care of myself with compassion.",
        "Every breath I take fills me with energy and purpose.",
        "I trust the process of life and know that good things are unfolding.",
        "I am resilient, adaptable, and capable of handling change.",
        "I celebrate the unique qualities that make me who I am.",
        "My voice matters, and I speak my truth with confidence.",
        "Today is full of endless potential and bright possibilities.",
        "I am worthy of love, kindness, and respect.",
        "I approach challenges with creativity and resourcefulness.",
        "I create a life that feels good on the inside, not just one that looks good on the outside."
    ]
    
    init() {
        setupMorningSession()
        selectRandomAffirmation()
    }
    
    func setupMorningSession() {
        let savedDate = UserDefaults.standard.object(forKey: reflectionDateKey) as? Date
        
        if savedDate != nil && Calendar.current.isDateInToday(savedDate!) {
            loadState()
            return
        }
        

        prompts = [
            MorningPrompt(text: "How did you sleep?", type: .sleepCheckin, description: "Take a moment to reflect on your rest quality"),
            MorningPrompt(text: "What's on your mind?", type: .recording, description: "Share your first thoughts, concerns, or excitement for today"),
            MorningPrompt(text: "Daily Affirmation", type: .affirmation, description: "Say this affirmation aloud with intention"),
            MorningPrompt(text: "What do you plan to do today?", type: .recording, description: "What's on your agenda?"),
//            MorningPrompt(text: "Breathing Exercise", type: .breathing, description: "Take a moment to center yourself with intention")
        ]
        
        completedPrompts = []
        hasCompletedForToday = false
        saveState()
    }
    
    func selectRandomAffirmation() {
        currentAffirmation = morningAffirmations.randomElement() ?? "I am present, focused, and ready for today."
        saveState()
    }
    
    func markPromptComplete(at index: Int) {
        guard index >= 0 && index < prompts.count else { return }
        
        completedPrompts.insert(index)
        if completedPrompts.count == prompts.count {
            hasCompletedForToday = true
            UserDefaults.standard.set(true, forKey: hasCompletedForTodayKey)
        }
        saveState()
    }
    
    func saveState() {
        let promptsData = prompts.map { prompt -> [String: Any] in
            var dict: [String: Any] = [
                "text": prompt.text,
                "type": prompt.type.rawValue
            ]
            
            if let description = prompt.description {
                dict["description"] = description
            }
            return dict
        }
        
        UserDefaults.standard.set(promptsData, forKey: promptsKey)
        UserDefaults.standard.set(Array(completedPrompts), forKey: completedPromptsKey)
        UserDefaults.standard.set(hasCompletedForToday, forKey: hasCompletedForTodayKey)
        UserDefaults.standard.set(Date(), forKey: reflectionDateKey)
        UserDefaults.standard.set(currentAffirmation, forKey: affirmationsKey)
    }
    
    func loadState() {
        if let savedPromptsData = UserDefaults.standard.array(forKey: promptsKey) as? [[String: Any]] {
            let savedPrompts = savedPromptsData.compactMap { MorningPrompt.fromDictionary($0) }
            let savedCompletedPrompts = Set(UserDefaults.standard.array(forKey: completedPromptsKey) as? [Int] ?? [])
            let savedHasCompleted = UserDefaults.standard.bool(forKey: hasCompletedForTodayKey)
            
            if !savedPrompts.isEmpty {
                prompts = savedPrompts
                completedPrompts = savedCompletedPrompts
                hasCompletedForToday = savedHasCompleted
            }
        }
        
        if let savedAffirmation = UserDefaults.standard.string(forKey: affirmationsKey) {
            currentAffirmation = savedAffirmation
        } else {
            selectRandomAffirmation()
        }
    }
    
    func reset() {
        setupMorningSession()
        selectRandomAffirmation()
    }
    
    func isPromptComplete(at index: Int) -> Bool {
        return completedPrompts.contains(index)
    }
    
    func getBreathingInstructions() -> [BreathingStep] {
        return [
            BreathingStep(instruction: "Inhale deeply", duration: 4),
            BreathingStep(instruction: "Hold", duration: 4),
            BreathingStep(instruction: "Exhale slowly", duration: 4),
            BreathingStep(instruction: "Hold", duration: 4)
        ]
    }
}

struct MorningPrompt: Equatable {
    let text: String
    let type: MorningPromptType
    let description: String?
    
    func toDictionary() -> [String: Any] {
        return [
            "text": text,
            "type": type.rawValue,
            "description": description ?? NSNull()
        ]
    }
    
    static func fromDictionary(_ dictionary: [String: Any]) -> MorningPrompt? {
        guard let text = dictionary["text"] as? String,
              let rawType = dictionary["type"] as? String,
              let type = MorningPromptType(rawValue: rawType) else { return nil }
        
        let description = dictionary["description"] as? String
        return MorningPrompt(text: text, type: type, description: description)
    }
}

enum MorningPromptType: String {
    case sleepCheckin
    case recording
    case affirmation
    case breathing
}

struct BreathingStep {
    let instruction: String
    let duration: Int
}
