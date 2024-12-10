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
    @State private var animateCards = false
    @State private var selectedTimeframe = Timeframe.today
    @State private var selectedInsightType: InsightType?
    @State private var expandedSections: Set<Section> = [.overview]
    @State private var selectedLoop: LoopAnalysis?
    @State private var showingLoopDetail = false
    
    // MARK: - Constants
    private let accentColor = Color(hex: "A28497")
    private let backgroundColor = Color(hex: "FAFBFC")
    private let surfaceColor = Color(hex: "F8F5F7")
    private let textColor = Color(hex: "2C3E50")
    
    // MARK: - Enums
    enum Timeframe: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
    }
    
    enum InsightType: String, CaseIterable {
        case pace = "Speaking Pace"
        case vocabulary = "Vocabulary"
        case patterns = "Patterns"
        case duration = "Duration"
    }
    
    enum Section: String {
        case overview = "Overview"
        case vocabulary = "Vocabulary Analysis"
        case patterns = "Speaking Patterns"
        case relationships = "Loop Relationships"
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    header
                        .opacity(animateCards ? 1 : 0)
                        .offset(y: animateCards ? 0 : 20)
                    
                    if let analysis = analysisManager.currentDailyAnalysis {
                        heroMetrics(analysis)
                        
                        keyInsightsCarousel(analysis)
                            .opacity(animateCards ? 1 : 0)
                            .offset(y: animateCards ? 0 : 30)
                        
                        vocabularySection(analysis)
                            .opacity(animateCards ? 1 : 0)
                            .offset(y: animateCards ? 0 : 40)
                        
                        speakingPatternsSection(analysis)
                            .opacity(animateCards ? 1 : 0)
                            .offset(y: animateCards ? 0 : 50)
                        
                        loopComparisonSection(analysis)
                            .opacity(animateCards ? 1 : 0)
                            .offset(y: animateCards ? 0 : 60)
                        
                        individualLoopsSection(analysis)
                            .opacity(animateCards ? 1 : 0)
                            .offset(y: animateCards ? 0 : 70)
                    } else {
                        noDataView
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
        }
        .sheet(item: $selectedLoop) { loop in
            LoopDetailView(loop: loop)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateCards = true
            }
        }
    }
    
    // MARK: - Hero Metrics Section
    private func heroMetrics(_ analysis: DailyAnalysis) -> some View {
        VStack(spacing: 24) {
            // Main metric card
            VStack(spacing: 16) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(Int(analysis.aggregateMetrics.averageWPM))")
                        .font(.system(size: 48, weight: .bold))
                    Text("WPM")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(textColor.opacity(0.6))
                }
                
                if let comparison = analysisManager.weeklyComparison?.wpmComparison {
                    HStack(spacing: 4) {
                        Image(systemName: comparison.direction == .increase ? "arrow.up.right" : "arrow.down.right")
                        Text("\(Int(comparison.percentageChange))% from last week")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(comparison.direction == .increase ? .green : .red)
                }
            }
            .frame(maxWidth: .infinity)
            .cardStyle()
            
            // Secondary metrics grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                metricCard(
                    title: "Duration",
                    value: formatDuration(analysis.aggregateMetrics.averageDuration),
                    comparison: analysisManager.weeklyComparison?.durationComparison,
                    trend: .up
                )
                
                metricCard(
                    title: "Word Count",
                    value: "\(Int(analysis.aggregateMetrics.averageWordCount))",
                    comparison: analysisManager.weeklyComparison?.wordCountComparison,
                    trend: .down
                )
            }
        }
    }
    
    // MARK: - Key Insights Carousel
    private func keyInsightsCarousel(_ analysis: DailyAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Insights")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(textColor)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    insightCard(
                        icon: "chart.bar.fill",
                        title: "Vocabulary Diversity",
                        detail: "Your vocabulary diversity is \(Int(analysis.aggregateMetrics.vocabularyDiversityRatio * 100))% today",
                        trend: .up
                    )
                    
                    insightCard(
                        icon: "person.fill",
                        title: "Self References",
                        detail: "You used \(Int(analysis.aggregateMetrics.averageSelfReferences)) self-references per loop",
                        trend: .neutral
                    )
                    
                    insightCard(
                        icon: "arrow.left.arrow.right",
                        title: "Loop Similarity",
                        detail: "Your loops are \(Int(analysis.overlapAnalysis.overallSimilarity * 100))% similar",
                        trend: .down
                    )
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Vocabulary Section
    private func vocabularySection(_ analysis: DailyAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionHeader("Vocabulary Analysis", icon: "textformat.abc")
            
            // Vocabulary metrics grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                vocabularyMetricCard(
                    title: "Unique Words",
                    value: "\(analysis.wordPatterns.totalUniqueWords.count)",
                    total: analysis.loops.reduce(0) { $0 + $1.metrics.wordCount }
                )
                
                vocabularyMetricCard(
                    title: "Average Word Length",
                    value: String(format: "%.1f", analysis.loops.reduce(0.0) { $0 + $1.metrics.averageWordLength } / Double(analysis.loops.count)),
                    subtitle: "characters per word"
                )
            }
            
            // Most used words chart
            VStack(alignment: .leading, spacing: 16) {
                Text("Most Used Words")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(textColor)
                
                Chart(analysis.wordPatterns.mostUsedWords.prefix(5), id: \.word) { wordCount in
                    BarMark(
                        x: .value("Count", wordCount.count),
                        y: .value("Word", wordCount.word)
                    )
                    .foregroundStyle(accentColor.gradient)
                }
                .frame(height: 200)
            }
            .cardStyle()
        }
    }
    
    // MARK: - Speaking Patterns Section
    private func speakingPatternsSection(_ analysis: DailyAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionHeader("Speaking Patterns", icon: "waveform")
            
            // WPM Trend
            VStack(alignment: .leading, spacing: 16) {
                Text("Speaking Pace Trend")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(textColor)
                
                Chart(analysis.loops) { loop in
                    LineMark(
                        x: .value("Time", loop.timestamp),
                        y: .value("WPM", loop.metrics.wordsPerMinute)
                    )
                    .foregroundStyle(accentColor.gradient)
                    
                    PointMark(
                        x: .value("Time", loop.timestamp),
                        y: .value("WPM", loop.metrics.wordsPerMinute)
                    )
                    .foregroundStyle(accentColor)
                }
                .frame(height: 200)
            }
            .cardStyle()
            
            // Range Analysis
            VStack(alignment: .leading, spacing: 16) {
                Text("Speaking Range")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(textColor)
                
                rangeGrid(analysis.rangeAnalysis)
            }
            .cardStyle()
        }
    }
    private func loopComparisonSection(_ analysis: DailyAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionHeader("Loop Relationships", icon: "arrow.triangle.2.circlepath")
            
            // Similarity Matrix
            VStack(alignment: .leading, spacing: 16) {
                Text("Loop Similarity")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(textColor)
                
                VStack(spacing: 12) {
                    ForEach(analysis.loops.indices, id: \.self) { i in
                        HStack(spacing: 12) {
                            ForEach(analysis.loops.indices, id: \.self) { j in
                                let similarityKey = "\(analysis.loops[i].id)-\(analysis.loops[j].id)"
                                let similarity = analysis.overlapAnalysis.pairwiseOverlap[similarityKey] ?? 0
                                
                                similarityCell(similarity)
                            }
                        }
                    }
                }
                
                // Legend
                HStack(spacing: 16) {
                    ForEach([0.0, 0.5, 1.0], id: \.self) { value in
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(accentColor.opacity(value))
                                .frame(width: 16, height: 16)
                                .cornerRadius(4)
                            
                            Text("\(Int(value * 100))%")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(textColor.opacity(0.6))
                        }
                    }
                }
            }
            .cardStyle()
            
            // Common Words Analysis
            VStack(alignment: .leading, spacing: 16) {
                Text("Common Themes")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(textColor)
                
                ForEach(Array(analysis.overlapAnalysis.commonWords.keys.prefix(3)), id: \.self) { key in
                    if let words = analysis.overlapAnalysis.commonWords[key] {
                        commonWordsRow(loopPair: key, words: words)
                    }
                }
            }
            .cardStyle()
        }
    }
    
    // MARK: - Individual Loops Section
    private func individualLoopsSection(_ analysis: DailyAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionHeader("Individual Loops", icon: "rectangle.stack")
            
            ForEach(analysis.loops) { loop in
                Button {
                    selectedLoop = loop
                } label: {
                    detailedLoopCard(loop)
                }
            }
        }
    }
    
    private func detailedLoopCard(_ loop: LoopAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatTime(loop.timestamp))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(accentColor)
                    
                    Text(loop.promptText)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(textColor)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(accentColor)
            }
            
            // Metrics Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                metricCell("Duration", value: formatDuration(loop.metrics.duration))
                metricCell("WPM", value: "\(Int(loop.metrics.wordsPerMinute))")
                metricCell("Words", value: "\(loop.metrics.wordCount)")
            }
            
            // Word Analysis Preview
            if !loop.wordAnalysis.mostUsedWords.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Top Words")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(textColor.opacity(0.6))
                    
                    FlowLayout(spacing: 8) {
                        ForEach(loop.wordAnalysis.mostUsedWords.prefix(3), id: \.word) { wordCount in
                            Text("\(wordCount.word) (\(wordCount.count))")
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(accentColor.opacity(0.1))
                                .foregroundColor(accentColor)
                                .cornerRadius(12)
                        }
                    }
                }
            }
        }
        .cardStyle()
    }
    
    // MARK: - Helper Components
    private func metricCell(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(textColor.opacity(0.6))
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(textColor)
        }
    }
    
    private func similarityCell(_ similarity: Double) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(accentColor.opacity(similarity))
            .frame(height: 40)
            .overlay(
                Text("\(Int(similarity * 100))%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(similarity > 0.5 ? .white : textColor)
            )
    }
    
    private func commonWordsRow(loopPair: String, words: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Loops \(loopPair)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(textColor.opacity(0.6))
            
            FlowLayout(spacing: 8) {
                ForEach(words.prefix(5), id: \.self) { word in
                    Text(word)
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(accentColor.opacity(0.1))
                        .foregroundColor(accentColor)
                        .cornerRadius(12)
                }
            }
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Insights")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(textColor)
            
            HStack(spacing: 16) {
                ForEach(Timeframe.allCases, id: \.self) { timeframe in
                    timeframeButton(timeframe)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var noDataView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundColor(accentColor)
            
            Text("No Insights Yet")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(textColor)
            
            Text("Complete your daily reflection loops to see insights about your speaking patterns.")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(textColor.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .cardStyle()
    }
    
    private func insightCard(icon: String, title: String, detail: String, trend: TrendDirection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(accentColor)
                
                Spacer()
                
                trendIndicator(trend)
            }
            
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(textColor)
            
            Text(detail)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(textColor.opacity(0.6))
                .lineLimit(2)
        }
        .padding(20)
        .frame(width: 280)
        .cardStyle()
    }
    
    private func metricCard(title: String, value: String, comparison: MetricComparison?, trend: TrendDirection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(textColor.opacity(0.6))
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(textColor)
            
            if let comparison = comparison {
                HStack(spacing: 4) {
                    Image(systemName: comparison.direction == .increase ? "arrow.up.right" : "arrow.down.right")
                    Text("\(Int(comparison.percentageChange))%")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(comparison.direction == .increase ? .green : .red)
            }
        }
        .padding(20)
        .cardStyle()
    }
    
    private func vocabularyMetricCard(title: String, value: String, total: Int? = nil, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(textColor.opacity(0.6))
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(textColor)
            
            if let total = total {
                Text("out of \(total) total words")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(textColor.opacity(0.6))
            }
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(textColor.opacity(0.6))
            }
        }
        .padding(20)
        .cardStyle()
    }
    
    private func rangeGrid(_ analysis: RangeAnalysis) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            rangeRow(
                title: "Speaking Pace",
                min: Int(analysis.wpmRange.min),
                max: Int(analysis.wpmRange.max),
                unit: "WPM"
            )
            
            rangeRow(
                title: "Duration",
                min: Int(analysis.durationRange.min),
                max: Int(analysis.durationRange.max),
                unit: "sec"
            )
            
            rangeRow(
                title: "Word Count",
                min: analysis.wordCountRange.min,
                max: analysis.wordCountRange.max,
                unit: "words"
            )
            
            rangeRow(
                title: "Self References",
                min: analysis.selfReferenceRange.min,
                max: analysis.selfReferenceRange.max,
                unit: "refs"
            )
        }
    }
    
    private func rangeRow(title: String, min: Int, max: Int, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(textColor.opacity(0.6))
            
            HStack(spacing: 4) {
                Text("\(min)-\(max)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(textColor)
                
                Text(unit)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(textColor.opacity(0.6))
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    // MARK: - Helper Functions
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
    
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(textColor)
            
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(accentColor)
        }
    }
    
    func trendIndicator(_ trend: TrendDirection) -> some View {
        Image(systemName: trend.systemImage)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(trend.color)
    }
    
    private func timeframeButton(_ timeframe: Timeframe) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTimeframe = timeframe
            }
        }) {
            Text(timeframe.rawValue)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(selectedTimeframe == timeframe ? .white : accentColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedTimeframe == timeframe ? accentColor : accentColor.opacity(0.1))
                )
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var width: CGFloat = 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        
        for size in sizes {
            if x + size.width > proposal.width ?? 0 {
                x = 0
                y += size.height + spacing
            }
            
            width = max(width, x + size.width)
            height = max(height, y + size.height)
            x += size.width + spacing
        }
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += size.height + spacing
            }
            
            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(size)
            )
            
            x += size.width + spacing
        }
    }
}

// MARK: - Detail Sheet View
struct LoopDetailView: View {
    let loop: LoopAnalysis
    @Environment(\.dismiss) private var dismiss
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text(formatTime(loop.timestamp))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(accentColor)
                        
                        Text(loop.promptText)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(textColor)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Main metrics
                    mainMetrics
                    
                    // Word analysis
                    wordAnalysis
                    
                    // Detailed word breakdown
                    wordBreakdown
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var mainMetrics: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            metricCard("Duration", value: formatDuration(loop.metrics.duration))
            metricCard("WPM", value: "\(Int(loop.metrics.wordsPerMinute))")
            metricCard("Total Words", value: "\(loop.metrics.wordCount)")
            metricCard("Unique Words", value: "\(loop.metrics.uniqueWordCount)")
        }
    }
    
    private var wordAnalysis: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Word Analysis")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(textColor)
            
            // Word frequency chart
            if !loop.wordAnalysis.mostUsedWords.isEmpty {
                Chart(loop.wordAnalysis.mostUsedWords.prefix(8), id: \.word) { wordCount in
                    BarMark(
                        x: .value("Count", wordCount.count),
                        y: .value("Word", wordCount.word)
                    )
                    .foregroundStyle(accentColor.gradient)
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var wordBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detailed Breakdown")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(textColor)
            
            VStack(alignment: .leading, spacing: 12) {
                breakdownRow("Self References", words: loop.wordAnalysis.selfReferenceTypes)
                breakdownRow("Most Used Words", words: loop.wordAnalysis.mostUsedWords.map(\.word))
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private func breakdownRow(_ title: String, words: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(textColor.opacity(0.6))
            
            FlowLayout(spacing: 8) {
                ForEach(words, id: \.self) { word in
                    Text(word)
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(accentColor.opacity(0.1))
                        .foregroundColor(accentColor)
                        .cornerRadius(12)
                }
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a, MMM d"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
    
    private func metricCard(_ title: String, value: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(textColor.opacity(0.6))
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(textColor)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}
