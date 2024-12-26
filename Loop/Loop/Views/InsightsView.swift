//
//  InsightsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/7/24.
//

import SwiftUI
import Charts

struct InsightsView: View {
    @ObservedObject var analysisManager: AnalysisManager = AnalysisManager.shared
    @State private var selectedSection: InsightSection = .today
    @State private var selectedFollowUp: FollowUp?
    @State private var animateContent = false
    
    // Colors
    private let accentColor = Color(hex: "A28497")
    private let backgroundColor = Color(hex: "FAFBFC")
    private let textColor = Color(hex: "2C3E50")
    
    enum InsightSection: String, CaseIterable {
        case today = "today"
        case trends = "trends"
        case review = "review"
        
        var title: String {
            rawValue.capitalized
        }
    }
    
    var body: some View {
        ZStack {
            // Elegant flowing background
            FlowingBackground(color: accentColor)
                .opacity(0.05)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerSection
                    .padding(.top, 16)
                    .padding(.horizontal, 24)
                
                // Section Picker
                sectionPicker
                    .padding(.top, 32)
                    .padding(.horizontal, 24)
                
                // Main Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        switch selectedSection {
                        case .today:
                            TodayInsightsContent(
                                analysisManager: analysisManager,
                                selectedFollowUp: $selectedFollowUp
                            )
                        case .trends:
                            TrendsInsightsView(analysisManager: analysisManager)
                        case .review:
//                            WeekInReviewView(analysisManager: analysisManager)
                            Text("coming soon")
                        }
                    }
                    .padding(.top, 32)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateContent = true
            }
        }
        .fullScreenCover(item: $selectedFollowUp) { followUp in
            RecordFollowUpLoopView(prompt: followUp.prompt)
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Insights")
                .font(.custom("PPNeueMontreal-Medium", size: 40))
                .foregroundColor(textColor)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
            
            Text("Your reflection patterns")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(textColor.opacity(0.6))
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var sectionPicker: some View {
        HStack(spacing: 24) {
            ForEach(InsightSection.allCases, id: \.self) { section in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedSection = section
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(section.title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(
                                selectedSection == section ?
                                textColor : textColor.opacity(0.5)
                            )
                        
                        // Indicator line
                        Rectangle()
                            .fill(selectedSection == section ? accentColor : Color.clear)
                            .frame(height: 2)
                            .cornerRadius(1)
                    }
                }
            }
            
            Spacer()
        }
    }
}

struct TodayInsightsContent: View {
    @ObservedObject var analysisManager: AnalysisManager
    @Binding var selectedFollowUp: FollowUp?
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 32) {
            switch analysisManager.analysisState {
            case .completed(let analysis):
                // AI Analysis Card
                aiAnalysisCard
                    .transition(.opacity)
                
                if let followUp = analysis.aiAnalysis?.followUp {
                    FollowUpCard(
                        followUpQuestion: followUp,
                        onRecordTapped: {
                            selectedFollowUp = FollowUp(id: UUID().uuidString, prompt: followUp)
                        }
                    )
                }
                
                // Speaking Patterns Section
                VStack(alignment: .leading, spacing: 16) {
                    sectionHeader("Speaking Patterns")
                    
                    VStack(spacing: 16) {
                        SpeakingRhythmCard(analysis: analysis)
                        DurationCard(analysis: analysis)
                        VocabularyCard(analysis: analysis)
                        ExpressionCard(analysis: analysis)
                    }
                }
                
                // Focus Section
                VStack(alignment: .leading, spacing: 16) {
                    sectionHeader("Focus & Reflection")
                    
                    VStack(spacing: 16) {
                        ActionReflectionCard(analysis: analysis)
                        SolutionFocusCard(analysis: analysis)
                        ThematicConnectionCard(analysis: analysis)
                    }
                }
                
            case .analyzing, .transcribing, .analyzing_ai:
                AnalyzingStateCard(state: analysisManager.analysisState)
                
            case .noLoops:
                EmptyStateCard(message: analysisManager.analysisState.description)
                
            case .partial(let count):
                PartialAnalysisCard(completedLoops: count)
                
            case .failed(let error):
                ErrorCard(error: error)
            }
        }
    }
    
    private var aiAnalysisCard: some View {
        InsightCard {
            VStack(alignment: .leading, spacing: 24) {
                // Card Label
                HStack(spacing: 8) {
                    Circle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 6, height: 6)
                        .overlay(
                            Circle()
                                .fill(accentColor)
                                .frame(width: 3, height: 3)
                        )
                    
                    Text("AI ANALYSIS")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(accentColor)
                        .tracking(1)
                }
                
                if let analysis = analysisManager.currentDailyAnalysis?.aiAnalysis {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(analysis.feeling.capitalized)
                            .font(.custom("PPNeueMontreal-Medium", size: 36))
                            .foregroundColor(textColor)
                        
                        Text(analysis.feelingDescription)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(textColor.opacity(0.7))
                            .lineSpacing(4)
                    }
                } else {
                    Text("Analyzing your responses...")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(textColor.opacity(0.7))
                }
            }
        }
    }
    
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .regular))
            .foregroundColor(textColor.opacity(0.5))
            .tracking(0.5)
    }
}

struct InsightCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.03), radius: 15, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "A28497").opacity(0.08), lineWidth: 0.5)
            )
    }
}

struct FollowUpCard: View {
    let followUpQuestion: String
    let onRecordTapped: () -> Void
    @ObservedObject private var analysisManager = AnalysisManager.shared
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        InsightCard {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 8) {
                    Circle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 6, height: 6)
                        .overlay(
                            Circle()
                                .fill(accentColor)
                                .frame(width: 3, height: 3)
                        )
                    
                    Text("FOLLOW UP")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(accentColor)
                        .tracking(1)
                    
                    Spacer()
                    
                    if analysisManager.isFollowUpCompletedToday {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(accentColor)
                    }
                }
                
                Text(followUpQuestion)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(textColor)
                    .lineSpacing(4)
                    .opacity(analysisManager.isFollowUpCompletedToday ? 0.6 : 1)
                
                Button(action: onRecordTapped) {
                    HStack(spacing: 8) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 16))
                        Text(analysisManager.isFollowUpCompletedToday ? "Recorded" : "Record Now")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(analysisManager.isFollowUpCompletedToday ? accentColor.opacity(0.5) : accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                }
                .disabled(analysisManager.isFollowUpCompletedToday)
            }
        }
        .opacity(analysisManager.isFollowUpCompletedToday ? 0.8 : 1)
    }
}

struct ExpressionCard: View {
    let analysis: DailyAnalysis
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        InsightCard {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Expression Length")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(textColor)
                    
                    Text("Average words per response")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(textColor.opacity(0.6))
                }
                
                HStack(alignment: .top, spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(Int(analysis.aggregateMetrics.averageWordCount))")
                            .font(.custom("PPNeueMontreal-Medium", size: 34))
                            .foregroundColor(textColor)
                        
                        Text("words")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(textColor.opacity(0.6))
                    }
                    
                    Text(getExpressionDescription(analysis.aggregateMetrics.averageWordCount))
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(textColor.opacity(0.7))
                        .lineSpacing(4)
                }
                
                // Word Count Visualization
                ProgressBarView(
                    value: min(analysis.aggregateMetrics.averageWordCount / 200, 1),
                    accentColor: accentColor
                )
            }
        }
    }
    
    private func getExpressionDescription(_ wordCount: Double) -> String {
        if wordCount > 200 {
            return "You're expressing thoughts very thoroughly today"
        } else if wordCount > 150 {
            return "Your responses show substantial development"
        } else if wordCount > 100 {
            return "You're finding a good balance of detail"
        } else {
            return "You're being clear and concise today"
        }
    }
}

struct SpeakingRhythmCard: View {
    let analysis: DailyAnalysis
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        InsightCard {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Speaking Rhythm")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(textColor)
                    
                    Text("A measure of your natural speaking pace")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(textColor.opacity(0.6))
                }
                
                // Data and Description
                HStack(alignment: .top, spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(Int(analysis.aggregateMetrics.averageWPM))")
                            .font(.custom("PPNeueMontreal-Medium", size: 34))
                            .foregroundColor(textColor)
                        
                        Text("words/min")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(textColor.opacity(0.6))
                    }
                    
                    Text(getWPMDescription(analysis.aggregateMetrics.averageWPM))
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(textColor.opacity(0.7))
                        .lineSpacing(4)
                }
                
                // Waveform Visualization
                InsightsWaveformView(value: analysis.aggregateMetrics.averageWPM)
            }
        }
    }
    
    private func getWPMDescription(_ wpm: Double) -> String {
        if wpm > 150 {
            return "Your speech flows quickly and energetically today"
        } else if wpm > 120 {
            return "You're expressing yourself at a lively pace today"
        } else if wpm > 90 {
            return "Your pace is natural and conversational today"
        } else if wpm > 60 {
            return "You're taking time to choose words carefully"
        } else {
            return "Your pace today is measured and deliberate"
        }
    }
}

struct DurationCard: View {
    let analysis: DailyAnalysis
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        InsightCard {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Speaking Duration")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(textColor)
                    
                    Text("Time spent on each reflection")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(textColor.opacity(0.6))
                }
                
                HStack(alignment: .top, spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatDuration(analysis.aggregateMetrics.averageDuration))
                            .font(.custom("PPNeueMontreal-Medium", size: 34))
                            .foregroundColor(textColor)
                        
                        Text("average")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(textColor.opacity(0.6))
                    }
                    
                    Text(getDurationDescription(analysis.aggregateMetrics.averageDuration))
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(textColor.opacity(0.7))
                        .lineSpacing(4)
                }
                
                // Duration Bar Visualization
                ProgressBarView(
                    value: min(analysis.aggregateMetrics.averageDuration / 300, 1),
                    accentColor: accentColor
                )
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return seconds == 0 ? "\(minutes)m" : "\(minutes)m \(seconds)s"
    }
    
    private func getDurationDescription(_ duration: TimeInterval) -> String {
        let minutes = duration / 60
        if minutes > 5 {
            return "You're taking time for in-depth exploration today"
        } else if minutes > 3 {
            return "Your responses show thorough development today"
        } else if minutes > 2 {
            return "You're balancing detail and conciseness well"
        } else {
            return "You're keeping responses clear and focused"
        }
    }
}

struct VocabularyCard: View {
    let analysis: DailyAnalysis
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        InsightCard {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Vocabulary Range")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(textColor)
                    
                    Text("Diversity of word choice")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(textColor.opacity(0.6))
                }
                
                HStack(alignment: .top, spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(Int(analysis.aggregateMetrics.averageUniqueWordCount))")
                            .font(.custom("PPNeueMontreal-Medium", size: 34))
                            .foregroundColor(textColor)
                        
                        Text("unique words")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(textColor.opacity(0.6))
                    }
                    
                    Text(getVocabularyDescription(analysis.aggregateMetrics.vocabularyDiversityRatio))
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(textColor.opacity(0.7))
                        .lineSpacing(4)
                }
                
                // Vocabulary Diversity Bar
                ProgressBarView(
                    value: analysis.aggregateMetrics.vocabularyDiversityRatio,
                    accentColor: accentColor
                )
            }
        }
    }
    
    private func getVocabularyDescription(_ ratio: Double) -> String {
        if ratio > 0.8 {
            return "Your vocabulary range is exceptionally diverse today"
        } else if ratio > 0.6 {
            return "You're using a broad range of words in your responses"
        } else if ratio > 0.4 {
            return "Your word choice shows good variety"
        } else {
            return "You're using focused, consistent language"
        }
    }
}

// Reusable Components
struct InsightsWaveformView: View {
    let value: Double
    
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<30) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(accentColor.opacity(0.3))
                    .frame(width: 2, height: getHeight(for: i))
            }
        }
        .frame(height: 50)
    }
    
    private func getHeight(for index: Int) -> CGFloat {
        let baseHeight = CGFloat(20)
        let amplitude = min(value / 150, 1.0) * 20
        return baseHeight + CGFloat(sin(Double(index) * 0.3) * amplitude)
    }
}

struct ProgressBarView: View {
    let value: Double
    let accentColor: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(accentColor.opacity(0.2))
                    .frame(height: 4)
                    .cornerRadius(2)
                
                Rectangle()
                    .fill(accentColor)
                    .frame(width: geometry.size.width * value, height: 4)
                    .cornerRadius(2)
            }
        }
        .frame(height: 4)
    }
}

struct ActionReflectionCard: View {
    let analysis: DailyAnalysis
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        InsightCard {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Action vs Reflection")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(textColor)
                    
                    Text("Balance between doing and thinking")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(textColor.opacity(0.6))
                }
                
                HStack(alignment: .top, spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(analysis.aiAnalysis?.actionReflectionRatio ?? "")
                            .font(.custom("PPNeueMontreal-Medium", size: 34))
                            .foregroundColor(textColor)
                        
                        Text("action/reflection")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(textColor.opacity(0.6))
                    }
                    
                    Text(analysis.aiAnalysis?.actionReflectionDescription ?? "")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(textColor.opacity(0.7))
                        .lineSpacing(4)
                }
                
                // Balance Visualization
                BalanceBarView(ratio: getActionRatio(from: analysis.aiAnalysis?.actionReflectionRatio))
            }
        }
    }
    
    private func getActionRatio(from ratio: String?) -> Double {
        guard let ratio = ratio else { return 0.5 }
        let components = ratio.split(separator: "/")
        guard components.count == 2,
              let action = Double(components[0]),
              let reflection = Double(components[1]) else {
            return 0.5
        }
        let total = action + reflection
        return action / total
    }
}

struct SolutionFocusCard: View {
    let analysis: DailyAnalysis
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        InsightCard {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Solution Focus")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(textColor)
                    
                    Text("How you approach challenges")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(textColor.opacity(0.6))
                }
                
                HStack(alignment: .top, spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(analysis.aiAnalysis?.solutionFocus ?? "")
                            .font(.custom("PPNeueMontreal-Medium", size: 34))
                            .foregroundColor(textColor)
                        
                        Text("solution/problem")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(textColor.opacity(0.6))
                    }
                    
                    Text(analysis.aiAnalysis?.solutionFocusDescription ?? "")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(textColor.opacity(0.7))
                        .lineSpacing(4)
                }
                
                // Solution Focus Visualization
                SolutionFocusView(ratio: getSolutionRatio(from: analysis.aiAnalysis?.solutionFocus))
            }
        }
    }
    
    private func getSolutionRatio(from ratio: String?) -> Double {
        guard let ratio = ratio else { return 0.5 }
        let components = ratio.split(separator: "/")
        guard components.count == 2,
              let solution = Double(components[0]),
              let problem = Double(components[1]) else {
            return 0.5
        }
        let total = solution + problem
        return solution / total
    }
}

struct ThematicConnectionCard: View {
    let analysis: DailyAnalysis
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        InsightCard {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Thematic Connections")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(textColor)
                    
                    Text("Patterns across your reflections")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(textColor.opacity(0.6))
                }
                
                HStack(alignment: .top, spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(Int((analysis.overlapAnalysis.overallSimilarity) * 100))%")
                            .font(.custom("PPNeueMontreal-Medium", size: 34))
                            .foregroundColor(textColor)
                        
                        Text("connection strength")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(textColor.opacity(0.6))
                    }
                    
                    Text(getConnectionDescription(analysis.overlapAnalysis.overallSimilarity))
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(textColor.opacity(0.7))
                        .lineSpacing(4)
                }
                
                // Connection Visualization
                ConnectionVisualization(strength: analysis.overlapAnalysis.overallSimilarity)
            }
        }
    }
    
    private func getConnectionDescription(_ similarity: Double) -> String {
        if similarity > 0.8 {
            return "Your reflections show strong thematic unity today"
        } else if similarity > 0.6 {
            return "Clear patterns emerge across your responses"
        } else if similarity > 0.4 {
            return "Your thoughts show moderate connectivity"
        } else {
            return "Each reflection brings unique perspectives"
        }
    }
}

// Supporting Visualizations
struct BalanceBarView: View {
    let ratio: Double
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background bar
                Rectangle()
                    .fill(accentColor.opacity(0.2))
                    .frame(height: 4)
                    .cornerRadius(2)
                
                // Progress bar
                Rectangle()
                    .fill(accentColor)
                    .frame(width: geometry.size.width * ratio, height: 4)
                    .cornerRadius(2)
                
                // Center indicator
                Rectangle()
                    .fill(accentColor.opacity(0.5))
                    .frame(width: 2, height: 8)
                    .position(x: geometry.size.width / 2, y: 2)
            }
        }
        .frame(height: 4)
    }
}

struct SolutionFocusView: View {
    let ratio: Double
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background circle
                Circle()
                    .stroke(accentColor.opacity(0.2), lineWidth: 4)
                
                // Progress arc
                Circle()
                    .trim(from: 0, to: ratio)
                    .stroke(accentColor, lineWidth: 4)
                    .rotationEffect(.degrees(-90))
            }
        }
        .frame(height: 40)
    }
}

struct ConnectionVisualization: View {
    let strength: Double
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        HStack(spacing: 20) {
            ForEach(0..<3) { i in
                Circle()
                    .stroke(accentColor.opacity(0.2), lineWidth: 1)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .fill(accentColor.opacity(strength))
                            .frame(width: 6, height: 6)
                    )
            }
        }
    }
}

struct AnalyzingStateCard: View {
    let state: AnalysisState
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        InsightCard {
            VStack(spacing: 16) {
                Text(state.description)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(textColor)
                
                // Animated dots
                PulsingDotsView()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        }
    }
}

struct PulsingDotsView: View {
    @State private var animating = false
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(accentColor)
                    .frame(width: 8, height: 8)
                    .opacity(animating ? 0.3 : 0.7)
                    .animation(
                        Animation
                            .easeInOut(duration: 0.8)
                            .repeatForever()
                            .delay(Double(i) * 0.2),
                        value: animating
                    )
            }
        }
        .onAppear {
            animating = true
        }
    }
}

struct EmptyStateCard: View {
    let message: String
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        InsightCard {
            VStack(spacing: 16) {
                Image(systemName: "square.text.square")
                    .font(.system(size: 32))
                    .foregroundColor(accentColor)
                
                Text(message)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                
                Text("Your insights will appear here after recording reflections")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(textColor.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        }
    }
}

struct PartialAnalysisCard: View {
    let completedLoops: Int
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        InsightCard {
            VStack(spacing: 24) {
                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(accentColor.opacity(0.2), lineWidth: 4)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(completedLoops) / 3.0)
                        .stroke(accentColor, lineWidth: 4)
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(completedLoops)/3")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(textColor)
                }
                
                VStack(spacing: 8) {
                    Text("Reflections in Progress")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(textColor)
                    
                    Text("Complete all three reflections to see your full insights")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(textColor.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        }
    }
}

struct ErrorCard: View {
    let error: AnalysisError
    
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        InsightCard {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 32))
                    .foregroundColor(.orange)
                
                VStack(spacing: 8) {
                    Text("Analysis Error")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(textColor)
                    
                    Text(getErrorMessage())
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(textColor.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                
                Button(action: {
                    // Add retry functionality here
                }) {
                    Text("Try Again")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: "A28497"))
                        .cornerRadius(22)
                }
                .padding(.top, 8)
            }
            .padding(.vertical, 24)
        }
    }
    
    private func getErrorMessage() -> String {
        switch error {
        case .transcriptionFailed(let message):
            return "Unable to process audio: \(message)"
        case .analysisFailure(let error):
            return "Analysis error: \(error.localizedDescription)"
        case .aiAnalysisFailed(let message):
            return "AI analysis failed: \(message)"
        case .invalidData(let details):
            return "Invalid data: \(details)"
        case .missingFields(let fields):
            return "Missing required data: \(fields.joined(separator: ", "))"
        }
    }
}

//extension AnalysisState {
//    var description: String {
//        switch self {
//        case .analyzing:
//            return "Analyzing your reflections..."
//        case .transcribing:
//            return "Processing your audio..."
//        case .analyzing_ai:
//            return "Generating insights..."
//        case .noLoops:
//            return "No reflections recorded yet"
//        case .partial(let count):
//            return "\(count) of 3 reflections completed"
//        case .completed:
//            return "Analysis complete"
//        case .failed(let error):
//            return "Error: \(error.localizedDescription)"
//        }
//    }
//}

struct TrendsInsightsView: View {
    @ObservedObject var analysisManager: AnalysisManager
    @State private var selectedPeriod = "week"
    @State private var selectedMetric: GraphData.MetricType = .wpm
    @State private var showingMetricPicker = false
    
    private let accentColor = Color(hex: "A28497")
    private let backgroundColor = Color(hex: "FAFBFC")
    private let surfaceColor = Color(hex: "F8F5F7")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Period Selector
                HStack(spacing: 24) {
                    ForEach(["week", "month", "year"], id: \.self) { period in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedPeriod = period
                            }
                            Task {
                                await loadDataForPeriod()
                            }
                        }) {
                            Text(period.capitalized)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(selectedPeriod == period ? textColor : textColor.opacity(0.5))
                        }
                    }
                }
                
                // Graph Section
                VStack(alignment: .leading, spacing: 16) {
                    // Metric Value and Selector
                    HStack(alignment: .center) {
                        // Current Value Display
                        VStack(alignment: .leading, spacing: 4) {
                           Text("\(selectedPeriod.capitalized) Average")
                               .font(.system(size: 13, weight: .medium))
                               .foregroundColor(textColor.opacity(0.6))
                           if let currentValue = getCurrentValue() {
                               Text(formatValue(currentValue, for: selectedMetric))
                                   .font(.system(size: 28, weight: .bold))
                                   .foregroundColor(textColor)
                           }
                           
                           Text(selectedMetric.rawValue)
                               .font(.system(size: 13, weight: .medium))
                               .foregroundColor(textColor.opacity(0.6))
                       }
                        
                        Spacer()
                        
                        // Metric Selector Capsule
                        Button(action: {
                            withAnimation {
                                showingMetricPicker.toggle()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Text(selectedMetric.shortName)
                                    .font(.system(size: 14, weight: .medium))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundColor(textColor.opacity(0.8))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(surfaceColor)
                            .clipShape(Capsule())
                        }
                        .confirmationDialog("Select Metric", isPresented: $showingMetricPicker) {
                            ForEach(GraphData.MetricType.allCases, id: \.self) { metric in
                                Button(metric.rawValue) {
                                    withAnimation {
                                        selectedMetric = metric
                                    }
                                }
                            }
                        }
                    }
                    
                    // Graph View
                    ZStack {
                        if isLoading {
                            ProgressView()
                        } else if let graphData = createGraphData() {
                            CleanGraphView(data: graphData)
                                .frame(height: 300)
                        } else {
                            Text("No data available")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(textColor.opacity(0.6))
                        }
                    }
                    .frame(height: 300)
                }
                .padding(24)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                if selectedPeriod == "week" {
                    TrendWidgets(analysisManager: analysisManager, period: "week")
                } else if selectedPeriod == "month" {
                    TrendWidgets(analysisManager: analysisManager, period: "month")
                } else {
                    TrendWidgets(analysisManager: analysisManager, period: "year")
                }
            }
            .task {
                await loadDataForPeriod()
            }
        }
    }
    
    private var isLoading: Bool {
        switch selectedPeriod {
        case "week": return analysisManager.isLoadingWeekStats
        case "month": return analysisManager.isLoadingMonthStats
        case "year": return analysisManager.isLoadingYearStats
        default: return false
        }
    }
    
    private func getCurrentValue() -> Double? {
        switch selectedPeriod {
        case "week":
            let stats = analysisManager.currentWeekStats
            guard !stats.isEmpty else { return nil }
            let sum = stats.reduce(0.0) { total, stat in
                switch selectedMetric {
                case .wpm: return total + stat.averageWPM
                case .duration: return total + stat.averageDuration
                case .wordCount: return total + stat.averageWordCount
                case .uniqueWords: return total + stat.averageUniqueWordCount
                case .selfReferences: return total + stat.averageSelfReferences
                case .vocabularyDiversity: return total + stat.vocabularyDiversityRatio
                }
            }
            return sum / Double(stats.count)
            
        case "month":
            let stats = analysisManager.currentMonthWeeklyStats
            guard !stats.isEmpty else { return nil }
            let sum = stats.reduce(0.0) { total, stat in
                switch selectedMetric {
                case .wpm: return total + stat.averageWPM
                case .duration: return total + stat.averageDuration
                case .wordCount: return total + stat.averageWordCount
                case .uniqueWords: return total + stat.averageUniqueWordCount
                case .selfReferences: return total + stat.averageSelfReferences
                case .vocabularyDiversity: return total + stat.vocabularyDiversityRatio
                }
            }
            return sum / Double(stats.count)
            
        case "year":
            let stats = analysisManager.currentYearMonthlyStats
            guard !stats.isEmpty else { return nil }
            let sum = stats.reduce(0.0) { total, stat in
                switch selectedMetric {
                case .wpm: return total + stat.averageWPM
                case .duration: return total + stat.averageDuration
                case .wordCount: return total + stat.averageWordCount
                case .uniqueWords: return total + stat.averageUniqueWordCount
                case .selfReferences: return total + stat.averageSelfReferences
                case .vocabularyDiversity: return total + stat.vocabularyDiversityRatio
                }
            }
            return sum / Double(stats.count)
            
        default:
            return nil
        }
    }
    
    private func formatValue(_ value: Double, for metric: GraphData.MetricType) -> String {
        switch metric {
        case .wpm:
            return String(format: "%.1f", value)
        case .duration:
            let minutes = Int(value) / 60
            let seconds = Int(value) % 60
            return seconds == 0 ? "\(minutes)m" : "\(minutes)m \(seconds)s"
        case .wordCount, .uniqueWords, .selfReferences:
            return String(format: "%.0f", value)
        case .vocabularyDiversity:
            return String(format: "%.1f%%", value * 100)
        }
    }
    
    private func createGraphData() -> GraphData? {
        switch selectedPeriod {
        case "week":
            return createWeekGraphData()
        case "month":
            return createMonthGraphData()
        case "year":
            return createYearGraphData()
        default:
            return nil
        }
    }
    
    private func createWeekGraphData() -> GraphData? {
        let stats = analysisManager.currentWeekStats
        guard !stats.isEmpty else { return nil }
        
        let points = stats.map { stat in
            GraphPoint(
                date: stat.date ?? Date(),
                value: getValue(from: stat),
                label: "" // Will be formatted by GraphData
            )
        }
        
        return GraphData(points: points, metric: selectedMetric, period: .week)
    }
    
    private func createMonthGraphData() -> GraphData? {
        let stats = analysisManager.currentMonthWeeklyStats
        guard !stats.isEmpty else { return nil }
        
        let points = stats.map { stat in
            GraphPoint(
                date: stat.lastUpdated ?? Date(),
                value: getValue(from: stat),
                label: "" // Will be formatted by GraphData
            )
        }
        
        return GraphData(points: points, metric: selectedMetric, period: .month)
    }
    
    private func createYearGraphData() -> GraphData? {
        let stats = analysisManager.currentYearMonthlyStats
        guard !stats.isEmpty else { return nil }
        
        let points = stats.map { stat in
            GraphPoint(
                date: stat.lastUpdated ?? Date(),
                value: getValue(from: stat),
                label: "" // Will be formatted by GraphData
            )
        }
        
        return GraphData(points: points, metric: selectedMetric, period: .year)
    }
    
    private func getValue(from stat: DailyStats) -> Double {
        switch selectedMetric {
        case .wpm: return stat.averageWPM
        case .duration: return stat.averageDuration
        case .wordCount: return stat.averageWordCount
        case .uniqueWords: return stat.averageUniqueWordCount
        case .selfReferences: return stat.averageSelfReferences
        case .vocabularyDiversity: return stat.vocabularyDiversityRatio
        }
    }
    
    private func getValue(from stat: WeeklyStats) -> Double {
        switch selectedMetric {
        case .wpm: return stat.averageWPM
        case .duration: return stat.averageDuration
        case .wordCount: return stat.averageWordCount
        case .uniqueWords: return stat.averageUniqueWordCount
        case .selfReferences: return stat.averageSelfReferences
        case .vocabularyDiversity: return stat.vocabularyDiversityRatio
        }
    }
    
    private func getValue(from stat: MonthlyStats) -> Double {
        switch selectedMetric {
        case .wpm: return stat.averageWPM
        case .duration: return stat.averageDuration
        case .wordCount: return stat.averageWordCount
        case .uniqueWords: return stat.averageUniqueWordCount
        case .selfReferences: return stat.averageSelfReferences
        case .vocabularyDiversity: return stat.vocabularyDiversityRatio
        }
    }
    
    private func loadDataForPeriod() async {
        switch selectedPeriod {
        case "week":
            await analysisManager.fetchCurrentWeekStats()
        case "month":
            await analysisManager.fetchCurrentMonthWeeklyStats()
        case "year":
            await analysisManager.fetchCurrentYearMonthlyStats()
        default:
            break
        }
    }
}

struct TrendWidgets: View {
    @ObservedObject var analysisManager: AnalysisManager
    let period: String // "week", "month", or "year"
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("speaking patterns")
                
                VStack(spacing: 3) {
                    // Speaking Rhythm (WPM)
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Speaking Rhythm")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(textColor)
                                
                                Spacer()
                            }
                            
                            HStack {
                                Text("Average speaking pace")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(textColor.opacity(0.6))
                                
                                Spacer()
                            }
                        }
                        
                        HStack(alignment: .top, spacing: 24) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(Int(getAverageWPM()))")
                                    .font(.system(size: 34, weight: .medium))
                                    .foregroundColor(textColor)
                                
                                Text("words/min")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(textColor.opacity(0.6))
                            }
                            
                            Text(getWPMDescription())
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(textColor.opacity(0.7))
                                .lineSpacing(4)
                        }
                        
                        waveformView
                    }
                    .padding(24)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Duration
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Speaking Duration")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(textColor)
                            
                            Text("Average reflection length")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(textColor.opacity(0.6))
                        }
                        
                        HStack(alignment: .top, spacing: 24) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(formatDuration(getAverageDuration()))
                                    .font(.system(size: 34, weight: .medium))
                                    .foregroundColor(textColor)
                                
                                Text("average")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(textColor.opacity(0.6))
                            }
                            
                            Text(getDurationDescription())
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(textColor.opacity(0.7))
                                .lineSpacing(4)
                        }
                        
                        durationBar
                    }
                    .padding(24)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Self References
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Self References")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(textColor)
                            
                            Text("Personal experience expression")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(textColor.opacity(0.6))
                        }
                        
                        HStack(alignment: .top, spacing: 24) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(Int(getAverageSelfReferences()))")
                                    .font(.system(size: 34, weight: .medium))
                                    .foregroundColor(textColor)
                                
                                Text("mentions")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(textColor.opacity(0.6))
                            }
                            
                            Text(getSelfReferencesDescription())
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(textColor.opacity(0.7))
                                .lineSpacing(4)
                        }
                        
                        selfReferenceIndicators
                    }
                    .padding(24)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("language patterns")
                
                VStack(spacing: 3) {
                    // Unique Words
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Vocabulary Range")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(textColor)
                            
                            Text("Distinct words used")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(textColor.opacity(0.6))
                        }
                        
                        HStack(alignment: .top, spacing: 24) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(Int(getAverageUniqueWords()))")
                                    .font(.system(size: 34, weight: .medium))
                                    .foregroundColor(textColor)
                                
                                Text("unique words")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(textColor.opacity(0.6))
                            }
                            
                            Text(getUniqueWordsDescription())
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(textColor.opacity(0.7))
                                .lineSpacing(4)
                        }
                    }
                    .padding(24)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }
    
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .regular))
            .foregroundColor(textColor.opacity(0.5))
            .tracking(0.5)
    }
    
    // Visual Elements
    private var waveformView: some View {
        HStack(spacing: 3) {
            ForEach(0..<30) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(accentColor.opacity(0.3))
                    .frame(width: 2, height: CGFloat(sin(Double(i) * 0.3) * 20 + 25))
            }
        }
        .frame(height: 50)
    }
    
    private var durationBar: some View {
        GeometryReader { geometry in
            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(accentColor.opacity(0.2))
                        .frame(height: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .fill(accentColor)
                                .frame(width: geometry.size.width / 3 * 0.8)
                                .offset(x: CGFloat(i) * 4),
                            alignment: .leading
                        )
                }
            }
        }
        .frame(height: 4)
    }
    
    private var selfReferenceIndicators: some View {
        HStack(spacing: 12) {
            ForEach(0..<min(Int(getAverageSelfReferences()), 5)) { _ in
                Circle()
                    .fill(accentColor.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
    
    // Data Functions
    private func getAverageWPM() -> Double {
        let stats = getStatsForPeriod()
        return stats.reduce(0.0) { $0 + $1.averageWPM } / Double(max(1, stats.count))
    }
    
    private func getAverageDuration() -> Double {
        let stats = getStatsForPeriod()
        return stats.reduce(0.0) { $0 + $1.averageDuration } / Double(max(1, stats.count))
    }
    
    private func getAverageSelfReferences() -> Double {
        let stats = getStatsForPeriod()
        return stats.reduce(0.0) { $0 + $1.averageSelfReferences } / Double(max(1, stats.count))
    }
    
    private func getAverageUniqueWords() -> Double {
        let stats = getStatsForPeriod()
        return stats.reduce(0.0) { $0 + $1.averageUniqueWordCount } / Double(max(1, stats.count))
    }
    
    private func getStatsForPeriod() -> [any StatsProtocol] {
        switch period {
        case "week":
            return analysisManager.currentWeekStats
        case "month":
            return analysisManager.currentMonthWeeklyStats
        case "year":
            return analysisManager.currentYearMonthlyStats
        default:
            return []
        }
    }
    
    // Formatting Functions
    private func formatDuration(_ duration: Double) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return seconds == 0 ? "\(minutes)m" : "\(minutes)m \(seconds)s"
    }
    
    private func getWPMDescription() -> String {
        let averageWPM = getAverageWPM()
        switch period {
        case "week":
            if averageWPM > 150 {
                return "Your reflections this week show a rapid speaking pace"
            } else if averageWPM > 120 {
                return "You're speaking at a brisk, energetic pace this week"
            } else if averageWPM > 90 {
                return "Your speaking pace this week is conversational and natural"
            } else if averageWPM > 60 {
                return "You're taking your time to express thoughts this week"
            } else {
                return "Your pace this week is slow and deliberate"
            }
            
        case "month":
            if averageWPM > 150 {
                return "This month shows consistently quick verbal expression"
            } else if averageWPM > 120 {
                return "Your monthly pace trends toward energetic speech"
            } else if averageWPM > 90 {
                return "Your monthly average shows natural conversational speed"
            } else if averageWPM > 60 {
                return "This month shows a measured speaking rhythm"
            } else {
                return "Your monthly pace emphasizes careful word choice"
            }
            
        case "year":
            if averageWPM > 150 {
                return "Your yearly pattern shows naturally quick expression"
            } else if averageWPM > 120 {
                return "You tend toward lively, energetic speech this year"
            } else if averageWPM > 90 {
                return "Your yearly pace stays conversationally fluid"
            } else if averageWPM > 60 {
                return "Your yearly trend shows measured, thoughtful speech"
            } else {
                return "You consistently take time to choose words carefully"
            }
        default: return ""
        }
    }

    private func getDurationDescription() -> String {
        let avgDuration = getAverageDuration()
        let minutes = avgDuration / 60
        
        switch period {
        case "week":
            if minutes > 5 {
                return "Your reflections this week are extensively detailed"
            } else if minutes > 3 {
                return "You're taking good time to develop thoughts this week"
            } else if minutes > 2 {
                return "Your responses this week are concise but complete"
            } else {
                return "You're keeping reflections brief and focused this week"
            }
            
        case "month":
            if minutes > 5 {
                return "This month shows consistently detailed responses"
            } else if minutes > 3 {
                return "Your monthly pattern shows thorough reflection time"
            } else if minutes > 2 {
                return "Monthly responses maintain focused brevity"
            } else {
                return "You're staying succinct in monthly reflections"
            }
            
        case "year":
            if minutes > 5 {
                return "You tend toward detailed exploration this year"
            } else if minutes > 3 {
                return "Your yearly responses show steady thoroughness"
            } else if minutes > 2 {
                return "You maintain efficient expression this year"
            } else {
                return "Your yearly pattern favors quick, focused thoughts"
            }
        default: return ""
        }
    }

    private func getSelfReferencesDescription() -> String {
        let avg = getAverageSelfReferences()
        switch period {
        case "week":
            if avg > 15 {
                return "Reflections this week are highly self-focused"
            } else if avg > 10 {
                return "You're drawing strongly from personal experience"
            } else if avg > 5 {
                return "Your responses balance self-reference and context"
            } else {
                return "This week's focus tends toward external perspectives"
            }
            
        case "month":
            if avg > 15 {
                return "Monthly pattern shows frequent self-reference"
            } else if avg > 10 {
                return "Personal perspective features strongly this month"
            } else if avg > 5 {
                return "You mix personal and external views monthly"
            } else {
                return "Monthly focus leans toward external observation"
            }
            
        case "year":
            if avg > 15 {
                return "Your yearly style emphasizes personal perspective"
            } else if avg > 10 {
                return "Self-reference is a key part of your expression"
            } else if avg > 5 {
                return "You balance personal and external views yearly"
            } else {
                return "Your yearly focus tends toward external contexts"
            }
        default: return ""
        }
    }

    private func getUniqueWordsDescription() -> String {
        let avg = getAverageUniqueWords()
        switch period {
        case "week":
            if avg > 100 {
                return "Your vocabulary range this week is notably broad"
            } else if avg > 75 {
                return "You're using varied language in reflections"
            } else if avg > 50 {
                return "Your word choice shows moderate variety"
            } else {
                return "You're working with a focused vocabulary set"
            }
            
        case "month":
            if avg > 100 {
                return "Monthly vocabulary shows significant range"
            } else if avg > 75 {
                return "Your monthly language use is nicely varied"
            } else if avg > 50 {
                return "Word choice shows consistent variety monthly"
            } else {
                return "You maintain a focused vocabulary this month"
            }
            
        case "year":
            if avg > 100 {
                return "Your yearly pattern shows extensive vocabulary"
            } else if avg > 75 {
                return "You maintain good word variety this year"
            } else if avg > 50 {
                return "Yearly vocabulary shows steady range"
            } else {
                return "You work with a consistent core vocabulary"
            }
        default: return ""
        }
    }
    
}
extension AnalysisManager {
    static var mock: AnalysisManager {
        let manager = AnalysisManager()
        
        // Mock LoopAnalysis
        let mockLoop = LoopAnalysis(
            id: UUID().uuidString,
            timestamp: Date(),
            promptText: "Describe your day",
            category: "Reflection", transcript: "",
            metrics: LoopMetrics(
                duration: 180.0,
                wordCount: 120,
                uniqueWordCount: 80,
                wordsPerMinute: 40.0,
                selfReferenceCount: 10,
                uniqueSelfReferenceCount: 2,
                averageWordLength: 4.5
            ),
            wordAnalysis: WordAnalysis(
                words: ["today", "was", "great", "I", "went", "to", "the", "park"],
                uniqueWords: ["today", "great", "park"],
                mostUsedWords: [
                    WordCount(word: "today", count: 5),
                    WordCount(word: "great", count: 4),
                    WordCount(word: "park", count: 3)
                ],
                selfReferenceTypes: ["I", "myself"]
            )
        )
        
        let mockDailyAnalysis = DailyAnalysis(
            date: Date(),
            loops: [mockLoop, mockLoop, mockLoop],
            aggregateMetrics: AggregateMetrics(
                averageDuration: 180.0,
                averageWordCount: 120.0,
                averageUniqueWordCount: 80.0,
                averageWPM: 40.0,
                averageSelfReferences: 10.0,
                vocabularyDiversityRatio: 0.67
            ),
            wordPatterns: WordPatterns(
                totalUniqueWords: ["today", "great", "park"],
                wordsInAllResponses: ["today", "great"],
                mostUsedWords: [
                    WordCount(word: "today", count: 15),
                    WordCount(word: "great", count: 12)
                ]
            ),
            overlapAnalysis: OverlapAnalysis(
                pairwiseOverlap: ["1-2": 0.75, "1-3": 0.60],
                commonWords: ["1-2": ["today", "great"]],
                overallSimilarity: 0.65
            ),
            rangeAnalysis: RangeAnalysis(
                wpmRange: MinMaxRange(min: 35.0, max: 45.0),
                durationRange: MinMaxRange(min: 160.0, max: 200.0),
                wordCountRange: IntRange(min: 110, max: 130),
                selfReferenceRange: IntRange(min: 8, max: 12)
            ),
            aiAnalysis: AIAnalysisResult(
                feeling: "Contemplative",
                feelingDescription: "Your reflections today show deep introspection and thoughtful consideration of personal experiences",
                tense: "Present",
                tenseDescription: "You're focused on understanding your current state of mind",
                selfReferenceCount: 12,
                followUp: "How do these moments of reflection influence your daily choices?",
                actionReflectionRatio: "30/70",
                actionReflectionDescription: "You spend more time in thought than planning next steps",
                solutionFocus: "40/60",
                solutionFocusDescription: "Your responses explore situations more than seeking solutions"
            )
        )
        
        manager.currentDailyAnalysis = mockDailyAnalysis
        manager.todaysLoops = [mockLoop, mockLoop, mockLoop]
        manager.weeklyComparison = LoopComparison(
            date: Date(),
            pastLoopDate: Date().addingTimeInterval(-7 * 24 * 60 * 60),
            durationComparison: MetricComparison(direction: .increase, percentageChange: 10.0),
            wpmComparison: MetricComparison(direction: .increase, percentageChange: 5.0),
            wordCountComparison: MetricComparison(direction: .decrease, percentageChange: 3.0),
            uniqueWordComparison: MetricComparison(direction: .increase, percentageChange: 8.0),
            vocabularyDiversityComparison: MetricComparison(direction: .increase, percentageChange: 15.0),
            averageWordLengthComparison: MetricComparison(direction: .same, percentageChange: 0.0),
            selfReferenceComparison: MetricComparison(direction: .decrease, percentageChange: 2.0),
            similarityScore: 0.75,
            commonWords: ["today", "great"]
        )
        
        return manager
    }
}

struct InsightWavyBackground: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: 0, y: height * 0.5))
        
        // Create a flowing, wavy path
        path.addCurve(
            to: CGPoint(x: width, y: height * 0.5),
            control1: CGPoint(x: width * 0.3, y: height * 0.35),
            control2: CGPoint(x: width * 0.7, y: height * 0.65)
        )
        
        // Complete the shape
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

// Preview
struct InsightsView_Previews: PreviewProvider {
    static var previews: some View {
        InsightsView(analysisManager: AnalysisManager.mock)
            .previewDevice("iPhone 14 Pro")
            .previewDisplayName("Insights View")
    }
}



struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, frame) in result.frames {
            let position = CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY)
            subviews[index].place(at: position, proposal: ProposedViewSize(frame.size))
        }
    }
    
    struct FlowResult {
        var size: CGSize
        var frames: [Int: CGRect]
        
        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var height: CGFloat = 0
            var maxWidth: CGFloat = 0
            var x: CGFloat = 0
            var y: CGFloat = 0
            var row: CGFloat = 0
            var frames = [Int: CGRect]()
            
            for (index, subview) in subviews.enumerated() {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > width {
                    x = 0
                    y += row + spacing
                    row = 0
                }
                
                frames[index] = CGRect(x: x, y: y, width: size.width, height: size.height)
                row = max(row, size.height)
                x += size.width + spacing
                maxWidth = max(maxWidth, x)
                height = max(height, y + row)
            }
            
            self.size = CGSize(width: maxWidth, height: height)
            self.frames = frames
        }
    }
}
    
struct ErrorView: View {
    let error: AnalysisError
    let textColor: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("Error Occurred")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(textColor)
                
                Text(getRawErrorMessage())
                    .font(.system(size: 14))
                    .foregroundColor(textColor.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func getRawErrorMessage() -> String {
        switch error {
        case .transcriptionFailed(let message):
            return "Transcription Error: \(message)"
        case .analysisFailure(let underlyingError):
            return String(describing: underlyingError)
        case .aiAnalysisFailed(let apiError):
            return "API Error: \(apiError)"
        case .invalidData(let details):
            return "Data Error: \(details)"
        case .missingFields(let fields):
            return "Missing fields: \(fields.joined(separator: ", "))"
        }
    }
}
