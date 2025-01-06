//
//  AnalysisManagerPreview.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/27/24.
//

import Foundation
import SwiftUI

import Foundation
import SwiftUI

#if DEBUG
extension AnalysisManager {
    static var preview: AnalysisManager {
        let manager = AnalysisManager()
        
        // Use a fixed date for previews
        let fixedDate = Calendar.current.date(from: DateComponents(year: 2024, month: 12, day: 27))!
        
        let mockLoopAnalysis = LoopAnalysis(
            id: UUID().uuidString,
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
                emotion: "thoughtful",
                description: "You are taking time to carefully consider and reflect on your experiences"
            ),
            expression: ExpressionStyle(
                fillerWords: "minimal",
                pattern: "analytical",
                note: "You express yourself with clarity and precision"
            ),
            social: SocialLandscape(
                focus: "balanced",
                context: "personal",
                connections: "You maintain a healthy balance between personal growth and relationships with others"
            ),
            nextSteps: NextSteps(
                actions: [
                    "Schedule time for meditation practice",
                    "Write down three goals for the week",
                    "Reach out to mentor for guidance"
                ],
                hasActions: true
            ),
            challenges: Challenges(
                items: [
                    "Finding balance between work and personal time",
                    "Maintaining consistent meditation practice"
                ],
                hasChallenges: true
            ),
            followUp: FollowUp(
                question: "How might you apply today's insights to tomorrow's challenges?",
                purpose: "To help you build on your current momentum and growth mindset"
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
        manager.analysisState = .completed(mockDailyAnalysis)
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
