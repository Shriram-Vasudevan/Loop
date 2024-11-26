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
    @State private var selectedLoopIndex = 0
    @State private var animateIn = false
    @State private var selectedTimeframe: TimeframeFilter = .current
    
    let accentColor = Color(hex: "A28497")
    let backgroundColor = Color(hex: "FAFBFC")
    let surfaceColor = Color(hex: "F8F5F7")
    let textColor = Color(hex: "2C3E50")
    
    enum TimeframeFilter {
        case current, all
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                headerSection
                timeframeSelector
                if let analysis = analysisManager.currentLoopAnalysis {
                    mainContent(analysis)
                } else {
                    emptyState
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
        .background(backgroundColor.edgesIgnoringSafeArea(.all))
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateIn = true
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Loop Analysis")
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundColor(textColor)
            Text("Understanding your reflections")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(textColor.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
    }
    
    private var timeframeSelector: some View {
        HStack(spacing: 16) {
            ForEach([TimeframeFilter.current, .all], id: \.self) { filter in
                Button(action: {
                    withAnimation {
                        selectedTimeframe = filter
                    }
                }) {
                    Text(filter == .current ? "Current Loop" : "All Loops")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(selectedTimeframe == filter ? .white : accentColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(selectedTimeframe == filter ? accentColor : accentColor.opacity(0.1))
                        )
                }
            }
        }
    }
    
    private func mainContent(_ analysis: LoopAnalysis) -> some View {
        VStack(spacing: 24) {
            emotionalAnalysisCard(analysis.emotion)
            speechPatternsCard(analysis.speechPattern)
            cognitiveAnalysisCard(analysis.cognitive)
            selfReferenceCard(analysis.selfReference)
            thematicAnalysisCard(analysis.thematic)
            if selectedTimeframe == .all {
                loopComparisonSection
            }
        }
    }
    
    private func emotionalAnalysisCard(_ emotion: EmotionAnalysis) -> some View {
        InsightCard(title: "Emotional Patterns", subtitle: "How you expressed yourself") {
            VStack(spacing: 24) {
                HStack(spacing: 20) {
                    EmotionIntensityRing(
                        intensity: emotion.emotionalIntensity,
                        sentiment: emotion.overallSentiment
                    )
                    .frame(width: 120, height: 120)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(emotion.primaryEmotions.prefix(3), id: \.self) { emotion in
                            EmotionRow(emotion: emotion)
                        }
                    }
                }
                
                EmotionalKeywords(words: emotion.emotionalWords)
                EmotionalInsight(intensity: emotion.emotionalIntensity, complexity: emotion.emotionalComplexity)
            }
        }
    }
    
    private func speechPatternsCard(_ speech: SpeechPatternAnalysis) -> some View {
        InsightCard(title: "Speech Flow", subtitle: "Your speaking patterns") {
            VStack(spacing: 24) {
                HStack(spacing: 20) {
                    SpeechFlowGauge(
                        flowScore: speech.speechFlowScore,
                        wpm: speech.wordsPerMinute
                    )
                    .frame(width: 120, height: 120)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        StatRow(
                            title: "Articulation Rate",
                            value: String(format: "%.1f", speech.articulationRate),
                            icon: "waveform"
                        )
                        StatRow(
                            title: "Average Pause",
                            value: String(format: "%.1fs", speech.averagePauseDuration),
                            icon: "timer"
                        )
                        StatRow(
                            title: "Longest Pause",
                            value: String(format: "%.1fs", speech.longestPause),
                            icon: "clock"
                        )
                    }
                }
                
                PausePatternVisualizer(
                    pauseCount: speech.pauseCount,
                    averageDuration: speech.averagePauseDuration
                )
                
                SpeechInsight(
                    wpm: speech.wordsPerMinute,
                    flowScore: speech.speechFlowScore
                )
            }
        }
    }
    
    private func cognitiveAnalysisCard(_ cognitive: CognitiveAnalysis) -> some View {
        InsightCard(title: "Thought Structure", subtitle: "Your cognitive patterns") {
            VStack(spacing: 24) {
                CognitiveMetricsChart(analysis: cognitive)
                    .frame(height: 160)
                
                HStack(spacing: 16) {
                    CognitiveMetricBox(
                        title: "Analytical Depth",
                        value: cognitive.analyticalScore,
                        icon: "brain"
                    )
                    CognitiveMetricBox(
                        title: "Complexity",
                        value: cognitive.complexityScore,
                        icon: "circle.grid.cross"
                    )
                }
                
                ThoughtPatternTags(
                    insightWords: cognitive.insightWords,
                    discrepancyWords: cognitive.discrepancyWords
                )
                
                CognitiveInsight(
                    analyticalScore: cognitive.analyticalScore,
                    complexityScore: cognitive.complexityScore
                )
            }
        }
    }
    
    private func selfReferenceCard(_ selfRef: SelfReferenceAnalysis) -> some View {
        InsightCard(title: "Self Expression", subtitle: "Your perspective focus") {
            VStack(spacing: 24) {
                HStack(spacing: 20) {
                    SelfReferencePie(
                        selfPercentage: selfRef.selfReferencePercentage,
                        otherReferences: selfRef.otherReferences
                    )
                    .frame(width: 120, height: 120)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        TenseDistributionBar(
                            past: selfRef.pastTensePercentage,
                            present: selfRef.presentTensePercentage,
                            future: selfRef.futureTensePercentage
                        )
                    }
                }
                
                VoiceAnalysis(
                    activeVoicePercentage: selfRef.activeVoicePercentage
                )
                
                SelfExpressionInsight(
                    selfRefPercentage: selfRef.selfReferencePercentage,
                    activeVoice: selfRef.activeVoicePercentage
                )
            }
        }
    }
    
    private func thematicAnalysisCard(_ thematic: ThematicAnalysis) -> some View {
        InsightCard(title: "Themes & Context", subtitle: "Key topics and connections") {
            VStack(spacing: 24) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(thematic.keyTopics.prefix(5)), id: \.key) { topic, weight in
                            TopicBubble(
                                topic: topic,
                                weight: weight,
                                color: accentColor
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
                
                if !thematic.significantPhrases.isEmpty {
                    SignificantPhraseCloud(phrases: thematic.significantPhrases)
                }
                
                if !thematic.namedEntities.isEmpty {
                    NamedEntitiesGrid(entities: thematic.namedEntities)
                }
                
                ThematicInsight(
                    coherence: thematic.topicCoherence,
                    topicCount: thematic.keyTopics.count
                )
            }
        }
    }
    
    private var loopComparisonSection: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Loop Progression")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(textColor)
                Spacer()
                Text("\(analysisManager.analyzedLoops.count) analyzed")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(textColor.opacity(0.7))
            }
            
            TabView(selection: $selectedLoopIndex) {
                ForEach(Array(analysisManager.analyzedLoops.enumerated()), id: \.element.loopId) { index, loop in
                    LoopComparisonCard(
                        analysis: loop,
                        totalLoops: analysisManager.analyzedLoops.count,
                        index: index
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 200)
            
            PageIndicator(
                totalPages: analysisManager.analyzedLoops.count,
                currentPage: selectedLoopIndex
            )
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(accentColor)
            Text("Ready for Analysis")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(textColor)
            Text("Record your loop to see insights")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(textColor.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
    }
}

// Supporting Views - Part 1
struct EmotionIntensityRing: View {
    let intensity: Double
    let sentiment: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.1), lineWidth: 12)
            
            Circle()
                .trim(from: 0, to: CGFloat(intensity))
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.7),
                            sentiment > 0 ? Color.green : Color.red
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: 4) {
                Text("\(Int(intensity * 100))%")
                    .font(.system(size: 24, weight: .light))
                Text("Intensity")
                    .font(.system(size: 12, weight: .light))
            }
            .foregroundColor(Color(hex: "2C3E50"))
        }
    }
}

struct EmotionRow: View {
    let emotion: String
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(getEmotionColor(emotion))
                .frame(width: 8, height: 8)
            Text(emotion.capitalized)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(Color(hex: "2C3E50"))
        }
    }
    
    private func getEmotionColor(_ emotion: String) -> Color {
        let colors: [String: Color] = [
            "happy": .blue,
            "sad": .purple,
            "angry": .red,
            "excited": .orange,
            "worried": .green,
            "proud": .yellow,
            "grateful": .pink
        ]
        return colors[emotion.lowercased()] ?? .gray
    }
}

struct EmotionalKeywords: View {
    let words: [String: Double]
    
    var sortedWords: [(String, Double)] {
        words.sorted { $0.value > $1.value }.prefix(8).map { ($0.key, $0.value) }
    }
    
    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(sortedWords, id: \.0) { word, intensity in
                Text(word)
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(hex: "A28497").opacity(0.8 + (intensity * 0.2)))
                    )
            }
        }
    }
}

struct SpeechFlowGauge: View {
    let flowScore: Double
    let wpm: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.1), lineWidth: 12)
            
            Circle()
                .trim(from: 0, to: CGFloat(flowScore))
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(hex: "A28497"),
                            Color(hex: "A28497").opacity(0.6)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: 4) {
                Text("\(Int(wpm))")
                    .font(.system(size: 24, weight: .light))
                Text("WPM")
                    .font(.system(size: 12, weight: .light))
            }
            .foregroundColor(Color(hex: "2C3E50"))
        }
    }
}

struct PausePatternVisualizer: View {
    let pauseCount: Int
    let averageDuration: Double
    
    var bars: [Double] {
        Array(repeating: averageDuration, count: pauseCount)
            .map { $0 + Double.random(in: -0.2...0.2) }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(bars.indices, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: "A28497").opacity(0.3))
                    .frame(width: 4, height: CGFloat(bars[index] * 20))
                    .animation(.easeInOut(duration: 0.5), value: bars[index])
            }
        }
        .frame(height: 40)
    }
}

struct CognitiveMetricsChart: View {
    let analysis: CognitiveAnalysis
    
    var data: [(String, Double)] {
        [
            ("Analytical", analysis.analyticalScore),
            ("Complexity", analysis.complexityScore),
            ("Causality", analysis.causalityScore * 100),
            ("Qualifier", analysis.qualifierFrequency * 100)
        ]
    }
    
    var body: some View {
        Chart {
            ForEach(data, id: \.0) { item in
                BarMark(
                    x: .value("Category", item.0),
                    y: .value("Score", item.1)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hex: "A28497"),
                            Color(hex: "A28497").opacity(0.6)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
    }
}

struct ThoughtPatternTags: View {
    let insightWords: [String]
    let discrepancyWords: [String]
    
    var body: some View {
        VStack(spacing: 16) {
            if !insightWords.isEmpty {
                PatternSection(title: "Insights", words: insightWords)
            }
            if !discrepancyWords.isEmpty {
                PatternSection(title: "Discrepancies", words: discrepancyWords)
            }
        }
    }
}

struct PatternSection: View {
    let title: String
    let words: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(hex: "2C3E50").opacity(0.7))
            
            FlowLayout(spacing: 8) {
                ForEach(words, id: \.self) { word in
                    Text(word)
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(Color(hex: "A28497"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color(hex: "A28497").opacity(0.1))
                        )
                }
            }
        }
    }
}

struct SelfReferencePie: View {
    let selfPercentage: Double
    let otherReferences: Int
    
    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: 1)
                .stroke(Color.gray.opacity(0.1), lineWidth: 12)
            
            Circle()
                .trim(from: 0, to: selfPercentage / 100)
                .stroke(
                    Color(hex: "A28497"),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: 4) {
                Text("\(Int(selfPercentage))%")
                    .font(.system(size: 24, weight: .light))
                Text("Self")
                    .font(.system(size: 12, weight: .light))
            }
            .foregroundColor(Color(hex: "2C3E50"))
        }
    }
}

struct TenseDistributionBar: View {
    let past: Double
    let present: Double
    let future: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TenseRow(label: "Past", percentage: past, color: .blue)
            TenseRow(label: "Present", percentage: present, color: .green)
            TenseRow(label: "Future", percentage: future, color: .purple)
        }
    }
}

struct TenseRow: View {
    let label: String
    let percentage: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color(hex: "2C3E50").opacity(0.7))
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(percentage / 100))
                }
            }
            .frame(height: 6)
            .cornerRadius(3)
        }
    }
}

struct VoiceAnalysis: View {
    let activeVoicePercentage: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Voice Usage")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(hex: "2C3E50").opacity(0.7))
            
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color(hex: "A28497"))
                    .frame(width: UIScreen.main.bounds.width * 0.5 * CGFloat(activeVoicePercentage / 100))
                
                Rectangle()
                    .fill(Color(hex: "A28497").opacity(0.3))
                    .frame(width: UIScreen.main.bounds.width * 0.5 * CGFloat((100 - activeVoicePercentage) / 100))
            }
            .frame(height: 24)
            .cornerRadius(12)
            
            HStack {
                Text("Active")
                    .font(.system(size: 12, weight: .light))
                Spacer()
                Text("Passive")
                    .font(.system(size: 12, weight: .light))
            }
            .foregroundColor(Color(hex: "2C3E50"))
        }
    }
}

struct SignificantPhraseCloud: View {
    let phrases: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Key Phrases")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(hex: "2C3E50").opacity(0.7))
            
            FlowLayout(spacing: 8) {
                ForEach(phrases, id: \.self) { phrase in
                    Text(phrase)
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(Color(hex: "A28497"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "A28497").opacity(0.1))
                        )
                }
            }
        }
    }
}

struct NamedEntitiesGrid: View {
    let entities: [String]
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("People & Places")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(hex: "2C3E50").opacity(0.7))
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(entities, id: \.self) { entity in
                    EntityBubble(name: entity)
                }
            }
        }
    }
}

struct EntityBubble: View {
    let name: String
    
    var body: some View {
        HStack(spacing: 8) {
            Text(String(name.prefix(1)))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color(hex: "A28497")))
            
            Text(name)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(hex: "2C3E50"))
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "A28497").opacity(0.1))
        )
    }
}

struct ThematicInsight: View {
    let coherence: Double
    let topicCount: Int
    
    var message: String {
        if coherence > 0.7 {
            return "Your thoughts were deeply connected"
        } else if coherence > 0.4 {
            return "You explored related themes"
        } else {
            return "You covered diverse topics"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: coherence > 0.5 ? "link.circle.fill" : "circle.grid.2x2.fill")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(Color(hex: "A28497"))
            
            Text(message)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(Color(hex: "2C3E50"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "A28497").opacity(0.1))
        )
    }
}

struct LoopComparisonCard: View {
    let analysis: LoopAnalysis
    let totalLoops: Int
    let index: Int
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Loop \(index + 1) of \(totalLoops)")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color(hex: "2C3E50"))
                    Text(timeString(from: analysis.timestamp))
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(Color(hex: "2C3E50").opacity(0.7))
                }
                Spacer()
            }
            
            ComparisonMetrics(analysis: analysis)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10)
        )
        .padding(.horizontal)
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct ComparisonMetrics: View {
    let analysis: LoopAnalysis
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                MetricBox(
                    title: "Words/Min",
                    value: String(format: "%.0f", analysis.speechPattern.wordsPerMinute)
                )
                MetricBox(
                    title: "Emotion",
                    value: String(format: "%.0f%%", analysis.emotion.emotionalIntensity * 100)
                )
                MetricBox(
                    title: "Complexity",
                    value: String(format: "%.0f%%", analysis.cognitive.complexityScore)
                )
            }
            
            if !analysis.emotion.primaryEmotions.isEmpty {
                HStack {
                    ForEach(analysis.emotion.primaryEmotions.prefix(3), id: \.self) { emotion in
                        Text(emotion)
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(Color(hex: "A28497"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color(hex: "A28497").opacity(0.1))
                            )
                    }
                }
            }
        }
    }
}

struct MetricBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color(hex: "2C3E50").opacity(0.7))
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "2C3E50"))
        }
        .frame(maxWidth: .infinity)
    }
}

struct PageIndicator: View {
    let totalPages: Int
    let currentPage: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(Color(hex: "A28497").opacity(index == currentPage ? 1 : 0.2))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut, value: currentPage)
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            let point = CGPoint(x: position.x + bounds.minX, y: position.y + bounds.minY)
            subviews[index].place(at: point, proposal: .unspecified)
        }
    }
    
    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        guard !subviews.isEmpty else { return ([], .zero) }
        
        let maxWidth = proposal.width ?? .infinity
        var currentPosition = CGPoint.zero
        var positions: [CGPoint] = []
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentPosition.x + size.width > maxWidth && currentPosition.x > 0 {
                currentPosition.x = 0
                currentPosition.y += rowHeight + spacing
                totalHeight += rowHeight + spacing
                rowHeight = 0
            }
            
            positions.append(currentPosition)
            rowHeight = max(rowHeight, size.height)
            currentPosition.x += size.width + spacing
        }
        
        totalHeight += rowHeight
        
        return (positions, CGSize(width: maxWidth, height: totalHeight))
    }
}

struct InsightCard<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content
    
    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(Color(hex: "2C3E50"))
                Text(subtitle)
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(Color(hex: "2C3E50").opacity(0.7))
            }
            content
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 20)
        )
    }
}

struct TopicBubble: View {
    let topic: String
    let weight: Double
    let color: Color
    
    var size: CGFloat {
        40 + CGFloat(weight * 40)
    }
    
    var body: some View {
        Text(topic)
            .font(.system(size: 14, weight: .light))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
    }
}

struct CognitiveMetricBox: View {
    let title: String
    let value: Double
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "A28497").opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(Color(hex: "A28497"))
            }
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(hex: "2C3E50").opacity(0.7))
                Text("\(Int(value))%")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(hex: "2C3E50"))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10)
        )
    }
}

struct SpeechInsight: View {
    let wpm: Double
    let flowScore: Double
    
    var message: String {
        if wpm > 160 {
            return "Your pace was energetic and flowing"
        } else if wpm > 120 {
            return "You spoke at a comfortable, natural pace"
        } else {
            return "Your pace was measured and thoughtful"
        }
    }
    
    var icon: String {
        if wpm > 160 {
            return "bolt.fill"
        } else if wpm > 120 {
            return "waveform.path"
        } else {
            return "arrow.left.and.right"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(Color(hex: "A28497"))
            
            Text(message)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(Color(hex: "2C3E50"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "A28497").opacity(0.1))
        )
    }
}

struct StatRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(Color(hex: "A28497"))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(hex: "2C3E50").opacity(0.7))
                Text(value)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(hex: "2C3E50"))
            }
        }
    }
}

struct SelfExpressionInsight: View {
    let selfRefPercentage: Double
    let activeVoice: Double
    
    var message: String {
        if selfRefPercentage > 70 {
            return "Your reflection was deeply personal"
        } else if selfRefPercentage > 40 {
            return "You balanced personal and external perspectives"
        } else {
            return "You focused more on external observations"
        }
    }
    
    var voiceMessage: String {
        if activeVoice > 80 {
            return " with strong, direct expression"
        } else if activeVoice > 50 {
            return " with balanced expression"
        } else {
            return " with reflective distance"
        }
    }
    
    var icon: String {
        if selfRefPercentage > 70 {
            return "person.fill"
        } else if selfRefPercentage > 40 {
            return "circle.grid.2x2"
        } else {
            return "eye"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(Color(hex: "A28497"))
            
            Text(message + voiceMessage)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(Color(hex: "2C3E50"))
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "A28497").opacity(0.1))
        )
    }
}

struct CognitiveInsight: View {
    let analyticalScore: Double
    let complexityScore: Double
    
    var message: String {
        if analyticalScore > 0.7 {
            return "Your thinking showed deep analytical depth"
        } else if analyticalScore > 0.4 {
            if complexityScore > 0.6 {
                return "You expressed nuanced perspectives"
            } else {
                return "You maintained clear analytical focus"
            }
        } else {
            if complexityScore > 0.6 {
                return "Your thoughts were creatively complex"
            } else {
                return "You expressed straightforward thoughts"
            }
        }
    }
    
    var icon: String {
        if analyticalScore > 0.7 {
            return "brain.head.profile"
        } else if complexityScore > 0.6 {
            return "network"
        } else {
            return "arrow.left.and.right"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(Color(hex: "A28497"))
            
            Text(message)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(Color(hex: "2C3E50"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "A28497").opacity(0.1))
        )
    }
}

struct EmotionalInsight: View {
    let intensity: Double
    let complexity: Int
    
    var message: String {
        if intensity > 0.7 {
            if complexity > 3 {
                return "Your expression was deeply emotional and complex"
            } else {
                return "You showed strong, focused emotions"
            }
        } else if intensity > 0.4 {
            if complexity > 3 {
                return "You balanced various emotional tones"
            } else {
                return "Your emotions were measured and clear"
            }
        } else {
            if complexity > 3 {
                return "You expressed subtle emotional variety"
            } else {
                return "Your expression was calm and controlled"
            }
        }
    }
    
    var icon: String {
        if intensity > 0.7 {
            return "heart.fill"
        } else if complexity > 3 {
            return "square.on.square"
        } else {
            return "water.waves"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(Color(hex: "A28497"))
            
            Text(message)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(Color(hex: "2C3E50"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "A28497").opacity(0.1))
        )
    }
}
