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
                            TodayAnalysisView(analysis: analysis)
                                .tag("today")
                            
                            ComingSoonView(title: "compare",
                                         description: "Compare analysis between multiple loops")
                                .tag("compare")
                            
                            ComingSoonView(title: "trends",
                                         description: "View your progress over time")
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
                    Text("loop insights")
                        .font(.system(size: 40, weight: .ultraLight))
                        .foregroundColor(textColor)
                    Text("your voice, analyzed with care")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(textColor.opacity(0.7))
                }
                Spacer()
            }
            .offset(y: animateIn ? 0 : 20)
            .opacity(animateIn ? 1 : 0)
            
            InsightsTabBar(selection: $selectedTab)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                AnimatedBackground()
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
}

struct InsightsTabBar: View {
    @Binding var selection: String
    
    private let tabs = [
        ("today", "Today", "calendar"),
        ("compare", "Compare", "square.on.square"),
        ("trends", "Trends", "chart.xyaxis.line")
    ]
    
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.0) { tab in
                InsightsTabButton(
                    title: tab.1,
                    icon: tab.2,
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

struct InsightsTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.system(size: 16, weight: .light))
            }
            .foregroundColor(isSelected ? .white : accentColor)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(isSelected ? accentColor : accentColor.opacity(0.1))
            )
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

struct ComingSoonView: View {
    let title: String
    let description: String
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundColor(accentColor)
            
            Text(title)
                .font(.system(size: 24, weight: .light))
                .foregroundColor(textColor)
            
            Text(description)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(textColor.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
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

struct MetricValue: View {
    let value: Double
    let label: String
    let sublabel: String?
    let icon: String?
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    init(value: Double, label: String, sublabel: String? = nil, icon: String? = nil) {
        self.value = value
        self.label = label
        self.sublabel = sublabel
        self.icon = icon
    }
    
    var body: some View {
        VStack(spacing: 8) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(accentColor)
            }
            
            Text(String(format: "%.1f", value))
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(textColor)
            
            Text(label)
                .font(.system(size: 14, weight: .light))
                .foregroundColor(textColor.opacity(0.7))
            
            if let sublabel = sublabel {
                Text(sublabel)
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(textColor.opacity(0.5))
            }
        }
    }
}

struct ProgressBar: View {
    let value: Double
    let maxValue: Double
    let label: String
    let color: Color
    
    private let height: CGFloat = 8
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 14, weight: .light))
                Spacer()
                Text("\(Int((value / maxValue) * 100))%")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(textColor)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(color.opacity(0.1))
                        .frame(height: height)
                        .cornerRadius(height / 2)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(min(value / maxValue, 1)), height: height)
                        .cornerRadius(height / 2)
                }
            }
            .frame(height: height)
        }
    }
}

//struct CircularProgress: View {
//    let value: Double
//    let maxValue: Double
//    let size: CGFloat
//    let lineWidth: CGFloat
//    let color: Color
//    
//    private let textColor = Color(hex: "2C3E50")
//    
//    var body: some View {
//        ZStack {
//            Circle()
//                .stroke(color.opacity(0.1), lineWidth: lineWidth)
//            
//            Circle()
//                .trim(from: 0, to: min(value / maxValue, 1))
//                .stroke(
//                    color,
//                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
//                )
//                .rotationEffect(.degrees(-90))
//                .animation(.easeInOut, value: value)
//        }
//        .frame(width: size, height: size)
//    }
//}

struct SectionHeader: View {
    let title: String
    let icon: String
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .light))
                .foregroundColor(accentColor)
            
            Text(title)
                .font(.system(size: 24, weight: .ultraLight))
                .foregroundColor(textColor)
        }
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

struct TodayAnalysisView: View {
    let analysis: LoopAnalysis
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(spacing: 24) {
            VoicePatternsCard(analysis: analysis)
            LanguageAnalysisCard(analysis: analysis.languagePattern)
            PerspectiveCard(analysis: analysis.selfReference)
        }
    }
}

struct VoicePatternsCard: View {
    let analysis: LoopAnalysis
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    private let secondaryColor = Color(hex: "B7A284")
    
    var body: some View {
        InsightCard(analysis.voicePattern.rhythmConsistency) {
            VStack(alignment: .leading, spacing: 24) {
                SectionHeader(title: "Voice Patterns", icon: "waveform")
                
                HStack(spacing: 20) {
                    VoiceMetricCircle(
                        value: analysis.speechPattern.wordsPerMinute,
                        maxValue: 200,
                        label: "WPM",
                        description: paceDescription
                    )
                    
                    VStack(spacing: 16) {
                        MetricBar(
                            label: "Filler Words",
                            value: analysis.voicePattern.fillerWordPercentage,
                            maxValue: 100,
                            color: accentColor,
                            icon: "text.bubble"
                        )
                        
                        MetricBar(
                            label: "Rhythm",
                            value: analysis.voicePattern.rhythmConsistency * 100,
                            maxValue: 100,
                            color: secondaryColor,
                            icon: "waveform.path"
                        )
                        
                        MetricBar(
                            label: "Pitch Variation",
                            value: min(analysis.voicePattern.pitchVariation * 100, 100),
                            maxValue: 100,
                            color: accentColor,
                            icon: "wave.3.right"
                        )
                    }
                }
                
                Divider()
                    .background(accentColor.opacity(0.1))
                    .padding(.vertical, 8)
                
                PauseAnalysis(speechPattern: analysis.speechPattern)
                
                VoiceInsight(analysis: analysis.voicePattern)
            }
        }
    }
    
    private var paceDescription: String {
        switch analysis.speechPattern.wordsPerMinute {
        case ...100: return "Measured Pace"
        case 100...150: return "Natural Flow"
        case 150...180: return "Engaged Pace"
        default: return "Swift Expression"
        }
    }
}

struct VoiceMetricCircle: View {
    let value: Double
    let maxValue: Double
    let label: String
    let description: String
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(accentColor.opacity(0.1), lineWidth: 12)
                
                Circle()
                    .trim(from: 0, to: min(value / maxValue, 1))
                    .stroke(
                        AngularGradient(
                            colors: [accentColor, accentColor.opacity(0.6)],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("\(Int(value))")
                        .font(.system(size: 32, weight: .medium))
                    Text(label)
                        .font(.system(size: 14, weight: .light))
                }
                .foregroundColor(textColor)
            }
            .frame(width: 140, height: 140)
            
            Text(description)
                .font(.system(size: 14, weight: .light))
                .foregroundColor(textColor.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
}

struct MetricBar: View {
    let label: String
    let value: Double
    let maxValue: Double
    let color: Color
    let icon: String
    
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .light))
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
                        .fill(color.opacity(0.1))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
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
                    unit: "sec",
                    icon: "clock"
                )
                
                PauseMetric(
                    value: speechPattern.longestPause,
                    label: "Longest",
                    unit: "sec",
                    icon: "clock.circle"
                )
                
                PauseMetric(
                    value: Double(speechPattern.pauseCount),
                    label: "Count",
                    unit: "pauses",
                    icon: "number.circle"
                )
            }
            .padding(16)
            .background(accentColor.opacity(0.05))
            .cornerRadius(12)
        }
    }
}

struct PauseMetric: View {
    let value: Double
    let label: String
    let unit: String
    let icon: String
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(accentColor)
            
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

struct VoiceInsight: View {
    let analysis: VoiceAnalysis
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Voice Insight")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(textColor)
            
            Text(insightMessage)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(textColor.opacity(0.8))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(accentColor.opacity(0.05))
                .cornerRadius(12)
        }
    }
    
    private var insightMessage: String {
        let rhythmQuality = analysis.rhythmConsistency >= 0.7 ? "consistent" : "varied"
        let fillerStatus = analysis.fillerWordPercentage <= 5 ? "minimal" : "notable"
        let pitchRange = analysis.pitchVariation >= 0.5 ? "expressive" : "steady"
        
        return "Your voice shows \(rhythmQuality) rhythm with \(fillerStatus) use of filler words. The \(pitchRange) pitch variation adds \(analysis.pitchVariation >= 0.5 ? "dynamic engagement" : "stable clarity") to your expression."
    }
}

struct LanguageAnalysisCard: View {
    let analysis: LanguagePatternAnalysis
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    private let secondaryColor = Color(hex: "B7A284")
    
    var body: some View {
        InsightCard(abs(analysis.emotionalToneScore)) {
            VStack(alignment: .leading, spacing: 24) {
                SectionHeader(title: "Language Patterns", icon: "text.word.spacing")
                
                EmotionalToneGauge(analysis: analysis)
                
                Divider()
                    .background(accentColor.opacity(0.1))
                    .padding(.vertical, 8)
                
                HStack(spacing: 20) {
                    WordCountMetric(
                        count: analysis.positiveWordCount,
                        label: "Positive",
                        icon: "plus.circle",
                        color: Color(hex: "4ECB71")
                    )
                    
                    WordCountMetric(
                        count: analysis.negativeWordCount,
                        label: "Negative",
                        icon: "minus.circle",
                        color: Color(hex: "FF6B6B")
                    )
                }
                
                ConnectionAnalysis(
                    causalCount: analysis.causalConjunctionCount,
                    adversativeCount: analysis.adversativeConjunctionCount
                )
                
                SocialPronounAnalysisView(pronouns: analysis.socialPronouns)
            }
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
                
                VStack(spacing: 4) {
                    Text(String(format: "%.2f", analysis.emotionalToneScore))
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(textColor)
                    
                    Text("Tone Score")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(textColor.opacity(0.7))
                }
            }
            
            Text(emotionalDescription)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
        }
    }
    
    private var emotionalDescription: String {
        switch analysis.emotionalToneScore {
        case 0.3...1.0: return "Predominantly positive expression"
        case -0.3...0.3: return "Balanced emotional tone"
        default: return "Processing challenging experiences"
        }
    }
}

struct WordCountMetric: View {
    let count: Int
    let label: String
    let icon: String
    let color: Color
    
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .light))
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(textColor)
            
            Text(label)
                .font(.system(size: 14, weight: .light))
                .foregroundColor(textColor.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.05))
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
        VStack(alignment: .leading, spacing: 16) {
            Text("Expression Structure")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(textColor)
            
            HStack(spacing: 20) {
                ConnectionMetric(
                    count: causalCount,
                    total: totalConnections,
                    label: "Causal",
                    icon: "arrow.right.circle",
                    color: accentColor
                )
                
                ConnectionMetric(
                    count: adversativeCount,
                    total: totalConnections,
                    label: "Contrast",
                    icon: "arrow.up.and.down.circle",
                    color: secondaryColor
                )
            }
            .padding(16)
            .background(accentColor.opacity(0.05))
            .cornerRadius(12)
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
    let icon: String
    let color: Color
    
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                
                Text(label)
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(textColor)
            }
            
            Text("\(count)")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(textColor)
            
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: geometry.size.width * CGFloat(count) / CGFloat(total))
                    .frame(height: 8)
            }
            .frame(height: 8)
        }
    }
}

struct SocialPronounAnalysisView: View {
    let pronouns: SocialPronounAnalysis
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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
            .padding(16)
            .background(accentColor.opacity(0.05))
            .cornerRadius(12)
        }
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

struct PerspectiveCard: View {
    let analysis: SelfReferenceAnalysis
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    private let secondaryColor = Color(hex: "B7A284")
    
    var body: some View {
        InsightCard(analysis.selfReferencePercentage / 100) {
            VStack(alignment: .leading, spacing: 24) {
                SectionHeader(title: "Perspective", icon: "person.fill.viewfinder")
                
                HStack(spacing: 20) {
                    SelfReferenceGauge(
                        percentage: analysis.selfReferencePercentage,
                        reflectionCount: analysis.reflectionCount
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
                
                Divider()
                    .background(accentColor.opacity(0.1))
                    .padding(.vertical, 8)
                
                TimeDistribution(
                    past: analysis.pastTensePercentage,
                    present: analysis.presentTensePercentage,
                    future: analysis.futureTensePercentage
                )
                
                PerspectiveInsight(analysis: analysis)
            }
        }
    }
}

struct SelfReferenceGauge: View {
    let percentage: Double
    let reflectionCount: Int
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(accentColor.opacity(0.1), lineWidth: 12)
                
                Circle()
                    .trim(from: 0, to: percentage / 100)
                    .stroke(
                        AngularGradient(
                            colors: [accentColor, accentColor.opacity(0.6)],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("\(Int(percentage))%")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(textColor)
                    
                    Text("Self Focus")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(textColor.opacity(0.7))
                }
            }
            .frame(width: 140, height: 140)
            
            Text(focusDescription)
                .font(.system(size: 14, weight: .light))
                .foregroundColor(textColor.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
    
    private var focusDescription: String {
        switch percentage {
        case 0...20: return "External Focus"
        case 20...40: return "Balanced Perspective"
        case 40...60: return "Personal Insight"
        default: return "Deep Self-Reflection"
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
                    RoundedRectangle(cornerRadius: 8)
                        .fill(accentColor.opacity(0.1))
                        .frame(height: 16)
                    
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

struct PerspectiveInsight: View {
    let analysis: SelfReferenceAnalysis
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Perspective Insight")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(textColor)
            
            Text(insightMessage)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(textColor.opacity(0.8))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(accentColor.opacity(0.05))
                .cornerRadius(12)
        }
    }
    
    private var insightMessage: String {
        let timeOrientation = if analysis.pastTensePercentage > analysis.futureTensePercentage {
            "drawing from past experiences"
        } else if analysis.futureTensePercentage > analysis.pastTensePercentage {
            "focusing on future possibilities"
        } else {
            "maintaining present awareness"
        }
        
        let reflectionLevel = if analysis.reflectionCount > 3 {
            "deep reflection"
        } else if analysis.reflectionCount > 0 {
            "thoughtful consideration"
        } else {
            "direct expression"
        }
        
        return "Your response shows \(reflectionLevel) while \(timeOrientation). \(uncertaintyInsight)"
    }
    
    private var uncertaintyInsight: String {
        if analysis.uncertaintyCount > 3 {
            return "You're exploring multiple possibilities."
        } else if analysis.uncertaintyCount > 0 {
            return "You're considering different perspectives."
        } else {
            return "You express clear conviction."
        }
    }
}
