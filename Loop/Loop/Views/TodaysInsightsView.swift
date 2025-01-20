//
//  TodaysInsightsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/27/24.
//

import SwiftUI

struct TodaysInsightsView: View {
    @ObservedObject var analysisManager = AnalysisManager.shared
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    private let lightMauve = Color(hex: "D5C5CC")
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                switch analysisManager.analysisState {
                case .notStarted:
                    ProgressStateView(
                        icon: "pencil.circle",
                        title: "REFLECTIONS NEEDED",
                        description: "Complete your daily reflection to see insights",
                        accentColor: accentColor,
                        textColor: textColor
                    )
                case .retrievingResponses, .analyzingQuantitative, .analyzingAI:
                    ProgressStateView(
                        icon: "gear",
                        title: "ANALYZING",
                        description: "Processing your reflections",
                        isLoading: true,
                        accentColor: accentColor,
                        textColor: textColor
                    )
                case .completed(let analysis):
                    analysisContent(analysis)
                case .failed(let error):
                    ProgressStateView(
                        icon: "exclamationmark.circle",
                        title: "ANALYSIS UNAVAILABLE",
                        description: error.description,
                        accentColor: accentColor,
                        textColor: textColor
                    )
                }
            }
            .padding(24)
        }
        .background(Color(hex: "F5F5F5"))
    }
    
    private func analysisContent(_ analysis: DailyAnalysis) -> some View {
        VStack(spacing: 12) {
            VStack(spacing: 24) {
                HStack {
                    Text("TODAY'S INSIGHTS")
                        .font(.system(size: 13, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(textColor.opacity(0.5))
                    
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    // Words count card
                    MetricCard(
                        value: "\(analysis.quantitativeMetrics.totalWordCount)",
                        label: "WORDS",
                        sublabel: getWordCountDescription(analysis.quantitativeMetrics.totalWordCount),
                        icon: "text.word.spacing",
                        color: accentColor
                    )


                    MetricCard(
                        value: analysis.quantitativeMetrics.totalDurationSeconds < 60
                            ? String(format: "%.0f", analysis.quantitativeMetrics.totalDurationSeconds)
                            : String(format: "%.0f", analysis.quantitativeMetrics.totalDurationSeconds / 60),
                        label: analysis.quantitativeMetrics.totalDurationSeconds < 60 ? "SECONDS" : "MINUTES",
                        sublabel: getDurationDescription(analysis.quantitativeMetrics.totalDurationSeconds),
                        icon: "clock",
                        color: accentColor
                    )
                }
            }
            
            // Mood Section
            if let mood = analysis.aiAnalysis.mood.rating {
                MoodInsightCard(rating: mood, sleep: analysis.aiAnalysis.mood.sleep)
            }
            
            FollowUpCard(followUp: analysis.aiAnalysis.followUp)
            
            // Expression Analysis
            if !analysis.aiAnalysis.expression.topics.isEmpty {
                TopicsCard(topics: analysis.aiAnalysis.expression.topics)
            }
            
            // Key Moments Section
            if !analysis.aiAnalysis.notableElements.isEmpty {
                KeyMomentsCard(elements: analysis.aiAnalysis.notableElements)
            } else {
                EmptyKeyMomentsCard()
            }

        }
    }
    
    private func getWordCountDescription(_ count: Int) -> String {
        if count > 250 {
            return "Very detailed reflection"
        } else if count > 175 {
            return "Good depth of expression"
        } else if count > 100 {
            return "Clear and concise thoughts"
        } else {
            return "Brief reflection"
        }
    }
    
    private func getDurationDescription(_ seconds: Double) -> String {
        let minutes = seconds / 60
        if minutes >= 1.5 { // 90+ seconds
            return "In-depth reflection"
        } else if minutes >= 1.0 { // 60-89 seconds
            return "Good reflection time"
        } else if minutes >= 0.75 { // 45-59 seconds
            return "Focused reflection"
        } else {
            return "Quick check-in" // Less than 45 seconds
        }
    }
}

struct MetricCard: View {
    let value: String
    let label: String
    let sublabel: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color.opacity(0.6))
                
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(color.opacity(0.6))
            }
            .frame(height: 20)
            
            Text(value)
                .font(.system(size: 32, weight: .light))
                .foregroundColor(Color(hex: "2C3E50"))
                .frame(height: 38)
            
            Text(sublabel)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "2C3E50").opacity(0.6))
                .lineLimit(2)
                .frame(height: 36, alignment: .top)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 100)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 4)
        )
    }
}

struct MoodInsightCard: View {
    let rating: Double
    let sleep: Int?
    private let textColor = Color(hex: "2C3E50")
    
    private var moodColor: Color {
        if rating <= 5 {
            return Color(hex: "1E3D59") // Sad color
        } else if rating <= 7 {
            return Color(hex: "94A7B7") // Neutral color
        } else {
            return Color(hex: "B784A7") // Happy color
        }
    }
    
    private var moodDescription: String {
        if rating <= 3 {
            return "feeling down"
        } else if rating <= 4 {
            return "not great"
        } else if rating <= 6 {
            return "okay"
        } else if rating <= 8 {
            return "pretty good"
        } else {
            return "feeling great"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("MOOD & ENERGY")
                .font(.system(size: 13, weight: .medium))
                .tracking(1.5)
                .foregroundColor(textColor.opacity(0.5))
            
            HStack(spacing: 24) {
                // Mood indicator
                Circle()
                    .fill(moodColor)
                    .frame(width: 64, height: 64)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .shadow(color: moodColor.opacity(0.2), radius: 10)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(moodDescription)
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(textColor)
                    
                    if let sleep = sleep {
                        Text("\(sleep) hours of sleep")
                            .font(.system(size: 14))
                            .foregroundColor(textColor.opacity(0.6))
                    }
                }
                
                Spacer()
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 4)
        )
    }
}

struct TopicsCard: View {
    let topics: Set<TopicCategory>
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("TOPICS DISCUSSED")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.5))
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(topics), id: \.self) { topic in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(accentColor.opacity(0.2))
                            .frame(width: 8, height: 8)
                        
                        Text(topic.rawValue)
                            .font(.system(size: 16))
                            .foregroundColor(textColor)
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 4)
        )
    }
}

struct KeyMomentsCard: View {
    let elements: [NotableElement]
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("KEY MOMENTS")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.5))
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(elements.enumerated()), id: \.element.content) { index, element in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(element.type.rawValue.uppercased())
                            .font(.system(size: 11, weight: .medium))
                            .tracking(1.5)
                            .foregroundColor(accentColor)
                        
                        Text(element.content)
                            .font(.system(size: 16))
                            .foregroundColor(textColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 12)
                    
                    if index < elements.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 4)
        )
    }
}

struct EmptyKeyMomentsCard: View {
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("KEY MOMENTS")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.5))
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                    .foregroundColor(textColor.opacity(0.3))
                
                Text("No key moments identified today")
                    .font(.system(size: 16))
                    .foregroundColor(textColor.opacity(0.6))
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 4)
        )
    }
}

struct FollowUpCard: View {
    let followUp: FollowUp
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    @State private var selectedFollowUp: FollowUp?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(accentColor)
                
                Text("NEXT REFLECTION")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.5))
            }
            
            Text(followUp.question)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(textColor)
            
            Text(followUp.purpose)
                .font(.system(size: 14))
                .foregroundColor(textColor.opacity(0.8))
                .lineSpacing(8)
        }
        .disabled(AnalysisManager.shared.isFollowUpCompletedToday)
        .opacity(AnalysisManager.shared.isFollowUpCompletedToday == true ? 0.5 : 1.0)
        .onTapGesture {
            selectedFollowUp = followUp
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.white
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(accentColor.opacity(0.1), lineWidth: 1)
                )
        )
        .fullScreenCover(item: $selectedFollowUp) { followUp in
            RecordFollowUpLoopView(prompt: followUp.question)
       }
    }
}

struct TodaysInsightsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Empty State
            TodaysInsightsView(analysisManager: mockManager(with: .notStarted))
                .previewDisplayName("Empty State")
            
            // Processing State
            TodaysInsightsView(analysisManager: mockManager(with: .analyzingAI))
                .previewDisplayName("Processing")
            
            // Completed State with Full Data
            TodaysInsightsView(analysisManager: mockManager(with: .completed(mockAnalysis())))
                .previewDisplayName("Complete - Full Data")
            
            // Completed State with Partial Data
            TodaysInsightsView(analysisManager: mockManager(with: .completed(mockPartialAnalysis())))
                .previewDisplayName("Complete - Partial Data")
            
            // Error State
            TodaysInsightsView(analysisManager: mockManager(with: .failed(.noResponses)))
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
