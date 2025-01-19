//
//  LoopManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/1/24.
//

import Foundation
import CloudKit
import SwiftUI
import CoreData

class LoopManager: ObservableObject {
    static let shared = LoopManager()

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
    
    @Published private(set) var featuredReflections: [Prompt] = []
    
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
    
    @Environment(\.scenePhase) var scenePhase
    
    enum MemoryBankStatus {
        case checking
        case building(daysRemaining: Int)
        case ready
        case noMemoriesForPrompt
    }
    
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
    
    @AppStorage("hasRemovedUnlockReminder") var hasRemovedUnlockReminder: Bool = false
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "LoopData")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    init() {
        Task {
            await loadThematicPrompts()
            await checkSevenDayStatus()

            fetchRecentDates(limit: 10, completion: {
                
            })
        }

    }

    
    func calculateStreak() async {
        do {
            let cloudStreak = try await LoopCloudKitUtility.calculateStreak()
            let localStreak = try await localStorage.calculateStreak()
            
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
            let cloudCheck = try await LoopCloudKitUtility.fetchDistinctLoopingDays()
            let localCheckCount = try await localStorage.fetchDistinctLoopingDays()
            
            print("cloud check \(cloudCheck)")
            print("localCheckCount \(localCheckCount)")
            let distinctDays = cloudCheck + localCheckCount
            print("distinct days \(distinctDays)")
            self.distinctDays = distinctDays
            isCheckingDistinctDays = false
        } catch {
            isCheckingDistinctDays = false
        }
    }

    
    func loadThematicPrompts() async {
        do {
            let prompts = try await LoopCloudKitUtility.fetchThematicPrompts()
            await MainActor.run {
                self.thematicPrompts = prompts.shuffled()
            }
        } catch {
            print("Error loading thematic prompts: \(error)")
        }
    }
    
    private func handleThematicPromptSelection() {
        guard let selectedId = selectedThematicPromptId,
              let selectedTheme = thematicPrompts.first(where: { $0.id == selectedId }),
              selectedTheme.prompts.count >= 3 else {
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
            return
        }
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
    
    func fetchDistinctLoopingDays() async throws -> Int {
        let cloudCount = try await LoopCloudKitUtility.fetchDistinctLoopingDays()
        let localCount = try await localStorage.fetchDistinctLoopingDays()
        
        return max(cloudCount, localCount)
    }
    
    
    func addLoop(mediaURL: URL, isVideo: Bool, prompt: String, mood: String? = nil, freeResponse: Bool = false, isDailyLoop: Bool, isFollowUp: Bool, isSuccess: Bool, isUnguided: Bool) async -> (Loop, String) {

        let loopID = UUID().uuidString
        let timestamp = Date()
        let ckAsset = CKAsset(fileURL: mediaURL)
        let category = ""
        
        var transcript: String = ""
        if !isVideo {
            do {
                transcript = try await AudioAnalyzer.shared.transcribeAudio(url: mediaURL)
            } catch {
                print("Transcription failed: \(error)")
            }
        }
        
        let words = transcript.split(separator: " ")
        let firstFewWords = words.prefix(4).joined(separator: " ") + "..."

        let loop = Loop(
            id: loopID,
            data: ckAsset,
            timestamp: timestamp,
            lastRetrieved: timestamp,
            promptText: isUnguided ? firstFewWords : prompt,
            category: category,
            transcript: transcript,
            freeResponse: freeResponse,
            isVideo: isVideo,
            isDailyLoop: isDailyLoop,
            isFollowUp: isFollowUp,
            isSuccessJournal: isSuccess
        )

        let loopDate = Calendar.current.startOfDay(for: timestamp)
        await MainActor.run {
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
                recentDates.sort(by: >)
            }
        }

        // Save based on iCloud backup setting
        if UserDefaults.standard.bool(forKey: "iCloudBackupEnabled") {
            Task {
                await LoopCloudKitUtility.addLoop(loop: loop)
            }
        } else {
            await localStorage.addLoop(loop: loop)
        }

        print("dding day activity")
        addDayActivity()
        
        return (loop, transcript)
    }

    func addDayActivity() {
       do {
           print("📝 Starting addDayActivity...")
           let date = Date()
           
           let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "ActivityForToday")

           let calendar = Calendar.current
           let startOfDay = calendar.startOfDay(for: date)
           let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
           
           print("🔍 Checking for existing activity between \(startOfDay) and \(endOfDay)")
           fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
           
           let existingEntries = try context.fetch(fetchRequest)
           
           if let existingEntry = existingEntries.first {
               print("✅ Found existing activity entry for today")
           } else {
               print("➕ No existing activity found - creating new entry")
               guard let entityDescription = NSEntityDescription.entity(forEntityName: "ActivityForToday", in: context) else {
                   print("❌ Failed to get entity description for ActivityForToday")
                   return
               }
               let entity = NSManagedObject(entity: entityDescription, insertInto: context)
               entity.setValue(startOfDay, forKey: "date")
               print("✏️ Set activity date to \(startOfDay)")
           }
           
           try context.save()
           print("💾 Successfully saved activity to Core Data")
       } catch {
           print("❌ Error in addDayActivity: \(error.localizedDescription)")
           return
       }
    }
    
    func fetchRecentDates(limit: Int = 10, completion: @escaping () -> Void) {
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
    
    func fetchNextPageOfDates(limit: Int = 10, completion: @escaping () -> Void) {
        guard let lastFetchedDate = recentDates.last else {
            completion()
            return
        }
        
        let group = DispatchGroup()
        let dateQueue = DispatchQueue(label: "com.loop.dateCollection")
        var allNewDates = Set<Date>()
        
     
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

    private func isCacheValidForToday() -> Bool {
        if let lastPromptDate = UserDefaults.standard.object(forKey: lastPromptDateKey) as? Date {
            return Calendar.current.isDateInToday(lastPromptDate)
        }
        return false
    }
    
    func loadActiveMonths() async {
        do {
            let cloudMonths = try await LoopCloudKitUtility.fetchActiveMonths()
            let localMonths = try await localStorage.fetchActiveMonths()
            
            let cloudMonthsSet = Set(cloudMonths)
            let localMonthsSet = Set(localMonths)
            
            let combinedSet = cloudMonthsSet.union(localMonthsSet)
            await MainActor.run {
                self.activeMonths = Array(combinedSet)
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
            let selectedMonthCloudSummary = try await LoopCloudKitUtility.fetchMonthData(monthId: monthId)
            let selectedMonthLocalSummary = try await localStorage.fetchMonthData(monthId: monthId)
            
            let combinedLoops = Set(selectedMonthCloudSummary.loops + selectedMonthLocalSummary.loops)
            
            let selectedMonthSummary = MonthSummary(year: monthId.year, month: monthId.month, totalEntries: selectedMonthCloudSummary.loops.count + selectedMonthLocalSummary.loops.count, completionRate: 0.0, loops: Array(combinedLoops))
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
    
    func fetchLoopsForDateRange(start: Date, end: Date) async throws -> [Loop] {
        print("🔍 Fetching daily loops between \(start) and \(end)")
        
        async let cloudLoops = LoopCloudKitUtility.fetchLoopsInDateRange(start: start, end: end)
        async let localLoops = localStorage.fetchLoopsInDateRange(start: start, end: end)
        
        do {
            let allLoops = try await cloudLoops + localLoops
            
            var uniqueLoopsDict: [String: Loop] = [:]
            allLoops.forEach { loop in
                if let existing = uniqueLoopsDict[loop.id] {
                    let existingRetrieved = existing.lastRetrieved ?? .distantPast
                    let newRetrieved = loop.lastRetrieved ?? .distantPast
                    if newRetrieved > existingRetrieved {
                        uniqueLoopsDict[loop.id] = loop
                    }
                } else {
                    uniqueLoopsDict[loop.id] = loop
                }
            }
            
            let sortedLoops = uniqueLoopsDict.values.sorted { $0.timestamp > $1.timestamp }
            print("🎯 Returning \(sortedLoops.count) unique daily loops")
            return sortedLoops
            
        } catch {
            print("❌ Error fetching loops: \(error)")
            throw error
        }
    }
    
    func editTranscript(forLoopId id: String, newTranscript: String) async throws {
        print("🔄 Starting transcript edit for loop ID: \(id)")
        
        if try await localStorage.findAndUpdateTranscript(forLoopId: id, newTranscript: newTranscript) {
            print("✅ Successfully updated transcript in local storage")
            
            await updateInMemoryTranscript(id: id, newTranscript: newTranscript)

            return
        }
        
        // If not found in local storage and cloud backup is enabled, try cloud
        if UserDefaults.standard.bool(forKey: "iCloudBackupEnabled") {
            if try await LoopCloudKitUtility.findAndUpdateTranscript(
                forLoopId: id,
                newTranscript: newTranscript
            ) {
                print("✅ Successfully updated transcript in cloud storage")
                await updateInMemoryTranscript(id: id, newTranscript: newTranscript)
                return
            }
        }
        
        throw NSError(
            domain: "LoopManager",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Loop not found in any storage location"]
        )
    }
    
    private func updateInMemoryTranscript(id: String, newTranscript: String) async {
        await MainActor.run {
            for (date, var loops) in loopsByDate {
                if let index = loops.firstIndex(where: { $0.id == id }) {
                    var updatedLoop = loops[index]
                    updatedLoop.transcript = newTranscript
                    loops[index] = updatedLoop
                    loopsByDate[date] = loops
                    break
                }
            }
        }
    }
    
    
    func dismissUnlockReminder() {
        hasRemovedUnlockReminder = true
    }

    func getAvailableCategories() -> [PromptCategory] {
        return PromptCategory.allCases
    }

//    private func getAvailablePromptsForCategory(_ category: PromptCategory, isDailyPrompt: Bool) -> [Prompt] {
//        let recentPrompts = getRecentPrompts()
//        let todaysPrompts = Set(dailyPrompts)
//        
//        return promptGroups[category]?
//            .filter {
//                $0.isDailyPrompt == isDailyPrompt &&
//                !recentPrompts.contains($0.text) &&
//                !todaysPrompts.contains($0.text)
//            } ?? []
//    }
//
//    func selectCategory(_ category: PromptCategory) async {
//        guard currentPromptIndex == 2 else { return }
//        
//        selectedCategories[currentPromptIndex] = category
//        let availablePrompts = getAvailablePromptsForCategory(category, isDailyPrompt: currentPromptIndex == 2)
//        
//        let selectedPrompt: Prompt
//        if let prompt = availablePrompts.randomElement() {
//            selectedPrompt = prompt
//        } else {
//            selectedPrompt = Prompt(
//                text: getFallbackPrompt(for: category, isDailyPrompt: currentPromptIndex == 2),
//                category: category,
//                isDailyPrompt: currentPromptIndex == 2
//            )
//        }
//        
//        await MainActor.run {
//            var updatedPrompts = dailyPrompts
//            updatedPrompts[currentPromptIndex] = selectedPrompt.text
//            dailyPrompts = updatedPrompts
//            saveRecentPrompt(selectedPrompt.text)
//            saveCachedState()
//        }
//    }

    private func getFallbackPrompt(for category: PromptCategory, isDailyPrompt: Bool) -> String {
        switch (category, isDailyPrompt) {
            case (.emotionalWellbeing, true): return "How are your emotions evolving today?"
            case (.emotionalWellbeing, false): return "What feelings are you sitting with right now?"
            case (.challenges, true): return "What challenge did you face today?"
            case (.challenges, false): return "How are you growing through your current challenges?"
            case (.growth, true): return "What did you learn about yourself today?"
            case (.growth, false): return "What's an area where you're seeing progress?"
            case (.connections, true): return "Who made an impact on your day?"
            case (.connections, false): return "What relationship is on your mind?"
            case (.curiosity, true): return "What sparked your interest today?"
            case (.curiosity, false): return "What are you curious about lately?"
            case (.extraPrompts, true): return "What would you like to remember about today?"
            case (.extraPrompts, false): return "What's worth noting right now?"
            case (.freeform, _): return "What's on your mind?"
        }
    }
    
}

enum MemoryBankStatus {
        case checking
        case building(daysRemaining: Int)
        case ready
        case noMemoriesForPrompt
}

struct Prompt {
    let text: String
    let category: PromptCategory
    let isDailyPrompt: Bool
}

extension UserDefaults {
    var lastReflectionPlanDate: Date? {
        get { object(forKey: "lastReflectionPlanDate") as? Date }
        set { set(newValue, forKey: "lastReflectionPlanDate") }
    }
    
    var hasOpenedReflectionToday: Bool {
        if let lastDate = lastReflectionPlanDate {
            return Calendar.current.isDateInToday(lastDate)
        }
        return false
    }
}
