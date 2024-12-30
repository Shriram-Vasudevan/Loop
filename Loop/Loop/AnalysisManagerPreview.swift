//
//  AnalysisManagerPreview.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/27/24.
//

import Foundation
import SwiftUI

#if DEBUG
extension AnalysisManager {
    static var preview: AnalysisManager {
        let manager = AnalysisManager()
        
        // Use a fixed date for previews to ensure consistency
        let fixedDate = Calendar.current.date(from: DateComponents(year: 2024, month: 12, day: 27))!
        
        let mockLoopAnalysis = LoopAnalysis(
            id: UUID().uuidString, // Use UUID for unique IDs
            timestamp: fixedDate,
            promptText: "What's on your mind today?",
            category: "Daily Reflection",
            transcript: "Today has been quite productive...",
            metrics: LoopMetrics(
                duration: 165,
                wordCount: 150,
                uniqueWordCount: 85,
                wordsPerMinute: 128,
                vocabularyDiversity: 0.82
            )
        )
        
        let mockAIAnalysis = AIAnalysisResult(
            emotion: EmotionAnalysis(
                primary: "Contemplative",
                intensity: 8,
                tone: "Balanced",
                description: "Showing thoughtful reflection and careful consideration of experiences."
            ),
            timeFocus: TimeFocus(
                orientation: .future,
                description: "Strong emphasis on future planning while maintaining present awareness."
            ),
            focus: FocusAnalysis(
                pattern: "Growth-Oriented",
                description: "Balanced self-reflection focusing on learning and development."
            ),
            phrases: SignificantPhrases(
                insightPhrases: ["deeper understanding emerged", "patterns became clear"],
                reflectionPhrases: ["moment of realization", "perspective shift"],
                decisionPhrases: ["commit to daily practice"],
                description: "Notable focus on personal growth and systematic improvement."
            ),
            followUp: FollowUp(
                question: "How might you apply today's insights to tomorrow's challenges?",
                context: "Building on demonstrated growth mindset",
                focus: "Future Application"
            )
        )
        
        let mockDailyAnalysis = DailyAnalysis(
            date: fixedDate,
            loops: [
                mockLoopAnalysis,
                mockLoopAnalysis.copy(withNewId: UUID().uuidString),
                mockLoopAnalysis.copy(withNewId: UUID().uuidString)
            ],
            aggregateMetrics: AggregateMetrics(
                averageDuration: 155,
                averageWordCount: 145.0,
                averageWPM: 125.0,
                vocabularyDiversity: 0.85
            ),
            aiAnalysis: mockAIAnalysis
        )
        
        manager.currentDailyAnalysis = mockDailyAnalysis
        return manager
    }
}

extension LoopAnalysis {
    func copy(withNewId newId: String) -> LoopAnalysis {
        LoopAnalysis(
            id: newId,
            timestamp: self.timestamp,
            promptText: self.promptText,
            category: self.category,
            transcript: self.transcript,
            metrics: self.metrics
        )
    }
}


// Preview modifier
struct PreviewAnalysisManager: ViewModifier {
    let manager: AnalysisManager
    
    func body(content: Content) -> some View {
        content
            .environmentObject(manager)
    }
}

extension View {
    func withPreviewAnalysisManager() -> some View {
        modifier(PreviewAnalysisManager(manager: .preview))
    }
}

#endif
