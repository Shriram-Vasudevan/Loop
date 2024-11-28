//
//  InsightsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/7/24.
//

import SwiftUI
import Charts


enum InsightSection: String, CaseIterable {
    case voice = "Voice"
    case language = "Language"
    case perspective = "Perspective"
}

struct InsightMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: Double
    let context: String
    let trend: MetricTrend
    
    enum MetricTrend {
        case up, down, neutral
    }
}

struct InsightsView: View {
    @ObservedObject var analysisManager = AnalysisManager.shared
    @State private var selectedSection: InsightSection = .voice
    @State private var scrollOffset: CGFloat = 0
    @State private var animateIn = false
    
    private let accentColor = Color(hex: "A28497")
    private let secondaryColor = Color(hex: "B7A284")
    private let backgroundColor = Color(hex: "FAFBFC")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        ZStack {
            FlowingBackground()
                .opacity(0.7)
                .ignoresSafeArea()
            
            ScrollView {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: ScrollOffsetKey.self,
                        value: proxy.frame(in: .named("scroll")).minY
                    )
                }
                .frame(height: 0)
                
                VStack(spacing: 32) {
                    headerSection
                    
                    if let analysis = analysisManager.currentLoopAnalysis {
                        mainContent(analysis)
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetKey.self) { offset in
                scrollOffset = offset
            }
        }
        .background(backgroundColor)
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                animateIn = true
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 24) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Insights")
                        .font(.system(size: 40, weight: .ultraLight))
                        .foregroundColor(textColor)
                    Text("Analysis & Patterns")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(textColor.opacity(0.7))
                }
                Spacer()
            }
            .opacity(animateIn ? 1 : 0)
            .offset(y: animateIn ? 0 : 20)
            
            sectionPicker
        }
    }
    
    private var sectionPicker: some View {
        HStack(spacing: 0) {
            ForEach(InsightSection.allCases, id: \.self) { section in
                Button(action: {
                    withAnimation(.spring()) {
                        selectedSection = section
                    }
                }) {
                    Text(section.rawValue)
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(selectedSection == section ? .white : accentColor)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(selectedSection == section ? accentColor : accentColor.opacity(0.1))
                        )
                }
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10)
        )
    }
    
    @ViewBuilder
    private func mainContent(_ analysis: LoopAnalysis) -> some View {
        VStack(spacing: 32) {
            switch selectedSection {
            case .voice:
                VoiceAnalysisSection(
                    speechPattern: analysis.speechPattern,
                    voicePattern: analysis.voicePattern,
                    scrollOffset: scrollOffset
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                
            case .language:
                LanguageAnalysisSection(
                    languagePattern: analysis.languagePattern,
                    scrollOffset: scrollOffset
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                
            case .perspective:
                PerspectiveAnalysisSection(
                    selfReference: analysis.selfReference,
                    scrollOffset: scrollOffset
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "waveform.path")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(accentColor)
            
            Text("Record your first loop")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(textColor)
            
            Text("Complete a loop to see your patterns")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(textColor.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
    }
}

struct VoiceAnalysisSection: View {
    let speechPattern: SpeechPatternAnalysis
    let voicePattern: VoiceAnalysis
    let scrollOffset: CGFloat
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 24) {
            // Speaking Pace Card
            InsightCard {
                VStack(spacing: 20) {
                    HStack(spacing: 24) {
                        CircularProgress(
                            value: min(speechPattern.wordsPerMinute / 200, 1),
                            label: "\(Int(speechPattern.wordsPerMinute))\nWPM",
                            scrollOffset: scrollOffset
                        )
                        .frame(width: 120, height: 120)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(paceInsight)
                                .font(.system(size: 18, weight: .light))
                                .foregroundColor(textColor)
                            
                            Text("Speaking Pace")
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(textColor.opacity(0.6))
                        }
                    }
                    
                    Divider()
                        .background(accentColor.opacity(0.1))
                    
                    FlowMetrics(speechPattern: speechPattern)
                }
                .padding(24)
            }
            
            // Voice Patterns Card
            InsightCard {
                VStack(spacing: 16) {
                    HStack {
                        Text("Voice Patterns")
                            .font(.system(size: 18, weight: .light))
                            .foregroundColor(textColor)
                        Spacer()
                    }
                    
                    VoiceMetrics(
                        voicePattern: voicePattern,
                        scrollOffset: scrollOffset
                    )
                }
                .padding(24)
            }
            
            // Rhythm Analysis Card
            InsightCard {
                VStack(spacing: 16) {
                    HStack {
                        Text("Rhythm Analysis")
                            .font(.system(size: 18, weight: .light))
                            .foregroundColor(textColor)
                        Spacer()
                    }
                    
                    RhythmVisualizer(
                        consistency: voicePattern.rhythmConsistency,
                        scrollOffset: scrollOffset
                    )
                }
                .padding(24)
            }
        }
    }
    
    private var paceInsight: String {
        switch speechPattern.wordsPerMinute {
        case ...100:
            return "Measured, thoughtful pace"
        case 100...150:
            return "Natural conversational flow"
        default:
            return "Energetic expression"
        }
    }
}

struct CircularProgress: View {
    let value: Double
    let label: String
    let scrollOffset: CGFloat
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    accentColor.opacity(0.1),
                    lineWidth: 12
                )
            
            Circle()
                .trim(from: 0, to: value)
                .stroke(
                    accentColor,
                    style: StrokeStyle(
                        lineWidth: 12,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .rotation3DEffect(
                    .degrees(scrollOffset * 0.1),
                    axis: (x: 0, y: 1, z: 0)
                )
            
            Text(label)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
        }
    }
}

struct VoiceMetrics: View {
    let voicePattern: VoiceAnalysis
    let scrollOffset: CGFloat
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 16) {
            MetricBar(
                label: "Filler Words",
                value: voicePattern.fillerWordPercentage,
                maxValue: 30,
                scrollOffset: scrollOffset
            )
            
            MetricBar(
                label: "Pitch Variation",
                value: min(voicePattern.pitchVariation * 100, 100),
                maxValue: 100,
                scrollOffset: scrollOffset
            )
        }
    }
}

struct MetricBar: View {
    let label: String
    let value: Double
    let maxValue: Double
    let scrollOffset: CGFloat
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 14, weight: .light))
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
                        .frame(width: geometry.size.width * CGFloat(value / maxValue), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            .offset(x: scrollOffset * 0.1)
        }
    }
}

struct RhythmVisualizer: View {
    let consistency: Double
    let scrollOffset: CGFloat
    
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<20, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(accentColor.opacity(0.3))
                    .frame(width: 4, height: height(for: index))
                    .offset(y: offset(for: index))
            }
        }
        .frame(height: 60)
        .animation(.easeInOut(duration: 1), value: scrollOffset)
    }
    
    private func height(for index: Int) -> CGFloat {
        let base = 20 + consistency * 40
        let variation = sin(Double(index) * 0.5 + scrollOffset * 0.05) * 10
        return base + variation
    }
    
    private func offset(for index: Int) -> CGFloat {
        sin(Double(index) * 0.5 + scrollOffset * 0.05) * 5
    }
}

struct InsightCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .shadow(color: Color(hex: "A28497").opacity(0.05), radius: 20)
            )
    }
}

struct LanguageAnalysisSection: View {
    let languagePattern: LanguagePatternAnalysis
    let scrollOffset: CGFloat
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 24) {
            // Emotional Tone Card
            InsightCard {
                VStack(spacing: 20) {
                    HStack(spacing: 24) {
                        EmotionalToneGauge(
                            score: languagePattern.emotionalToneScore,
                            scrollOffset: scrollOffset
                        )
                        .frame(width: 120, height: 120)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(emotionalInsight)
                                .font(.system(size: 18, weight: .light))
                                .foregroundColor(textColor)
                            
                            Text("Emotional Tone")
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(textColor.opacity(0.6))
                        }
                    }
                    
                    WordMetrics(
                        positiveCount: languagePattern.positiveWordCount,
                        negativeCount: languagePattern.negativeWordCount
                    )
                }
                .padding(24)
            }
            
            // Language Structure Card
            InsightCard {
                VStack(spacing: 16) {
                    HStack {
                        Text("Expression Structure")
                            .font(.system(size: 18, weight: .light))
                            .foregroundColor(textColor)
                        Spacer()
                    }
                    
                    ConjunctionAnalysis(
                        causalCount: languagePattern.causalConjunctionCount,
                        adversativeCount: languagePattern.adversativeConjunctionCount,
                        scrollOffset: scrollOffset
                    )
                }
                .padding(24)
            }
            
            // Social Context Card
            InsightCard {
                VStack(spacing: 16) {
                    HStack {
                        Text("Social Context")
                            .font(.system(size: 18, weight: .light))
                            .foregroundColor(textColor)
                        Spacer()
                    }
                    
                    SocialPronounVisualizer(
                        pronouns: languagePattern.socialPronouns,
                        scrollOffset: scrollOffset
                    )
                }
                .padding(24)
            }
        }
    }
    
    private var emotionalInsight: String {
        switch languagePattern.emotionalToneScore {
        case 0.3...1.0:
            return "Predominantly positive tone"
        case -0.3...0.3:
            return "Balanced expression"
        default:
            return "Processing challenges"
        }
    }
}

struct EmotionalToneGauge: View {
    let score: Double
    let scrollOffset: CGFloat
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(accentColor.opacity(0.1), lineWidth: 12)
            
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
                .rotationEffect(.degrees(180))
                .rotation3DEffect(
                    .degrees(scrollOffset * 0.1),
                    axis: (x: 0, y: 1, z: 0)
                )
            
            Rectangle()
                .fill(accentColor)
                .frame(width: 3, height: 20)
                .offset(y: -40)
                .rotationEffect(.degrees(180 * (score + 1)))
            
            Text(String(format: "%.1f", score))
                .font(.system(size: 24, weight: .light))
                .foregroundColor(textColor)
        }
    }
}

struct WordMetrics: View {
    let positiveCount: Int
    let negativeCount: Int
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        HStack(spacing: 20) {
            MetricBox(
                title: "Positive",
                value: String(positiveCount),
                icon: "plus.circle"
            )
            
            MetricBox(
                title: "Negative",
                value: String(negativeCount),
                icon: "minus.circle"
            )
        }
    }
}

struct ConjunctionAnalysis: View {
    let causalCount: Int
    let adversativeCount: Int
    let scrollOffset: CGFloat
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Reasoning Pattern")
                    .font(.system(size: 14, weight: .light))
                Spacer()
                Text("\(causalCount + adversativeCount) connections")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(textColor)
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(accentColor.opacity(0.1))
                    .frame(height: 8)
                    .cornerRadius(4)
                
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(accentColor)
                        .frame(width: causalWidth, height: 8)
                    
                    Rectangle()
                        .fill(Color(hex: "B7A284"))
                        .frame(width: adversativeWidth, height: 8)
                }
                .cornerRadius(4)
            }
            .frame(height: 8)
        }
    }
    
    private var totalCount: Int {
        max(causalCount + adversativeCount, 1)
    }
    
    private var causalWidth: CGFloat {
        CGFloat(causalCount) / CGFloat(totalCount) * UIScreen.main.bounds.width * 0.7
    }
    
    private var adversativeWidth: CGFloat {
        CGFloat(adversativeCount) / CGFloat(totalCount) * UIScreen.main.bounds.width * 0.7
    }
}

struct SocialPronounVisualizer: View {
    let pronouns: SocialPronounAnalysis
    let scrollOffset: CGFloat
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 40) {
                PronounCount(
                    label: "Collective",
                    count: pronouns.weCount,
                    icon: "person.2"
                )
                
                PronounCount(
                    label: "Others",
                    count: pronouns.theyCount,
                    icon: "person.3"
                )
            }
            
            Text("Ratio: \(String(format: "%.1f", pronouns.weTheyRatio))")
                .font(.system(size: 14, weight: .light))
                .foregroundColor(textColor)
        }
    }
}

struct PronounCount: View {
    let label: String
    let count: Int
    let icon: String
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
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

struct PerspectiveAnalysisSection: View {
    let selfReference: SelfReferenceAnalysis
    let scrollOffset: CGFloat
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 24) {
            // Self Reference Card
            InsightCard {
                VStack(spacing: 20) {
                    HStack(spacing: 24) {
                        CircularProgress(
                            value: selfReference.selfReferencePercentage / 100,
                            label: "\(Int(selfReference.selfReferencePercentage))%\nSelf Focus",
                            scrollOffset: scrollOffset
                        )
                        .frame(width: 120, height: 120)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(selfReferenceInsight)
                                .font(.system(size: 18, weight: .light))
                                .foregroundColor(textColor)
                            
                            Text("Personal Perspective")
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(textColor.opacity(0.6))
                        }
                    }
                    
                    Divider()
                        .background(accentColor.opacity(0.1))
                    
                    TimeOrientationChart(
                        past: selfReference.pastTensePercentage,
                        present: selfReference.presentTensePercentage,
                        future: selfReference.futureTensePercentage,
                        scrollOffset: scrollOffset
                    )
                }
                .padding(24)
            }
            
            // Reflection Patterns Card
            InsightCard {
                VStack(spacing: 16) {
                    HStack {
                        Text("Reflection Patterns")
                            .font(.system(size: 18, weight: .light))
                            .foregroundColor(textColor)
                        Spacer()
                    }
                    
                    ReflectionMetrics(
                        uncertaintyCount: selfReference.uncertaintyCount,
                        reflectionCount: selfReference.reflectionCount,
                        scrollOffset: scrollOffset
                    )
                }
                .padding(24)
            }
            
            // Time Perspective Card
            InsightCard {
                VStack(spacing: 16) {
                    HStack {
                        Text("Time Perspective")
                            .font(.system(size: 18, weight: .light))
                            .foregroundColor(textColor)
                        Spacer()
                    }
                    
                    TimeDistributionView(
                        past: selfReference.pastTensePercentage,
                        present: selfReference.presentTensePercentage,
                        future: selfReference.futureTensePercentage
                    )
                }
                .padding(24)
            }
        }
    }
    
    private var selfReferenceInsight: String {
        switch selfReference.selfReferencePercentage {
        case 0...20:
            return "External observation focused"
        case 20...50:
            return "Balanced perspective"
        default:
            return "Deep personal reflection"
        }
    }
}

struct TimeOrientationChart: View {
    let past: Double
    let present: Double
    let future: Double
    let scrollOffset: CGFloat
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Time Orientation")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(textColor)
            
            GeometryReader { geometry in
                HStack(spacing: 4) {
                    TimeBar(
                        value: past,
                        total: total,
                        label: "Past",
                        width: geometry.size.width / 3 - 4,
                        scrollOffset: scrollOffset
                    )
                    
                    TimeBar(
                        value: present,
                        total: total,
                        label: "Present",
                        width: geometry.size.width / 3 - 4,
                        scrollOffset: scrollOffset
                    )
                    
                    TimeBar(
                        value: future,
                        total: total,
                        label: "Future",
                        width: geometry.size.width / 3 - 4,
                        scrollOffset: scrollOffset
                    )
                }
            }
            .frame(height: 120)
        }
    }
    
    private var total: Double {
        past + present + future
    }
}

struct TimeBar: View {
    let value: Double
    let total: Double
    let label: String
    let width: CGFloat
    let scrollOffset: CGFloat
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack {
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: width)
                
                Rectangle()
                    .fill(accentColor)
                    .frame(width: width, height: height)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: height)
            }
            .frame(height: 80)
            .cornerRadius(8)
            
            Text(label)
                .font(.system(size: 14, weight: .light))
                .foregroundColor(textColor)
            
            Text("\(Int(percentage))%")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(textColor.opacity(0.7))
        }
    }
    
    private var height: CGFloat {
        CGFloat(value / total * 80) + scrollOffset * 0.1
    }
    
    private var percentage: Double {
        (value / total) * 100
    }
}

struct ReflectionMetrics: View {
    let uncertaintyCount: Int
    let reflectionCount: Int
    let scrollOffset: CGFloat
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 16) {
            MetricRow(
                icon: "questionmark.circle",
                label: "Uncertainty Markers",
                count: uncertaintyCount,
                scrollOffset: scrollOffset
            )
            
            MetricRow(
                icon: "sparkles",
                label: "Reflection Markers",
                count: reflectionCount,
                scrollOffset: scrollOffset
            )
        }
    }
}

struct MetricRow: View {
    let icon: String
    let label: String
    let count: Int
    let scrollOffset: CGFloat
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .light))
                .foregroundColor(accentColor)
                .frame(width: 40)
            
            Text(label)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(textColor)
            
            Spacer()
            
            Text("\(count)")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(textColor)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(accentColor.opacity(0.05))
        )
        .offset(x: scrollOffset * 0.1)
    }
}

struct TimeDistributionView: View {
    let past: Double
    let present: Double
    let future: Double
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .leading) {
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color(hex: "4ECB71"))
                            .frame(width: geometry.size.width * CGFloat(pastRatio))
                        
                        Rectangle()
                            .fill(accentColor)
                            .frame(width: geometry.size.width * CGFloat(presentRatio))
                        
                        Rectangle()
                            .fill(Color(hex: "B7A284"))
                            .frame(width: geometry.size.width * CGFloat(futureRatio))
                    }
                    .cornerRadius(8)
                }
            }
            .frame(height: 16)
            
            HStack(spacing: 20) {
                TimeLabel(color: Color(hex: "4ECB71"), label: "Past", value: Int(past))
                TimeLabel(color: accentColor, label: "Present", value: Int(present))
                TimeLabel(color: Color(hex: "B7A284"), label: "Future", value: Int(future))
            }
        }
    }
    
    private var total: Double {
        past + present + future
    }
    
    private var pastRatio: Double {
        past / total
    }
    
    private var presentRatio: Double {
        present / total
    }
    
    private var futureRatio: Double {
        future / total
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

struct FlowingBackground: View {
    @State private var phase = 0.0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let rect = Path(CGRect(origin: .zero, size: size))
                context.clip(to: rect)
                
                let colors = [
                    Color(hex: "A28497").opacity(0.1),
                    Color(hex: "B7A284").opacity(0.1)
                ]
                
                let timeNow = timeline.date.timeIntervalSinceReferenceDate
                phase = timeNow.remainder(dividingBy: 10)
                
                let wavelength = size.width / 4
                let amplitude = size.height / 16
                let baseline = size.height * 0.5
                
                for i in 0..<2 {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: baseline))
                    
                    for x in stride(from: 0, through: size.width, by: 1) {
                        let relativeX = x / wavelength
                        let normalizedPhase = phase + Double(i) * .pi / 2
                        let y = baseline + sin(relativeX + normalizedPhase) * amplitude
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    
                    context.stroke(
                        path,
                        with: .color(colors[i]),
                        lineWidth: 2
                    )
                }
            }
        }
    }
}

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct FlowMetrics: View {
    let speechPattern: SpeechPatternAnalysis
    
    var body: some View {
        HStack(spacing: 20) {
            MetricBox(
                title: "Average Pause",
                value: String(format: "%.1fs", speechPattern.averagePauseDuration),
                icon: "stopwatch"
            )
            
            MetricBox(
                title: "Longest Pause",
                value: String(format: "%.1fs", speechPattern.longestPause),
                icon: "timer"
            )
        }
    }
}

struct MetricBox: View {
    let title: String
    let value: String
    let icon: String
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .light))
                .foregroundColor(accentColor)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(textColor)
                
                Text(title)
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(textColor.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "A28497").opacity(0.05))
        )
    }
}
