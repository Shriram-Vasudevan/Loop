import Foundation
import SwiftUI
import CloudKit

class PremiumMemoryManager: ObservableObject {
    static let shared = PremiumMemoryManager()
    
    @Published private(set) var dailyMemory: Loop?
    @Published private(set) var isLoading = false
    
    private let premiumManager = PremiumManager.shared
    private let loopManager = LoopManager.shared
    
    private struct MemoryCache: Codable {
        let loop: Loop.CodableRepresentation
        let date: Date
    }
    
    private struct MemoryHistory: Codable {
        let loopId: String
        let date: Date
    }
    
    private let userDefaults = UserDefaults.standard
    private let dailyMemoryKey = "dailyPremiumMemory"
    private let memoryHistoryKey = "premiumMemoryHistory"
    
    private var memoryHistory: [MemoryHistory] = []
    private let maxHistoryDays = 90 // Keep track of memories shown in the last 90 days
    
    private init() {
        loadMemoryHistory()
        
        // Try to load today's memory on initialization
        if !loadTodaysMemory() {
            // If there's no memory for today, don't auto-fetch
            // We'll fetch when requested by the user
        }
    }
    
    // MARK: - Public Methods
    
    /// Fetches today's memory if not already fetched, or returns the cached one
    func getDailyMemory() async -> (loop: Loop?, error: MemoryAccessError?) {
        // Check for premium status
        guard premiumManager.isUserPremium() else {
            return (nil, .premiumRequired)
        }
        
        // If we already have today's memory loaded, return it
        if let dailyMemory = self.dailyMemory, Calendar.current.isDateInToday(dailyMemory.timestamp) {
            return (dailyMemory, nil)
        }
        
        // Otherwise, fetch a new memory
        return await fetchNewDailyMemory()
    }
    
    /// Force fetches a new daily memory
    func refreshDailyMemory() async -> (loop: Loop?, error: MemoryAccessError?) {
        guard premiumManager.isUserPremium() else {
            return (nil, .premiumRequired)
        }
        
        return await fetchNewDailyMemory()
    }
    
    // MARK: - Private Methods
    
    private func fetchNewDailyMemory() async -> (loop: Loop?, error: MemoryAccessError?) {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            // Get a date range focused on meaningful memories
            // Prefer memories from 3-12 months ago
            let calendar = Calendar.current
            let today = Date()
            let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: today)!
            let twelveMonthsAgo = calendar.date(byAdding: .month, value: -12, to: today)!
            
            // First try to find a memory from the same day in previous years/months
            if let sameDayMemory = await findMemoryFromSameDay() {
                await updateDailyMemory(sameDayMemory)
                await MainActor.run { isLoading = false }
                return (sameDayMemory, nil)
            }
            
            // Then try to find a memory from the ideal time window (3-12 months ago)
            let allLoops = try await loopManager.fetchLoopsForDateRange(start: twelveMonthsAgo, end: threeMonthsAgo)
            
            // Filter out recently shown memories
            let recentMemoryIds = getRecentMemoryIds()
            let availableLoops = allLoops.filter { !recentMemoryIds.contains($0.id) }
            
            if availableLoops.isEmpty {
                // If no memories in ideal range, try any memory older than 1 month
                let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: today)!
                let olderLoops = try await loopManager.fetchLoopsForDateRange(
                    start: calendar.date(byAdding: .year, value: -5, to: today)!,
                    end: oneMonthAgo
                )
                
                let availableOlderLoops = olderLoops.filter { !recentMemoryIds.contains($0.id) }
                
                if let memory = availableOlderLoops.randomElement() {
                    await updateDailyMemory(memory)
                    await MainActor.run { isLoading = false }
                    return (memory, nil)
                } else if let anyMemory = olderLoops.randomElement() {
                    // If all have been shown recently, just pick any older memory
                    await updateDailyMemory(anyMemory)
                    await MainActor.run { isLoading = false }
                    return (anyMemory, nil)
                }
                
                await MainActor.run { isLoading = false }
                return (nil, .noMemoriesFound)
            }
            
            // Pick a random memory from available ones
            let selectedMemory = availableLoops.randomElement()!
            await updateDailyMemory(selectedMemory)
            
            await MainActor.run { isLoading = false }
            return (selectedMemory, nil)
            
        } catch {
            print("Error fetching daily memory: \(error)")
            await MainActor.run { isLoading = false }
            return (nil, .fetchError(error))
        }
    }
    
    private func findMemoryFromSameDay() async -> Loop? {
        let calendar = Calendar.current
        let today = Date()
        let currentDay = calendar.component(.day, from: today)
        let currentMonth = calendar.component(.month, from: today)
        
        do {
            // Look for memories from previous years but same day
            let fiveYearsAgo = calendar.date(byAdding: .year, value: -5, to: today)!
            let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: today)!
            
            let olderLoops = try await loopManager.fetchLoopsForDateRange(
                start: fiveYearsAgo,
                end: oneMonthAgo
            )
            
            // Find loops from the same day (and optionally month)
            let sameDayLoops = olderLoops.filter { loop in
                let loopDay = calendar.component(.day, from: loop.timestamp)
                let loopMonth = calendar.component(.month, from: loop.timestamp)
                
                // Exact date match (same day and month in previous years)
                if loopDay == currentDay && loopMonth == currentMonth {
                    return true
                }
                
                // Or just the same day of month
                return loopDay == currentDay
            }
            
            // Filter out recently shown memories
            let recentMemoryIds = getRecentMemoryIds()
            let availableSameDayLoops = sameDayLoops.filter { !recentMemoryIds.contains($0.id) }
            
            return availableSameDayLoops.randomElement()
            
        } catch {
            print("Error searching for same-day memories: \(error)")
            return nil
        }
    }
    
    @MainActor
    private func updateDailyMemory(_ memory: Loop) {
        dailyMemory = memory
        saveCurrentMemory()
        addToHistory(memory)
    }
    
    private func getRecentMemoryIds() -> Set<String> {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!
        
        return Set(
            memoryHistory
                .filter { $0.date > thirtyDaysAgo }
                .map { $0.loopId }
        )
    }
    
    // MARK: - Persistence Methods
    
    private func loadMemoryHistory() {
        if let data = userDefaults.data(forKey: memoryHistoryKey),
           let history = try? JSONDecoder().decode([MemoryHistory].self, from: data) {
            memoryHistory = history
        }
    }
    
    private func saveMemoryHistory() {
        if let encoded = try? JSONEncoder().encode(memoryHistory) {
            userDefaults.set(encoded, forKey: memoryHistoryKey)
        }
    }
    
    private func addToHistory(_ memory: Loop) {
        let historyEntry = MemoryHistory(loopId: memory.id, date: Date())
        memoryHistory.append(historyEntry)
        
        // Trim history to only keep the last 90 days
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -maxHistoryDays, to: Date())!
        memoryHistory = memoryHistory.filter { $0.date > cutoffDate }
        
        saveMemoryHistory()
    }
    
    private func loadTodaysMemory() -> Bool {
        guard let data = userDefaults.data(forKey: dailyMemoryKey),
              let cachedMemory = try? JSONDecoder().decode(MemoryCache.self, from: data) else {
            return false
        }
        
        // Only use the cached memory if it's from today
        if Calendar.current.isDateInToday(cachedMemory.date) {
            dailyMemory = Loop.from(codable: cachedMemory.loop)
            return dailyMemory != nil
        }
        
        return false
    }
    
    private func saveCurrentMemory() {
        guard let memory = dailyMemory else { return }
        
        let codableLoop = memory.toCodable()
        let cacheEntry = MemoryCache(loop: codableLoop, date: Date())
        
        if let encoded = try? JSONEncoder().encode(cacheEntry) {
            userDefaults.set(encoded, forKey: dailyMemoryKey)
        }
    }
}

// MARK: - Supporting Types

enum MemoryAccessError: Error {
    case premiumRequired
    case noMemoriesFound
    case fetchError(Error)
    
    var userMessage: String {
        switch self {
        case .premiumRequired:
            return "This feature requires a premium subscription."
        case .noMemoriesFound:
            return "No memories found in your journal."
        case .fetchError:
            return "Unable to retrieve your memories. Please try again."
        }
    }
}

// MARK: - Loop Extensions

extension Loop {
    struct CodableRepresentation: Codable {
        let id: String
        let timestamp: Date
        let lastRetrieved: Date?
        let promptText: String
        let category: String
        let transcript: String?
        let freeResponse: Bool
        let isVideo: Bool
        let isDailyLoop: Bool
        let isFollowUp: Bool
        let isSuccessJournal: Bool
        let isDream: Bool
        let isAffirmation: Bool
        let isMorningJournal: Bool
        let mood: String?
        let mediaPath: String
    }
    
    func toCodable() -> CodableRepresentation {
        let mediaPath = self.data.fileURL?.lastPathComponent ?? ""
        
        return CodableRepresentation(
            id: id,
            timestamp: timestamp,
            lastRetrieved: lastRetrieved,
            promptText: promptText,
            category: category,
            transcript: transcript,
            freeResponse: freeResponse,
            isVideo: isVideo,
            isDailyLoop: isDailyLoop,
            isFollowUp: isFollowUp,
            isSuccessJournal: isSuccessJournal ?? false,
            isDream: isDream ?? false,
            isAffirmation: isAffirmation ?? false,
            isMorningJournal: isMorningJournal ?? false,
            mood: mood,
            mediaPath: mediaPath
        )
    }
    
    static func from(codable: CodableRepresentation) -> Loop? {
        let fileManager = FileManager.default
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let mediaDir = paths[0].appendingPathComponent("LoopMedia")
        let mediaURL = mediaDir.appendingPathComponent(codable.mediaPath)
        
        guard fileManager.fileExists(atPath: mediaURL.path) else {
            return nil
        }
        
        let asset = CKAsset(fileURL: mediaURL)
        
        return Loop(
            id: codable.id,
            data: asset,
            timestamp: codable.timestamp,
            lastRetrieved: codable.lastRetrieved,
            promptText: codable.promptText,
            category: codable.category,
            transcript: codable.transcript,
            freeResponse: codable.freeResponse,
            isVideo: codable.isVideo,
            isDailyLoop: codable.isDailyLoop,
            isFollowUp: codable.isFollowUp,
            isSuccessJournal: codable.isSuccessJournal,
            isDream: codable.isDream,
            isAffirmation: codable.isAffirmation,
            isMorningJournal: codable.isMorningJournal,
            mood: codable.mood
        )
    }
}
