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
        let mockLoopAnalysis = LoopAnalysis(
            id: "1",
            timestamp: Date(),
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
            selfReference: SelfReferenceAnalysis(
                frequency: "moderate",
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
            date: Date(),
            loops: [mockLoopAnalysis, mockLoopAnalysis, mockLoopAnalysis],
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
#endif

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
