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
    
    @Published var prompts: [String] = []
    @Published var currentPromptIndex: Int = 0
    @Published var retryAttemptsLeft: Int = 1
    @Published var pastLoops: [Loop] = []
    @Published var loopsByDate: [Date: [Loop]] = [:]
    @Published var recentDates: [Date] = []
    @Published var hasCompletedToday: Bool = false
    
    @Published var queuedLoops: [Loop] = []
    private let queuedLoopsKey = "QueuedLoopsKey"
    private let pastLoopsKey = "PastLoopsKey"
    
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
    
    private let promptCacheKey = "PromptsForTheDay"
    private let promptIndexKey = "CurrentPromptIndex"
    private let retryAttemptsKey = "RetryAttemptsLeft"
    private let lastPromptDateKey = "LastPromptDate"
    private let stateKey = "CurrentLoopState"
    private var lastFetchedDate: Date?
    
    @Published var moodData: [Date: String] = [
            Date(timeIntervalSinceNow: -6 * 24 * 60 * 60): "happy",
            Date(timeIntervalSinceNow: -5 * 24 * 60 * 60): "sad",
            Date(timeIntervalSinceNow: -4 * 24 * 60 * 60): "stressed",
            Date(timeIntervalSinceNow: -3 * 24 * 60 * 60): "energetic",
            Date(timeIntervalSinceNow: -2 * 24 * 60 * 60): "anxious",
            Date(timeIntervalSinceNow: -1 * 24 * 60 * 60): "happy"
        ]

    let moodColors: [String: Color] = [
        "happy": Color(hex: "6FCF97"),
        "sad": Color(hex: "56CCF2"),
        "stressed": Color(hex: "F2994A"),
        "energetic": Color(hex: "9B51E0"),
        "anxious": Color(hex: "EB5757")
    ]
    
    init() {
        checkAndResetIfNeeded()
    
    }
    
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
    
    func handleLoopCompletion() {
        LoopCloudKitUtility.getRandomLoop { [weak self] randomLoop in
            if let loop = randomLoop {
                DispatchQueue.main.async {
                    self?.queuedLoops.append(loop)
                    self?.saveQueuedLoops()
                }
            }
        }
    }
    
    func fetchRandomPastLoop() {
        LoopCloudKitUtility.getRandomLoop(completion: { randomLoop in
            if let loop = randomLoop {
                DispatchQueue.main.async {
                    self.pastLoops.append(loop)
                }
            }
        })
        
    }
    
    // Modified addLoop method
    func addLoop(mediaURL: URL, isVideo: Bool, prompt: String, mood: String? = nil, freeResponse: Bool = false) {
        let loopID = UUID().uuidString
        let timestamp = Date()
        let ckAsset = CKAsset(fileURL: mediaURL)
        
        let loop = Loop(id: loopID,
                       data: ckAsset,
                       timestamp: timestamp,
                       lastRetrieved: timestamp,
                       promptText: prompt,
                       mood: mood,
                       freeResponse: freeResponse,
                       isVideo: isVideo)
        
        LoopCloudKitUtility.addLoop(loop: loop)
        handleLoopCompletion() 
    }
    
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
        
        // Make sure all values are property list compatible
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
        
        // Make sure all values are property list compatible
        if JSONSerialization.isValidJSONObject(cachedLoops) {
            UserDefaults.standard.set(cachedLoops, forKey: pastLoopsKey)
        }
    }
    
    private func loadCachedLoops() {
        if let queuedData = UserDefaults.standard.array(forKey: queuedLoopsKey) as? [[String: Any]] {
            let today = Calendar.current.startOfDay(for: Date())
            
            queuedLoops = queuedData.compactMap { data -> Loop? in
                // Check if cache is from today
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
                
                // Create CKAsset from cached URL string
                let asset: CKAsset
                if let urlString = assetURLString,
                   let url = URL(string: urlString) {
                    asset = CKAsset(fileURL: url)
                } else {
                    // Create empty asset if URL is missing
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
                // Check if cache is from today
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
                
                // Create CKAsset from cached URL string
                let asset: CKAsset
                if let urlString = assetURLString,
                   let url = URL(string: urlString) {
                    asset = CKAsset(fileURL: url)
                } else {
                    // Create empty asset if URL is missing
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
    
    func fetchRecentDates(limit: Int = 6, completion: @escaping () -> Void) {
       LoopCloudKitUtility.fetchRecentLoopDates(limit: limit) { [weak self] result in
           DispatchQueue.main.async {
               switch result {
               case .success(let dates):
                   self?.recentDates = dates
                   self?.lastFetchedDate = dates.last  // Track the last date for pagination
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

        // Fetch dates older than the last unique date retrieved.
        LoopCloudKitUtility.fetchRecentLoopDates(startingFrom: lastFetchedDate, limit: limit) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let newDates):
                    // Append new unique dates and remove duplicates.
                    self?.recentDates.append(contentsOf: newDates)
                    self?.recentDates = Array(Set(self!.recentDates)).sorted(by: >)
                    
                    // Fetch loops for the new dates.
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
                        // Ensure loops are grouped by their respective date.
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
