//
//  JournalOfTheDayManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 3/7/25.
//

import Foundation

//
//  JournalOfTheDayManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 3/7/25.
//

import Foundation

enum JournalType: String {
    case none = "none"
    case freeResponse = "freeResponse"
    case success = "success"
    case dream = "dream"
}

class JournalOfTheDayManager: ObservableObject {
    static let shared = JournalOfTheDayManager()

    private let availableJournals = ["freeResponse", "success", "dream"]

    @Published var currentJournal: JournalType

    private let userDefaults = UserDefaults.standard
    private let todaysJournalKey = "todaysJournal"
    private let journalHistoryKey = "journalHistory"

    private var journalHistory: [JournalHistory] = []
    
    init() {
        currentJournal = .none
        
        loadJournalHistory()
        setTodaysJournal()
    }
    
    func selectNewJournalForToday() {
        assignJournalForToday()
    }

    private func setTodaysJournal() {
        if let todaysJournal = getExistingJournalForToday() {
            currentJournal = getJournalType(journalID: todaysJournal.journalId)
        } else {
            assignJournalForToday()
        }
    }

    private func getExistingJournalForToday() -> JournalHistory? {
        let today = Calendar.current.startOfDay(for: Date())
        
        return journalHistory.first { history in
            Calendar.current.isDate(history.date, inSameDayAs: today)
        }
    }

    private func assignJournalForToday() {
        let recentJournals = getRecentJournals(days: 3)

        let availableJournals = self.availableJournals.filter { journalId in
            !recentJournals.contains(journalId)
        }

        let selectedJournal = availableJournals.isEmpty ?
            self.availableJournals.randomElement()! :
            availableJournals.randomElement()!

        let today = Date()

        journalHistory.removeAll { Calendar.current.isDate($0.date, inSameDayAs: today) }

        let newEntry = JournalHistory(journalId: selectedJournal, date: today)
        journalHistory.append(newEntry)

        cleanupOldEntries()

        saveJournalHistory()

        currentJournal = getJournalType(journalID: selectedJournal)
    }

    private func getRecentJournals(days: Int) -> [String] {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -days, to: Date())!
        
        return journalHistory
            .filter { $0.date >= cutoffDate }
            .map { $0.journalId }
    }

    private func cleanupOldEntries() {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -7, to: Date())!
        
        journalHistory.removeAll { $0.date < cutoffDate }
    }

    private func loadJournalHistory() {
        if let data = userDefaults.data(forKey: journalHistoryKey),
           let history = try? JSONDecoder().decode([JournalHistory].self, from: data) {
            self.journalHistory = history
        }
    }
    
    private func saveJournalHistory() {
        if let encoded = try? JSONEncoder().encode(journalHistory) {
            userDefaults.set(encoded, forKey: journalHistoryKey)
        }
    }

    private func getJournalType(journalID: String) -> JournalType {
        switch journalID {
        case "freeResponse":
            return .freeResponse
        case "success":
            return .success
        case "dream":
            return .dream
        default:
            return .none
        }
    }
}

struct JournalHistory: Codable {
    let journalId: String
    let date: Date
}
