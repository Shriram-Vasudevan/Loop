//
//  ReflectionSessionManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/17/25.
//

import Foundation
import Foundation

class ReflectionSessionManager: ObservableObject {
    static let shared = ReflectionSessionManager()
    
    @Published var prompts: [ReflectionPrompt] = []
    @Published var completedPrompts: Set<Int> = []
    @Published private(set) var hasCompletedForToday: Bool = false
    
    private let promptsKey = "DailyReflectionPrompts"
    private let completedPromptsKey = "CompletedReflectionPrompts"
    private let hasCompletedForTodayKey = "HasCompletedForToday"
    private let reflectionDateKey = "ReflectionDate"
    
    @Published var selectedCategory: PromptCategory?
    @Published var aiPromptAttempted: Bool = false
    @Published var generatedAIPrompt: String?
    @Published private(set) var promptGroups: [PromptCategory: [Prompt]] = [:]
    @Published private var isLoadingPrompts = false
    
    private let promptCacheKeys = PromptCacheKeys.self
    
    private let transcriptCacheKey = "TodaysTranscripts"
    
    @Published var isLoadingAIPrompt: Bool = false
    
    let availableCategories: [PromptCategory] = [
        .emotionalWellbeing,
        .challenges,
        .growth,
        .connections,
        .curiosity,
        .extraPrompts
    ]
    
    struct CachedResponse: Codable {
        let prompt: String
        let transcript: String
        let date: Date
    }
    
    @Published var isSavingLoop: Bool = false
    @Published var isSavingTranscript: Bool = false

    

//    NotificationCenter.default.addObserver(
//       self,
//       selector: #selector(appDidBecomeActive),
//       name: UIApplication.didBecomeActiveNotification,
//       object: nil
//   )
//}
//
//@objc private func appDidBecomeActive() {
//    checkAndResetIfNeeded()
//}
//    
//deinit {
//    NotificationCenter.default.removeObserver(self)
//}

    init() {
        Task {
            loadState()
            await loadPrompts()
        }
    }
    
    func setupSession(withCards cards: [ReflectionCardManager.ReflectionCardType]) {
        let selectedPrompts = cards.map { card in
            switch card {
            case .sleepCheckin:
                return ReflectionPrompt(text: "How many hours did you sleep?", type: .sleepCheckin, description: nil)
            case .moodCheckin:
                return ReflectionPrompt(text: "How are you feeling right now?", type: .moodCheckIn, description: nil)
            case .daySummary:
                return ReflectionPrompt(
                    text: "Give a short summary of your day.",
                    type: .recording,
                    description: "Think about how you spent your time, what you did, and how it all felt. No need to overthink—just share the highlights or an overview."
                )
            case .standOut:
                return ReflectionPrompt(
                    text: "What do you want to share about today?",
                    type: .recording,
                    description: "Share whatever you're thinking about today - perhaps a memorable event, realization, success, or even a challenge. Focus in on something that matters to you."
                )
            case .success:
                return ReflectionPrompt(
                    text: "What success or win would you like to celebrate today?",
                    type: .recording,
                    description: "Share a moment of achievement or progress—whether it's completing a task, maintaining a habit, or making someone smile. Every win counts, no matter how small. We'll bring these back for you whenever you need them."
                )
            case .aiGenerated:
                return ReflectionPrompt(
                    text: "What question would you like to reflect on?",
                    type: .guided,
                    description: nil
                )
            case .freeform:
                return ReflectionPrompt(
                    text: "Share anything on your mind.",
                    type: .recording,
                    description: "Feel free to open up about anything that's on your mind today—no structure, just your thoughts."
                )
            }
        }
        
        prompts = selectedPrompts
        completedPrompts = []
        hasCompletedForToday = false
        saveState()
    }

    func markPromptComplete(at index: Int) {
        guard index >= 0 && index < prompts.count else { return }
        completedPrompts.insert(index)
        if completedPrompts.count == prompts.count {
            Task {
                await AnalysisManager.shared.performAnalysis()
            }
            hasCompletedForToday = true
            UserDefaults.standard.set(true, forKey: hasCompletedForTodayKey)
        }
        saveState()
    }
    
    func completeSession() {
        guard completedPrompts.count == prompts.count else { return }
        hasCompletedForToday = true
        Task {
            await AnalysisManager.shared.performAnalysis()
        }
        saveState()
    }
    
    func needCategorySelection() -> Bool {
        let guidedPrompt = self.prompts.first(where: { $0.type == .guided })
        return guidedPrompt?.text == "What question would you like to reflect on?"
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
    }
    
    func loadState() {
        let savedDate = UserDefaults.standard.object(forKey: reflectionDateKey) as? Date
        
        if savedDate == nil || !Calendar.current.isDateInToday(savedDate!) {
            setupSession(withCards: Array(ReflectionCardManager.shared.currentTemplate.selectedCards))
            return
        }

        if let savedPromptsData = UserDefaults.standard.array(forKey: promptsKey) as? [[String: Any]] {
            let savedPrompts = savedPromptsData.compactMap { ReflectionPrompt.fromDictionary($0) }
            let savedCompletedPrompts = Set(UserDefaults.standard.array(forKey: completedPromptsKey) as? [Int] ?? [])
            let savedHasCompleted = UserDefaults.standard.bool(forKey: hasCompletedForTodayKey)

            if !savedPrompts.isEmpty {
                prompts = savedPrompts
                completedPrompts = savedCompletedPrompts
                hasCompletedForToday = savedHasCompleted
                return
            }
        }

        setupSession(withCards: Array(ReflectionCardManager.shared.currentTemplate.selectedCards))
    }
    
    func saveRecordingCache(prompt: String, transcript: String) {
        isSavingTranscript = true  // Start tracking

        cacheResponse(prompt: prompt, transcript: transcript)

        DispatchQueue.main.async {
            print("[Cache] ✅ Transcript saved: \"\(transcript.prefix(50))...\"")
            self.isSavingTranscript = false  // Mark transcript saving complete
        }
    }

    
    func cacheResponse(prompt: String, transcript: String) {
        let response = CachedResponse(
            prompt: prompt,
            transcript: transcript,
            date: Date()
        )
        
        var cachedResponses = getTodaysCachedResponses()
        cachedResponses.append(response)
        
        if let encoded = try? JSONEncoder().encode(cachedResponses) {
            UserDefaults.standard.set(encoded, forKey: transcriptCacheKey)
        }
    }
    
    func getTodaysCachedResponses() -> [CachedResponse] {
        guard let data = UserDefaults.standard.data(forKey: transcriptCacheKey),
              let responses = try? JSONDecoder().decode([CachedResponse].self, from: data) else {
            return []
        }
        
        return responses.filter { Calendar.current.isDateInToday($0.date) }
    }
    
    func clearOldCachedResponses() {
            let responses = getTodaysCachedResponses()
            if let encoded = try? JSONEncoder().encode(responses) {
                UserDefaults.standard.set(encoded, forKey: transcriptCacheKey)
            }
        }
    
    private func loadPrompts() async {
        await MainActor.run {
            isLoadingPrompts = true
        }
        
        do {
            if let newPromptSet = try await LoopCloudKitUtility.fetchPromptSetIfNeeded() {
                if let encodedData = try? JSONEncoder().encode(newPromptSet) {
                    UserDefaults.standard.set(encodedData, forKey: promptCacheKeys.promptSetKey)
                }
                
                let newPromptGroups = newPromptSet.getPromptGroups()
                await MainActor.run {
                    self.promptGroups = newPromptGroups
                    self.isLoadingPrompts = false
                }
            } else {
                loadCachedPrompts()
            }
        } catch {
            print("Error loading prompts: \(error)")
            loadCachedPrompts()
        }
    }
    
    private func loadCachedPrompts() {
        guard let cachedData = UserDefaults.standard.data(forKey: promptCacheKeys.promptSetKey),
              let promptSet = try? JSONDecoder().decode(PromptSet.self, from: cachedData) else {
            print("⚠️ No cached prompts found, using fallback")
   
            if let url = Bundle.main.url(forResource: "fallback_prompts", withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let promptSet = try? JSONDecoder().decode(PromptSet.self, from: data) {
                promptGroups = promptSet.getPromptGroups()
            }
            return
        }
        
        promptGroups = promptSet.getPromptGroups()
    }
    
    func getRandomPrompt(for category: PromptCategory) -> Prompt? {
        return promptGroups[category]?.randomElement()
    }
   
    func updateGuidedPrompt(_ newPrompt: ReflectionPrompt) {
        if let index = prompts.firstIndex(where: { $0.type == .guided }) {
            prompts[index] = newPrompt
            saveState()
        }
    }
    
   func generateAIPrompt() async -> String? {
       aiPromptAttempted = true
       return await AIPromptManager.shared.generatePrompt()
   }
   
    func resetGuidedPrompt() {
        if let index = prompts.firstIndex(where: { $0.type == .guided }) {
            prompts[index] = ReflectionPrompt(
                text: "What question would you like to reflect on?",
                type: .guided,
                description: nil
            )
            selectedCategory = nil
            saveState()
        }
    }
    
   func resetCategorySelection() {
       selectedCategory = nil
       if !aiPromptAttempted {
           generatedAIPrompt = nil
       }
   }
    
    
    func isPromptComplete(at index: Int) -> Bool {
        return completedPrompts.contains(index)
    }

    func canModifyPrompt(at index: Int) -> Bool {
        let prompt = prompts[index]
        return prompt.type == .moodCheckIn || !completedPrompts.contains(index)
    }
}

struct ReflectionPrompt: Equatable {
    let text: String
    let type: PromptType
    let description: String? 

    func toDictionary() -> [String: Any] {
        return [
            "text": text,
            "type": type.rawValue,
            "description": description ?? NSNull()
        ]
    }

    static func fromDictionary(_ dictionary: [String: Any]) -> ReflectionPrompt? {
        guard let text = dictionary["text"] as? String,
              let rawType = dictionary["type"] as? String,
              let type = PromptType(rawValue: rawType) else { return nil }
        
        let description = dictionary["description"] as? String
        return ReflectionPrompt(text: text, type: type, description: description)
    }
}

enum PromptType: String {
    case sleepCheckin
    case moodCheckIn
    case guided
    case recording
}

enum PromptCategory: String, CaseIterable, Codable {
    case freeform = "Share Anything"
    case emotionalWellbeing = "Emotional Wellbeing"
    case challenges = "Challenges"
    case growth = "Growth"
    case connections = "Connections"
    case curiosity = "Curiosity"
    case extraPrompts = "Extra Prompts"
}
