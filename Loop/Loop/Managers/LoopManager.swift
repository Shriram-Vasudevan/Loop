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
    
    // MARK: - Published Properties
    @Published var prompts: [String] = []
    @Published var currentPromptIndex: Int = 0
    @Published var retryAttemptsLeft: Int = 1
    @Published var pastLoops: [Loop] = []
    @Published var loopsByDate: [Date: [Loop]] = [:]
    @Published var recentDates: [Date] = []
    @Published var hasCompletedToday: Bool = false
    @Published var queuedLoops: [Loop] = []
    @Published var memoryBankStatus: MemoryBankStatus = .checking
    @Published var currentPastLoop: Loop?
    
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
    
    let moodColors: [String: Color] = [
        "happy": Color(hex: "6FCF97"),
        "sad": Color(hex: "56CCF2"),
        "stressed": Color(hex: "F2994A"),
        "energetic": Color(hex: "9B51E0"),
        "anxious": Color(hex: "EB5757")
    ]
    
    // MARK: - Private Properties
    private let container = CKContainer(identifier: "iCloud.com.yourapp.Loop")
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
    
    let availablePrompts = [
        "What's something you're grateful for today?",
        "Describe a challenge you faced recently.",
        "What's a goal you're working towards?",
        "How are you feeling emotionally?",
        "What's something you're looking forward to?",
        "Reflect on a recent accomplishment.",
        "Describe your current mood in one word.",
        "What did you learn today?",
        "What's one thing that made you smile today?",
        "What's a personal strength you've relied on lately?",
        "How can you improve tomorrow?",
        "What's been on your mind lately?",
        "What's something you're proud of?",
        "How did you overcome a recent obstacle?",
        "What motivates you?",
        "Who's someone that inspires you?",
        "What's something you need to let go of?",
        "What's a recent positive experience?",
        "How do you handle stress?",
        "What's one thing you want to focus on tomorrow?",
        "What's something that challenged you today?",
        "Describe your ideal day.",
        "What's something you appreciate about yourself?",
        "What's a habit you want to develop?",
        "What makes you feel energized?"
    ]
    
    init() {
        checkAndResetIfNeeded()
        Task {
            await checkSevenDayStatus()
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
                // Use the constant dates here
                let completionStatus = try await LoopCloudKitUtility.checkDailyCompletion(for: dates)
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

    
    // MARK: - Memory Bank Management
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
        let privateDB = container.privateCloudDatabase
        let query = CKQuery(recordType: "LoopRecord", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "Timestamp", ascending: false)]
        
        let calendar = Calendar.current
        var distinctDates = Set<Date>()
        
        let records = try await privateDB.records(matching: query, inZoneWith: nil)
        for record in records {
            if let timestamp = record["Timestamp"] as? Date {
                let startOfDay = calendar.startOfDay(for: timestamp)
                distinctDates.insert(startOfDay)
            }
        }
        
        return distinctDates.count
    }
    
    // MARK: - Past Loop Fetching
    func fetchPastLoopForCurrentPrompt() async throws -> Loop? {
        guard case .ready = memoryBankStatus else {
            return nil
        }
        
        let privateDB = container.privateCloudDatabase
        let currentPrompt = getCurrentPrompt()
        
        let predicate = NSPredicate(format: "Prompt == %@ AND Timestamp < %@",
                                  currentPrompt, Date() as NSDate)
        let query = CKQuery(recordType: "LoopRecord", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "Timestamp", ascending: false)]
        
        let records = try await privateDB.records(matching: query, inZoneWith: nil)
        let loops = records.compactMap { record -> Loop? in
            guard let id = record["ID"] as? String,
                  let data = record["Data"] as? CKAsset,
                  let timestamp = record["Timestamp"] as? Date,
                  let promptText = record["Prompt"] as? String else {
                return nil
            }
            
            return Loop(
                id: id,
                data: data,
                timestamp: timestamp,
                lastRetrieved: record["LastRetrieved"] as? Date,
                promptText: promptText,
                mood: record["Mood"] as? String,
                freeResponse: record["FreeResponse"] as? Bool ?? false,
                isVideo: record["IsVideo"] as? Bool ?? false
            )
        }
        
        return loops.first
    }
    
    // MARK: - Loop Management
    func checkAndResetIfNeeded() {
        if !isCacheValidForToday() {
            selectRandomPrompts()
            resetPromptProgress()
            saveCachedState()
        } else {
            loadCachedState()
        }
    }
    
    func selectRandomPrompts() {
        prompts = ["Share Anything"] + availablePrompts.shuffled().prefix(2).map { $0 }
    }
    
    func resetPromptProgress() {
        currentPromptIndex = 0
        retryAttemptsLeft = 1
        hasCompletedToday = false
    }
    
    func moveToNextPrompt() {
        guard currentPromptIndex < prompts.count - 1 else {
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
        return prompts[currentPromptIndex]
    }
    
    func isLastPrompt() -> Bool {
        return currentPromptIndex == prompts.count - 1
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
    
    func addLoop(mediaURL: URL, isVideo: Bool, prompt: String, mood: String? = nil, freeResponse: Bool = false) {
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
            isVideo: isVideo
        )
        
        LoopCloudKitUtility.addLoop(loop: loop)

        Task {
            if let pastLoop = try? await fetchPastLoopForCurrentPrompt() {
                await MainActor.run {
                    self.currentPastLoop = pastLoop
                    self.queuedLoops.append(loop)
                    self.saveQueuedLoops()
                }
            }
        }
    }
    
    func fetchRecentDates(limit: Int = 6, completion: @escaping () -> Void) {
        LoopCloudKitUtility.fetchRecentLoopDates(limit: limit) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let dates):
                    self?.recentDates = dates
                    self?.lastFetchedDate = dates.last
                    self?.fetchLoopsForAllRecentDates(dates: dates, completion: completion)
                case .failure(let error):
                    print("Error fetching recent dates: \(error.localizedDescription)")
                    completion()
                }
            }
        }
    }
    
    func fetchNextPageOfDates(limit: Int = 6, completion: @escaping () -> Void) {
        guard let lastFetchedDate = recentDates.last else {
            completion()
            return
        }
        
        LoopCloudKitUtility.fetchRecentLoopDates(startingFrom: lastFetchedDate, limit: limit) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let newDates):
                    self?.recentDates.append(contentsOf: newDates)
                    self?.recentDates = Array(Set(self!.recentDates)).sorted(by: >)
                    self?.fetchLoopsForAllRecentDates(dates: newDates, completion: completion)
                case .failure(let error):
                    print("Error fetching more dates: \(error.localizedDescription)")
                    completion()
                }
            }
        }
    }
    
    func fetchLoopsForAllRecentDates(dates: [Date], completion: @escaping () -> Void) {
        let group = DispatchGroup()
        
        for date in dates {
            group.enter()
            LoopCloudKitUtility.fetchLoops(for: date) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let loops):
                        self?.loopsByDate[date, default: []].append(contentsOf: loops)
                    case .failure(let error):
                        print("Error fetching loops for \(date): \(error.localizedDescription)")
                    }
                    group.leave()
                }
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
                        isVideo: isVideo
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
                        isVideo: isVideo
                    )
                }
            }
        }
        
        private func saveCachedState() {
            UserDefaults.standard.set(prompts, forKey: promptCacheKey)
            UserDefaults.standard.set(currentPromptIndex, forKey: promptIndexKey)
            UserDefaults.standard.set(retryAttemptsLeft, forKey: retryAttemptsKey)
            UserDefaults.standard.set(hasCompletedToday, forKey: "hasCompletedToday")
            UserDefaults.standard.set(Date(), forKey: lastPromptDateKey)
        }
        
        private func loadCachedState() {
            prompts = UserDefaults.standard.stringArray(forKey: promptCacheKey) ?? []
            currentPromptIndex = UserDefaults.standard.integer(forKey: promptIndexKey)
            retryAttemptsLeft = UserDefaults.standard.integer(forKey: retryAttemptsKey)
            hasCompletedToday = UserDefaults.standard.bool(forKey: "hasCompletedToday")
        }
        
        private func isCacheValidForToday() -> Bool {
            if let lastPromptDate = UserDefaults.standard.object(forKey: lastPromptDateKey) as? Date {
                return Calendar.current.isDateInToday(lastPromptDate)
            }
            return false
        }
    }
