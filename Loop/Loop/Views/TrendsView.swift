//
//  TrendsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/28/24.
//


import SwiftUI

import SwiftUI

struct TrendsView: View {
    @ObservedObject var quantTrendsManager = QuantitativeTrendsManager.shared
    @ObservedObject var aiTrendsManager = AITrendsManager.shared
    @ObservedObject var analysisManager = AnalysisManager.shared
    
    @State private var selectedMetric: MetricType = .wpm
    @State private var selectedTimeframe: Timeframe = .week
    @State private var isLoading = true
    @State private var showTimeframePicker = false
    @State private var dropdownOffset: CGFloat = -50
    @State private var dropdownOpacity: Double = 0
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    private let backgroundColor = Color(hex: "F5F5F5")
    
    enum MetricType: String, CaseIterable, Identifiable {
        case wpm = "Speaking Pace"
        case duration = "Duration"
        case wordCount = "Word Count"
        case vocabulary = "Vocabulary"
        
        var id: String { rawValue }
        
        var description: String {
            switch self {
            case .wpm: return "Your natural speaking rhythm"
            case .duration: return "Time spent in reflection"
            case .wordCount: return "Depth of expression"
            case .vocabulary: return "Richness of language"
            }
        }
    }
    
    enum Timeframe: String, CaseIterable {
        case week = "This Week"
        case month = "This Month"
        case year = "This Year"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 4) {
                headerSection
                    .padding(.top, 4)
                    .padding(.horizontal, 24)
                
                if isLoading {
                    loadingView
                } else {
                    VStack(spacing: 40) {
                        TrendGraphCard(
                            selectedMetric: $selectedMetric,
                            timeframe: $selectedTimeframe,
                            quantTrendsManager: quantTrendsManager
                        )
                        
                        correlations()
                            .padding(.horizontal, 24)
                        
                        if let frequencies = getFrequencies() {
                            insightsSection(frequencies)
                                .padding(.horizontal, 24)
                        }
                    }
                }
            }
            .padding(.bottom, 32)
        }
        .background(backgroundColor)
        .onAppear {
            Task {
                await refreshData()
            }
        }
    }
    
    private var headerSection: some View {
        HStack(spacing: 24) {
            timeframeSelector
            
            Spacer()
        }
    }
    
    private var timeframeSelector: some View {
        Menu {
            ForEach(Timeframe.allCases, id: \.self) { timeframe in
                Button(action: {
                    withAnimation {
                        selectedTimeframe = timeframe
                        Task {
                            await refreshData()
                        }
                    }
                }) {
                    HStack {
                        Text(timeframe.rawValue)
                        if selectedTimeframe == timeframe {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text(selectedTimeframe.rawValue)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(textColor)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(accentColor)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(accentColor.opacity(0.1))
            )
        }
    }
    
    private func correlations() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("correlations")
                    .font(.custom("PPNeueMontreal-Medium", size: 28))
                    .foregroundColor(textColor)
                    .padding(.bottom, 8)
                
                Spacer()
            }
            
            
            if let fastestDay = quantTrendsManager.getFastestSpeakingDay() {
                SpeakingPatternsCard(
                    highlight: fastestDay,
                    averageWPM: fastestDay.wpm
                )
            }
            
            if let longestDay = quantTrendsManager.getLongestDurationDay() {
                DurationPatternCard(highlight: longestDay)
            }

            if let mostWordsDay = quantTrendsManager.getMostWordsDay() {
                WordCountPatternCard(highlight: mostWordsDay)
            }
            
        }
    }
    
    private func insightsSection(_ frequencies: AITrendsManager.TimeframeFrequencies) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("reflection patterns")
                .font(.custom("PPNeueMontreal-Medium", size: 28))
                .foregroundColor(textColor)
                .padding(.bottom, 8)
            
            VStack(spacing: 24) {
                EmotionalLandscapeCard(frequencies: frequencies)
//                ReflectionThemesCard(frequencies: frequencies)
//                TimeOrientationCard(frequencies: frequencies)
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(accentColor)
            
            Text("processing reflections...")
                .font(.system(size: 15))
                .foregroundColor(textColor.opacity(0.7))
        }
        .frame(height: 200)
    }
    
    private func getFrequencies() -> AITrendsManager.TimeframeFrequencies? {
        switch selectedTimeframe {
        case .week: return aiTrendsManager.getWeeklyFrequencies()
        case .month: return aiTrendsManager.getMonthlyFrequencies()
        case .year: return aiTrendsManager.getYearlyFrequencies()
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

struct EmotionalLandscapeCard: View {
    let frequencies: AITrendsManager.TimeframeFrequencies
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("EMOTIONAL LANDSCAPE")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.5))
                
                Text("Your most frequent emotional states")
                    .font(.system(size: 15))
                    .foregroundColor(textColor.opacity(0.6))
            }
            
            // Decorative separator
            Path { path in
                path.move(to: CGPoint(x: 0, y: 10))
                for x in stride(from: 0, through: 400, by: 40) {
                    path.addCurve(
                        to: CGPoint(x: x + 40, y: 10),
                        control1: CGPoint(x: x + 10, y: 0),
                        control2: CGPoint(x: x + 30, y: 20)
                    )
                }
            }
            .stroke(accentColor.opacity(0.15), lineWidth: 1)
            .frame(height: 20)
            
            // Emotions list
            VStack(alignment: .leading, spacing: 16) {
                ForEach(frequencies.topEmotions.prefix(3), id: \.value) { emotion in
                    HStack(alignment: .center) {
                        Text(emotion.value.capitalized)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(textColor)
                        
                        Spacer()
                        
                        // Frequency indicator
                        HStack(spacing: 8) {
                            Text("\(Int(emotion.percentage))%")
                                .font(.system(size: 15, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(accentColor.opacity(0.1))
                                )
                                .foregroundColor(accentColor)
                            
                            Text("\(emotion.count)×")
                                .font(.system(size: 15))
                                .foregroundColor(textColor.opacity(0.5))
                        }
                    }
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 2)
    }
}

//struct ReflectionThemesCard: View {
//    let frequencies: AITrendsManager.TimeframeFrequencies
//    private let textColor = Color(hex: "2C3E50")
//    private let accentColor = Color(hex: "A28497")
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 24) {
//            // Header
//            HStack(spacing: 16) {
//                Image(systemName: "square.stack.3d.up")
//                    .font(.system(size: 20))
//                    .foregroundColor(accentColor)
//                
//                VStack(alignment: .leading, spacing: 4) {
//                    Text("THOUGHT PATTERNS")
//                        .font(.system(size: 13, weight: .medium))
//                        .tracking(1.5)
//                        .foregroundColor(textColor.opacity(0.6))
//                    
//                    Text("How you approach your reflections")
//                        .font(.system(size: 14))
//                        .foregroundColor(textColor.opacity(0.6))
//                }
//            }
//            
//            // Themes Grid
//            LazyVGrid(columns: [
//                GridItem(.flexible()),
//                GridItem(.flexible()),
//                GridItem(.flexible())
//            ], spacing: 20) {
//                ForEach(frequencies.topFocuses.prefix(3), id: \.value) { theme in
//                    VStack(spacing: 12) {
//                        Circle()
//                            .strokeBorder(accentColor.opacity(0.3), lineWidth: 1.5)
//                            .background(Circle().fill(accentColor.opacity(0.1)))
//                            .frame(width: 44, height: 44)
//                            .overlay(
//                                getThemeIcon(for: theme.value)
//                                    .font(.system(size: 20))
//                                    .foregroundColor(accentColor)
//                            )
//                        
//                        VStack(spacing: 4) {
//                            Text(theme.value.capitalized)
//                                .font(.system(size: 15))
//                                .foregroundColor(textColor)
//                                .multilineTextAlignment(.center)
//                                .lineLimit(1)
//                            
//                            Text("\(Int(theme.percentage))%")
//                                .font(.system(size: 13))
//                                .foregroundColor(textColor.opacity(0.5))
//                        }
//                    }
//                }
//            }
//        }
//        .padding(24)
//        .background(Color.white)
//        .cornerRadius(16)
//        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 2)
//    }
//    
//    private func getThemeIcon(for theme: String) -> Image {
//        let lowerTheme = theme.lowercased()
//        
//        // Using more abstract icons that represent patterns rather than specific topics
//        if lowerTheme.contains("problem") || lowerTheme.contains("solution") {
//            return Image(systemName: "circle.grid.cross")
//        } else if lowerTheme.contains("reflect") || lowerTheme.contains("contemplat") {
//            return Image(systemName: "rays")
//        } else if lowerTheme.contains("explor") || lowerTheme.contains("discover") {
//            return Image(systemName: "sparkles")
//        } else if lowerTheme.contains("process") || lowerTheme.contains("understand") {
//            return Image(systemName: "square.stack.3d.up")
//        } else if lowerTheme.contains("plan") || lowerTheme.contains("future") {
//            return Image(systemName: "square.3.layers.3d")
//        } else {
//            return Image(systemName: "circle.hexagonpath")
//        }
//    }
//}
//
//struct TimeOrientationCard: View {
//    let frequencies: AITrendsManager.TimeframeFrequencies
//    private let textColor = Color(hex: "2C3E50")
//    private let accentColor = Color(hex: "A28497")
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 20) {
//            // Header
//            VStack(alignment: .leading, spacing: 6) {
//                Text("TIME FOCUS")
//                    .font(.system(size: 13, weight: .medium))
//                    .tracking(1.5)
//                    .foregroundColor(textColor.opacity(0.5))
//                
//                Text("How your reflections flow through time")
//                    .font(.system(size: 15))
//                    .foregroundColor(textColor.opacity(0.6))
//            }
//            
//            // Time orientations
//            VStack(spacing: 16) {
//                ForEach(frequencies.topTimeOrientations, id: \.value) { orientation in
//                    HStack(spacing: 16) {
//                        // Circular progress indicator
//                        Circle()
//                            .trim(from: 0, to: orientation.percentage / 100)
//                            .stroke(accentColor.opacity(0.3), style: StrokeStyle(lineWidth: 3, lineCap: .round))
//                            .rotationEffect(.degrees(-90))
//                            .frame(width: 36, height: 36)
//                            .overlay(
//                                Circle()
//                                    .fill(accentColor.opacity(0.1))
//                                    .frame(width: 28, height: 28)
//                            )
//                        
//                        VStack(alignment: .leading, spacing: 4) {
//                            Text(orientation.value)
//                                .font(.system(size: 16, weight: .medium))
//                                .foregroundColor(textColor)
//                            
////                            Text(getTimeDescription(for: orientation.value))
////                                .font(.system(size: 14))
////                                .foregroundColor(textColor.opacity(0.6))
////                                .lineLimit(1)
//                        }
//                        
//                        Spacer()
//                        
//                        Text("\(Int(orientation.percentage))%")
//                            .font(.system(size: 15, weight: .medium))
//                            .foregroundColor(accentColor)
//                    }
//                }
//            }
//        }
//        .padding(24)
//        .background(Color.white)
//        .cornerRadius(16)
//        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 2)
//    }
//    
//    private func getTimeDescription(for orientation: String) -> String {
//        switch orientation.lowercased() {
//        case "past":
//            return "Drawing from experience"
//        case "present":
//            return "Living in the moment"
//        case "future":
//            return "Looking ahead"
//        default:
//            return "Time orientation"
//        }
//    }
//}

struct TimeframeOption: View {
    let timeframe: TrendsView.Timeframe
    let isSelected: Bool
    let action: () -> Void
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(timeframe.rawValue)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? accentColor : textColor)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(accentColor)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
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
