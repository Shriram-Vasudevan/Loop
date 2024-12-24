//
//  WeekInReviewView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/23/24.
//

import SwiftUI

struct WeekInReviewView: View {
    @ObservedObject var analysisManager: AnalysisManager
    @State private var selectedPastAnalysis: WeeklyAnalysis?
    @State private var showingPastAnalysis = false
    
    private let accentColor = Color(hex: "A28497")
    private let backgroundColor = Color(hex: "FAFBFC")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    header
                    
                    if analysisManager.isLoadingWeekInReview {
                        loadingView
                    } else if !analysisManager.isSunday() {
                        waitForSundayMessage
                    }
                    
                    if let latestAnalysis = analysisManager.pastWeeklyAnalyses.first {
                        latestWeekReview(latestAnalysis)
                    }
                    
                    if analysisManager.pastWeeklyAnalyses.count > 1 {
                        pastWeeksSection
                    }
                }
                .padding(.horizontal)
            }
        }
        .sheet(item: $selectedPastAnalysis) { analysis in
            WeekInReviewDetailView(analysis: analysis)
        }
        .task {
            await analysisManager.loadWeekInReviewData()
            if analysisManager.isSunday() {
                await analysisManager.performWeeklyAnalysisIfNeeded()
            }
        }
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("week in review")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(textColor)
                
                Text("reflect & understand")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(textColor.opacity(0.6))
                    .tracking(2)
            }
            Spacer()
        }
        .padding(.top, 16)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Analyzing your week...")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(textColor)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var waitForSundayMessage: some View {
        Text("Check back on Sunday for this week's review")
            .font(.system(size: 17, weight: .medium))
            .foregroundColor(textColor.opacity(0.7))
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    private func latestWeekReview(_ analysis: WeeklyAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Latest Review")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(textColor.opacity(0.5))
                .tracking(0.5)
            
            WeekInReviewCard(analysis: analysis)
                .onTapGesture {
                    selectedPastAnalysis = analysis
                }
        }
    }
    
    private var pastWeeksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Previous Weeks")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(textColor.opacity(0.5))
                .tracking(0.5)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(analysisManager.pastWeeklyAnalyses.dropFirst(), id: \.weekStartDate) { analysis in
                    PastWeekInReviewWidget(analysis: analysis)
                        .onTapGesture {
                            selectedPastAnalysis = analysis
                        }
                }
            }
        }
    }
}

// WeekInReviewCard.swift

struct WeekInReviewCard: View {
    let analysis: WeeklyAnalysis
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            weekRange
            
            keyMetrics
            
            themeSection(analysis.themes)
            
            keyMomentsSection(analysis.keyMoments)
        }
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var weekRange: some View {
        Text(formatDateRange(start: analysis.weekStartDate, end: analysis.weekEndDate))
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(textColor)
    }
    
    private var keyMetrics: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Metrics")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(textColor)
            
            HStack(spacing: 24) {
                MetricView(
                    value: String(format: "%.0f", analysis.aggregateMetrics.averageWordsPerMinute),
                    label: "avg WPM"
                )
                
                MetricView(
                    value: String(format: "%.0f", analysis.aggregateMetrics.averageWordsPerMinute),
                    label: "words/loop"
                )
                
                MetricView(
                    value: String(format: "%.0f%%", analysis.aggregateMetrics.averageDuration),
                    label: "avg duration"
                )
            }
        }
    }
    
    private func themeSection(_ themes: [Theme]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Themes")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(textColor)
            
            ForEach(themes, id: \.name) { theme in
                ThemeRow(theme: theme)
            }
        }
    }
    
    private func keyMomentsSection(_ moments: [KeyMoment]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Moments")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(textColor)
            
            ForEach(moments, id: \.quote) { moment in
                MomentRow(moment: moment)
            }
        }
    }
    
    private func formatDateRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

// Helper Views

struct MetricView: View {
    let value: String
    let label: String
    
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(textColor)
            
            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(textColor.opacity(0.6))
        }
    }
}

struct ThemeRow: View {
    let theme: Theme
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(theme.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(textColor)
            
            Text(theme.description)
                .font(.system(size: 13))
                .foregroundColor(textColor.opacity(0.7))
                .lineLimit(2)
        }
        .padding(12)
        .background(accentColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct MomentRow: View {
    let moment: KeyMoment
    
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(moment.quote)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(textColor)
            
            Text(moment.significance)
                .font(.system(size: 13))
                .foregroundColor(textColor.opacity(0.7))
                .lineLimit(2)
        }
    }
}

struct PastWeekInReviewWidget: View {
    let analysis: WeeklyAnalysis
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(formatDateRange(start: analysis.weekStartDate, end: analysis.weekEndDate))
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(textColor)
            
            ForEach(Array(analysis.themes.prefix(2)), id: \.name) { theme in
                Text(theme.name)
                    .font(.system(size: 13))
                    .foregroundColor(textColor.opacity(0.7))
            }
            
            Spacer()
            
            HStack {
                Text("\(analysis.loops.count) reflections")
                    .font(.system(size: 12))
                    .foregroundColor(accentColor)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(accentColor)
            }
        }
        .padding(16)
        .frame(height: 140)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: accentColor.opacity(0.1), radius: 10, y: 4)
    }
    
    private func formatDateRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

// WeekInReviewDetailView.swift

struct WeekInReviewDetailView: View {
    let analysis: WeeklyAnalysis
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = "overview"
    
    private let accentColor = Color(hex: "A28497")
    private let backgroundColor = Color(hex: "FAFBFC")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Tab selection
                        tabPicker
                        
                        // Content based on selected tab
                        switch selectedTab {
                        case "overview":
                            WeekOverviewTab(analysis: analysis)
                        case "insights":
                            WeekInsightsTab(analysis: analysis)
                        case "stats":
                            WeekStatsTab(analysis: analysis)
                        case "transcripts":
                            WeekTranscriptsTab(analysis: analysis)
                        default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle(formatDateRange(start: analysis.weekStartDate, end: analysis.weekEndDate))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(textColor.opacity(0.5))
                    }
                }
            }
        }
    }
    
    private var tabPicker: some View {
        HStack(spacing: 20) {
            ForEach(["overview", "insights", "stats", "transcripts"], id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }) {
                    Text(tab.capitalized)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(selectedTab == tab ? textColor : textColor.opacity(0.5))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedTab == tab ? accentColor.opacity(0.1) : Color.clear)
                        )
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatDateRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end)), \(Calendar.current.component(.year, from: start))"
    }
}

struct WeekOverviewTab: View {
    let analysis: WeeklyAnalysis
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(spacing: 24) {
            mainStatsCard
            
            themesSection(analysis.themes)
            
            keyMomentsSection(analysis.keyMoments)
            
            aiInsightsSection(analysis.aiInsights)
        }
    }
    
    private var mainStatsCard: some View {
        VStack(spacing: 20) {
            HStack(spacing: 24) {
                StatBox(
                    value: String(format: "%.0f", analysis.aggregateMetrics.averageWordsPerMinute),
                    label: "Average WPM",
                    icon: "speedometer"
                )
                
                StatBox(
                    value: String(format: "%.0f", analysis.aggregateMetrics.totalWords),
                    label: "Total words used",
                    icon: "text.word.spacing"
                )
            }
            
            HStack(spacing: 24) {
                StatBox(
                    value: String(format: "%.0f%%", analysis.aggregateMetrics.totalSelfReferenceCount),
                    label: "Total Self-References",
                    icon: "textformat.size"
                )
                
                StatBox(
                    value: formatDuration(analysis.aggregateMetrics.averageDuration),
                    label: "Avg Duration",
                    icon: "clock"
                )
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func themesSection(_ themes: [Theme]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Weekly Themes")
            
            ForEach(themes, id: \.name) { theme in
                ThemeCard(theme: theme)
            }
        }
    }
    
    private func keyMomentsSection(_ moments: [KeyMoment]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Key Moments")
            
            ForEach(moments, id: \.quote) { moment in
                MomentCard(moment: moment)
            }
        }
    }
    
    private func aiInsightsSection(_ insights: WeeklyAIInsights) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("AI Analysis")
            
            VStack(alignment: .leading, spacing: 20) {
                insightRow("Overall Tone", insights.overallTone)
                
                if let patterns = insights.patterns {
                    insightRow("Patterns", patterns)
                }
                
                if let progress = insights.progressNotes {
                    insightRow("Progress", progress)
                }
            }
            .padding(20)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .regular))
            .foregroundColor(textColor.opacity(0.5))
            .tracking(0.5)
    }
    
    private func insightRow(_ title: String, _ content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(textColor)
            
            Text(content)
                .font(.system(size: 13))
                .foregroundColor(textColor.opacity(0.7))
                .lineSpacing(4)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return seconds == 0 ? "\(minutes)m" : "\(minutes)m \(seconds)s"
    }
}

// Helper components for WeekOverviewTab

struct StatBox: View {
    let value: String
    let label: String
    let icon: String
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(accentColor)
            
            Text(value)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(textColor)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(textColor.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(accentColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ThemeCard: View {
    let theme: Theme
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(theme.name)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(textColor)
            
            Text(theme.description)
                .font(.system(size: 15))
                .foregroundColor(textColor.opacity(0.7))
                .lineSpacing(4)
            
            if !theme.relatedQuotes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Related Quotes")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(textColor.opacity(0.6))
                    
                    ForEach(theme.relatedQuotes, id: \.quote) { quote in
                        Text("\(quote.quote)")
                            .font(.system(size: 14))
                            .foregroundColor(textColor.opacity(0.8))
                            .lineSpacing(4)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct MomentCard: View {
    let moment: KeyMoment
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(formatDate(moment.date))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(accentColor)
            
            Text("\(moment.quote)")
                .font(.system(size: 17))
                .foregroundColor(textColor)
                .lineSpacing(4)
            
            Text(moment.significance)
                .font(.system(size: 15))
                .foregroundColor(textColor.opacity(0.7))
                .lineSpacing(4)
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
}


