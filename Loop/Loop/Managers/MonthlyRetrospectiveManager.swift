//
//  MonthlyRetrospectiveView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 3/16/25.
//

import SwiftUI
import AVKit

class MonthlyRetrospectiveManager: ObservableObject {
    static let shared = MonthlyRetrospectiveManager()
    
    @Published var isLoading = false
    @Published var currentSection = 0
    @Published var monthReflections: [Loop] = []
    @Published var topEmotions: [(emotion: String, percentage: Double)] = []
    @Published var insightsText = ""
    @Published var monthlyThemes: [String] = []
    @Published var nextMonthIntentions: [String] = [""]

    let sectionTitles = [
        "Month in Review",
        "Emotional Patterns",
        "Key Moments",
        "Insights & Learnings",
        "Next Month Intentions"
    ]
    
    private let loopManager = LoopManager.shared
    private let premiumManager = PremiumManager.shared
    
    func loadMonthData() async {
        // Only proceed if user is premium
        guard premiumManager.isUserPremium() else { return }
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let calendar = Calendar.current
            let today = Date()
            let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: today)!
            
            // Fetch data from the past month
            let monthLoops = try await loopManager.fetchLoopsForDateRange(start: oneMonthAgo, end: today)
            
            // Generate insights based on the past month
            await generateInsights(from: monthLoops)
            
            await MainActor.run {
                monthReflections = monthLoops
                isLoading = false
            }
        } catch {
            print("Error loading month data: \(error)")
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func generateInsights(from loops: [Loop]) async {
        // This would ideally use more sophisticated analysis
        // For now, we'll keep it simple
        
        let emotions = [
            ("feeling great", 35.0),
            ("pretty good", 25.0),
            ("okay", 20.0),
            ("not great", 15.0),
            ("feeling down", 5.0)
        ]
        
        let themes = [
            "Work-life balance",
            "Personal growth",
            "Health & wellness",
            "Creativity"
        ]
        
        // Sample insights text
        let insights = "This month showed significant growth in your self-awareness. Your reflections were most positive when discussing personal achievements and creative pursuits. There's a pattern of increased positivity in the mornings."
        
        await MainActor.run {
            self.topEmotions = emotions
            self.monthlyThemes = themes
            self.insightsText = insights
        }
    }
    
    func saveIntentions() {
        // In a real implementation, this would save the intentions
        // For this example, we'll just print them
        print("Saving intentions: \(nextMonthIntentions)")
    }
}

