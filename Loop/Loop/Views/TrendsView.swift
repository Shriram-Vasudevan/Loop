//
//  TrendsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/28/24.
//

import SwiftUI

import SwiftUI
import Charts

struct TrendsView: View {
    @ObservedObject var quantTrendsManager = QuantitativeTrendsManager.shared
    @ObservedObject var aiTrendsManager = AITrendsManager.shared
    @ObservedObject var analysisManager = AnalysisManager.shared
    
    @State private var selectedMetric: MetricType = .wpm
    @State private var selectedTimeframe: Timeframe = .week
    @State private var isLoading = true
    @State private var showMetricPicker = false
    @State private var showTimeframePicker = false
    
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
                // Header Section
                headerSection
                    .padding(.top, 16)
                    .padding(.horizontal, 24)
                
                if isLoading {
                    loadingView
                } else {
                    VStack(spacing: 32) {
                        // Main Trend Graph Card
                        trendGraphSection
                        
                        // Comparison Section
                        if let dailyAnalysis = analysisManager.currentDailyAnalysis {
                            comparisonSection(dailyAnalysis)
                                .padding(.horizontal, 24)
                        }
                        
                        // Insights Section
                        insightsSection
                            .padding(.horizontal, 24)
                    }
                }
            }
            .padding(.bottom, 32)
        }
        .background(backgroundColor)
        .onChange(of: selectedTimeframe) { _ in
            Task {
                await refreshData()
            }
        }
        .onAppear {
            Task {
                await refreshData()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PERFORMANCE")
                .font(.system(size: 13, weight: .medium))
                .tracking(1.5)
                .foregroundColor(textColor.opacity(0.6))
            
            HStack {
                Button(action: {
                    withAnimation(.spring()) {
                        showMetricPicker.toggle()
                    }
                }) {
                    Text(selectedMetric.rawValue)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(textColor)
                }
                
                Spacer()
                
                timeframeButton
            }
        }
        .overlay(
            Group {
                if showMetricPicker {
                    metricPickerOverlay
                }
            }
        )
    }
    
    private var timeframeButton: some View {
        Button(action: {
            withAnimation(.spring()) {
                showTimeframePicker.toggle()
            }
        }) {
            HStack(spacing: 8) {
                Text(selectedTimeframe.rawValue)
                    .font(.system(size: 15, weight: .medium))
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .rotationEffect(.degrees(showTimeframePicker ? 180 : 0))
            }
            .foregroundColor(accentColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(accentColor.opacity(0.08))
            )
        }
        .overlay(
            Group {
                if showTimeframePicker {
                    timeframePickerOverlay
                }
            }
        )
    }
    
    private var metricPickerOverlay: some View {
        VStack(spacing: 0) {
            ForEach(MetricType.allCases, id: \.self) { metric in
                Button(action: {
                    withAnimation {
                        selectedMetric = metric
                        showMetricPicker = false
                    }
                }) {
                    HStack {
                        Text(metric.rawValue)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(selectedMetric == metric ? accentColor : textColor)
                        
                        Spacer()
                        
                        if selectedMetric == metric {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(accentColor)
                        }
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(selectedMetric == metric ? accentColor.opacity(0.08) : Color.clear)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .offset(y: 80)
        .zIndex(1)
    }
    
    private var timeframePickerOverlay: some View {
        VStack(spacing: 0) {
            ForEach(Timeframe.allCases, id: \.self) { timeframe in
                Button(action: {
                    withAnimation {
                        selectedTimeframe = timeframe
                        showTimeframePicker = false
                    }
                }) {
                    HStack {
                        Text(timeframe.rawValue)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(selectedTimeframe == timeframe ? accentColor : textColor)
                        
                        Spacer()
                        
                        if selectedTimeframe == timeframe {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(accentColor)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(selectedTimeframe == timeframe ? accentColor.opacity(0.08) : Color.clear)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 8)
        )
        .offset(y: 50)
        .zIndex(1)
    }
    
    private var trendGraphSection: some View {
        TrendGraphCard(
            selectedMetric: $selectedMetric,
            timeframe: $selectedTimeframe,
            quantTrendsManager: quantTrendsManager
        )
        .padding(.horizontal, 24)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(accentColor)
            
            Text("Loading your insights...")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(textColor.opacity(0.7))
        }
        .frame(height: 200)
    }
    
    private func comparisonSection(_ analysis: DailyAnalysis) -> some View {
        let comparisons = quantTrendsManager.compareWithToday(analysis)
        if let comparison = comparisons.first(where: { $0.metric == selectedMetric.rawValue }) {
            return AnyView(
                VStack(alignment: .leading, spacing: 8) {
                    Text("COMPARISON")
                        .font(.system(size: 13, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(textColor.opacity(0.6))
                    
                    Text(comparison.trend)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(textColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 4)
                )
            )
        } else {
            return AnyView(EmptyView())
        }
    }
    
    private var insightsSection: some View {
        VStack(spacing: 24) {
            if let frequencies = getFrequencies() {
                EmotionsInsightCard(frequencies: frequencies)
                FocusInsightCard(frequencies: frequencies)
                TimeOrientationCard(frequencies: frequencies)
            }
        }
    }
    
    private func getFrequencies() -> AITrendsManager.TimeframeFrequencies? {
        switch selectedTimeframe {
        case .week:
            return aiTrendsManager.getWeeklyFrequencies()
        case .month:
            return aiTrendsManager.getMonthlyFrequencies()
        case .year:
            return aiTrendsManager.getYearlyFrequencies()
        }
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

struct EmotionsInsightCard: View {
    let frequencies: AITrendsManager.TimeframeFrequencies
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("EMOTIONS")
                .font(.system(size: 13, weight: .medium))
                .tracking(1.5)
                .foregroundColor(textColor.opacity(0.6))
            
            VStack(spacing: 16) {
                ForEach(frequencies.topEmotions.prefix(3), id: \.value) { emotion in
                    HStack {
                        Text(emotion.value.capitalized)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(textColor)
                        
                        Spacer()
                        
                        Text("\(Int(emotion.percentage))%")
                            .font(.system(size: 15))
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
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 4)
        )
    }
}

struct FocusInsightCard: View {
    let frequencies: AITrendsManager.TimeframeFrequencies
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("FOCUS")
                .font(.system(size: 13, weight: .medium))
                .tracking(1.5)
                .foregroundColor(textColor.opacity(0.6))
            
            if let topFocus = frequencies.topFocuses.first {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(topFocus.value.capitalized)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(textColor)
                        
                        Text("\(Int(topFocus.percentage))% of reflections")
                            .font(.system(size: 15))
                            .foregroundColor(textColor.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    CircularProgressView(
                        progress: topFocus.percentage / 100,
                        color: accentColor
                    )
                    .frame(width: 60, height: 60)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 4)
        )
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    color.opacity(0.2),
                    lineWidth: 8
                )
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: 8,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
        }
    }
}

struct InsufficientDataView: View {
    let timeframe: TrendsView.Timeframe
    let accentColor: Color
    let textColor: Color
    
    var body: some View {
        VStack(spacing: 24) {
            WavyPattern()
                .fill(accentColor.opacity(0.1))
                .frame(height: 60)
            
            VStack(spacing: 12) {
                Text("NO DATA")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.6))
                
                Text(getMessage())
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(height: 200)
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func getMessage() -> String {
        switch timeframe {
        case .month:
            return "Complete 5 days of reflection\nto unlock monthly insights"
                    case .year:
                        return "Complete 40 days of reflection\nto see yearly patterns"
                    case .week:
                        return "Start reflecting to see\nyour weekly progress"
                    }
                }
            }

struct WavyPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height / 2
        let waveHeight = height * 0.25
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        // Create a smooth, continuous wave pattern
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let y = midHeight + sin(relativeX * .pi * 4) * waveHeight
            
            if x == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        return path
    }
}

struct TimeOrientationCard: View {
    let frequencies: AITrendsManager.TimeframeFrequencies
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("TIME ORIENTATION")
                .font(.system(size: 13, weight: .medium))
                .tracking(1.5)
                .foregroundColor(textColor.opacity(0.6))
            
            if let topTime = frequencies.topTimeOrientations.first {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(topTime.value.capitalized)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(textColor)
                        
                        Text("\(Int(topTime.percentage))% of reflections")
                            .font(.system(size: 15))
                            .foregroundColor(textColor.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    CircularProgressView(
                        progress: topTime.percentage / 100,
                        color: accentColor
                    )
                    .frame(width: 60, height: 60)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 4)
        )
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
