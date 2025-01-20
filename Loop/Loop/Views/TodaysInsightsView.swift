//
//  TodaysInsightsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/27/24.
//

import SwiftUI

struct TodayInsightsView: View {
    @ObservedObject var analysisManager = AnalysisManager.shared
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    private let lightMauve = Color(hex: "D5C5CC")
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                switch analysisManager.analysisState {
                case .notStarted:
                    EmptyAnalysisView()
                case .retrievingResponses, .analyzingQuantitative, .analyzingAI:
                    ProcessingView()
                case .completed(let analysis):
                    AnalysisContentView(analysis: analysis)
                case .failed(let error):
                    AnalysisErrorView(error: error)
                }
            }
            .padding(24)
        }
        .background(Color(hex: "F5F5F5"))
    }
}

struct EmptyAnalysisView: View {
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    private let lightMauve = Color(hex: "D5C5CC")
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        lightMauve.opacity(0.3),
                        Color.white.opacity(0.9)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                GeometricMountains()
                    .fill(accentColor)
                    .opacity(0.2)
                    .frame(height: 120)
                    .offset(y: 40)
                
                VStack(spacing: 16) {
                    Text("COMPLETE YOUR REFLECTION")
                        .font(.system(size: 13, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(textColor.opacity(0.5))
                    
                    Text("Record your daily reflection to see insights")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(textColor)
                        .multilineTextAlignment(.center)
                }
                .padding(32)
            }
            .frame(height: 240)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct ProcessingView: View {
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(spacing: 16) {
            WavePattern()
                .fill(accentColor.opacity(0.7))
                .frame(height: 60)
            
            ProgressView()
                .scaleEffect(1.5)
                .tint(accentColor)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 240)
    }
}

struct AnalysisContentView: View {
    let analysis: DailyAnalysis
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    private let lightMauve = Color(hex: "D5C5CC")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            // Mood and Sleep Section
            if let rating = analysis.aiAnalysis.mood.rating {
                VStack(alignment: .leading, spacing: 24) {
                    dayOverview(rating: rating, sleep: analysis.aiAnalysis.mood.sleep)
                    
                    if !analysis.aiAnalysis.expression.topics.isEmpty {
                        topicsList(topics: analysis.aiAnalysis.expression.topics)
                    }
                }
            }
            
            // Notable Elements Section (if any exist)
            if !analysis.aiAnalysis.notableElements.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("KEY MOMENTS")
                        .font(.system(size: 13, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(textColor.opacity(0.5))
                    
                    ForEach(analysis.aiAnalysis.notableElements, id: \.content) { element in
                        keyMomentRow(element: element)
                    }
                }
            } else {
                emptyKeyMomentsView
            }
            
            // Metrics Section
            metricsOverview(metrics: analysis.quantitativeMetrics)
            
            // Follow-up Section
            followUpPrompt(followUp: analysis.aiAnalysis.followUp)
        }
    }
    
    private var emptyKeyMomentsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("KEY MOMENTS")
                .font(.system(size: 13, weight: .medium))
                .tracking(1.5)
                .foregroundColor(textColor.opacity(0.5))
            
            Text("No key moments recorded today")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(textColor.opacity(0.7))
        }
    }
    
    private func dayOverview(rating: Double, sleep: Int?) -> some View {
        HStack(spacing: 40) {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(String(format: "%.1f", rating))")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(textColor)
                
                Text("TODAY'S MOOD")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.5))
            }
            
            if let sleep = sleep {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(sleep)")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(textColor)
                    
                    Text("HOURS SLEEP")
                        .font(.system(size: 13, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(textColor.opacity(0.5))
                }
            }
        }
    }
    
    private func topicsList(topics: Set<TopicCategory>) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(topics), id: \.self) { topic in
                    Text(topic.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(textColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(lightMauve.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
    }
    
    private func keyMomentRow(element: NotableElement) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(element.type.rawValue.uppercased())
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(accentColor)
            
            Text(element.content)
                .font(.system(size: 16))
                .foregroundColor(textColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 12)
    }
    
    private func metricsOverview(metrics: QuantitativeMetrics) -> some View {
        HStack(spacing: 40) {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(metrics.totalWordCount)")
                    .font(.system(size: 24, weight: .light))
                Text("TOTAL WORDS")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.5))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(String(format: "%.1f", metrics.totalDurationSeconds / 60))
                    .font(.system(size: 24, weight: .light))
                Text("MINUTES")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.5))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(String(format: "%.0f", metrics.averageWordsPerRecording))
                    .font(.system(size: 24, weight: .light))
                Text("WPM")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.5))
            }
        }
    }
    
    private func followUpPrompt(followUp: FollowUp) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NEXT REFLECTION")
                .font(.system(size: 13, weight: .medium))
                .tracking(1.5)
                .foregroundColor(textColor.opacity(0.5))
            
            Text(followUp.question)
                .font(.system(size: 20, weight: .light))
                .foregroundColor(textColor)
        }
    }
}

struct AnalysisErrorView: View {
    let error: AnalysisError
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(spacing: 16) {
            WavePattern()
                .fill(accentColor.opacity(0.2))
                .frame(height: 60)
            
            Text(error.description)
                .font(.system(size: 16))
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
        }
        .frame(height: 240)
    }
}

struct TodayInsightsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Empty State
            TodayInsightsView(analysisManager: mockManager(with: .notStarted))
                .previewDisplayName("Empty State")
            
            // Processing State
            TodayInsightsView(analysisManager: mockManager(with: .analyzingAI))
                .previewDisplayName("Processing")
            
            // Completed State (Full Data)
            TodayInsightsView(analysisManager: mockManager(with: .completed(mockAnalysis())))
                .previewDisplayName("Complete - Full Data")
            
            // Completed State (Partial Data)
            TodayInsightsView(analysisManager: mockManager(with: .completed(mockPartialAnalysis())))
                .previewDisplayName("Complete - Partial Data")
            
            // Error State
            TodayInsightsView(analysisManager: mockManager(with: .failed(.noResponses)))
                .previewDisplayName("Error")
        }
    }
    
    static func mockManager(with state: AnalysisState) -> AnalysisManager {
        let manager = MockAnalysisManager()
        manager.setState(state)
        return manager
    }
    
    static func mockAnalysis() -> DailyAnalysis {
        DailyAnalysis(
            date: Date(),
            quantitativeMetrics: QuantitativeMetrics(
                totalWordCount: 856,
                totalDurationSeconds: 425,
                averageWordsPerRecording: 171.2,
                averageDurationPerRecording: 85
            ),
            aiAnalysis: DailyAIAnalysisResult(
                date: Date(),
                expression: DailyExpression(
                    style: .reflective,
                    topics: [.growth, .wellbeing, .purpose, .creativity],
                    tone: .positive
                ),
                notableElements: [
                    NotableElement(type: .insight, content: "Morning routines significantly impact daily energy"),
                    NotableElement(type: .win, content: "Successfully implemented new project methodology"),
                    NotableElement(type: .challenge, content: "Balancing deep work with team collaboration"),
                    NotableElement(type: .strategy, content: "Breaking large tasks into manageable chunks")
                ],
                mood: MoodCorrelation(rating: 8.5, sleep: 7),
                followUp: FollowUp(
                    question: "How might you build on today's progress?",
                    purpose: "Reinforcing positive patterns"
                )
            )
        )
    }
    
    static func mockPartialAnalysis() -> DailyAnalysis {
        DailyAnalysis(
            date: Date(),
            quantitativeMetrics: QuantitativeMetrics(
                totalWordCount: 856,
                totalDurationSeconds: 425,
                averageWordsPerRecording: 171.2,
                averageDurationPerRecording: 85
            ),
            aiAnalysis: DailyAIAnalysisResult(
                date: Date(),
                expression: DailyExpression(
                    style: .reflective,
                    topics: [], // Empty topics
                    tone: .neutral
                ),
                notableElements: [], // Empty elements
                mood: MoodCorrelation(rating: 7.0, sleep: nil), // No sleep data
                followUp: FollowUp(
                    question: "What would you like to reflect on?",
                    purpose: "Open reflection"
                )
            )
        )
    }
}

class MockAnalysisManager: AnalysisManager {
    private var _mockState: AnalysisState = .notStarted
    
    override var analysisState: AnalysisState {
        get { _mockState }
        set { _mockState = newValue }
    }
    
    func setState(_ state: AnalysisState) {
        _mockState = state
    }
}

