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
    private let backgroundColor = Color(hex: "FAFBFC")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            FlowingBackground(color: accentColor)
                .opacity(0.3)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    header
                    
                    if analysisManager.analyzedLoops.count == 3 {
                        Text("It's three!")
                            .onAppear {
                                print(analysisManager.analyzedLoops)
                            }
                        TabView(selection: $selectedTab) {
                            TodayAnalysisView(analysisManager: analysisManager)
                                .tag("today")
                                .transition(.opacity)
                            
                            ComingSoonView(title: "compare")
                                .tag("compare")
                            
                            ComingSoonView(title: "trends")
                                .tag("trends")
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                    } else {
                        IncompleteView(count: analysisManager.analyzedLoops.count)
                            .transition(.opacity)
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
                    Text(headerSubtitle)
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(textColor.opacity(0.7))
                }
                Spacer()
            }
            .offset(y: animateIn ? 0 : 20)
            .opacity(animateIn ? 1 : 0)
            
            if analysisManager.analyzedLoops.count == 3 {
                InsightTabs(selection: $selectedTab)
                    .transition(.opacity)
            }
        }
    }
    
    private var headerSubtitle: String {
        analysisManager.analyzedLoops.count == 3 ?
            "daily reflection analysis" :
            "complete your daily loops"
    }
}


struct InsightTabs: View {
    @Binding var selection: String
    
    private let tabs = [
        ("today", "Today"),
        ("compare", "Compare"),
        ("trends", "Trends")
    ]
    
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.0) { tab in
                Button(action: { selection = tab.0 }) {
                    Text(tab.1)
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(selection == tab.0 ? .white : accentColor)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            selection == tab.0 ?
                                accentColor :
                                accentColor.opacity(0.1)
                        )
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: accentColor.opacity(0.1), radius: 20)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct TodayAnalysisView: View {
    @ObservedObject var analysisManager: AnalysisManager
    @State private var selectedLoopIndex = 0
    @State private var animateIn = false
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Text("hello")
                // Aggregated Stats
                AggregateInsights()
                    .offset(y: animateIn ? 0 : 20)
                    .opacity(animateIn ? 1 : 0)
                
                // Individual Loop Analysis
                if !analysisManager.analyzedLoops.isEmpty {
                    VStack(spacing: 24) {
                        // Loop Selector
                        HStack(spacing: 16) {
                            ForEach(0..<analysisManager.analyzedLoops.count, id: \.self) { index in
                                Button(action: {
                                    withAnimation {
                                        selectedLoopIndex = index
                                    }
                                }) {
                                    Text("\(index + 1)")
                                        .font(.system(size: 16, weight: .light))
                                        .foregroundColor(selectedLoopIndex == index ? .white : accentColor)
                                        .frame(width: 40, height: 40)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(selectedLoopIndex == index ? accentColor : accentColor.opacity(0.1))
                                        )
                                }
                            }
                        }
                        
                        // Selected Loop Analysis
                        if let loop = analysisManager.analyzedLoops[safe: selectedLoopIndex] {
                            VStack(spacing: 24) {
                                // Prompt
                                PromptCard(loop: loop)
                                
                                // Analysis Components
                                SpeechAnalysisView(analysis: loop.speechPattern)
                                VoiceAnalysisView(analysis: loop.voicePattern)
                                LanguageAnalysisView(analysis: loop.languagePattern)
                                SelfReferenceView(analysis: loop.selfReference)
                            }
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.95)),
                                removal: .opacity.combined(with: .scale(scale: 1.05))
                            ))
                        }
                    }
                    .offset(y: animateIn ? 0 : 40)
                    .opacity(animateIn ? 1 : 0)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 32)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                animateIn = true
            }
        }
    }
}

struct InsightCard<Content: View>: View {
    let title: String
    let content: Content
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(.system(size: 24, weight: .ultraLight))
                .foregroundColor(textColor)
            
            content
        }
        .padding(24)
        .background(
            ZStack {
                Color.white
                FlowingBackground(color: accentColor)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: accentColor.opacity(0.05), radius: 20)
        )
    }
}

struct MetricInsightView: View {
    let insight: MetricInsight
    let title: String
    let suffix: String
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(textColor.opacity(0.6))
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.1f", insight.value))
                        .font(.system(size: 28, weight: .light))
                    Text(suffix)
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(textColor.opacity(0.6))
                }
            }
            
            Text(insight.interpretation)
                .font(.system(size: 15, weight: .light))
                .foregroundColor(textColor.opacity(0.8))
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(accentColor.opacity(0.04))
                .cornerRadius(12)
        }
    }
}

struct EmotionalToneView: View {
    let score: Double
    let positive: Int
    let negative: Int
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Emotional Tone")
                        .font(.system(size: 14, weight: .light))
                    Text(String(format: "%.2f", score))
                        .font(.system(size: 28, weight: .light))
                }
                
                Spacer()
                
                EmotionalGauge(value: score)
            }
            
            HStack(spacing: 20) {
                WordCount(count: positive, label: "Positive", color: Color(hex: "4ECB71"))
                WordCount(count: negative, label: "Negative", color: Color(hex: "FF6B6B"))
            }
        }
    }
}

struct EmotionalGauge: View {
    let value: Double
    
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: 0.5)
                .stroke(accentColor.opacity(0.1), lineWidth: 4)
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(180))
            
            Circle()
                .trim(from: 0, to: 0.5)
                .stroke(
                    LinearGradient(
                        colors: [accentColor.opacity(0.8), accentColor.opacity(0.4)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(180))
            
            Rectangle()
                .fill(accentColor)
                .frame(width: 2, height: 12)
                .offset(y: -24)
                .rotationEffect(.degrees(180 * (value + 1)))
        }
    }
}

struct WordCount: View {
    let count: Int
    let label: String
    let color: Color
    
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 8, height: 8)
            
            Text("\(count)")
                .font(.system(size: 16, weight: .medium))
            
            Text(label)
                .font(.system(size: 14, weight: .light))
                .foregroundColor(textColor.opacity(0.6))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(color.opacity(0.05))
        .cornerRadius(12)
    }
}

struct ReflectionMetric: View {
    let count: Int
    let title: String
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .light))
                .foregroundColor(textColor.opacity(0.6))
            
            Text("\(count)")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(textColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(accentColor.opacity(0.04))
        .cornerRadius(16)
    }
}

struct LoopButton: View {
    let index: Int
    let isSelected: Bool
    let action: () -> Void
    
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        Button(action: action) {
            Text("\(index)")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(isSelected ? .white : accentColor)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? accentColor : accentColor.opacity(0.1))
                )
        }
    }
}

struct SpeechAnalysisView: View {
    let analysis: SpeechPatternAnalysis
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        InsightCard(title: "Speech Patterns") {
            VStack(spacing: 24) {
                // WPM with interpretation
                MetricInsightView(
                    insight: analysis.wordsPerMinute,
                    title: "Speaking Pace",
                    suffix: "WPM"
                )
                
                // Pause analysis combining MetricInsight and raw values
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 24) {
                        MetricPill(
                            value: Double(analysis.pauseCount),
                            label: "Pauses"
                        )
                        
                        MetricPill(
                            value: analysis.averagePauseDuration.value,
                            label: "Avg Duration",
                            format: "%.1fs"
                        )
                        
                        MetricPill(
                            value: analysis.longestPause,
                            label: "Longest",
                            format: "%.1fs"
                        )
                    }
                    
                    // Show interpretation for pause duration
                    Text(analysis.averagePauseDuration.interpretation)
                        .font(.system(size: 15, weight: .light))
                        .foregroundColor(textColor.opacity(0.8))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(accentColor.opacity(0.04))
                        .cornerRadius(12)
                }
            }
        }
    }
}

struct VoiceAnalysisView: View {
    let analysis: VoiceAnalysis
    
    var body: some View {
        InsightCard(title: "Voice Quality") {
            VStack(spacing: 24) {
                // Filler words insight
                MetricInsightView(
                    insight: analysis.fillerWords,
                    title: "Expression Clarity",
                    suffix: "%"
                )
                
                HStack(spacing: 20) {
                    // Pitch variation with interpretation
                    MetricInsightView(
                        insight: analysis.pitchVariation,
                        title: "Pitch Variation",
                        suffix: "%"
                    )
                    
                    // Rhythm consistency with interpretation
                    MetricInsightView(
                        insight: analysis.rhythmConsistency,
                        title: "Rhythm",
                        suffix: "%"
                    )
                }
            }
        }
    }
}

struct LanguageAnalysisView: View {
    let analysis: LanguagePatternAnalysis
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        InsightCard(title: "Language Patterns") {
            VStack(spacing: 24) {
                // Emotional tone with full context
                VStack(spacing: 16) {
                    MetricInsightView(
                        insight: analysis.emotionalTone,
                        title: "Emotional Tone",
                        suffix: ""
                    )
                    
                    HStack(spacing: 20) {
                        WordCount(
                            count: analysis.positiveWordCount,
                            label: "Positive",
                            color: Color(hex: "4ECB71")
                        )
                        WordCount(
                            count: analysis.negativeWordCount,
                            label: "Negative",
                            color: Color(hex: "FF6B6B")
                        )
                    }
                }
                
                // Expression style showing both insight and raw counts
                VStack(spacing: 16) {
                    MetricInsightView(
                        insight: analysis.expressionStyle,
                        title: "Expression Style",
                        suffix: ""
                    )
                    
                    HStack(spacing: 20) {
                        ConnectionCount(
                            count: analysis.causalConjunctionCount,
                            label: "Causal"
                        )
                        ConnectionCount(
                            count: analysis.adversativeConjunctionCount,
                            label: "Contrasting"
                        )
                    }
                }
                
                // Social context with pronouns breakdown
                VStack(spacing: 16) {
                    MetricInsightView(
                        insight: analysis.socialContext,
                        title: "Social Context",
                        suffix: ""
                    )
                    
                    HStack(spacing: 20) {
                        PronounCount(
                            count: analysis.socialPronouns.weCount,
                            label: "We/Us"
                        )
                        PronounCount(
                            count: analysis.socialPronouns.theyCount,
                            label: "They/Them"
                        )
                    }
                }
            }
        }
    }
}

struct SelfReferenceView: View {
    let analysis: SelfReferenceAnalysis
    
    var body: some View {
        InsightCard(title: "Self Expression") {
            VStack(spacing: 24) {
                // Self reference with interpretation
                MetricInsightView(
                    insight: analysis.selfReference,
                    title: "Self Reference",
                    suffix: "%"
                )
                
                // Tense distribution with interpretation
                MetricInsightView(
                    insight: analysis.tenseDistribution,
                    title: "Time Orientation",
                    suffix: ""
                )
                
                // Reflection metrics combining insight and raw count
                VStack(spacing: 16) {
                    MetricInsightView(
                        insight: analysis.reflectionCount,
                        title: "Reflection Depth",
                        suffix: "markers"
                    )
                    
                    MetricPill(
                        value: Double(analysis.uncertaintyCount),
                        label: "Uncertainty Expressions"
                    )
                }
            }
        }
    }
}

// Supporting Components
struct MetricPill: View {
    let value: Double
    let label: String
    var format: String = "%.0f"
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(String(format: format, value))
                .font(.system(size: 18, weight: .medium))
            
            Text(label)
                .font(.system(size: 12, weight: .light))
                .foregroundColor(textColor.opacity(0.6))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(accentColor.opacity(0.04))
        .cornerRadius(12)
    }
}

struct ConnectionCount: View {
    let count: Int
    let label: String
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        HStack(spacing: 8) {
            Text("\(count)")
                .font(.system(size: 18, weight: .medium))
            Text(label)
                .font(.system(size: 14, weight: .light))
                .foregroundColor(textColor.opacity(0.6))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(accentColor.opacity(0.04))
        .cornerRadius(12)
    }
}

struct PronounCount: View {
    let count: Int
    let label: String
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(count)")
                .font(.system(size: 18, weight: .medium))
            Text(label)
                .font(.system(size: 12, weight: .light))
                .foregroundColor(textColor.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(accentColor.opacity(0.04))
        .cornerRadius(12)
    }
}

struct PromptCard: View {
    let loop: LoopAnalysis
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(loop.promptText)
                .font(.system(size: 20, weight: .light))
                .foregroundColor(textColor)
            
            Text(loop.timestamp.formatted(date: .abbreviated, time: .shortened))
                .font(.system(size: 14, weight: .light))
                .foregroundColor(textColor.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: accentColor.opacity(0.05), radius: 15)
        )
    }
}

struct AggregateInsights: View {
    @ObservedObject var analysisManager = AnalysisManager()
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 24) {
                // Voice Stats
                InsightSection(title: "Voice Expression") {
                    VStack(spacing: 20) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("\(Int( analysisManager.sessionStats.averageWordsPerMinute))")
                                .font(.system(size: 40, weight: .ultraLight))
                            Text("WPM")
                                .font(.system(size: 16, weight: .light))
                                .foregroundColor(textColor.opacity(0.7))
                        }
                        
                        HStack(spacing: 20) {
                            StatItem(
                                value: String(format: "%.1f%%", 100 -  analysisManager.sessionStats.averageFillerWordPercentage),
                                label: "Clarity"
                            )
                            StatItem(
                                value: String(format: "%.1f%%",  analysisManager.sessionStats.averageRhythmConsistency),
                                label: "Rhythm"
                            )
                            StatItem(
                                value: String(format: "%.1f%%",  analysisManager.sessionStats.averagePitchVariation),
                                label: "Variation"
                            )
                        }
                    }
                }
                
                // Expression Stats
                InsightSection(title: "Expression") {
                    VStack(spacing: 20) {
                        HStack(spacing: 20) {
                            StatItem(
                                value: "\( analysisManager.sessionStats.totalReflectionMarkers)",
                                label: "Reflections"
                            )
                            StatItem(
                                value: "\( analysisManager.sessionStats.totalUncertaintyMarkers)",
                                label: "Considerations"
                            )
                        }
                        
                        EmotionalStats(
                            positive:  analysisManager.sessionStats.totalPositiveWords,
                            negative:  analysisManager.sessionStats.totalNegativeWords,
                            tone:  analysisManager.sessionStats.averageEmotionalToneScore
                        )
                    }
                }
            }
        }
    }
}

struct InsightSection<Content: View>: View {
    let title: String
    let content: Content
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(.system(size: 24, weight: .ultraLight))
                .foregroundColor(textColor)
            
            content
        }
        .padding(24)
        .background(
            ZStack {
                Color.white
                FlowingBackground(color: accentColor)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: accentColor.opacity(0.05), radius: 20)
        )
    }
}

struct StatItem: View {
    let value: String
    let label: String
    
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .light))
            Text(label)
                .font(.system(size: 14, weight: .light))
                .foregroundColor(textColor.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

struct EmotionalStats: View {
    let positive: Int
    let negative: Int
    let tone: Double
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                WordStat(count: positive, label: "Positive")
                WordStat(count: negative, label: "Negative")
            }
            
            Divider()
                .background(accentColor.opacity(0.1))
            
            HStack(spacing: 8) {
                Text("Emotional Tone:")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(textColor.opacity(0.7))
                Text(String(format: "%.2f", tone))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(textColor)
            }
        }
        .padding(16)
        .background(accentColor.opacity(0.05))
        .cornerRadius(16)
    }
}

struct WordStat: View {
    let count: Int
    let label: String
    
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        HStack(spacing: 8) {
            Text("\(count)")
                .font(.system(size: 16, weight: .medium))
            Text(label)
                .font(.system(size: 14, weight: .light))
                .foregroundColor(textColor.opacity(0.7))
        }
    }
}

struct IncompleteView: View {
    let count: Int
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .trim(from: 0, to: CGFloat(count) / 3)
                    .stroke(
                        accentColor,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("\(count)")
                        .font(.system(size: 32, weight: .light))
                    Text("of 3")
                        .font(.system(size: 16, weight: .light))
                }
                .foregroundColor(textColor)
            }
            
            VStack(spacing: 16) {
                Text("Complete Your Daily Loops")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(textColor)
                
                Text("\(3 - count) more loops needed")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(textColor.opacity(0.7))
            }
            
            HStack(spacing: 24) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(index < count ? accentColor : accentColor.opacity(0.2))
                        .frame(width: 12, height: 12)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

struct ComingSoonView: View {
    let title: String
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(accentColor)
            }
            
            Text(title)
                .font(.system(size: 24, weight: .light))
                .foregroundColor(textColor)
            
            Text("Coming Soon")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(textColor.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 60)
    }
}
