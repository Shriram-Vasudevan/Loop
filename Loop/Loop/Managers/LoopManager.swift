//
//  LoopManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/1/24.
//

import Foundation
import CloudKit
import SwiftUI
class LoopManager: ObservableObject {
    static let shared = LoopManager()

    @Published var dailyPrompts: [String] = []
    @Published var currentPromptIndex: Int = 0
    @Published var retryAttemptsLeft: Int = 1
    @Published var pastLoops: [Loop] = []
    @Published var loopsByDate: [Date: [Loop]] = [:]
    @Published var recentDates: [Date] = []
    @Published var hasCompletedToday: Bool = false
    @Published var queuedLoops: [Loop] = []
    @Published var memoryBankStatus: MemoryBankStatus = .checking
    @Published var currentPastLoop: Loop?
    @Published var currentStreak: LoopingStreak?

    @Published var additionalPrompts: [String] = []
    
    
    
    @Published var moodData: [Date: String] = [
        Date(timeIntervalSinceNow: -6 * 24 * 60 * 60): "happy",
        Date(timeIntervalSinceNow: -5 * 24 * 60 * 60): "sad",
        Date(timeIntervalSinceNow: -4 * 24 * 60 * 60): "stressed",
        Date(timeIntervalSinceNow: -3 * 24 * 60 * 60): "energetic",
        Date(timeIntervalSinceNow: -2 * 24 * 60 * 60): "anxious",
        Date(timeIntervalSinceNow: -1 * 24 * 60 * 60): "happy"
    ]
    
    @Published var weekSchedule: [Date: Bool] = [:]
    @Published var isLoadingSchedule = false
    
    @Published var activeMonths: [MonthIdentifier] = []
    @Published var selectedMonthSummary: MonthSummary?
    @Published var yearSummaries: [Int: [MonthSummary]] = [:]
    @Published var isLoadingMonthData = false
    @Published var isLoadingYearData = false
    
    let moodColors: [String: Color] = [
        "happy": Color(hex: "6FCF97"),
        "sad": Color(hex: "56CCF2"),
        "stressed": Color(hex: "F2994A"),
        "energetic": Color(hex: "9B51E0"),
        "anxious": Color(hex: "EB5757")
    ]
    
    private let container = CKContainer(identifier: "iCloud.LoopContainer")
    private let localStorage = LoopLocalStorageUtility.shared
    
    private let queuedLoopsKey = "QueuedLoopsKey"
    private let pastLoopsKey = "PastLoopsKey"
    private let promptCacheKey = "PromptsForTheDay"
    private let promptIndexKey = "CurrentPromptIndex"
    private let retryAttemptsKey = "RetryAttemptsLeft"
    private let lastPromptDateKey = "LastPromptDate"
    private let sevenDayCheckKey = "SevenDayCheckKey"
    private let sevenDayCheckDateKey = "SevenDayCheckDateKey"
    private let stateKey = "CurrentLoopState"
    private var lastFetchedDate: Date?
    
    enum MemoryBankStatus {
        case checking
        case building(daysRemaining: Int)
        case ready
        case noMemoriesForPrompt
    }

        
    @Published private(set) var promptGroups: [PromptCategory: [Prompt]] = [:]
    @Published private(set) var isLoadingPrompts = false
    
    private let promptCacheKeys = PromptCacheKeys.self
    
    private let recentPromptsKey = "RecentPromptsKey"
    private let recentCategoriesKey = "RecentCategoriesKey"
    private let maxPromptHistory = 3
    
    @Published private(set) var thematicPrompts: [ThematicPrompt] = []
    @Published var selectedThematicPromptId: String? = nil {
        didSet {
            if oldValue != selectedThematicPromptId {
                handleThematicPromptSelection()
            }
        }
    }
    
    private let userDefaults = UserDefaults.standard
        
    private var isCloudBackupEnabled: Bool {
        return userDefaults.bool(forKey: "iCloudBackupEnabled")
    }
    
    
    init() {
        Task {
            await loadPrompts()
            await MainActor.run {
                checkAndResetIfNeeded()
            }
            await loadThematicPrompts()
            await checkSevenDayStatus()
            // Add streak calculation on init
            await calculateStreak()
        }
    }
    
    func calculateStreak() async {
        do {
            // Get streaks from both sources
            let cloudStreak = try await LoopCloudKitUtility.calculateStreak()
            let localStreak = try await localStorage.calculateStreak()
            
            // Take the higher values
            let combinedStreak = LoopingStreak(
                currentStreak: max(cloudStreak.currentStreak, localStreak.currentStreak),
                longestStreak: max(cloudStreak.longestStreak, localStreak.longestStreak),
                distinctDays: max(cloudStreak.distinctDays, localStreak.distinctDays)
            )
            
            await MainActor.run {
                self.currentStreak = combinedStreak
            }
        } catch {
            print("Error calculating streak: \(error)")
        }
    }
        
    private func loadPrompts() async {
        await MainActor.run {
            isLoadingPrompts = true
            do { isLoadingPrompts = false }
        }
        
        do {
            if let newPromptSet = try await LoopCloudKitUtility.fetchPromptSetIfNeeded() {
                if let encodedData = try? JSONEncoder().encode(newPromptSet) {
                    UserDefaults.standard.set(encodedData, forKey: promptCacheKeys.promptSetKey)
                }
                
                let newPromptSet = newPromptSet.getPromptGroups()
                await MainActor.run {
                    self.promptGroups = newPromptSet
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
        
        let promptGroups = promptSet.getPromptGroups()
        DispatchQueue.main.sync {
            self.promptGroups = promptGroups
            print(promptGroups)
        }
    }

    
    func getCategoryForPrompt(_ promptText: String) -> PromptCategory? {
        for (category, prompts) in promptGroups {
            if prompts.contains(where: { $0.text == promptText }) {
                return category
            }
        }
        return nil
    }
    
    
    private func getRecentPrompts() -> [String] {
        return UserDefaults.standard.stringArray(forKey: recentPromptsKey) ?? []
    }

    
    private func saveRecentPrompt(_ prompt: String) {
        var recentPrompts = getRecentPrompts()
        recentPrompts.insert(prompt, at: 0)
        if recentPrompts.count > maxPromptHistory {
            recentPrompts = Array(recentPrompts.prefix(maxPromptHistory))
        }
        UserDefaults.standard.set(recentPrompts, forKey: recentPromptsKey)
    }
    
    
    private func selectDailyPrompt() -> Prompt {
        let recentPrompts = getRecentPrompts()
        
        let dailyPrompts = promptGroups.values.flatMap { $0 }.filter { $0.isDailyPrompt }
        
        let availablePrompts = dailyPrompts.filter { prompt in
            !recentPrompts.contains(prompt.text)
        }
        
        if let selectedPrompt = availablePrompts.randomElement() {
            return selectedPrompt
        }

        return dailyPrompts.randomElement() ?? dailyPrompts[0]
    }
    
    private func selectGeneralPrompt(excluding category: PromptCategory) -> Prompt {
        let recentPrompts = getRecentPrompts()

        let availablePrompts = promptGroups.filter { $0.key != category }
            .values
            .flatMap { $0 }
            .filter { !recentPrompts.contains($0.text) }

        if let selectedPrompt = availablePrompts.randomElement() {
            return selectedPrompt
        }
        
        return promptGroups.filter { $0.key != category }
            .values
            .flatMap { $0 }
            .randomElement() ?? promptGroups.values.first!.first!
    }
    
    private func selectRandomPrompts() {
        // Get all available prompts from the JSON structure
        let shareAnything = promptGroups.values
            .flatMap { $0 }
            .filter { $0.category == .freeform }
        
        let dailyPrompts = promptGroups.values
            .flatMap { $0 }
            .filter { $0.isDailyPrompt && $0.category != .freeform }
        
        let generalPrompts = promptGroups.values
            .flatMap { $0 }
            .filter { !$0.isDailyPrompt && $0.category != .freeform }
        
        let firstPrompt: Prompt
        if let randomShare = shareAnything.randomElement() {
            firstPrompt = randomShare
        } else {
            firstPrompt = dailyPrompts.randomElement() ??
                Prompt(text: "What's on your mind?", category: .freeform, isDailyPrompt: true)
        }
        let secondPrompt: Prompt
        let availableDailyPrompts = dailyPrompts.filter { $0.category != firstPrompt.category }
        if let randomDaily = availableDailyPrompts.randomElement() {
            secondPrompt = randomDaily
        } else {
            secondPrompt = dailyPrompts.randomElement() ??
                Prompt(text: "How are you feeling today?", category: .emotionalWellbeing, isDailyPrompt: true)
        }
        
        // Third prompt: Random general prompt (excluding previous categories)
        let thirdPrompt: Prompt
        let availableGeneralPrompts = generalPrompts.filter {
            $0.category != firstPrompt.category && $0.category != secondPrompt.category
        }
        if let randomGeneral = availableGeneralPrompts.randomElement() {
            thirdPrompt = randomGeneral
        } else {
            // Try any general prompt if filtered list is empty
            thirdPrompt = generalPrompts.randomElement() ??
                Prompt(text: "What's giving you hope lately?", category: .growth, isDailyPrompt: false)
        }
        
        // Update the prompts array with our selections
        self.dailyPrompts = [firstPrompt.text, secondPrompt.text, thirdPrompt.text]
        
        // Save our selections to recent prompts
        saveRecentPrompt(firstPrompt.text)
        saveRecentPrompt(secondPrompt.text)
        saveRecentPrompt(thirdPrompt.text)
        
        print("Selected prompts: \(self.dailyPrompts)")
    }
    
    func switchToPrompt(_ newPrompt: Prompt) {
        var updatedPrompts = dailyPrompts
        updatedPrompts[currentPromptIndex] = newPrompt.text
        dailyPrompts = updatedPrompts
        saveRecentPrompt(newPrompt.text)
        saveCachedState()
    }
    
    func getAlternativePrompts() -> [Prompt] {
        guard currentPromptIndex > 0 else { return [] }
        
        let currentPrompt = getCurrentPrompt()
        let currentCategory = getCategoryForPrompt(currentPrompt)
        
        if currentPromptIndex == 1 {
            return Array(promptGroups
                .filter { $0.key != .freeform }
                .values
                .flatMap { $0 }
                .filter { $0.isDailyPrompt && $0.text != currentPrompt }
                .shuffled()
                .prefix(3))
        }
        
        else {
            return Array(promptGroups
                .filter { $0.key != .freeform && $0.key != currentCategory }
                .values
                .flatMap { $0 }
                .filter { !$0.isDailyPrompt && $0.text != currentPrompt }
                .shuffled()
                .prefix(3))
        }
    }
    
    func loadThematicPrompts() async {
        do {
            let prompts = try await LoopCloudKitUtility.fetchThematicPrompts()
            await MainActor.run {
                self.thematicPrompts = prompts
            }
        } catch {
            print("Error loading thematic prompts: \(error)")
        }
    }
    
    private func handleThematicPromptSelection() {
        guard let selectedId = selectedThematicPromptId,
              let selectedTheme = thematicPrompts.first(where: { $0.id == selectedId }),
              selectedTheme.prompts.count >= 3 else {
            // If no theme selected or not enough prompts, revert to normal prompts
            selectRandomPrompts()
            return
        }
        
        // Randomly select 3 unique prompts
        var availablePrompts = selectedTheme.prompts
        var selectedPrompts: [String] = []
        
        for _ in 0..<3 {
            guard let randomPrompt = availablePrompts.randomElement(),
                  let index = availablePrompts.firstIndex(of: randomPrompt) else { break }
            selectedPrompts.append(randomPrompt)
            availablePrompts.remove(at: index)
        }
        
        guard selectedPrompts.count == 3 else {
            print("Couldn't select enough prompts")
            selectRandomPrompts()
            return
        }
        
        self.dailyPrompts = selectedPrompts
        resetPromptProgress()
        saveCachedState()
    }

    func fetchWeekSchedule() {
        isLoadingSchedule = true
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Generate the dates array as a constant
        let dates: [Date] = (-3...3).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: today)
        }
        
        Task {
            do {
                let completionStatus = try await checkDailyCompletion(for: dates)
                await MainActor.run {
                    self.weekSchedule = completionStatus
                    self.isLoadingSchedule = false
                }
            } catch {
                print("Error fetching week schedule: \(error)")
                await MainActor.run {
                    self.isLoadingSchedule = false
                }
            }
        }
    }

    func checkDailyCompletion(for dates: [Date]) async throws -> [Date: Bool] {
       var completionStatus: [Date: Bool] = [:]
       
       // Get completion status from both sources
       let cloudStatus = try await LoopCloudKitUtility.checkDailyCompletion(for: dates)
       let localStatus = try await localStorage.checkDailyCompletion(for: dates)
       
       // Combine results - if either source shows completion, mark as completed
       for date in dates {
           completionStatus[date] = cloudStatus[date] == true || localStatus[date] == true
       }
       
       return completionStatus
   }
    
    private func checkSevenDayStatus() async {
        if let lastCheck = UserDefaults.standard.object(forKey: sevenDayCheckDateKey) as? Date,
           Calendar.current.isDateInToday(lastCheck) {
            let status = UserDefaults.standard.bool(forKey: sevenDayCheckKey)
            await MainActor.run {
                self.memoryBankStatus = status ? .ready : .building(daysRemaining: 7)
            }
            return
        }
        
        do {
            let distinctDays = try await fetchDistinctLoopingDays()
            let daysRemaining = max(0, 7 - distinctDays)
            
            await MainActor.run {
                if distinctDays >= 7 {
                    self.memoryBankStatus = .ready
                    UserDefaults.standard.set(true, forKey: sevenDayCheckKey)
                } else {
                    self.memoryBankStatus = .building(daysRemaining: daysRemaining)
                    UserDefaults.standard.set(false, forKey: sevenDayCheckKey)
                }
                UserDefaults.standard.set(Date(), forKey: sevenDayCheckDateKey)
            }
        } catch {
            print("Error checking seven day status: \(error)")
        }
    }
    
    private func fetchDistinctLoopingDays() async throws -> Int {
        let cloudCount = try await LoopCloudKitUtility.fetchDistinctLoopingDays()
        let localCount = try await localStorage.fetchDistinctLoopingDays()
        
        return max(cloudCount, localCount)
    }
    
    private func determinePreferredStorage() async throws -> StorageSystem {
        let cloudCount = try await LoopCloudKitUtility.fetchDistinctLoopingDays()
        let localCount = try await localStorage.fetchDistinctLoopingDays()
        
        if cloudCount > localCount {
            return .cloud
        } else if localCount > cloudCount {
            return .local
        } else {
            // If equal, randomly choose
            return Bool.random() ? .cloud : .local
        }
    }
    
    func getPastLoopForComparison(recordedPrompts: [String]) async throws -> Loop? {
        print("\n🔄 Starting getPastLoopForComparison")
        print("📝 Recorded prompts: \(recordedPrompts)")
        
        let userDays = try await fetchDistinctLoopingDays()
        print("📅 User has been looping for \(userDays) days")
        
        // Need at least 3 days of history
        guard userDays >= 3 else {
            print("❌ Not enough history (need 3 days, have \(userDays))")
            return nil
        }
        
        // Determine which storage to try first
        let preferredStorage = try await determinePreferredStorage()
        print("🗄️ Using \(preferredStorage) storage first")
        
        // Get Prompt objects for the recorded prompts
        let promptObjects = recordedPrompts.compactMap { promptText in
            promptGroups.values
                .flatMap { $0 }
                .first { $0.text == promptText }
        }
        
        print("\n🔍 Analyzing prompts:")
        for (index, prompt) in promptObjects.enumerated() {
            print("   \(index + 1). \"\(prompt.text)\"")
            print("      Category: \(prompt.category)")
            print("      Type: \(prompt.isDailyPrompt ? "Daily" : "General")")
        }
        
        // Separate into daily and general prompts
        let generalPrompts = promptObjects.filter { !$0.isDailyPrompt }
        let dailyPrompts = promptObjects.filter { $0.isDailyPrompt }
        
        print("\n📊 Found \(generalPrompts.count) general prompts and \(dailyPrompts.count) daily prompts")
        
        // First try to match with general prompts
        if !generalPrompts.isEmpty {
            print("\n🎯 Attempting to match general prompts first")
            let timeWindows = [
                (min: 30, max: 90),  // 1-3 months
                (min: 14, max: 30),  // 2-4 weeks
                (min: 7, max: 14),   // 1-2 weeks
                (min: 1, max: 7)     // 4-7 days
            ]
            
            for window in timeWindows {
                print("\n⏰ Trying time window: \(window.min)-\(window.max) days ago")
                
                // Try category matches first
                for prompt in generalPrompts {
                    print("\n🔎 Searching for category match with prompt: \"\(prompt.text)\"")
                    print("   Category: \(prompt.category)")
                    
                    // Try preferred storage first
                    let firstTryLoop = try await (preferredStorage == .cloud ?
                        LoopCloudKitUtility.fetchPastLoop(
                            forPrompts: recordedPrompts,
                            minDaysAgo: window.min,
                            maxDaysAgo: window.max,
                            preferGeneralPrompts: true,
                            category: prompt.category
                        ) :
                        localStorage.fetchPastLoop(
                            forPrompts: recordedPrompts,
                            minDaysAgo: window.min,
                            maxDaysAgo: window.max,
                            preferGeneralPrompts: true,
                            category: prompt.category
                        ))
                    
                    if let loop = firstTryLoop {
                        print("✅ Found matching loop in preferred storage!")
                        print("   Date: \(loop.timestamp)")
                        print("   Prompt: \"\(loop.promptText)\"")
                        return loop
                    }
                    
                    // If no match, try other storage
                    let secondTryLoop = try await (preferredStorage == .cloud ?
                        localStorage.fetchPastLoop(
                            forPrompts: recordedPrompts,
                            minDaysAgo: window.min,
                            maxDaysAgo: window.max,
                            preferGeneralPrompts: true,
                            category: prompt.category
                        ) :
                        LoopCloudKitUtility.fetchPastLoop(
                            forPrompts: recordedPrompts,
                            minDaysAgo: window.min,
                            maxDaysAgo: window.max,
                            preferGeneralPrompts: true,
                            category: prompt.category
                        ))
                    
                    if let loop = secondTryLoop {
                        print("✅ Found matching loop in secondary storage!")
                        print("   Date: \(loop.timestamp)")
                        print("   Prompt: \"\(loop.promptText)\"")
                        return loop
                    }
                    print("   ⚠️ No category match found in either storage")
                }
                
                print("\n🔄 Trying without category preference for this time window")
                let firstTryLoop = try await (preferredStorage == .cloud ?
                    LoopCloudKitUtility.fetchPastLoop(
                        forPrompts: recordedPrompts,
                        minDaysAgo: window.min,
                        maxDaysAgo: window.max,
                        preferGeneralPrompts: true
                    ) :
                    localStorage.fetchPastLoop(
                        forPrompts: recordedPrompts,
                        minDaysAgo: window.min,
                        maxDaysAgo: window.max,
                        preferGeneralPrompts: true
                    ))
                
                if let loop = firstTryLoop {
                    print("✅ Found matching loop in preferred storage (no category restriction)!")
                    print("   Date: \(loop.timestamp)")
                    print("   Prompt: \"\(loop.promptText)\"")
                    return loop
                }

                let secondTryLoop = try await (preferredStorage == .cloud ?
                    localStorage.fetchPastLoop(
                        forPrompts: recordedPrompts,
                        minDaysAgo: window.min,
                        maxDaysAgo: window.max,
                        preferGeneralPrompts: true
                    ) :
                    LoopCloudKitUtility.fetchPastLoop(
                        forPrompts: recordedPrompts,
                        minDaysAgo: window.min,
                        maxDaysAgo: window.max,
                        preferGeneralPrompts: true
                    ))
                
                if let loop = secondTryLoop {
                    print("✅ Found matching loop in secondary storage (no category restriction)!")
                    print("   Date: \(loop.timestamp)")
                    print("   Prompt: \"\(loop.promptText)\"")
                    return loop
                }
                print("   ⚠️ No matches found in this time window")
            }
            print("\n❌ No matches found for general prompts in any time window")
        }

        if !dailyPrompts.isEmpty {
            print("\n📝 Falling back to daily prompts")
            let dailyTimeWindows = [
                (min: 14, max: 45),
                (min: 3, max: 14)
            ]
            
            for window in dailyTimeWindows {
                print("\n⏰ Trying daily prompt time window: \(window.min)-\(window.max) days ago")
                
                for prompt in dailyPrompts {
                    print("\n🔎 Searching for daily prompt match: \"\(prompt.text)\"")
                    print("   Category: \(prompt.category)")
                    
                    // Try preferred storage first
                    let firstTryLoop = try await (preferredStorage == .cloud ?
                        LoopCloudKitUtility.fetchPastLoop(
                            forPrompts: recordedPrompts,
                            minDaysAgo: window.min,
                            maxDaysAgo: window.max,
                            preferGeneralPrompts: false,
                            category: prompt.category
                        ) :
                        localStorage.fetchPastLoop(
                            forPrompts: recordedPrompts,
                            minDaysAgo: window.min,
                            maxDaysAgo: window.max,
                            preferGeneralPrompts: false,
                            category: prompt.category
                        ))
                    
                    if let loop = firstTryLoop {
                        print("✅ Found matching daily loop in preferred storage!")
                        print("   Date: \(loop.timestamp)")
                        print("   Prompt: \"\(loop.promptText)\"")
                        return loop
                    }
                    
                    // Try other storage
                    let secondTryLoop = try await (preferredStorage == .cloud ?
                        localStorage.fetchPastLoop(
                            forPrompts: recordedPrompts,
                            minDaysAgo: window.min,
                            maxDaysAgo: window.max,
                            preferGeneralPrompts: false,
                            category: prompt.category
                        ) :
                        LoopCloudKitUtility.fetchPastLoop(
                            forPrompts: recordedPrompts,
                            minDaysAgo: window.min,
                            maxDaysAgo: window.max,
                            preferGeneralPrompts: false,
                            category: prompt.category
                        ))
                    
                    if let loop = secondTryLoop {
                        print("✅ Found matching daily loop in secondary storage!")
                        print("   Date: \(loop.timestamp)")
                        print("   Prompt: \"\(loop.promptText)\"")
                        return loop
                    }
                    print("   ⚠️ No match found for this daily prompt")
                }
            }
            print("\n❌ No matches found for daily prompts")
        } else {
            print("\n📝 Skipping daily prompts search (no daily prompts)")
        }
        
        print("\n❌ No matching loops found after trying all strategies")
        return nil
    }
    
    func checkAndResetIfNeeded() {
        if !isCacheValidForToday() {
            selectRandomPrompts()
            resetPromptProgress()
            saveCachedState()
        } else {
            loadCachedState()
        }
        
        print(self.dailyPrompts)
    }
    
    func resetPromptProgress() {
        currentPromptIndex = 0
        retryAttemptsLeft = 1
        hasCompletedToday = false
    }
    
    func moveToNextPrompt() {
        guard currentPromptIndex < dailyPrompts.count - 1 else {
            completeAllPrompts()
            return
        }
        
        currentPromptIndex += 1
        retryAttemptsLeft = 1
        saveCachedState()
    }
    
    private func completeAllPrompts() {
        hasCompletedToday = true
        saveCachedState()
    }
    
    func getCurrentPrompt() -> String {
        return dailyPrompts[currentPromptIndex]
    }
    
    func isLastPrompt() -> Bool {
        return currentPromptIndex == dailyPrompts.count - 1
    }
    
    func retryRecording() {
        if retryAttemptsLeft > 0 {
            retryAttemptsLeft -= 1
            saveCachedState()
        }
    }
    
    func areAllPromptsDone() -> Bool {
        return hasCompletedToday
    }
    
    // MARK: - CloudKit Operations
//    func handleLoopCompletion() {
//        LoopCloudKitUtility.getRandomLoop { [weak self] randomLoop in
//            if let loop = randomLoop {
//                DispatchQueue.main.async {
//                    self?.queuedLoops.append(loop)
//                    self?.saveQueuedLoops()
//                }
//            }
//        }
//    }
//    
//    func fetchRandomPastLoop() {
//        LoopCloudKitUtility.getRandomLoop(completion: { randomLoop in
//            if let loop = randomLoop {
//                DispatchQueue.main.async {
//                    self.pastLoops.append(loop)
//                }
//            }
//        })
//    }
    
    func addLoop(mediaURL: URL, isVideo: Bool, prompt: String, mood: String? = nil, freeResponse: Bool = false, isDailyLoop: Bool) -> Loop {
        let loopID = UUID().uuidString
        let timestamp = Date()
        let ckAsset = CKAsset(fileURL: mediaURL)
        
        let loop = Loop(
            id: loopID,
            data: ckAsset,
            timestamp: timestamp,
            lastRetrieved: timestamp,
            promptText: prompt,
            mood: mood,
            freeResponse: freeResponse,
            isVideo: isVideo,
            isDailyLoop: isDailyLoop
        )
        
        // Check backup setting and store accordingly
        if UserDefaults.standard.bool(forKey: "iCloudBackupEnabled") {
            LoopCloudKitUtility.addLoop(loop: loop)
        } else {
            Task {
                await localStorage.addLoop(loop: loop)
            }
        }
        
        return loop
    }
    
    func fetchRecentDates(limit: Int = 6, completion: @escaping () -> Void) {
        let group = DispatchGroup()
        let dateQueue = DispatchQueue(label: "com.loop.dateCollection")
        var allDates = Set<Date>()
        
        group.enter()
        LoopCloudKitUtility.fetchRecentLoopDates(limit: limit) { result in
            switch result {
            case .success(let cloudDates):
                dateQueue.sync {
                    allDates.formUnion(cloudDates)
                }
            case .failure(let error):
                print("CloudKit fetch error: \(error)")
            }
            group.leave()
        }
        
        group.enter()
        Task {
            do {
                let localDates = try await localStorage.fetchRecentLoopDates(limit: limit)
                dateQueue.sync {
                    allDates.formUnion(localDates)
                }
            } catch {
                print("Local storage fetch error: \(error)")
            }
            group.leave()
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.recentDates = Array(allDates).sorted(by: >)
            self?.fetchLoopsForAllRecentDates(dates: Array(allDates), completion: completion)
        }
    }
    
    func fetchNextPageOfDates(limit: Int = 6, completion: @escaping () -> Void) {
        guard let lastFetchedDate = recentDates.last else {
            completion()
            return
        }
        
        let group = DispatchGroup()
        let dateQueue = DispatchQueue(label: "com.loop.dateCollection")
        var allNewDates = Set<Date>()
        
        // Fetch from CloudKit
        group.enter()
        LoopCloudKitUtility.fetchRecentLoopDates(startingFrom: lastFetchedDate, limit: limit) { [weak self] result in
            switch result {
            case .success(let cloudDates):
                dateQueue.sync {
                    allNewDates.formUnion(cloudDates)
                }
            case .failure(let error):
                print("CloudKit fetch error: \(error.localizedDescription)")
            }
            group.leave()
        }
        
        // Fetch from local storage
        group.enter()
        Task { [weak self] in
            do {
                let localDates = try await localStorage.fetchRecentLoopDates(startingFrom: lastFetchedDate, limit: limit)
                dateQueue.sync {
                    allNewDates.formUnion(localDates)
                }
            } catch {
                print("Local storage fetch error: \(error.localizedDescription)")
            }
            group.leave()
        }
        
        group.notify(queue: .main) { [weak self] in
            let newDates = Array(allNewDates).sorted(by: >)
            self?.recentDates.append(contentsOf: newDates)
            self?.recentDates = Array(Set(self?.recentDates ?? [])).sorted(by: >)
            self?.fetchLoopsForAllRecentDates(dates: newDates, completion: completion)
        }
    }
    
    func fetchLoopsForAllRecentDates(dates: [Date], completion: @escaping () -> Void) {
        let group = DispatchGroup()
        
        for date in dates {
            group.enter()
            
            // Fetch from CloudKit
            LoopCloudKitUtility.fetchLoops(for: date) { [weak self] result in
                switch result {
                case .success(let cloudLoops):
                    DispatchQueue.main.async {
                        self?.loopsByDate[date, default: []].append(contentsOf: cloudLoops)
                    }
                case .failure(let error):
                    print("CloudKit fetch error for \(date): \(error)")
                }
                group.leave()
            }
            
            group.enter()
            // Fetch from local storage
            Task {
                do {
                    let localLoops = try await localStorage.fetchLoops(for: date)
                    await MainActor.run { [weak self] in
                        // Combine results, avoiding duplicates using Loop.id
                        let existingLoops = self?.loopsByDate[date] ?? []
                        let existingIds = Set(existingLoops.map { $0.id })
                        let uniqueLocalLoops = localLoops.filter { !existingIds.contains($0.id) }
                        self?.loopsByDate[date, default: []].append(contentsOf: uniqueLocalLoops)
                    }
                } catch {
                    print("Local storage fetch error for \(date): \(error)")
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion()
        }
    }
    
    
    // MARK: - Queue Management
    func showQueuedLoops(completion: @escaping () -> Void) {
        let loops = queuedLoops
        queuedLoops.removeAll()
        saveQueuedLoops()
        
        for (index, loop) in loops.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.5) { [weak self] in
                self?.pastLoops.append(loop)
                self?.savePastLoops()
                
                if index == loops.count - 1 {
                    completion()
                }
            }
        }
        
        if loops.isEmpty {
            completion()
        }
    }
    
    // MARK: - Cache Management
    private func saveQueuedLoops() {
        let cachedLoops = queuedLoops.map { loop -> [String: Any] in
            return [
                "id": loop.id,
                "timestamp": loop.timestamp.timeIntervalSince1970,
                "promptText": loop.promptText,
                "mood": loop.mood ?? "",
                "freeResponse": loop.freeResponse,
                "isVideo": loop.isVideo,
                "assetURLString": loop.data.fileURL?.absoluteString ?? "",
                "cacheDate": Date().timeIntervalSince1970
            ]
        }
        
        if JSONSerialization.isValidJSONObject(cachedLoops) {
            UserDefaults.standard.set(cachedLoops, forKey: queuedLoopsKey)
        }
    }
    
    private func savePastLoops() {
        let cachedLoops = pastLoops.map { loop -> [String: Any] in
            return [
                "id": loop.id,
                "timestamp": loop.timestamp.timeIntervalSince1970,
                "promptText": loop.promptText,
                "mood": loop.mood ?? "",
                "freeResponse": loop.freeResponse,
                "isVideo": loop.isVideo,
                "assetURLString": loop.data.fileURL?.absoluteString ?? "",
                "cacheDate": Date().timeIntervalSince1970
            ]
        }
        
        if JSONSerialization.isValidJSONObject(cachedLoops) {
            UserDefaults.standard.set(cachedLoops, forKey: pastLoopsKey)
        }
    }
        
    private func loadCachedLoops() {
        if let queuedData = UserDefaults.standard.array(forKey: queuedLoopsKey) as? [[String: Any]] {
            let today = Calendar.current.startOfDay(for: Date())
            
            queuedLoops = queuedData.compactMap { data -> Loop? in
                let cacheDate = Date(timeIntervalSince1970: data["cacheDate"] as? Double ?? 0)
                guard Calendar.current.isDate(cacheDate, inSameDayAs: today),
                      let id = data["id"] as? String,
                      let timestampDouble = data["timestamp"] as? Double,
                      let promptText = data["promptText"] as? String,
                      let freeResponse = data["freeResponse"] as? Bool,
                      let isVideo = data["isVideo"] as? Bool else {
                    return nil
                }
                
                let timestamp = Date(timeIntervalSince1970: timestampDouble)
                let mood = (data["mood"] as? String)?.nilIfEmpty
                let assetURLString = data["assetURLString"] as? String
                
                let asset: CKAsset
                if let urlString = assetURLString,
                   let url = URL(string: urlString) {
                    asset = CKAsset(fileURL: url)
                } else {
                    let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
                    try? Data().write(to: tempURL)
                    asset = CKAsset(fileURL: tempURL)
                }
                
                return Loop(
                    id: id,
                    data: asset,
                    timestamp: timestamp,
                    lastRetrieved: nil,
                    promptText: promptText,
                    mood: mood,
                    freeResponse: freeResponse,
                    isVideo: isVideo, 
                    isDailyLoop: true
                )
            }
        }
        
        if let pastData = UserDefaults.standard.array(forKey: pastLoopsKey) as? [[String: Any]] {
            let today = Calendar.current.startOfDay(for: Date())
            
            pastLoops = pastData.compactMap { data -> Loop? in
                let cacheDate = Date(timeIntervalSince1970: data["cacheDate"] as? Double ?? 0)
                guard Calendar.current.isDate(cacheDate, inSameDayAs: today),
                      let id = data["id"] as? String,
                      let timestampDouble = data["timestamp"] as? Double,
                      let promptText = data["promptText"] as? String,
                      let freeResponse = data["freeResponse"] as? Bool,
                      let isVideo = data["isVideo"] as? Bool else {
                    return nil
                }
                
                let timestamp = Date(timeIntervalSince1970: timestampDouble)
                let mood = (data["mood"] as? String)?.nilIfEmpty
                let assetURLString = data["assetURLString"] as? String
                
                let asset: CKAsset
                if let urlString = assetURLString,
                   let url = URL(string: urlString) {
                    asset = CKAsset(fileURL: url)
                } else {
                    let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
                    try? Data().write(to: tempURL)
                    asset = CKAsset(fileURL: tempURL)
                }
                
                return Loop(
                    id: id,
                    data: asset,
                    timestamp: timestamp,
                    lastRetrieved: nil,
                    promptText: promptText,
                    mood: mood,
                    freeResponse: freeResponse,
                    isVideo: isVideo,
                    isDailyLoop: true
                )
            }
        }
    }
    
    private func saveCachedState() {
       UserDefaults.standard.set(dailyPrompts, forKey: promptCacheKey)
       UserDefaults.standard.set(currentPromptIndex, forKey: promptIndexKey)
       UserDefaults.standard.set(retryAttemptsLeft, forKey: retryAttemptsKey)
       UserDefaults.standard.set(hasCompletedToday, forKey: "hasCompletedToday")
       UserDefaults.standard.set(Date(), forKey: lastPromptDateKey)
   }
   
    private func loadCachedState() {
        DispatchQueue.main.async {
            self.dailyPrompts = UserDefaults.standard.stringArray(forKey: self.promptCacheKey) ?? []
            self.currentPromptIndex = UserDefaults.standard.integer(forKey: self.promptIndexKey)
            self.retryAttemptsLeft = UserDefaults.standard.integer(forKey: self.retryAttemptsKey)
            self.hasCompletedToday = UserDefaults.standard.bool(forKey: "hasCompletedToday")
        }
    }
    
    private func isCacheValidForToday() -> Bool {
        if let lastPromptDate = UserDefaults.standard.object(forKey: lastPromptDateKey) as? Date {
            return Calendar.current.isDateInToday(lastPromptDate)
        }
        return false
    }
    
    func loadActiveMonths() async {
        do {
            let months = try await LoopCloudKitUtility.fetchActiveMonths()
            await MainActor.run {
                self.activeMonths = months
            }
        } catch {
            print("Error loading active months: \(error)")
        }
    }

    
    func loadMonthData(monthId: MonthIdentifier) async {
        await MainActor.run {
            self.isLoadingMonthData = true
            do { self.isLoadingMonthData = false }
        }
        
        do {
            let selectedMonthSummary = try await LoopCloudKitUtility.fetchMonthData(monthId: monthId)
            await MainActor.run {
                self.selectedMonthSummary = selectedMonthSummary
            }
        } catch {
            print("Error loading month data: \(error)")
        }
    }
    
    func loadYearData(year: Int) async {
        await MainActor.run {
            self.isLoadingYearData = true
            do { self.isLoadingYearData = false }
        }
        
        do {
            let activeMonths = try await LoopCloudKitUtility.fetchActiveMonths(year: year)
            var summaries: [MonthSummary] = []
            
            for monthId in activeMonths {
                let summary = try await LoopCloudKitUtility.fetchMonthData(monthId: monthId)
                summaries.append(summary)
            }
            
            yearSummaries[year] = summaries.sorted { $0.month > $1.month }
        } catch {
            print("Error loading year data: \(error)")
        }
    }

}

enum MemoryBankStatus {
        case checking
        case building(daysRemaining: Int)
        case ready
        case noMemoriesForPrompt
}


enum PromptCategory: String, CaseIterable {
    case freeform = "Share Anything"
    case emotionalWellbeing = "Emotional Wellbeing"
    case challenges = "Challenges"
    case growth = "Growth"
    case connections = "Connections"
    case curiosity = "Curiosity"
}


struct Prompt {
    let text: String
    let category: PromptCategory
    let isDailyPrompt: Bool
}

