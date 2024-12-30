//
//  TodaysInsightsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/27/24.
//

import SwiftUI

struct TodaysInsightsView: View {
    @ObservedObject private var analysisManager: AnalysisManager
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    // Secondary accent for depth and contrast
    private let secondaryAccent = Color(hex: "84A297")
    
    @State private var selectedQuote: String?
    @State private var backgroundOpacity = 0.2
    
    @State private var selectedFollowUp: FollowUp?
    
    init(analysisManager: AnalysisManager = .shared) {
        self.analysisManager = analysisManager
    }
    
    var body: some View {
        ZStack {
            Color(hex: "F5F5F5")
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    switch analysisManager.analysisState {
                    case .noLoops:
                        ProgressStateView(
                            icon: "mic.circle.fill",
                            title: "Complete Your Daily Reflection",
                            description: "Record all three of your daily loops to get insights",
                            progress: 0,
                            accentColor: accentColor,
                            textColor: textColor
                        )
                        
                    case .partial(let count):
                        ProgressStateView(
                            icon: "waveform.circle.fill",
                            title: "Recording in Progress",
                            description: "Complete \(3 - count) more loops to see your insights",
                            progress: Float(count) / 3.0,
                            accentColor: accentColor,
                            textColor: textColor
                        )
                        
                    case .analyzing:
                        ProgressStateView(
                            icon: "sparkles.circle.fill",
                            title: "Analyzing Your Reflections",
                            description: "Creating personalized insights from your loops",
                            isLoading: true,
                            accentColor: accentColor,
                            textColor: textColor
                        )
                        
                    case .completed(let analysis):
                        if let analysis = analysis.aiAnalysis {
                            VStack(spacing: 16) {
                                ThemeSection(analysis: analysis)
                                FollowUpView(followUp: analysis.followUp)
                                    .onTapGesture {
                                        selectedFollowUp = analysis.followUp
                                    }
                            }
                            PatternsView(analysis: analysis)
                        }
                        
                        if let metrics = analysisManager.currentDailyAnalysis?.aggregateMetrics {
                            MetricsGallery(metrics: metrics)
                        }
                        
                        if let loops = analysisManager.currentDailyAnalysis?.loops {
                            LoopsTimeline(loops: loops)
                        }
                        
                    case .failed(let error):
                        ErrorStateView(
                            error: error,
                            accentColor: accentColor,
                            textColor: textColor
                        )
                    case .transcribing:
                        ProgressStateView(
                            icon: "sparkles.circle.fill",
                            title: "Transcribing your responses",
                            description: "Creating personalized insights from your loops",
                            isLoading: true,
                            accentColor: accentColor,
                            textColor: textColor
                        )
                    case .analyzing_ai:
                        ProgressStateView(
                            icon: "sparkles.circle.fill",
                            title: "Performing AI Analysis",
                            description: "Creating personalized insights from your loops",
                            isLoading: true,
                            accentColor: accentColor,
                            textColor: textColor
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .fullScreenCover(item: $selectedFollowUp) { followUp in
            RecordFollowUpLoopView(prompt: followUp.question)
       }
    }
}

struct ThemeSection: View {
    let analysis: AIAnalysisResult
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            
            // Main content
            VStack(alignment: .leading, spacing: 16) {
                Text(analysis.emotion.primary)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(textColor)
                
                Text(analysis.emotion.description)
                    .font(.system(size: 16))
                    .lineSpacing(8)
                    .foregroundColor(textColor.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(
            ZStack {
                Color.white
                WavyBackground()
            }
            .cornerRadius(16)
        )
    }
}

struct QuotesGallery: View {
    let phrases: SignificantPhrases
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    private let secondaryAccent = Color(hex: "84A297")
    
    private struct CategoryQuotes {
        let icon: String
        let label: String
        let quotes: [String]
        let color: Color
    }
    
    private var categorizedQuotes: [CategoryQuotes] {
        [
            CategoryQuotes(
                icon: "lightbulb.circle.fill",
                label: "INSIGHTS",
                quotes: phrases.insightPhrases,
                color: accentColor
            ),
            CategoryQuotes(
                icon: "circle.fill",
                label: "REFLECTIONS",
                quotes: phrases.reflectionPhrases,
                color: secondaryAccent
            ),
            CategoryQuotes(
                icon: "arrow.right.circle.fill",
                label: "DECISIONS",
                quotes: phrases.decisionPhrases,
                color: accentColor.opacity(0.8)
            )
        ].filter { !$0.quotes.isEmpty }
    }
    
    @ViewBuilder
    var body: some View {
        if !categorizedQuotes.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text("memorable moments")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(textColor)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(categorizedQuotes, id: \.label) { category in
                            QuoteCategoryCard(
                                icon: category.icon,
                                label: category.label,
                                quotes: category.quotes,
                                color: category.color
                            )
                        }
                    }

                }
            }
        }
    }
}

struct QuoteCategoryCard: View {
    let icon: String
    let label: String
    let quotes: [String]
    let color: Color
    
    private let textColor = Color(hex: "2C3E50")
    private let standardHeight: CGFloat = 130
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.5))
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            
            // Quotes
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(quotes, id: \.self) { quote in
                        Text("\"\(quote)\"")
                            .font(.system(size: 15))
                            .foregroundColor(textColor.opacity(0.8))
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .frame(width: 300, height: standardHeight)
        .background(
            Color.white
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct PatternsView: View {
    let analysis: AIAnalysisResult
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    private let secondaryAccent = Color(hex: "84A297")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("perspective")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(textColor)
                
                
                Spacer()
            }
            
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 8, height: 8)
                        
                        Text("TIME")
                            .font(.system(size: 11, weight: .medium))
                            .tracking(1.5)
                            .foregroundColor(textColor.opacity(0.5))
                    }
                    
                    Text(analysis.timeFocus.orientation.rawValue.capitalized)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(textColor)
                }
                
                Rectangle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 1)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(secondaryAccent)
                            .frame(width: 8, height: 8)
                        
                        Text("SELF")
                            .font(.system(size: 11, weight: .medium))
                            .tracking(1.5)
                            .foregroundColor(textColor.opacity(0.5))
                    }
                    
                    Text(analysis.focus.pattern)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(textColor)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.cornerRadius(16))
            
//            Text(analysis.timeFocus.description)
//                .font(.system(size: 14))
//                .foregroundColor(textColor.opacity(0.8))
//                .lineSpacing(8)
//                .padding(.horizontal, 4)
        }
    }
}

struct MetricsGallery: View {
    let metrics: AggregateMetrics
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    private let secondaryAccent = Color(hex: "84A297")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("expression")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(textColor)
            
            VStack(spacing: 12) {
                MetricCard(
                    value: metrics.averageWPM,
                    label: "average speaking pace",
                    description: paceDescription(wpm: metrics.averageWPM),
                    valueFormat: "%.0f",
                    unit: "wpm",
                    color: accentColor
                )
                
                MetricCard(
                    value: metrics.averageDuration,
                    label: "average duration",
                    description: durationDescription(seconds: metrics.averageDuration),
                    valueFormat: "%.0f",
                    unit: "sec",
                    color: secondaryAccent
                )
                
                MetricCard(
                    value: metrics.averageWordCount,
                    label: "average expression length",
                    description: wordCountDescription(count: metrics.averageWordCount),
                    valueFormat: "%.0f",
                    unit: "words",
                    color: accentColor.opacity(0.8)
                )
            }
            .padding(20)
            .background(Color.white.cornerRadius(16))
        }
    }
    
    private func paceDescription(wpm: Double) -> String {
        switch wpm {
        case ..<80:
            return "Taking time to carefully consider each thought"
        case 80..<100:
            return "Speaking at a measured, reflective pace"
        case 100..<130:
            return "Natural conversational rhythm"
        default:
            return "Quick, energetic expression of ideas"
        }
    }
    
    private func durationDescription(seconds: Double) -> String {
        switch seconds {
        case ..<10:
            return "Brief, focused thoughts"
        case 10..<20:
            return "Concise reflection style"
        case 20..<25:
            return "Balanced expression length"
        default:
            return "Taking time to fully explore thoughts"
        }
    }
    
    private func wordCountDescription(count: Double) -> String {
        switch count {
        case ..<20:
            return "Direct and precise expression"
        case 20..<35:
            return "Clear, focused reflection"
        case 35..<50:
            return "Detailed exploration of thoughts"
        default:
            return "Rich, expansive expression style"
        }
    }
}

struct MetricCard: View {
    let value: Double
    let label: String
    let description: String
    let valueFormat: String
    let unit: String
    let color: Color
    
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with label
            HStack {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .textCase(.uppercase)
                    .foregroundColor(textColor.opacity(0.5))
                    .tracking(0.5)
                Spacer()
            }
            .padding(.bottom, 8)
            
            // Value and unit
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(String(format: valueFormat, value))
                    .font(.system(size: 22, weight: .medium))
                Text(unit)
                    .font(.system(size: 12))
                    .foregroundColor(textColor.opacity(0.6))
                Spacer()
            }
            .padding(.bottom, 8)
            
            // Description
            HStack {
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(textColor.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct LoopsTimeline: View {
    let loops: [LoopAnalysis]
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("daily loops")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(textColor)
                
                
                Spacer()
            }
            VStack(spacing: 24) {
                ForEach(loops) { loop in
                    LoopTimelineItem(loop: loop)
                }
            }
        }
    }
}

struct LoopTimelineItem: View {
    let loop: LoopAnalysis
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 0) {
                Circle()
                    .fill(accentColor)
                    .frame(width: 12, height: 12)
                
                if loop.id != "lastLoop" {
                    Rectangle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 2)
                        .frame(height: 40)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text(formatTime(loop.timestamp))
                    .font(.system(size: 12))
                    .foregroundColor(textColor.opacity(0.5))
                
                Text(loop.promptText)
                    .font(.system(size: 16))
                    .foregroundColor(textColor)
                
                HStack(spacing: 16) {
                    MetricPill(value: String(format: "%.0f", loop.metrics.wordsPerMinute), unit: "wpm")
                    MetricPill(value: String(format: "%.1f", loop.metrics.duration/60), unit: "min")
                    MetricPill(value: String(format: "%.0f", loop.metrics.wordCount), unit: "words")
                }
            }
            
            Spacer()
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date).lowercased()
    }
}

struct MetricPill: View {
    let value: String
    let unit: String
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.system(size: 14, weight: .medium))
            Text(unit)
                .font(.system(size: 14))
        }
        .foregroundColor(textColor.opacity(0.6))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(hex: "F8F9FA").cornerRadius(16))
    }
}

struct FollowUpView: View {
    let followUp: FollowUp
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
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
            
            Text(followUp.context)
                .font(.system(size: 14))
                .foregroundColor(textColor.opacity(0.8))
                .lineSpacing(8)
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
    }
}

#if DEBUG
struct TodaysInsightsView_Previews: PreviewProvider {
    static var previews: some View {
        TodaysInsightsView(analysisManager: .preview)
    }
}
#endif


