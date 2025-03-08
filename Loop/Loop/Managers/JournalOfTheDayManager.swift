//
//  JournalOfTheDayManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 3/7/25.
//

import Foundation

class JournalOfTheDayManager: ObservableObject {
    var journals: [String] = ["freeResponse", "success", "dream"]
    
    @Published var currentJournal: String
    
    private let userDefaults = UserDefaults.standard
    var currentJournalKey: String = "currentJournal"
    var selectedJournalsKey: String = "journalHistory"
    
    var journalHistory: [JournalHistory] = []
    
    init() {
        currentJournal = ""
        getJournalHistory()
        
        if loadTodaysJournal() {
            selectRandomJournal()
        }
    }
    
    func saveJournal(journalID: String) {
        let journalCache = DailyJournalCache(journal: journalID, date: Date())
        if let data = try? JSONEncoder().encode(journalCache) {
            userDefaults.set(data, forKey: currentJournalKey)
        }
    }
    
    func getJournalHistory() {
        if let data = userDefaults.data(forKey: selectedJournalsKey), let journalHistory = try? JSONDecoder().decode([JournalHistory].self, from: data) {
            self.journalHistory = journalHistory
        }
    }
    
    func addToJournalHistory() {
        if let encoded = try? JSONEncoder().encode(journalHistory) {
            userDefaults.set(encoded, forKey: selectedJournalsKey)
        }
    }
    
    
    func loadTodaysJournal() -> Bool {
        if let data = userDefaults.data(forKey: currentJournal), let decoded = try? JSONDecoder().decode(DailyJournalCache.self, from: data) {
            if Calendar.current.isDateInToday(decoded.date) {
                return false
            }
            
            return true
        }
        
        return true
    }
    
    func selectRandomJournal() {
        let calendar = Calendar.current
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        
        let unavailableJournals = journalHistory
            .filter { $0.date >= threeDaysAgo }
            .map { $0.journalId }
        
        let availableJournals = journals
            .filter { !unavailableJournals.contains($0) }
        
        let randomJournal = availableJournals.isEmpty ? journals.randomElement() : availableJournals.randomElement()
        
        let sixDaysAgo = calendar.date(byAdding: .day, value: -6, to: Date()) ?? Date()
        
        if let randomJournal = randomJournal {
            self.journalHistory = self.journalHistory.filter { $0.date >= sixDaysAgo }
            
            self.journalHistory.append(JournalHistory(journalId: randomJournal, date: Date()))
            
            addToJournalHistory()
            saveJournal(journalID: randomJournal)
        }
    }

}

struct JournalHistory: Codable {
    let journalId: String
    let date: Date
}

struct DailyJournalCache: Codable {
    let journal: String
    let date: Date
}
