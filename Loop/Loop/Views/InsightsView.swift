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
    @State private var selectedPeriod: ComparisonPeriod = .week
    @State private var showingPeriodPicker = false
    
    private let accentColor = Color(hex: "A28497")
    private let backgroundColor = Color(hex: "FAFBFC")
    private let textColor = Color(hex: "2C3E50")
    
    enum ComparisonPeriod {
        case week, month, allTime
        
        var title: String {
            switch self {
            case .week: return "This Week"
            case .month: return "This Month"
            case .allTime: return "All Time"
            }
        }
        
        var comparison: LoopComparison? {
            switch self {
            case .week: return AnalysisManager.shared.weeklyComparison
            case .month: return AnalysisManager.shared.monthlyComparison
            case .allTime: return AnalysisManager.shared.allTimeComparison
            }
        }
    }
    
    func getComparisonText(for comparison: MetricComparison, type: ComparisonType) -> String {
        if comparison.percentageChange < 1 {
            return "About the same as \(selectedPeriod.title.lowercased())"
        }
        
        let percentText = "\(Int(comparison.percentageChange))%"
        let direction = comparison.direction == .increase
        
        switch type {
        case .wpm:
            return "\(percentText) \(direction ? "faster" : "slower") than \(selectedPeriod.title.lowercased())"
        case .duration:
            return "\(percentText) \(direction ? "longer" : "shorter") than \(selectedPeriod.title.lowercased())"
        case .wordCount:
            return "\(percentText) \(direction ? "more" : "fewer") words than \(selectedPeriod.title.lowercased())"
        case .uniqueWords:
            return "\(percentText) \(direction ? "more" : "fewer") unique words than \(selectedPeriod.title.lowercased())"
        case .selfReference:
            return "\(percentText) \(direction ? "more" : "fewer") self references than \(selectedPeriod.title.lowercased())"
        case .vocabularyDiversity:
            return "\(percentText) \(direction ? "more" : "less") diverse than \(selectedPeriod.title.lowercased())"
        case .wordLength:
            return "\(percentText) \(direction ? "longer" : "shorter") words than \(selectedPeriod.title.lowercased())"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                periodSelector
                
                if let currentAnalysis = analysisManager.currentDailyAnalysis {
                    mainStatsCard(analysis: currentAnalysis)
                    loopCards(analysis: currentAnalysis)
                } else {
                    EmptyView()
                }
            }
            .padding()
        }
        .background(backgroundColor)
        .sheet(isPresented: $showingPeriodPicker) {
            periodPickerSheet
        }
    }
    
    private var periodSelector: some View {
        Button {
            showingPeriodPicker = true
        } label: {
            HStack(spacing: 4) {
                Text(selectedPeriod.title)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .foregroundColor(.white)
            .background(
                Capsule()
                    .fill(accentColor)
                    .shadow(color: textColor.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
    }
    
    private var periodPickerSheet: some View {
        NavigationView {
            List {
                ForEach([ComparisonPeriod.week, .month, .allTime], id: \.self) { period in
                    Button {
                        selectedPeriod = period
                        showingPeriodPicker = false
                    } label: {
                        HStack {
                            Text(period.title)
                                .foregroundColor(textColor)
                            Spacer()
                            if period == selectedPeriod {
                                Image(systemName: "checkmark")
                                    .foregroundColor(accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Period")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.height(200)])
    }
    
    private func mainStatsCard(analysis: DailyAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title section with subtle label
            Text("Speaking Analysis")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundColor(textColor.opacity(0.6))
                .padding(.horizontal, 20)
            
            // Primary WPM Stats
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(analysis.aggregateMetrics.averageWPM))")
                        .font(.system(size: 36, weight: .medium, design: .rounded))
                        .foregroundColor(textColor)
                    Text("WPM")
                        .font(.system(.body, design: .rounded, weight: .regular))
                        .foregroundColor(textColor.opacity(0.7))
                }
                
                if let comparison = selectedPeriod.comparison?.wpmComparison {
                    Text(getComparisonText(for: comparison, type: .wpm))
                        .font(.system(.subheadline, design: .rounded, weight: .regular))
                        .foregroundColor(comparison.direction == .increase ? .green : .red)
                }
            }
            .padding(.horizontal, 20)
            
            // Secondary Metrics Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                if let comparison = selectedPeriod.comparison {
                    MetricView(
                        title: "Duration",
                        value: formatDuration(analysis.aggregateMetrics.averageDuration),
                        comparison: comparison.durationComparison,
                        type: .duration
                    )
                    
                    MetricView(
                        title: "Word Count",
                        value: "\(Int(analysis.aggregateMetrics.averageWordCount))",
                        comparison: comparison.wordCountComparison,
                        type: .wordCount
                    )
                    
                    MetricView(
                        title: "Unique Words",
                        value: "\(Int(analysis.aggregateMetrics.averageUniqueWordCount))",
                        comparison: comparison.uniqueWordComparison,
                        type: .uniqueWords
                    )
                    
                    MetricView(
                        title: "Self References",
                        value: "\(Int(analysis.aggregateMetrics.averageSelfReferences))",
                        comparison: comparison.selfReferenceComparison,
                        type: .selfReference
                    )
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: textColor.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
    
    private func loopCards(analysis: DailyAnalysis) -> some View {
        TabView {
            ForEach(analysis.loops) { loop in
                VStack(alignment: .leading, spacing: 16) {
                    // Loop header with prompt and timestamp
                    VStack(alignment: .leading, spacing: 4) {
                        Text(loop.promptText)
                            .font(.system(.subheadline, design: .rounded, weight: .regular))
                            .foregroundColor(textColor)
                        Text(formatTime(loop.timestamp))
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundColor(accentColor)
                    }
                    .padding(.horizontal, 20)
                    
                    // Loop metrics
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        MetricItem(title: "Duration", value: formatDuration(loop.metrics.duration))
                        MetricItem(title: "WPM", value: "\(Int(loop.metrics.wordsPerMinute))")
                        MetricItem(title: "Words", value: "\(loop.metrics.wordCount)")
                        MetricItem(title: "Unique", value: "\(loop.metrics.uniqueWordCount)")
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: textColor.opacity(0.05), radius: 10, x: 0, y: 4)
                )
                .padding(.horizontal)
            }
        }
        .tabViewStyle(.page)
        .frame(height: 200)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

enum ComparisonType {
    case wpm, duration, wordCount, uniqueWords, selfReference, vocabularyDiversity, wordLength
}

private struct MetricView: View {
    let title: String
    let value: String
    let comparison: MetricComparison
    let type: ComparisonType
    
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundColor(textColor.opacity(0.6))
            Text(value)
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundColor(textColor)
            Text(InsightsView().getComparisonText(for: comparison, type: type))
                .font(.system(.caption, design: .rounded, weight: .regular))
                .foregroundColor(comparison.direction == .increase ? .green : .red)
                .lineLimit(1)
        }
    }
}

private struct MetricItem: View {
    let title: String
    let value: String
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundColor(textColor.opacity(0.6))
            Text(value)
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundColor(textColor)
        }
    }
}
