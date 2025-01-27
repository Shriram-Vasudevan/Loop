//
//  ReflectionCardManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/16/25.
//

import Foundation

class ReflectionCardManager: ObservableObject {
    static let shared = ReflectionCardManager()
    
    enum ReflectionCardType: Int, CaseIterable, Codable {
        case sleepCheckin = 0
        case moodCheckin = 1
        case daySummary = 2
        case standOut = 3
        case success = 4
        case aiGenerated = 5
        case freeform = 6
        
        var title: String {
            switch self {
                case .sleepCheckin: return "Sleep Check-in"
                case .moodCheckin: return "Mood Check-in"
                case .daySummary: return "Day Summary"
                case .standOut: return "What stood out?"
                case .success: return "Today's Wins"  // Add title
                case .aiGenerated: return "Guided Question"
                case .freeform: return "Share Anything"
            }
        }
        
        var description: String {
            switch self {
                case .sleepCheckin: return "Track your sleep quality"
                case .moodCheckin: return "Take a moment to check in with yourself"
                case .daySummary: return "Give a quick overview of your day"
                case .standOut: return "What moments caught your attention?"
                case .success: return "Celebrate your achievements, big or small"  // Add description
                case .aiGenerated: return "A personalized prompt based on your reflections"
                case .freeform: return "Open space to share what's on your mind"
            }
        }
    }
    
    struct ReflectionTemplate: Codable, Identifiable {
        let id: UUID
        var name: String
        var selectedCards: Set<ReflectionCardType>
        var isDefault: Bool
        
        static var `default`: ReflectionTemplate {
            ReflectionTemplate(
                id: UUID(),
                name: "Default",
                selectedCards: [.moodCheckin, .standOut, .aiGenerated],
                isDefault: true
            )
        }
        
        var isValid: Bool {
            !selectedCards.isEmpty
        }
    }
    
    @Published private(set) var currentTemplate: ReflectionTemplate
    @Published private(set) var savedTemplates: [ReflectionTemplate] = []
    @Published private(set) var completedCards: Set<ReflectionCardType> = []
    
    private let templateKey = "SavedReflectionTemplates"
    private let activeTemplateKey = "ActiveReflectionTemplate"
    
    init() {
        if let savedData = UserDefaults.standard.data(forKey: templateKey),
           let templates = try? JSONDecoder().decode([ReflectionTemplate].self, from: savedData) {
            self.savedTemplates = templates
        }
        
        if let activeData = UserDefaults.standard.data(forKey: activeTemplateKey),
           let template = try? JSONDecoder().decode(ReflectionTemplate.self, from: activeData),
           template.isValid {
            self.currentTemplate = template
        } else {
            self.currentTemplate = .default
        }
    }
    
    // MARK: - Template Management
    
    func createTemplate(name: String, cards: Set<ReflectionCardType>) {
        guard !cards.isEmpty else { return }
        
        let newTemplate = ReflectionTemplate(
            id: UUID(),
            name: name,
            selectedCards: cards,
            isDefault: false
        )
        
        savedTemplates.append(newTemplate)
        saveTemplates()
    }
    
    func saveCurrentAsTemplate(name: String) {
        createTemplate(name: name, cards: currentTemplate.selectedCards)
    }
    
    func activateTemplate(_ template: ReflectionTemplate) {
        guard template.isValid else { return }
        currentTemplate = template
        saveActiveTemplate()
    }
    
    func deleteTemplate(_ template: ReflectionTemplate) {
        guard !template.isDefault else { return }
        savedTemplates.removeAll { $0.id == template.id }
        saveTemplates()
    }
    
    func toggleCard(_ card: ReflectionCardType) {
        var updatedCards = currentTemplate.selectedCards

        if card == .moodCheckin {
            if updatedCards.contains(.moodCheckin) && updatedCards.count > 1 {
                updatedCards.remove(.moodCheckin)
            } else {
                updatedCards.insert(.moodCheckin)
            }
        } else {
            if updatedCards.contains(card) {
                // Don't remove if it would leave no cards
                if updatedCards.count > 1 {
                    updatedCards.remove(card)
                }
            } else {
                updatedCards.insert(card)
            }
        }
        
        if !updatedCards.isEmpty {
            currentTemplate = ReflectionTemplate(
                id: currentTemplate.id,
                name: currentTemplate.name,
                selectedCards: updatedCards,
                isDefault: currentTemplate.isDefault
            )
            saveActiveTemplate()
        }
    }
    
    func markCardComplete(_ card: ReflectionCardType) {
        completedCards.insert(card)
    }
    
    func isCardComplete(_ card: ReflectionCardType) -> Bool {
        completedCards.contains(card)
    }
    
    func resetCompletion() {
        completedCards.removeAll()
    }
    
    func getOrderedCards() -> [ReflectionCardType] {
        return ReflectionCardType.allCases.filter {
            currentTemplate.selectedCards.contains($0)
        }
    }
    
    var isReflectionComplete: Bool {
        !getOrderedCards().contains { !completedCards.contains($0) }
    }
    
    // MARK: - Private Helpers
    
    private func saveTemplates() {
        if let encoded = try? JSONEncoder().encode(savedTemplates) {
            UserDefaults.standard.set(encoded, forKey: templateKey)
        }
    }
    
    private func saveActiveTemplate() {
        if let encoded = try? JSONEncoder().encode(currentTemplate) {
            UserDefaults.standard.set(encoded, forKey: activeTemplateKey)
        }
    }
}
