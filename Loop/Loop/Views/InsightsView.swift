//
//  InsightsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/7/24.
//

import SwiftUI
import Charts


struct InsightsView: View {
    @ObservedObject var analysisManager = AnalysisManager.shared
    @State private var selectedTab = "today"
    @State private var animateIn = false
    
    // Colors
    private let accentColor = Color(hex: "A28497")
    private let secondaryColor = Color(hex: "B7A284")
    private let backgroundColor = Color(hex: "FAFBFC")
    private let surfaceColor = Color(hex: "F8F5F7")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            ArtisticBackground(baseColor: accentColor)
                .opacity(0.3)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    header
                    
                    if let analysis = analysisManager.currentLoopAnalysis {
                        TabView(selection: $selectedTab) {
                            todayView(analysis)
                                .tag("today")
                            
                            Text("Coming Soon")
                                .font(.system(size: 24, weight: .light))
                                .foregroundColor(textColor)
                                .tag("compare")
                            
                            Text("Coming Soon")
                                .font(.system(size: 24, weight: .light))
                                .foregroundColor(textColor)
                                .tag("trends")
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 32)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                animateIn = true
            }
        }
    }
    
    private var header: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Loop Insights")
                        .font(.system(size: 40, weight: .ultraLight))
                        .foregroundColor(textColor)
                    Text("Your voice, analyzed with care")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(textColor.opacity(0.7))
                }
                Spacer()
            }
            .offset(y: animateIn ? 0 : 20)
            .opacity(animateIn ? 1 : 0)
            
            FlowingTabBar(selection: $selectedTab)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                EmptyStateAnimation()
            }
            
            Text("Begin Your Loop")
                .font(.system(size: 32, weight: .ultraLight))
                .foregroundColor(textColor)
            
            Text("Complete your first recording to see insights")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(textColor.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 60)
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
    }
    
    @ViewBuilder
    private func todayView(_ analysis: LoopAnalysis) -> some View {
        VStack(spacing: 24) {
            // Key Messages
            InsightCard(analysis.languagePattern.emotionalToneScore) {
                VStack(alignment: .leading, spacing: 20) {
                    KeyMessagesView(messages: analysisManager.analysisMessages)
                }
            }
            
            // Voice Patterns
            InsightCard(analysis.voicePattern.rhythmConsistency) {
                VStack(alignment: .leading, spacing: 24) {
                    VoicePatternsView(analysis: analysis)
                }
            }
            
            // Language Analysis
            InsightCard(abs(analysis.languagePattern.emotionalToneScore)) {
                VStack(alignment: .leading, spacing: 24) {
                    LanguageAnalysisView(analysis: analysis)
                }
            }
            
            // Perspective
            InsightCard(analysis.selfReference.selfReferencePercentage / 100) {
                VStack(alignment: .leading, spacing: 24) {
                    PerspectiveView(analysis: analysis.selfReference)
                }
            }
        }
    }
}

struct FlowingTabBar: View {
    @Binding var selection: String
    private let tabs = [
        ("today", "Today's Loops"),
        ("compare", "Compare"),
        ("trends", "Trends")
    ]
    
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.0) { tab in
                TabButton(
                    title: tab.1,
                    isSelected: selection == tab.0,
                    action: { selection = tab.0 }
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: accentColor.opacity(0.1), radius: 20)
        )
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(isSelected ? .white : accentColor)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? accentColor : accentColor.opacity(0.1))
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct InsightCard<Content: View>: View {
    let intensity: Double
    let content: Content
    
    private let accentColor = Color(hex: "A28497")
    private let surfaceColor = Color(hex: "F8F5F7")
    
    init(_ intensity: Double, @ViewBuilder content: () -> Content) {
        self.intensity = intensity
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(24)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.white)
                    
                    FlowingGradient(
                        intensity: intensity,
                        baseColor: accentColor
                    )
                    .opacity(0.05)
                }
                .shadow(color: accentColor.opacity(0.05), radius: 20)
            )
    }
}

struct FlowingGradient: View {
    let intensity: Double
    let baseColor: Color
    @State private var phase: Double = 0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                phase = time.truncatingRemainder(dividingBy: 4)
                
                for i in 0..<3 {
                    let path = createFlowingPath(
                        in: size,
                        offset: phase + Double(i) * .pi / 3,
                        scale: 0.3 + intensity * 0.7
                    )
                    
                    context.fill(
                        path,
                        with: .linearGradient(
                            Gradient(colors: [
                                baseColor.opacity(0.05),
                                baseColor.opacity(0.02)
                            ]),
                            startPoint: CGPoint(x: 0, y: size.height/2),
                            endPoint: CGPoint(x: size.width, y: size.height/2)
                        )
                    )
                }
            }
        }
    }
    
    private func createFlowingPath(in size: CGSize, offset: Double, scale: Double) -> Path {
        var path = Path()
        let midY = size.height / 2
        
        path.move(to: CGPoint(x: 0, y: size.height))
        
        for x in stride(from: 0, through: size.width, by: 5) {
            let normalizedX = x / size.width
            let y = midY + sin(normalizedX * 4 * .pi + offset) * midY * scale
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.closeSubpath()
        return path
    }
}

struct EmptyStateAnimation: View {
    @State private var isAnimating = false
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        Image(systemName: "waveform")
            .font(.system(size: 32, weight: .light))
            .foregroundColor(accentColor)
            .scaleEffect(isAnimating ? 1.1 : 0.9)
            .opacity(isAnimating ? 1 : 0.7)
            .animation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

struct KeyMessagesView: View {
    let messages: [AnalysisMessage]
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Key Insights")
                .font(.system(size: 24, weight: .ultraLight))
                .foregroundColor(textColor)
            
            VStack(spacing: 12) {
                ForEach(messages) { message in
                    MessageRow(message: message)
                }
            }
        }
    }
}

struct MessageRow: View {
    let message: AnalysisMessage
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(severityColor.opacity(0.2))
                .frame(width: 8, height: 8)
            
            Text(message.message)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(textColor)
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(severityColor.opacity(0.05))
        )
    }
    
    private var severityColor: Color {
        switch message.severity {
        case .significant: return accentColor
        case .notable: return Color(hex: "B7A284")
        case .neutral: return Color(hex: "94A7B7")
        }
    }
}

struct VoicePatternsView: View {
    let analysis: LoopAnalysis
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Voice Expression")
                .font(.system(size: 24, weight: .ultraLight))
                .foregroundColor(textColor)
            
            HStack(spacing: 20) {
                VoiceMetricCircle(
                    value: analysis.speechPattern.wordsPerMinute,
                    maxValue: 200,
                    label: "WPM",
                    subtitle: paceDescription
                )
                
                VStack(spacing: 16) {
                    MetricBar(
                        label: "Filler Words",
                        value: analysis.voicePattern.fillerWordPercentage,
                        maxValue: 100,
                        icon: "text.bubble"
                    )
                    
                    MetricBar(
                        label: "Rhythm",
                        value: analysis.voicePattern.rhythmConsistency * 100,
                        maxValue: 100,
                        icon: "waveform.path"
                    )
                }
            }
            
            PauseAnalysis(speechPattern: analysis.speechPattern)
        }
    }
    
    private var paceDescription: String {
        switch analysis.speechPattern.wordsPerMinute {
        case ...100: return "measured pace"
        case 100...150: return "natural flow"
        default: return "swift expression"
        }
    }
}

struct VoiceMetricCircle: View {
    let value: Double
    let maxValue: Double
    let label: String
    let subtitle: String
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(accentColor.opacity(0.1), lineWidth: 12)
                
                Circle()
                    .trim(from: 0, to: min(value / maxValue, 1))
                    .stroke(
                        accentColor,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("\(Int(value))")
                        .font(.system(size: 24, weight: .medium))
                    Text(label)
                        .font(.system(size: 14, weight: .light))
                }
                .foregroundColor(textColor)
            }
            .frame(width: 120, height: 120)
            
            Text(subtitle)
                .font(.system(size: 14, weight: .light))
                .foregroundColor(textColor.opacity(0.7))
        }
    }
}

struct MetricBar: View {
    let label: String
    let value: Double
    let maxValue: Double
    let icon: String
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .light))
                Text(label)
                    .font(.system(size: 14, weight: .light))
                Spacer()
                Text("\(Int(value))%")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(textColor)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(accentColor.opacity(0.1))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(accentColor)
                        .frame(width: geometry.size.width * CGFloat(min(value / maxValue, 1)), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
    }
}

struct PauseAnalysis: View {
    let speechPattern: SpeechPatternAnalysis
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pause Pattern")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(textColor)
            
            HStack(spacing: 20) {
                PauseMetric(
                    value: speechPattern.averagePauseDuration,
                    label: "Average",
                    unit: "sec"
                )
                
                PauseMetric(
                    value: speechPattern.longestPause,
                    label: "Longest",
                    unit: "sec"
                )
                
                PauseMetric(
                    value: Double(speechPattern.pauseCount),
                    label: "Count",
                    unit: "pauses"
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(accentColor.opacity(0.05))
        )
    }
}

struct PauseMetric: View {
    let value: Double
    let label: String
    let unit: String
    
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(String(format: "%.1f", value))
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(textColor)
            
            Text(label)
                .font(.system(size: 14, weight: .light))
                .foregroundColor(textColor.opacity(0.7))
            
            Text(unit)
                .font(.system(size: 12, weight: .light))
                .foregroundColor(textColor.opacity(0.5))
        }
    }
}

struct LanguageAnalysisView: View {
    let analysis: LoopAnalysis
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    private let secondaryColor = Color(hex: "B7A284")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Language Patterns")
                .font(.system(size: 24, weight: .ultraLight))
                .foregroundColor(textColor)
            
            EmotionalToneGauge(analysis: analysis.languagePattern)
            
            HStack(spacing: 20) {
                WordCountMetric(
                    count: analysis.languagePattern.positiveWordCount,
                    label: "Positive",
                    icon: "plus.circle"
                )
                
                WordCountMetric(
                    count: analysis.languagePattern.negativeWordCount,
                    label: "Negative",
                    icon: "minus.circle"
                )
            }
            
            ConnectionAnalysis(
                causalCount: analysis.languagePattern.causalConjunctionCount,
                adversativeCount: analysis.languagePattern.adversativeConjunctionCount
            )
            
            SocialPronounAnalysisView(pronouns: analysis.languagePattern.socialPronouns)
        }
    }
}

struct EmotionalToneGauge: View {
    let analysis: LanguagePatternAnalysis
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(accentColor.opacity(0.1), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: 0.5)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(hex: "FF6B6B"),
                                accentColor,
                                Color(hex: "4ECB71")
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(180))
                
                Rectangle()
                    .fill(accentColor)
                    .frame(width: 3, height: 20)
                    .offset(y: -40)
                    .rotationEffect(.degrees(180 * (analysis.emotionalToneScore + 1)))
                
                Text(String(format: "%.1f", analysis.emotionalToneScore))
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(textColor)
            }
            
            Text(emotionalDescription)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
        }
    }
    
    private var emotionalDescription: String {
        switch analysis.emotionalToneScore {
        case 0.3...1.0: return "Predominantly positive tone"
        case -0.3...0.3: return "Balanced expression"
        default: return "Processing challenges"
        }
    }
}

struct WordCountMetric: View {
    let count: Int
    let label: String
    let icon: String
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .light))
                .foregroundColor(accentColor)
            
            Text("\(count)")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(textColor)
            
            Text(label)
                .font(.system(size: 14, weight: .light))
                .foregroundColor(textColor.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(accentColor.opacity(0.05))
        .cornerRadius(16)
    }
}

struct ConnectionAnalysis: View {
    let causalCount: Int
    let adversativeCount: Int
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    private let secondaryColor = Color(hex: "B7A284")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Expression Structure")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(textColor)
            
            HStack(spacing: 16) {
                ConnectionMetric(
                    count: causalCount,
                    total: totalConnections,
                    label: "Causal",
                    color: accentColor
                )
                
                ConnectionMetric(
                    count: adversativeCount,
                    total: totalConnections,
                    label: "Contrast",
                    color: secondaryColor
                )
            }
        }
    }
    
    private var totalConnections: Int {
        max(causalCount + adversativeCount, 1)
    }
}

struct ConnectionMetric: View {
    let count: Int
    let total: Int
    let label: String
    let color: Color
    
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .light))
                .foregroundColor(textColor)
            
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: geometry.size.width * CGFloat(count) / CGFloat(total))
                    .frame(height: 8)
            }
            .frame(height: 8)
            
            Text("\(count)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(textColor)
        }
    }
}

struct SocialPronounAnalysisView: View {
    let pronouns: SocialPronounAnalysis
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Social Context")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(textColor)
            
            HStack(spacing: 40) {
                PronounGroup(
                    count: pronouns.weCount,
                    label: "Collective",
                    icon: "person.2"
                )
                
                PronounGroup(
                    count: pronouns.theyCount,
                    label: "Others",
                    icon: "person.3"
                )
                
                if pronouns.weTheyRatio > 0 {
                    RatioIndicator(ratio: pronouns.weTheyRatio)
                }
            }
        }
        .padding(16)
        .background(accentColor.opacity(0.05))
        .cornerRadius(16)
    }
}

struct PronounGroup: View {
    let count: Int
    let label: String
    let icon: String
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .light))
                .foregroundColor(accentColor)
            
            Text("\(count)")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(textColor)
            
            Text(label)
                .font(.system(size: 14, weight: .light))
                .foregroundColor(textColor.opacity(0.7))
        }
    }
}

struct RatioIndicator: View {
    let ratio: Double
    
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 4) {
            Text("Ratio")
                .font(.system(size: 14, weight: .light))
                .foregroundColor(textColor.opacity(0.7))
            
            Text(String(format: "%.1f", ratio))
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(textColor)
        }
    }
}

struct PerspectiveView: View {
    let analysis: SelfReferenceAnalysis
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Perspective")
                .font(.system(size: 24, weight: .ultraLight))
                .foregroundColor(textColor)
            
            HStack(spacing: 20) {
                MetricCircle(
                    value: analysis.selfReferencePercentage,
                    maxValue: 100,
                    label: "Self Focus",
                    icon: "person.fill"
                )
                
                VStack(spacing: 16) {
                    ReflectionMetric(
                        count: analysis.uncertaintyCount,
                        label: "Uncertainty",
                        icon: "questionmark.circle"
                    )
                    
                    ReflectionMetric(
                        count: analysis.reflectionCount,
                        label: "Reflection",
                        icon: "sparkles"
                    )
                }
            }
            
            TimeDistribution(
                past: analysis.pastTensePercentage,
                present: analysis.presentTensePercentage,
                future: analysis.futureTensePercentage
            )
        }
    }
}

struct ReflectionMetric: View {
    let count: Int
    let label: String
    let icon: String
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .light))
                .foregroundColor(accentColor)
            
            Text(label)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(textColor)
            
            Spacer()
            
            Text("\(count)")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(textColor)
        }
        .padding(16)
        .background(accentColor.opacity(0.05))
        .cornerRadius(12)
    }
}

struct TimeDistribution: View {
    let past: Double
    let present: Double
    let future: Double
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    private let secondaryColor = Color(hex: "B7A284")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Time Orientation")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(textColor)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar
                    RoundedRectangle(cornerRadius: 8)
                        .fill(accentColor.opacity(0.1))
                        .frame(height: 16)
                    
                    // Distribution bars
                    HStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "4ECB71"))
                            .frame(width: geometry.size.width * CGFloat(past / total))
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(accentColor)
                            .frame(width: geometry.size.width * CGFloat(present / total))
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(secondaryColor)
                            .frame(width: geometry.size.width * CGFloat(future / total))
                    }
                    .frame(height: 16)
                }
            }
            .frame(height: 16)
            
            HStack(spacing: 20) {
                TimeLabel(color: Color(hex: "4ECB71"), label: "Past", value: Int(past))
                TimeLabel(color: accentColor, label: "Present", value: Int(present))
                TimeLabel(color: secondaryColor, label: "Future", value: Int(future))
            }
        }
        .padding(16)
        .background(accentColor.opacity(0.05))
        .cornerRadius(16)
    }
    
    private var total: Double {
        max(past + present + future, 1)
    }
}

struct MetricCircle: View {
    let value: Double
    let maxValue: Double
    let label: String
    let icon: String
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(accentColor.opacity(0.1), lineWidth: 12)
                
                Circle()
                    .trim(from: 0, to: value / maxValue)
                    .stroke(
                        accentColor,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(accentColor)
                    
                    Text("\(Int(value))%")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(textColor)
                }
            }
            .frame(width: 120, height: 120)
            
            Text(label)
                .font(.system(size: 14, weight: .light))
                .foregroundColor(textColor.opacity(0.7))
        }
    }
}

struct TimeLabel: View {
    let color: Color
    let label: String
    let value: Int
    
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text("\(label): \(value)%")
                .font(.system(size: 12, weight: .light))
                .foregroundColor(textColor)
        }
    }
}

#Preview {
    InsightsView()
}
