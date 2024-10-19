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
        
    @Published var prompts: [String] = []
    @Published var currentPromptIndex: Int = 0
    @Published var retryAttemptsLeft: Int = 1
    @Published var pastLoops: [Loop] = []
    
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
      
    private let promptCacheKey = "PromptsForTheDay"
    private let randomPastLoops = "RandomPastLoops"
    private let promptIndexKey = "CurrentPromptIndex"
    private let retryAttemptsKey = "RetryAttemptsLeft"
    private let lastPromptDateKey = "LastPromptDate"
    
    @Published var loopsByDate: [Date: [Loop]] = [:]
    @Published var recentDates: [Date] = []
    private var lastFetchedDate: Date?
    
    init() {
        loadCachedState()
         checkAndResetIfNeeded()
     }

     // Reset logic if a new day has started or all prompts are done.
     func checkAndResetIfNeeded() {
         if !isCacheValidForToday() || areAllPromptsDone() {
             selectRandomPrompts()
             resetPromptProgress()
         }
     }

     // Select random prompts for the day and cache them.
     func selectRandomPrompts() {
         prompts = ["Free Response"] + availablePrompts.shuffled().prefix(2).map { $0 }
         saveCachedState()
     }

     // Reset prompt progress and retry attempts.
     func resetPromptProgress() {
         currentPromptIndex = 0
         retryAttemptsLeft = 1
         saveCachedState()
     }

     // Move to the next prompt and save the state.
     func nextPrompt() {
         if currentPromptIndex < prompts.count - 1 {
             currentPromptIndex += 1
             saveCachedState()
         }
     }

     // Retrieve the current prompt.
     func getCurrentPrompt() -> String {
         return prompts[currentPromptIndex]
     }

     // Check if the user is on the last prompt.
     func isLastLoop() -> Bool {
         return currentPromptIndex == prompts.count - 1
     }

     // Check if all prompts for the day are complete.
     func areAllPromptsDone() -> Bool {
         return currentPromptIndex >= prompts.count
     }

     // Retry recording logic with decrementing retry attempts.
     func retryRecording() {
         if retryAttemptsLeft > 0 {
             retryAttemptsLeft -= 1
             saveCachedState()
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

    func addLoop(mediaURL: URL, isVideo: Bool, prompt: String, mood: String? = nil, freeResponse: Bool = false) {
        let loopID = UUID().uuidString
        let timestamp = Date()
        let ckAsset = CKAsset(fileURL: mediaURL)

        // Create a Loop object, marking it as video or audio based on isVideo
        let loop = Loop(id: loopID, data: ckAsset, timestamp: timestamp, lastRetrieved: timestamp, promptText: prompt, mood: mood, freeResponse: freeResponse, isVideo: isVideo)

        LoopCloudKitUtility.addLoop(loop: loop)
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
        let group = DispatchGroup() // Manage multiple fetch requests.

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

    
    // Cache the current state of the prompts, index, and retries.
    private func saveCachedState() {
        UserDefaults.standard.set(prompts, forKey: promptCacheKey)
        UserDefaults.standard.set(currentPromptIndex, forKey: promptIndexKey)
        UserDefaults.standard.set(retryAttemptsLeft, forKey: retryAttemptsKey)
        UserDefaults.standard.set(pastLoops, forKey: lastPromptDateKey)
        UserDefaults.standard.set(Date(), forKey: lastPromptDateKey)
    }

    // Load the cached state on app launch.
    private func loadCachedState() {
        prompts = UserDefaults.standard.stringArray(forKey: promptCacheKey) ?? []
        currentPromptIndex = UserDefaults.standard.integer(forKey: promptIndexKey)
        retryAttemptsLeft = UserDefaults.standard.integer(forKey: retryAttemptsKey)
        pastLoops = (UserDefaults.standard.array(forKey: lastPromptDateKey) ?? []) as? [Loop] ?? []
    }

    // Check if the cache is still valid for today.
    private func isCacheValidForToday() -> Bool {
        if let lastPromptDate = UserDefaults.standard.object(forKey: lastPromptDateKey) as? Date {
            return Calendar.current.isDateInToday(lastPromptDate)
        }
        return false
    }
}
