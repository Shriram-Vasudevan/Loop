//
//  TrendsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/28/24.
//

import SwiftUI

struct TrendsView: View {
    @ObservedObject var quantTrendsManager = QuantitativeTrendsManager.shared
    @ObservedObject var aiTrendsManager = AITrendsManager.shared
    @ObservedObject var analysisManager = AnalysisManager.shared
    
    @State private var selectedMetric: MetricType = .wpm
    @State private var selectedTimeframe: Timeframe = .week
    @State private var isLoading = true
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    private let backgroundColor = Color(hex: "F5F5F5")
    
    enum MetricType: String, CaseIterable {
        case wpm = "Speaking Pace"
        case duration = "Duration"
        case wordCount = "Word Count"
        case vocabulary = "Vocabulary"
    }
    
    enum Timeframe: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                TimeframeToggle(selection: $selectedTimeframe)
                    .padding(.top, 16)
                    .padding(.horizontal, 24)
                
                if isLoading {
                    TrendsLoadingView()
                        .padding(.top, 32)
                } else {
                    VStack(spacing: 32) {
                        TrendGraphCard(
                            selectedMetric: $selectedMetric,
                            timeframe: $selectedTimeframe
                        )
                        
                        if let dailyAnalysis = analysisManager.currentDailyAnalysis {
                            ComparisonView(
                                analysis: dailyAnalysis,
                                selectedMetric: selectedMetric,
                                comparisons: quantTrendsManager.compareWithToday(dailyAnalysis)
                            )
                            .padding(.horizontal, 24)
                        }
                        
                        EmotionalInsightsSection(
                            timeframe: selectedTimeframe,
                            aiTrendsManager: aiTrendsManager
                        )
                        .padding(.horizontal, 24)
                    }
                }
            }
            .padding(.bottom, 32)
        }
        .background(backgroundColor)
//        .onChange(of: selectedTimeframe) { _ in
//            Task {
//                await refreshData()
//            }
//        }
//        .onAppear {
//            Task {
//                await refreshData()
//            }
//        }
    }
    
    private func refreshData() async {
        isLoading = true
        switch selectedTimeframe {
        case .week:
            await quantTrendsManager.fetchCurrentWeekStats()
            await aiTrendsManager.fetchCurrentWeekAnalyses()
        case .month:
            await quantTrendsManager.fetchCurrentMonthStats()
            await aiTrendsManager.fetchCurrentMonthAnalyses()
        case .year:
            await quantTrendsManager.fetchCurrentYearStats()
            await aiTrendsManager.fetchCurrentYearAnalyses()
        }
        isLoading = false
    }
}

struct ComparisonView: View {
    let analysis: DailyAnalysis
    let selectedMetric: TrendsView.MetricType
    let comparisons: [QuantitativeTrendsManager.MetricComparison]
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        if let comparison = comparisons.first(where: { $0.metric == selectedMetric.rawValue }) {
            Text(comparison.trend)
                .font(.system(size: 15))
                .foregroundColor(textColor.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct EmotionalInsightsSection: View {
    let timeframe: TrendsView.Timeframe
    let aiTrendsManager: AITrendsManager
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        if let frequencies = getFrequencies() {
            VStack(alignment: .leading, spacing: 32) {
                EmotionsCard(frequencies: frequencies)
                FocusCard(frequencies: frequencies)
                TimeOrientationCard(frequencies: frequencies)
            }
        }
    }
    
    private func getFrequencies() -> AITrendsManager.TimeframeFrequencies? {
        switch timeframe {
        case .week:
            return aiTrendsManager.getWeeklyFrequencies()
        case .month:
            return aiTrendsManager.getMonthlyFrequencies()
        case .year:
            return aiTrendsManager.getYearlyFrequencies()
        }
    }
}

struct EmotionsCard: View {
    let frequencies: AITrendsManager.TimeframeFrequencies
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("emotions")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(textColor)
            
            VStack(spacing: 16) {
                ForEach(frequencies.topEmotions.prefix(3), id: \.value) { emotion in
                    HStack {
                        Text(emotion.value.capitalized)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(textColor)
                        
                        Spacer()
                        
                        Text("\(Int(emotion.percentage))%")
                            .font(.system(size: 14))
                            .foregroundColor(textColor.opacity(0.7))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(emotion == frequencies.topEmotions.first ?
                                 accentColor.opacity(0.1) : Color.clear)
                    )
                }
            }
        }
    }
}

struct FocusCard: View {
    let frequencies: AITrendsManager.TimeframeFrequencies
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("focus")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(textColor)
            
            if let topFocus = frequencies.topFocuses.first {
                Text(topFocus.value.capitalized)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(textColor)
            }
        }
    }
}

struct TimeOrientationCard: View {
    let frequencies: AITrendsManager.TimeframeFrequencies
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("time orientation")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(textColor)
            
            if let topTime = frequencies.topTimeOrientations.first {
                Text(topTime.value.capitalized)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(textColor)
            }
        }
    }
}

struct TimeframeToggle: View {
    @Binding var selection: TrendsView.Timeframe
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        HStack(spacing: 24) {
            ForEach(TrendsView.Timeframe.allCases, id: \.self) { timeframe in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selection = timeframe
                    }
                } label: {
                    VStack(spacing: 8) {
                        Text(timeframe.rawValue)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selection == timeframe ?
                                           textColor : textColor.opacity(0.5))
                        
                        Rectangle()
                            .fill(selection == timeframe ? accentColor : Color.clear)
                            .frame(height: 2)
                            .cornerRadius(1)
                    }
                }
            }
        }
    }
}

#if DEBUG
extension TrendsView {
    static var preview: TrendsView {
        let view = TrendsView()
        view.isLoading = false
        return view
    }
}

struct TrendsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TrendsView.preview
                .previewDisplayName("Loaded State")
            
            TrendsView()
                .previewDisplayName("Loading State")
        }
    }
}
#endif
