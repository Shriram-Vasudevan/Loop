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
    
    
    private func insightsSection(_ frequencies: AITrendsManager.TimeframeFrequencies) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("reflection patterns")
                .font(.custom("PPNeueMontreal-Medium", size: 28))
                .foregroundColor(textColor)
                .padding(.bottom, 8)
            
            VStack(spacing: 24) {
                EmotionalInsightCard(frequencies: frequencies)
                FocusAreaCard(frequencies: frequencies)
                TimeOrientationCard(frequencies: frequencies)
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

struct EmotionalInsightCard: View {
    let frequencies: AITrendsManager.TimeframeFrequencies
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("EMOTIONAL LANDSCAPE")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.5))
                
                Text("Your most frequent themes")
                    .font(.system(size: 15))
                    .foregroundColor(textColor.opacity(0.6))
            }
            
            // Wave Design
            ZStack {
                WavePattern()
                    .stroke(accentColor.opacity(0.1), lineWidth: 1)
                    .frame(height: 40)
                    .offset(x: 4, y: 2)
            }
            
            // Emotions list
            VStack(alignment: .leading, spacing: 16) {
                ForEach(frequencies.topEmotions.prefix(3), id: \.value) { emotion in
                    HStack(alignment: .center) {
                        Text(emotion.value.capitalized)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(textColor)
                        
                        Spacer()
                        
                        Text("\(emotion.count)")
                            .font(.system(size: 15, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(accentColor.opacity(0.1))
                            )
                            .foregroundColor(accentColor)
                    }
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(10)
    }
}

struct FocusAreaCard: View {
    let frequencies: AITrendsManager.TimeframeFrequencies
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 16) {
                Image(systemName: "target")
                    .font(.system(size: 20))
                    .foregroundColor(accentColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("FOCUS AREAS")
                        .font(.system(size: 13, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(textColor.opacity(0.6))
                    
                    Text("Key themes you've been reflecting on")
                        .font(.system(size: 14))
                        .foregroundColor(textColor.opacity(0.6))
                }
            }
            
            HStack(spacing: 20) {
                ForEach(frequencies.topFocuses.prefix(3), id: \.value) { focus in
                    VStack(spacing: 12) {
                        Circle()
                            .strokeBorder(accentColor.opacity(0.3), lineWidth: 1.5)
                            .background(Circle().fill(accentColor.opacity(0.1)))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: getFocusIcon(for: focus.value))
                                    .font(.system(size: 20))
                                    .foregroundColor(accentColor)
                            )
                        
                        Text(focus.value.capitalized)
                            .font(.system(size: 15))
                            .foregroundColor(textColor)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
    }
    
    private func getFocusIcon(for focus: String) -> String {
        switch focus.lowercased() {
        case "work", "career": return "briefcase.fill"
        case "relationships", "family": return "heart.circle.fill"
        case "health", "wellness": return "heart.text.square.fill"
        case "personal growth": return "leaf.fill"
        case "creativity": return "paintbrush.fill"
        case "learning": return "book.fill"
        default: return "star.fill"
        }
    }
}

struct TimeOrientationCard: View {
    let frequencies: AITrendsManager.TimeframeFrequencies
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 16) {
                Image(systemName: "clock")
                    .font(.system(size: 20))
                    .foregroundColor(accentColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("TEMPORAL FOCUS")
                        .font(.system(size: 13, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(textColor.opacity(0.6))
                    
                    Text("Where your thoughts are oriented in time")
                        .font(.system(size: 14))
                        .foregroundColor(textColor.opacity(0.6))
                }
            }
            
            HStack(spacing: 16) {
                if let orientation = frequencies.topTimeOrientations.first {
                    Circle()
                        .strokeBorder(accentColor.opacity(0.3), lineWidth: 1.5)
                        .background(Circle().fill(accentColor.opacity(0.1)))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: getTimeIcon(for: orientation.value))
                                .font(.system(size: 16))
                                .foregroundColor(accentColor)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(orientation.value.capitalized)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(textColor)
                        
                        Text(getTimeDescription(for: orientation.value))
                            .font(.system(size: 14))
                            .foregroundColor(textColor.opacity(0.6))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
    }
    
    private func getTimeIcon(for time: String) -> String {
        switch time.lowercased() {
        case "past": return "arrow.counterclockwise"
        case "present": return "sun.max.fill"
        case "future": return "arrow.forward"
        default: return "clock.fill"
        }
    }
    
    private func getTimeDescription(for time: String) -> String {
        switch time.lowercased() {
        case "past": return "Reflecting on previous experiences"
        case "present": return "Focused on the current moment"
        case "future": return "Looking ahead to what's coming"
        default: return "Temporal orientation"
        }
    }
}

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
