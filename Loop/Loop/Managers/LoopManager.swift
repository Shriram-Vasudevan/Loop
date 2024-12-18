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
    @Published var pastLoop: Loop?
    @Published var loopsByDate: [Date: [Loop]] = [:]
    @Published var recentDates: [Date] = []
    @Published var hasCompletedToday: Bool = false
    @Published var queuedLoops: [Loop] = []
    @Published var memoryBankStatus: MemoryBankStatus = .checking
    @Published var currentPastLoop: Loop?
    @Published var currentStreak: LoopingStreak?

    @Published var additionalPrompts: [String] = []
    
    
    @Published var weekSchedule: [Date: Bool] = [:]
    @Published var isLoadingSchedule = false
    
    @Published var activeMonths: [MonthIdentifier] = []
    @Published var selectedMonthSummary: MonthSummary?
    @Published var yearSummaries: [Int: [MonthSummary]] = [:]
    @Published var isLoadingMonthData = false
    @Published var isLoadingYearData = false
    
    @Published var distinctDays: Int = 0
    @Published var isCheckingDistinctDays: Bool = false
    
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
    
    func calculateDistinctLoopingDays() async {
        do {
            isCheckingDistinctDays = true
            let cloudCheck = try await LoopCloudKitUtility.checkThreeDayRequirement()
            let localCheckCount = try await localStorage.fetchDistinctLoopingDays() // Correct local call
            
            let distinctDays = cloudCheck.1 + localCheckCount
            self.distinctDays = distinctDays
            isCheckingDistinctDays = false
        } catch {
            isCheckingDistinctDays = false
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
        
        let thirdPrompt: Prompt
        if let randomShare = shareAnything.randomElement() {
            thirdPrompt = randomShare
        } else {
            thirdPrompt = dailyPrompts.randomElement() ??
                Prompt(text: "What's on your mind?", category: .freeform, isDailyPrompt: true)
        }
        
        let firstPrompt: Prompt
        let availableDailyPrompts = dailyPrompts.filter { $0.category != thirdPrompt.category }
        if let randomDaily = availableDailyPrompts.randomElement() {
            firstPrompt = randomDaily
        } else {
            firstPrompt = dailyPrompts.randomElement() ??
                Prompt(text: "How are you feeling today?", category: .emotionalWellbeing, isDailyPrompt: true)
        }

        let secondPrompt: Prompt
        let availableGeneralPrompts = generalPrompts.filter {
            $0.category != firstPrompt.category && $0.category != thirdPrompt.category
        }
        if let randomGeneral = availableGeneralPrompts.randomElement() {
            secondPrompt = randomGeneral
        } else {
            // Try any general prompt if filtered list is empty
            secondPrompt = generalPrompts.randomElement() ??
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
        print("\n🔍 Starting getPastLoopForComparison")
        print("📝 Input prompts:", recordedPrompts)
        
        // Check minimum history requirement first
        let userDays = try await fetchDistinctLoopingDays()
        print("📅 User has \(userDays) days of history")
        
        guard userDays >= 3 else {
            print("❌ Not enough history (need 3 days, have \(userDays))")
            return nil
        }
        
        // Get prompt objects to determine categories
        let promptObjects = recordedPrompts.compactMap { promptText in
            promptGroups.values
                .flatMap { $0 }
                .first { $0.text == promptText }
        }
        
        print("🎯 Found \(promptObjects.count) matching prompt objects")
        
        // Determine storage preference
        let preferredStorage = try await determinePreferredStorage()
        print("💾 Using \(preferredStorage) storage first")
        
        // Try each prompt
        for prompt in promptObjects {
            print("\n📋 Trying prompt: \(prompt.text)")
            print("📂 Category: \(prompt.category.rawValue)")
            print("🔄 Daily prompt: \(prompt.isDailyPrompt)")
            
            // Try preferred storage
            if let loop = try await fetchFromStorage(
                storage: preferredStorage,
                prompts: recordedPrompts,
                category: prompt.category,
                isDailyPrompt: prompt.isDailyPrompt
            ) {
                print("✅ Found matching loop in \(preferredStorage) storage")
                
                // Update lastRetrieved based on storage type
                if preferredStorage == .cloud {
                    try? await LoopCloudKitUtility.updateLastRetrieved(for: loop)
                } else {
                    try? localStorage.updateLastRetrieved(for: loop)
                }
                
                self.pastLoop = loop
                print("returning loop")
                return loop
            }
            
            print("⚠️ No match in \(preferredStorage) storage, trying alternate")
            
            // Try alternate storage
            let alternateStorage: StorageSystem = preferredStorage == .cloud ? .local : .cloud
            if let loop = try await fetchFromStorage(
                storage: alternateStorage,
                prompts: recordedPrompts,
                category: prompt.category,
                isDailyPrompt: prompt.isDailyPrompt
            ) {
                print("✅ Found matching loop in \(alternateStorage) storage")
                
                // Update lastRetrieved based on storage type
                if alternateStorage == .cloud {
                    try await LoopCloudKitUtility.updateLastRetrieved(for: loop)
                } else {
                    try await localStorage.updateLastRetrieved(for: loop)
                }
                
                self.pastLoop = loop
                return loop
            }
        }
        
        print("\n⚡️ No matches found with category filters, trying one last time without filters")
        
        // Final attempt without category filters
        let finalLoop: Loop?
        
        if let firstTry = try await fetchFromStorage(
            storage: preferredStorage,
            prompts: recordedPrompts,
            category: nil,
            isDailyPrompt: nil
        ) {
            print("✅ Found unfiltered match in \(preferredStorage) storage")
            finalLoop = firstTry
        } else {
            let alternateStorage: StorageSystem = preferredStorage == .cloud ? .local : .cloud
            let altLoop = try await fetchFromStorage(
                storage: alternateStorage,
                prompts: recordedPrompts,
                category: nil,
                isDailyPrompt: nil
            )
            if altLoop != nil {
                print("✅ Found unfiltered match in \(alternateStorage) storage")
            }
            finalLoop = altLoop
        }
        
        if let finalLoop = finalLoop {
            // Update lastRetrieved
            if preferredStorage == .cloud {
                try await LoopCloudKitUtility.updateLastRetrieved(for: finalLoop)
            } else {
                try await localStorage.updateLastRetrieved(for: finalLoop)
            }
        } else {
            print("❌ No matching loops found in any storage")
        }
        
        self.pastLoop = finalLoop
        return finalLoop
    }

    private func fetchFromStorage(
        storage: StorageSystem,
        prompts: [String],
        category: PromptCategory?,
        isDailyPrompt: Bool?
    ) async throws -> Loop? {
        print("\n🔎 Fetching from \(storage) storage")
        print("⏰ Time windows: \(isDailyPrompt == true ? "Daily prompt windows" : "General prompt windows")")
        
        // Define time windows based on prompt type
        let timeWindows: [(min: Int, max: Int)] = isDailyPrompt == true ?
            [(14, 45), (3, 14)] :  // Daily prompts
            [(30, 90), (14, 30), (7, 14), (1, 7)]  // General prompts
        
        // Try each time window
        for window in timeWindows {
            print("📅 Trying window: \(window.min)-\(window.max) days ago")
            
            let loop = try await (storage == .cloud ?
                // Use CloudKit utility
                LoopCloudKitUtility.fetchPastLoop(
                    forPrompts: prompts,
                    minDaysAgo: window.min,
                    maxDaysAgo: window.max,
                    preferGeneralPrompts: isDailyPrompt == false,
                    category: category
                ) :
                // Use local storage utility
                localStorage.fetchPastLoop(
                    forPrompts: prompts,
                    minDaysAgo: window.min,
                    maxDaysAgo: window.max,
                    preferGeneralPrompts: isDailyPrompt == false,
                    category: category
                ))
            
            if let loop = loop {
                print("✅ Found matching loop from \(window.min)-\(window.max) days ago")
                return loop
            }
        }
        
        print("❌ No matches found in any time window")
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
        print("all prompts completed")
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
    
    func addLoop(mediaURL: URL, isVideo: Bool, prompt: String, mood: String? = nil, freeResponse: Bool = false, isDailyLoop: Bool, isFollowUp: Bool) -> Loop {
        let loopID = UUID().uuidString
        let timestamp = Date()
        let ckAsset = CKAsset(fileURL: mediaURL)

        let category = getCategoryForPrompt(prompt)?.rawValue ?? "Share Anything"

        let loop = Loop(
            id: loopID,
            data: ckAsset,
            timestamp: timestamp,
            lastRetrieved: timestamp,
            promptText: prompt,
            category: category,
            mood: mood,
            freeResponse: freeResponse,
            isVideo: isVideo,
            isDailyLoop: isDailyLoop,
            isFollowUp: isFollowUp
        )

        // Add the loop to loopsByDate (check for duplicates)
        let loopDate = Calendar.current.startOfDay(for: timestamp) // Normalize to day
        if var existingLoops = loopsByDate[loopDate] {
            if !existingLoops.contains(where: { $0.id == loop.id }) {
                existingLoops.append(loop)
                loopsByDate[loopDate] = existingLoops.sorted { $0.timestamp > $1.timestamp }
            }
        } else {
            loopsByDate[loopDate] = [loop]
        }

        // Ensure the date is in recentDates
        if !recentDates.contains(loopDate) {
            recentDates.append(loopDate)
            recentDates.sort(by: >) // Ensure sorted
        }

        // Save based on iCloud backup setting
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
            
            // Fetch loops from CloudKit
            LoopCloudKitUtility.fetchLoops(for: date) { [weak self] result in
                switch result {
                case .success(let cloudLoops):
                    DispatchQueue.main.async {
                        self?.addUniqueLoops(cloudLoops, to: date)
                    }
                case .failure(let error):
                    print("CloudKit fetch error for \(date): \(error)")
                }
                group.leave()
            }
            
            group.enter()
            // Fetch loops from local storage
            Task {
                do {
                    let localLoops = try await localStorage.fetchLoops(for: date)
                    await MainActor.run { [weak self] in
                        self?.addUniqueLoops(localLoops, to: date)
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

    private func addUniqueLoops(_ newLoops: [Loop], to date: Date) {
        var existingLoops = loopsByDate[date] ?? []
        let existingIds = Set(existingLoops.map { $0.id })
        
        let uniqueLoops = newLoops.filter { !existingIds.contains($0.id) }
        existingLoops.append(contentsOf: uniqueLoops)
        loopsByDate[date] = existingLoops.sorted { $0.timestamp > $1.timestamp }
    }

    
    
//    // MARK: - Queue Management
//    func showQueuedLoops(completion: @escaping () -> Void) {
//        let loops = queuedLoops
//        queuedLoops.removeAll()
//        saveQueuedLoops()
//        
//        for (index, loop) in loops.enumerated() {
//            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.5) { [weak self] in
//                self?.pastLoops.append(loop)
//                self?.savePastLoops()
//                
//                if index == loops.count - 1 {
//                    completion()
//                }
//                }
//            }
//        }
//        
//        if loops.isEmpty {
//            completion()
//        }
//    }
//    
    // MARK: - Cache Management
    private func saveQueuedLoops() {
        let cachedLoops = queuedLoops.map { loop -> [String: Any] in
            return [
                "id": loop.id,
                "timestamp": loop.timestamp.timeIntervalSince1970,
                "promptText": loop.promptText,
                "category": getCategoryForPrompt(loop.promptText)?.rawValue ?? "Share Anything",
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
    
//    private func savePastLoops() {
//        
//        let cachedLoops = pastLoops.map { loop -> [String: Any] in
//            return [
//                "id": loop.id,
//                "timestamp": loop.timestamp.timeIntervalSince1970,
//                "promptText": loop.promptText,
//                "category": getCategoryForPrompt(loop.promptText)?.rawValue ?? "Share Anything",
//                "mood": loop.mood ?? "",
//                "freeResponse": loop.freeResponse,
//                "isVideo": loop.isVideo,
//                "assetURLString": loop.data.fileURL?.absoluteString ?? "",
//                "cacheDate": Date().timeIntervalSince1970
//            ]
//        }
//        
//        if JSONSerialization.isValidJSONObject(cachedLoops) {
//            UserDefaults.standard.set(cachedLoops, forKey: pastLoopsKey)
//        }
//    }
        
//    private func loadCachedLoops() {
//        if let queuedData = UserDefaults.standard.array(forKey: queuedLoopsKey) as? [[String: Any]] {
//            let today = Calendar.current.startOfDay(for: Date())
//            
//            queuedLoops = queuedData.compactMap { data -> Loop? in
//                let cacheDate = Date(timeIntervalSince1970: data["cacheDate"] as? Double ?? 0)
//                guard Calendar.current.isDate(cacheDate, inSameDayAs: today),
//                      let id = data["id"] as? String,
//                      let timestampDouble = data["timestamp"] as? Double,
//                      let promptText = data["promptText"] as? String,
//                      let category = data["category"] as? String,
//                      let freeResponse = data["freeResponse"] as? Bool,
//                      let isVideo = data["isVideo"] as? Bool else {
//                    return nil
//                }
//                
//                let timestamp = Date(timeIntervalSince1970: timestampDouble)
//                let mood = (data["mood"] as? String)?.nilIfEmpty
//                let assetURLString = data["assetURLString"] as? String
//                
//                let asset: CKAsset
//                if let urlString = assetURLString,
//                   let url = URL(string: urlString) {
//                    asset = CKAsset(fileURL: url)
//                } else {
//                    let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
//                    try? Data().write(to: tempURL)
//                    asset = CKAsset(fileURL: tempURL)
//                }
//                
//                return Loop(
//                    id: id,
//                    data: asset,
//                    timestamp: timestamp,
//                    lastRetrieved: nil,
//                    promptText: promptText, category: category,
//                    mood: mood,
//                    freeResponse: freeResponse,
//                    isVideo: isVideo, 
//                    isDailyLoop: true
//                )
//            }
//        }
//        
//        if let pastData = UserDefaults.standard.array(forKey: pastLoopsKey) as? [[String: Any]] {
//            let today = Calendar.current.startOfDay(for: Date())
//            
//            pastLoops = pastData.compactMap { data -> Loop? in
//                let cacheDate = Date(timeIntervalSince1970: data["cacheDate"] as? Double ?? 0)
//                guard Calendar.current.isDate(cacheDate, inSameDayAs: today),
//                      let id = data["id"] as? String,
//                      let timestampDouble = data["timestamp"] as? Double,
//                      let promptText = data["promptText"] as? String,
//                      let category = data["category"] as? String,
//                      let freeResponse = data["freeResponse"] as? Bool,
//                      let isVideo = data["isVideo"] as? Bool else {
//                    return nil
//                }
//                
//                let timestamp = Date(timeIntervalSince1970: timestampDouble)
//                let mood = (data["mood"] as? String)?.nilIfEmpty
//                let assetURLString = data["assetURLString"] as? String
//                
//                let asset: CKAsset
//                if let urlString = assetURLString,
//                   let url = URL(string: urlString) {
//                    asset = CKAsset(fileURL: url)
//                } else {
//                    let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
//                    try? Data().write(to: tempURL)
//                    asset = CKAsset(fileURL: tempURL)
//                }
//                
//                return Loop(
//                    id: id,
//                    data: asset,
//                    timestamp: timestamp,
//                    lastRetrieved: nil,
//                    promptText: promptText, category: category,
//                    mood: mood,
//                    freeResponse: freeResponse,
//                    isVideo: isVideo,
//                    isDailyLoop: true
//                )
//            }
//        }
//    }
//    
    func saveCachedState() {
       UserDefaults.standard.set(dailyPrompts, forKey: promptCacheKey)
       UserDefaults.standard.set(currentPromptIndex, forKey: promptIndexKey)
       UserDefaults.standard.set(retryAttemptsLeft, forKey: retryAttemptsKey)
       UserDefaults.standard.set(hasCompletedToday, forKey: "hasCompletedToday")
       UserDefaults.standard.set(Date(), forKey: lastPromptDateKey)
   }
   
    private func loadCachedState() {
        DispatchQueue.main.async {
            self.hasCompletedToday = UserDefaults.standard.bool(forKey: "hasCompletedToday")
            self.dailyPrompts = UserDefaults.standard.stringArray(forKey: self.promptCacheKey) ?? []
            self.currentPromptIndex = UserDefaults.standard.integer(forKey: self.promptIndexKey)
            self.retryAttemptsLeft = UserDefaults.standard.integer(forKey: self.retryAttemptsKey)
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
    
    func deleteLoop(withID loopID: String) async {
        do {
            // First find the loop in our current data structure
            for (date, loops) in loopsByDate {
                if let index = loops.firstIndex(where: { $0.id == loopID }) {
                    // Remove from local data structure
                    await MainActor.run {
                        loopsByDate[date]?.remove(at: index)
                    }
                    break
                }
            }
            
            // Delete from storage
            try await LoopLocalStorageUtility.shared.deleteLoop(withID: loopID)
            
            // If cloud backup is enabled, delete from cloud too
            if UserDefaults.standard.bool(forKey: "iCloudBackupEnabled") {
                try await LoopCloudKitUtility.deleteLoop(withID: loopID)
            }
            
            print("Successfully deleted loop with ID \(loopID)")
        } catch {
            print("Error deleting loop: \(error)")
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

