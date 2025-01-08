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
                            title: "COMPLETE YOUR DAILY REFLECTION",
                            description: "Record all three of your daily loops to get insights",
                            progress: 0,
                            accentColor: accentColor,
                            textColor: textColor
                        )
                        
                    case .partial(let count):
                        ProgressStateView(
                            icon: "waveform.circle.fill",
                            title: "RECORDING IN PROGRESS",
                            description: "Complete \(3 - count) more loops to see your insights",
                            progress: Float(count) / 3.0,
                            accentColor: accentColor,
                            textColor: textColor
                        )
                        
                    case .analyzing:
                        ProgressStateView(
                            icon: "sparkles.circle.fill",
                            title: "ANALYZING YOUR RFLECTION",
                            description: "Creating personalized insights from your loops",
                            isLoading: true,
                            accentColor: accentColor,
                            textColor: textColor
                        )
                        
                    case .completed(let analysis):
                        if let analysis = analysis.aiAnalysis {
                            VStack(spacing: 4) {
                                EmotionalStateCard(emotion: analysis.emotion)
                                FollowUpCard(followUp: analysis.followUp)
                                    .onTapGesture {
                                        selectedFollowUp = analysis.followUp
                                    }
                            }
                            
                            VStack(spacing: 12) {
                                Text("YOUR EXPRESSION")
                                    .font(.system(size: 13, weight: .medium))
                                    .tracking(1.5)
                                    .foregroundColor(textColor.opacity(0.5))
                                
                                ExpressionStyleCard(style: analysis.expression)
                            }
                        }
                        
                        
                        if let metrics = analysisManager.currentDailyAnalysis?.aggregateMetrics {
                            VStack(spacing: 12) {
                                Text("OVERALL STATS")
                                    .font(.system(size: 13, weight: .medium))
                                    .tracking(1.5)
                                    .foregroundColor(textColor.opacity(0.5))
                                StatsGrid(metrics: metrics)
                            }
                        }
//                        
                        VStack (spacing: 12) {
                            Text("INDIVIDUAL LOOPS")
                                .font(.system(size: 13, weight: .medium))
                                .tracking(1.5)
                                .foregroundColor(textColor.opacity(0.5))
                            
                            if let loops = analysisManager.currentDailyAnalysis?.loops {
                                LoopsTimeline(loops: loops)
                            }
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
                            title: "TRANSCRIBING YOUR RESPONSES",
                            description: "Creating personalized insights from your loops",
                            isLoading: true,
                            accentColor: accentColor,
                            textColor: textColor
                        )
                    case .analyzing_ai:
                        ProgressStateView(
                            icon: "sparkles.circle.fill",
                            title: "PERFORMING AI ANALYSIS",
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
//        .fullScreenCover(item: $selectedFollowUp) { followUp in
//            RecordFollowUpLoopView(prompt: followUp.question)
//       }
    }
}

struct EmotionalStateCard: View {
    let emotion: EmotionAnalysis
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Current state")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(textColor.opacity(0.6))
                    
                    Text(emotion.emotion.capitalized)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(textColor)
                }
                
                Spacer()
                
                Circle()
                    .fill(accentColor)
                    .frame(width: 8, height: 8)
            }
  
            HStack(spacing: 12) {
                Rectangle()
                    .fill(accentColor)
                    .frame(width: 2)
                
                Text(emotion.description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(textColor.opacity(0.7))
                    .lineSpacing(4)
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct StatsGrid: View {
    let metrics: AggregateMetrics
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                StatBox(
                    value: String(format: "%.0f", metrics.averageWordCount),
                    label: "Average Words", image: "waveform"
                )

                StatBox(
                    value: String(format: "%.0f", metrics.averageWPM),
                    label: "Average WPM", image: "waveform.path"
                )
            }
            
            // Bottom duration box with waveform
            DurationBox(duration: metrics.averageDuration)
        }
    }
}

struct StatBox: View {
    let value: String
    let label: String
    let image: String
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(textColor)
                
                Text(label)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(textColor.opacity(0.6))
            }
            
            Spacer()
            
            if image != "" {
                Image(systemName: image)
                    .foregroundColor(Color(hex: "A28497").opacity(0.5))
                    .font(.system(size: 30))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct DurationBox: View {
    let duration: TimeInterval
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        ZStack {
            HStack {
              Spacer()
              Text("DURATION")
                  .font(.system(size: 48, weight: .bold))
                  .foregroundColor(textColor.opacity(0.1))
                  .padding(.trailing, -8) // Slight overflow
          }
            
            HStack(spacing: 16) {
                // Duration text
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%.0f", duration))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(textColor)
                    
                    Text("second")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(textColor.opacity(0.6))
                }
                
                Spacer()
                
//                // Simple waveform visualization
//                HStack(spacing: 3) {
//                    ForEach(0..<12, id: \.self) { index in
//                        RoundedRectangle(cornerRadius: 1)
//                            .fill(accentColor.opacity(0.3))
//                            .frame(width: 2, height: waveHeight(for: index))
//                    }
//                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private func waveHeight(for index: Int) -> CGFloat {
        let heights: [CGFloat] = [15, 20, 25, 20, 15, 20, 25, 20, 15, 20, 25, 20]
        return heights[index]
    }
}

struct FollowUpCard: View {
    let followUp: FollowUp
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 8) {
                Text("Follow-up")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(textColor.opacity(0.6))
                
                Spacer()
                
                // Small indicator
                Circle()
                    .fill(accentColor)
                    .frame(width: 8, height: 8)
            }
            
            // Question
            Text(followUp.question)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(textColor)
                .lineSpacing(4)
            
            // Purpose with accent line
            HStack(spacing: 12) {
                Rectangle()
                    .fill(accentColor)
                    .frame(width: 2)
                
                Text(followUp.purpose)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(textColor.opacity(0.7))
                    .lineSpacing(4)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct LoopsTimeline: View {
    let loops: [LoopAnalysis]
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(spacing: 24) {
            ForEach(loops) { loop in
                TimelineItem(loop: loop)
            }
        }
    }
}

struct TimelineItem: View {
    let loop: LoopAnalysis
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline dot and line
            VStack(spacing: 0) {
                Circle()
                    .fill(accentColor)
                    .frame(width: 12, height: 12)
                
                if loop.id != "lastLoop" {
                    Rectangle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 2)
                        .frame(height: 60)
                }
            }
            .padding(.top, 8)
            
            // Content
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Text(formatTime(loop.timestamp))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(accentColor.opacity(0.1))
                        )
                    
                    Spacer()
                    
                    MetricRow(metrics: loop.metrics)
                }

                Text(loop.promptText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(textColor)
                    .lineSpacing(4)

                if !loop.transcript.isEmpty {
                    Text(loop.transcript.prefix(100) + (loop.transcript.count > 100 ? "..." : ""))
                        .font(.system(size: 14))
                        .foregroundColor(textColor.opacity(0.6))
                        .lineSpacing(4)
                }
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date).lowercased()
    }
}

struct MetricRow: View {
    let metrics: LoopMetrics
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        HStack(spacing: 12) {
            MetricPill(value: String(metrics.wordCount), unit: "words")
            MetricPill(value: String(format: "%.0f", metrics.duration), unit: "sec")
            MetricPill(value: String(format: "%.0f", metrics.wordsPerMinute), unit: "wpm")
        }
    }
}

struct MetricPill: View {
    let value: String
    let unit: String
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.system(size: 13, weight: .medium))
            Text(unit)
                .font(.system(size: 13, weight: .regular))
        }
        .foregroundColor(textColor.opacity(0.6))
    }
}

struct ExpressionStyleCard: View {
    let style: ExpressionStyle
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Pattern section
            VStack(alignment: .leading, spacing: 6) {
                Text("Communication pattern")
                    .font(.system(size: 12))
                    .foregroundColor(textColor.opacity(0.6))
                
                Text(style.pattern.capitalized)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(textColor)
            }
            
            // Filler words section with visual indicator
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Filler words")
                        .font(.system(size: 12))
                        .foregroundColor(textColor.opacity(0.6))
                    
                    Text(style.fillerWords.capitalized)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(textColor)
                }
                
                Spacer()
//                
//                // Visual indicator for filler word frequency
//                FillerWordIndicator(level: style.fillerWords)
            }
            
            // Insight
            Text(style.note)
                .font(.system(size: 13))
                .foregroundColor(textColor.opacity(0.7))
                .lineSpacing(4)
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.white)
                
                DecorativeBackground()
                    .cornerRadius(10)
                    .scaleEffect(x: 1, y: -1)
            }
        )
    }
}

struct FillerWordIndicator: View {
    let level: String
    private let accentColor = Color(hex: "A28497")
    
    var fillCount: Int {
        switch level.lowercased() {
        case "minimal": return 1
        case "moderate": return 2
        case "frequent": return 3
        default: return 0
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(index < fillCount ? accentColor : accentColor.opacity(0.2))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

//// Preview
//#Preview {
//    EmotionalStateCard(
//        emotion: EmotionAnalysis(
//            emotion: "Thoughtful",
//            description: "You are taking time to carefully consider and reflect on your experiences"
//        )
//    )
//    .padding(24)
//    .background(Color(hex: "F5F5F5"))
//}

//struct ThemeSection: View {
//    let analysis: AIAnalysisResult
//    private let textColor = Color(hex: "2C3E50")
//    private let accentColor = Color(hex: "A28497")
//    
//    var body: some View {
//        HStack(alignment: .top, spacing: 20) {
//            
//            // Main content
//            VStack(alignment: .leading, spacing: 16) {
////                Text(analysis.emotion.primary)
////                    .font(.system(size: 32, weight: .medium))
////                    .foregroundColor(textColor)
////                
//                Text(analysis.emotion.description)
//                    .font(.system(size: 16))
//                    .lineSpacing(8)
//                    .foregroundColor(textColor.opacity(0.8))
//            }
//        }
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .padding(24)
//        .background(
//            ZStack {
//                Color.white
//                WavyBackground()
//            }
//            .cornerRadius(16)
//        )
//    }
//}
//
//
//struct PatternsView: View {
//    let analysis: AIAnalysisResult
//    private let textColor = Color(hex: "2C3E50")
//    private let accentColor = Color(hex: "A28497")
//    private let secondaryAccent = Color(hex: "84A297")
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            HStack {
//                Text("perspective")
//                    .font(.system(size: 14, weight: .medium))
//                    .foregroundColor(textColor)
//                
//                
//                Spacer()
//            }
//            
//            HStack(spacing: 24) {
//                VStack(alignment: .leading, spacing: 12) {
//                    HStack(spacing: 8) {
//                        Circle()
//                            .fill(accentColor)
//                            .frame(width: 8, height: 8)
//                        
//                        Text("TIME")
//                            .font(.system(size: 11, weight: .medium))
//                            .tracking(1.5)
//                            .foregroundColor(textColor.opacity(0.5))
//                    }
//                    
////                    Text(analysis.timeFocus.orientation.rawValue.capitalized)
////                        .font(.system(size: 20, weight: .medium))
////                        .foregroundColor(textColor)
//                }
//                
//                Rectangle()
//                    .fill(accentColor.opacity(0.1))
//                    .frame(width: 1)
//                
//                VStack(alignment: .leading, spacing: 12) {
//                    HStack(spacing: 8) {
//                        Circle()
//                            .fill(secondaryAccent)
//                            .frame(width: 8, height: 8)
//                        
//                        Text("SELF")
//                            .font(.system(size: 11, weight: .medium))
//                            .tracking(1.5)
//                            .foregroundColor(textColor.opacity(0.5))
//                    }
////                    
////                    Text(analysis.focus.pattern)
////                        .font(.system(size: 20, weight: .medium))
////                        .foregroundColor(textColor)
//                }
//            }
//            .padding(24)
//            .frame(maxWidth: .infinity, alignment: .leading)
//            .background(Color.white.cornerRadius(16))
//            
////            Text(analysis.timeFocus.description)
////                .font(.system(size: 14))
////                .foregroundColor(textColor.opacity(0.8))
////                .lineSpacing(8)
////                .padding(.horizontal, 4)
//        }
//    }
//}
//
//struct MetricsGallery: View {
//    let metrics: AggregateMetrics
//    private let textColor = Color(hex: "2C3E50")
//    private let accentColor = Color(hex: "A28497")
//    private let secondaryAccent = Color(hex: "84A297")
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            Text("expression")
//                .font(.system(size: 14, weight: .medium))
//                .foregroundColor(textColor)
//            
//            VStack(spacing: 12) {
//                MetricCard(
//                    value: metrics.averageWPM,
//                    label: "average speaking pace",
//                    description: paceDescription(wpm: metrics.averageWPM),
//                    valueFormat: "%.0f",
//                    unit: "wpm",
//                    color: accentColor
//                )
//                
//                MetricCard(
//                    value: metrics.averageDuration,
//                    label: "average duration",
//                    description: durationDescription(seconds: metrics.averageDuration),
//                    valueFormat: "%.0f",
//                    unit: "sec",
//                    color: secondaryAccent
//                )
//                
//                MetricCard(
//                    value: metrics.averageWordCount,
//                    label: "average expression length",
//                    description: wordCountDescription(count: metrics.averageWordCount),
//                    valueFormat: "%.0f",
//                    unit: "words",
//                    color: accentColor.opacity(0.8)
//                )
//            }
//            .padding(20)
//            .background(Color.white.cornerRadius(16))
//        }
//    }
//    
//    private func paceDescription(wpm: Double) -> String {
//        switch wpm {
//        case ..<80:
//            return "Taking time to carefully consider each thought"
//        case 80..<100:
//            return "Speaking at a measured, reflective pace"
//        case 100..<130:
//            return "Natural conversational rhythm"
//        default:
//            return "Quick, energetic expression of ideas"
//        }
//    }
//    
//    private func durationDescription(seconds: Double) -> String {
//        switch seconds {
//        case ..<10:
//            return "Brief, focused thoughts"
//        case 10..<20:
//            return "Concise reflection style"
//        case 20..<25:
//            return "Balanced expression length"
//        default:
//            return "Taking time to fully explore thoughts"
//        }
//    }
//    
//    private func wordCountDescription(count: Double) -> String {
//        switch count {
//        case ..<20:
//            return "Direct and precise expression"
//        case 20..<35:
//            return "Clear, focused reflection"
//        case 35..<50:
//            return "Detailed exploration of thoughts"
//        default:
//            return "Rich, expansive expression style"
//        }
//    }
//}
//
//struct MetricCard: View {
//    let value: Double
//    let label: String
//    let description: String
//    let valueFormat: String
//    let unit: String
//    let color: Color
//    
//    private let textColor = Color(hex: "2C3E50")
//    
//    var body: some View {
//        VStack(spacing: 0) {
//            // Header with label
//            HStack {
//                Text(label)
//                    .font(.system(size: 11, weight: .medium))
//                    .textCase(.uppercase)
//                    .foregroundColor(textColor.opacity(0.5))
//                    .tracking(0.5)
//                Spacer()
//            }
//            .padding(.bottom, 8)
//            
//            // Value and unit
//            HStack(alignment: .firstTextBaseline, spacing: 4) {
//                Text(String(format: valueFormat, value))
//                    .font(.system(size: 22, weight: .medium))
//                Text(unit)
//                    .font(.system(size: 12))
//                    .foregroundColor(textColor.opacity(0.6))
//                Spacer()
//            }
//            .padding(.bottom, 8)
//            
//            // Description
//            HStack {
//                Text(description)
//                    .font(.system(size: 13))
//                    .foregroundColor(textColor.opacity(0.7))
//                    .fixedSize(horizontal: false, vertical: true)
//                
//                Spacer()
//            }
//        }
//        .padding(16)
//        .background(
//            RoundedRectangle(cornerRadius: 12)
//                .fill(Color.white)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 12)
//                        .stroke(color.opacity(0.1), lineWidth: 1)
//                )
//        )
//    }
//}
//
//struct LoopsTimeline: View {
//    let loops: [LoopAnalysis]
//    private let textColor = Color(hex: "2C3E50")
//    private let accentColor = Color(hex: "A28497")
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 20) {
//            HStack {
//                Text("daily loops")
//                    .font(.system(size: 14, weight: .medium))
//                    .foregroundColor(textColor)
//                
//                
//                Spacer()
//            }
//            VStack(spacing: 24) {
//                ForEach(loops) { loop in
//                    LoopTimelineItem(loop: loop)
//                }
//            }
//        }
//    }
//}
//
//struct LoopTimelineItem: View {
//    let loop: LoopAnalysis
//    private let textColor = Color(hex: "2C3E50")
//    private let accentColor = Color(hex: "A28497")
//    
//    var body: some View {
//        HStack(spacing: 16) {
//            VStack(spacing: 0) {
//                Circle()
//                    .fill(accentColor)
//                    .frame(width: 12, height: 12)
//                
//                if loop.id != "lastLoop" {
//                    Rectangle()
//                        .fill(accentColor.opacity(0.2))
//                        .frame(width: 2)
//                        .frame(height: 40)
//                }
//            }
//            
//            VStack(alignment: .leading, spacing: 12) {
//                Text(formatTime(loop.timestamp))
//                    .font(.system(size: 12))
//                    .foregroundColor(textColor.opacity(0.5))
//                
//                Text(loop.promptText)
//                    .font(.system(size: 16))
//                    .foregroundColor(textColor)
//                
//                HStack(spacing: 16) {
//                    MetricPill(value: String(format: "%.0f", loop.metrics.wordsPerMinute), unit: "wpm")
//                    MetricPill(value: String(format: "%.1f", loop.metrics.duration/60), unit: "min")
//                    MetricPill(value: String(format: "%.0f", loop.metrics.wordCount), unit: "words")
//                }
//            }
//            
//            Spacer()
//        }
//    }
//    
//    private func formatTime(_ date: Date) -> String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "h:mm a"
//        return formatter.string(from: date).lowercased()
//    }
//}
//
//struct MetricPill: View {
//    let value: String
//    let unit: String
//    private let textColor = Color(hex: "2C3E50")
//    
//    var body: some View {
//        HStack(spacing: 4) {
//            Text(value)
//                .font(.system(size: 14, weight: .medium))
//            Text(unit)
//                .font(.system(size: 14))
//        }
//        .foregroundColor(textColor.opacity(0.6))
//        .padding(.horizontal, 12)
//        .padding(.vertical, 6)
//        .background(Color(hex: "F8F9FA").cornerRadius(16))
//    }
//}
//
//struct FollowUpView: View {
//    let followUp: FollowUp
//    private let textColor = Color(hex: "2C3E50")
//    private let accentColor = Color(hex: "A28497")
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            HStack(spacing: 8) {
//                Image(systemName: "arrow.right.circle.fill")
//                    .foregroundColor(accentColor)
//                
//                Text("NEXT REFLECTION")
//                    .font(.system(size: 11, weight: .medium))
//                    .tracking(1.5)
//                    .foregroundColor(textColor.opacity(0.5))
//            }
//            
//            Text(followUp.question)
//                .font(.system(size: 18, weight: .medium))
//                .foregroundColor(textColor)
//            
//            Text(followUp.question)
//                .font(.system(size: 14))
//                .foregroundColor(textColor.opacity(0.8))
//                .lineSpacing(8)
//        }
//        .padding(24)
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .background(
//            Color.white
//                .cornerRadius(16)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 16)
//                        .stroke(accentColor.opacity(0.1), lineWidth: 1)
//                )
//        )
//    }
//}

#if DEBUG
struct TodaysInsightsView_Previews: PreviewProvider {
    static var previews: some View {
        TodaysInsightsView(analysisManager: .preview)
    }
}
#endif


