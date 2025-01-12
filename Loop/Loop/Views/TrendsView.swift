//
//  TrendsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/28/24.
//


import SwiftUI

import SwiftUI

struct TrendsView: View {
    @State var selectedTimeframe: Timeframe = .week
    @ObservedObject private var quantTrendsManager = QuantitativeTrendsManager.shared
    @ObservedObject private var aiTrendsManager = AITrendsManager.shared
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    private let backgroundColor = Color(hex: "F5F5F5")
    
    let previewData: ((current: [DailyStats]?, previous: [DailyStats]?))?

    let mockCurent: [DailyStats] = [
        DailyStats(
            date: Date(),
            year: 2024,
            month: 1,
            weekOfYear: 1,
            weekday: 1,
            averageWPM: 100,
            averageDuration: 120,
            averageWordCount: 200,
            averageUniqueWordCount: 100,
            vocabularyDiversityRatio: 0.5,
            loopCount: 3,
            lastUpdated: Date()
        ),
        DailyStats(
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            year: 2024,
            month: 1,
            weekOfYear: 1,
            weekday: 1,
            averageWPM: 100,
            averageDuration: 90,
            averageWordCount: 200,
            averageUniqueWordCount: 100,
            vocabularyDiversityRatio: 0.5,
            loopCount: 3,
            lastUpdated: Date()
        ),
        DailyStats(
            date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
            year: 2024,
            month: 1,
            weekOfYear: 1,
            weekday: 1,
            averageWPM: 100,
            averageDuration: 150,
            averageWordCount: 200,
            averageUniqueWordCount: 100,
            vocabularyDiversityRatio: 0.5,
            loopCount: 3,
            lastUpdated: Date()
        )
    ]

    let mockPast: [DailyStats] = [
        DailyStats(
            date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
            year: 2024,
            month: 1,
            weekOfYear: 1,
            weekday: 1,
            averageWPM: 100,
            averageDuration: 100,
            averageWordCount: 200,
            averageUniqueWordCount: 100,
            vocabularyDiversityRatio: 0.5,
            loopCount: 3,
            lastUpdated: Date()
        ),
        DailyStats(
            date: Calendar.current.date(byAdding: .day, value: -8, to: Date())!,
            year: 2024,
            month: 1,
            weekOfYear: 1,
            weekday: 1,
            averageWPM: 100,
            averageDuration: 130,
            averageWordCount: 200,
            averageUniqueWordCount: 100,
            vocabularyDiversityRatio: 0.5,
            loopCount: 3,
            lastUpdated: Date()
        ),
        DailyStats(
            date: Calendar.current.date(byAdding: .day, value: -9, to: Date())!,
            year: 2024,
            month: 1,
            weekOfYear: 1,
            weekday: 1,
            averageWPM: 100,
            averageDuration: 110,
            averageWordCount: 200,
            averageUniqueWordCount: 100,
            vocabularyDiversityRatio: 0.5,
            loopCount: 3,
            lastUpdated: Date()
        )
    ]
    
  private var graphData: (current: [DailyStats]?, previous: [DailyStats]?) {
      if let preview = previewData {
          return preview
      }
      return quantTrendsManager.getDurationComparison(for: selectedTimeframe)
  }

    
    private var hasEnoughData: Bool {
        if let preview = previewData {
            return false
        }
        if let stats = quantTrendsManager.weeklyStats {
            return stats.count >= 3
        }
        return false
    }
    
    private var emotionFrequencies: [FrequencyResult] {
        switch selectedTimeframe {
        case .week:
            if let frequencies = aiTrendsManager.getWeeklyFrequencies()?.topEmotions {
                return frequencies.map { result in
                    FrequencyResult(value: result.value, count: result.count, percentage: result.percentage / 100)
                }
            }
        case .month:
            if let frequencies = aiTrendsManager.getMonthlyFrequencies()?.topEmotions {
                return frequencies.map { result in
                    FrequencyResult(value: result.value, count: result.count, percentage: result.percentage / 100)
                }
            }
        case .year:
            if let frequencies = aiTrendsManager.getYearlyFrequencies()?.topEmotions {
                return frequencies.map { result in
                    FrequencyResult(value: result.value, count: result.count, percentage: result.percentage / 100)
                }
            }
        }
        return []
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                HStack {
                    TimeframeSelector(
                       selectedTimeframe: $selectedTimeframe,
                       accentColor: accentColor,
                       textColor: textColor, changedTime: {
                           Task {
                               await refreshData()
                           }
                       }
                   )
                    
                    Spacer()
                }
                .padding(.top, 30)
                
                if ((graphData.current?.isEmpty) != nil) {
                    DurationGraph(
                        currentPeriod: mockCurent,
                        previousPeriod: mockPast,
                        timeframe: selectedTimeframe,
                        accentColor: accentColor,
                        hasEnoughData: hasEnoughData
                    )
                } else {
                    DurationGraph(
                        currentPeriod: graphData.current,
                        previousPeriod: graphData.previous,
                        timeframe: selectedTimeframe,
                        accentColor: accentColor,
                        hasEnoughData: hasEnoughData
                    )
                }
                
                // Emotions Section
                VStack (spacing: 12) {
                    Text("EMOTIONS")
                        .font(.system(size: 13, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(textColor.opacity(0.5))
                    
                    TopEmotionsCard(
                        emotions: emotionFrequencies,
                        accentColor: accentColor,
                        textColor: textColor
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                
                
                // Key Moments Section
                VStack {
                    // Key moments content
                }
                .padding(.horizontal, 24)
                
                // Explore Further Section
                VStack {
                    // Explore content
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .background(backgroundColor)
        .scrollContentBackground(.hidden)
        .onAppear {
           Task {
               await refreshData()
           }
       }
    }
    
    private func refreshData() async {
     //  isLoading = true
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
     //  isLoading = false
    }
}

struct TimeframeSelector: View {
    @Binding var selectedTimeframe: Timeframe
    let accentColor: Color
    let textColor: Color
    
    @State var changedTime: () -> Void
    
    var body: some View {
        Menu {
            ForEach(Timeframe.allCases, id: \.self) { timeframe in
                Button(action: {
                    selectedTimeframe = timeframe
                    changedTime()
                }) {
                    Text(timeframe.rawValue)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text(selectedTimeframe.rawValue)
                    .font(.system(size: 18, weight: .bold))
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(textColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
        .padding(.horizontal, 24)
    }
}

struct DurationGraph: View {
    let currentPeriod: [DailyStats]?
    let previousPeriod: [DailyStats]?
    let timeframe: Timeframe
    let accentColor: Color
    let hasEnoughData: Bool
    
    private let graphHeight: CGFloat = 200
    private let labelHeight: CGFloat = 30
    
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 8) {
           // Title and Key in same row
           HStack {
               VStack (spacing: 8) {
                   Text("Average Duration")
                       .font(.system(size: 30, weight: .bold))
                       .foregroundColor(.black.opacity(0.8))
                   
                   HStack(spacing: 12) {
                       HStack(spacing: 4) {
                           Circle()
                               .fill(accentColor)
                               .frame(width: 6, height: 6)
                           Text(timeframe.rawValue)
                               .font(.system(size: 11, weight: .medium))
                       }
                       
                       if previousPeriod != nil {
                           HStack(spacing: 4) {
                               Circle()
                                   .fill(Color.gray.opacity(0.5))
                                   .frame(width: 6, height: 6)
                               Text("Previous")
                                   .font(.system(size: 11, weight: .medium))
                           }
                       }
                   }
                   .foregroundColor(.black.opacity(0.6))
               }

            
           }
           .padding(.vertical, 8)
           .padding(.horizontal, 24)
           
           // Graph with thicker lines
           GeometryReader { geometry in
               ZStack {
                   if let previousData = previousPeriod {
                       GraphLine(
                           data: previousData,
                           timeframe: timeframe,
                           width: geometry.size.width,
                           height: graphHeight,
                           color: Color.gray.opacity(0.5),
                           lineWidth: 6  // Increased from 2
                       )
                   }
                   
                   if let currentData = currentPeriod {
                       GraphLine(
                           data: currentData,
                           timeframe: timeframe,
                           width: geometry.size.width,
                           height: graphHeight,
                           color: accentColor,
                           lineWidth: 8  // Increased from 2
                       )
                   }
               }
               .blur(radius: hasEnoughData ? 0 : 3)
               .overlay {
                   if !hasEnoughData {
                       VStack(spacing: 20) {
                           VStack(spacing: 8) {
                               Text("REFLECTIONS REQUIRED")
                                   .font(.system(size: 13, weight: .medium))
                                   .tracking(1.5)
                                   .foregroundColor(textColor.opacity(0.6))
               
                               Text(noDataMessage)
                                   .font(.system(size: 17))
                                   .foregroundColor(textColor)
                                   .multilineTextAlignment(.center)
                           }
                       }
                       .padding(.bottom, 40)
                   }
               }
           }
           .frame(height: graphHeight)
           
           // Bottom Labels
           TimeLabels(timeframe: timeframe)
               .frame(height: labelHeight)
       }
    }
    
    private var noDataMessage: String {
        switch timeframe {
        case .week: return "Complete 3 Daily Reflections \nthis week to see this trend"
        case .month: return "Complete 9 days of daily reflection\nthis month to unlock this trend"
        case .year: return "Complete 40 days of daily reflection\nthis year to see this trend"
        }
    }
}

struct GraphLine: View {
    let data: [DailyStats]
    let timeframe: Timeframe
    let width: CGFloat
    let height: CGFloat
    let color: Color
    let lineWidth: CGFloat
    
    var body: some View {
        Path { path in
            let points = data.enumerated().map { index, stat -> CGPoint in
                let x = (width / CGFloat(data.count - 1)) * CGFloat(index)
                
                // Calculate normalized y position
                let maxDuration = data.map { $0.averageDuration }.max() ?? 0
                let minDuration = data.map { $0.averageDuration }.min() ?? 0
                let range = maxDuration - minDuration
                
                // Add padding to top and bottom (20%)
                let paddingPercent: Double = 0.2
                let paddedRange = range * (1 + 2 * paddingPercent)
                let midPoint = (maxDuration + minDuration) / 2
                let yPosition = ((stat.averageDuration - midPoint) / paddedRange) * height
                
                // Center the line and invert (since y grows downward)
                let y = (height / 2) - yPosition
                
                return CGPoint(x: x, y: y)
            }
            
            // Rest of the path drawing...
            path.move(to: points[0])
            
            for i in 1..<points.count {
                let prevPoint = points[i-1]
                let currentPoint = points[i]
                
                let control1 = CGPoint(
                    x: prevPoint.x + (currentPoint.x - prevPoint.x) / 2,
                    y: prevPoint.y
                )
                let control2 = CGPoint(
                    x: prevPoint.x + (currentPoint.x - prevPoint.x) / 2,
                    y: currentPoint.y
                )
                
                path.addCurve(to: currentPoint,
                             control1: control1,
                             control2: control2)
            }
        }
        .stroke(color, lineWidth: lineWidth)
    }
}

struct TimeLabels: View {
    let timeframe: Timeframe
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(labels, id: \.self) { label in
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.black.opacity(0.6))
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private var labels: [String] {
        switch timeframe {
        case .week:
            return ["S", "M", "T", "W", "T", "F", "S"]
        case .month:
            return ["1", "2", "3", "4"]
        case .year:
            return ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]
        }
    }
}

struct EntriesNeededOverlay: View {
    let currentEntries: Int
    let neededEntries: Int = 3
    let accentColor: Color
    
    var body: some View {
        ZStack {
            
            // Progress Card
            VStack(spacing: 16) {
                // Progress circles
                HStack(spacing: 12) {
                    ForEach(0..<neededEntries, id: \.self) { index in
                        Circle()
                            .stroke(accentColor.opacity(0.2), lineWidth: 2)
                            .overlay {
                                if index < currentEntries {
                                    Circle()
                                        .fill(accentColor)
                                }
                            }
                            .frame(width: 12, height: 12)
                    }
                }
                
                VStack(spacing: 8) {
                    Text("\(currentEntries)/\(neededEntries) entries")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "2C3E50"))
                    
                    Text("Complete more reflections to see your trends")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "2C3E50").opacity(0.6))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 4)
            )
            .padding(.horizontal, 32)
        }
    }
}


struct EmotionsCard: View {
    let emotions: [(emotion: String, percentage: Double)]
    let accentColor: Color
    let textColor: Color
    
    private let maxBars = 4 // Show top 4 emotions
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title
            Text("top emotions")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(textColor)
            
            // Emotion bars
            VStack(spacing: 16) {
                ForEach(emotions.prefix(maxBars), id: \.emotion) { item in
                    HStack(spacing: 12) {
                        // Emotion name
                        Text(item.emotion.lowercased())
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(textColor)
                            .frame(width: 80, alignment: .leading)
                        
                        // Bar
                        GeometryReader { geometry in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(accentColor.opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(accentColor)
                                        .frame(width: geometry.size.width * item.percentage)
                                    , alignment: .leading
                                )
                        }
                        .frame(height: 8)
                        
                        // Percentage
                        Text("\(Int(item.percentage * 100))%")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(textColor.opacity(0.6))
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 4)
    }
}

//#Preview {
//    TrendsView()
//}

//
//struct TrendsView: View {
//    @ObservedObject var quantTrendsManager = QuantitativeTrendsManager.shared
//    @ObservedObject var aiTrendsManager = AITrendsManager.shared
//    @ObservedObject var analysisManager = AnalysisManager.shared
//    
//    @State private var selectedMetric: MetricType = .wpm
//    @State private var selectedTimeframe: Timeframe = .week
//    @State private var isLoading = true
//    @State private var showTimeframePicker = false
//    @State private var dropdownOffset: CGFloat = -50
//    @State private var dropdownOpacity: Double = 0
//    
//    private let accentColor = Color(hex: "A28497")
//    private let textColor = Color(hex: "2C3E50")
//    private let backgroundColor = Color(hex: "F5F5F5")
//    
//    enum MetricType: String, CaseIterable, Identifiable {
//        case wpm = "Speaking Pace"
//        case duration = "Duration"
//        case wordCount = "Word Count"
//        case vocabulary = "Vocabulary"
//        
//        var id: String { rawValue }
//        
//        var description: String {
//            switch self {
//            case .wpm: return "Your natural speaking rhythm"
//            case .duration: return "Time spent in reflection"
//            case .wordCount: return "Depth of expression"
//            case .vocabulary: return "Richness of language"
//            }
//        }
//    }
//    
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 4) {
//                headerSection
//                    .padding(.top, 4)
//                    .padding(.horizontal, 24)
//                
//                if isLoading {
//                    loadingView
//                } else {
//                    VStack(spacing: 40) {
//                        TrendGraphCard(
//                            selectedMetric: $selectedMetric,
//                            timeframe: $selectedTimeframe,
//                            quantTrendsManager: quantTrendsManager
//                        )
//                        
//                        correlations()
//                            .padding(.horizontal, 24)
//                        
////                        if let frequencies = getFrequencies() {
////                            insightsSection(frequencies)
////                                .padding(.horizontal, 24)
////                        }
//                    }
//                }
//            }
//            .padding(.bottom, 32)
//        }
//        .background(backgroundColor)
//        .onAppear {
//            Task {
//                await refreshData()
//            }
//        }
//    }
//    
//    private var headerSection: some View {
//        HStack(spacing: 24) {
//            timeframeSelector
//            
//            Spacer()
//        }
//    }
//    
//    private var timeframeSelector: some View {
//        Menu {
//            ForEach(Timeframe.allCases, id: \.self) { timeframe in
//                Button(action: {
//                    withAnimation {
//                        selectedTimeframe = timeframe
//                        Task {
//                            await refreshData()
//                        }
//                    }
//                }) {
//                    HStack {
//                        Text(timeframe.rawValue)
//                        if selectedTimeframe == timeframe {
//                            Image(systemName: "checkmark")
//                        }
//                    }
//                }
//            }
//        } label: {
//            HStack(spacing: 8) {
//                Text(selectedTimeframe.rawValue)
//                    .font(.system(size: 16, weight: .medium))
//                    .foregroundColor(textColor)
//                
//                Image(systemName: "chevron.down")
//                    .font(.system(size: 12, weight: .semibold))
//                    .foregroundColor(accentColor)
//            }
//            .padding(.horizontal, 20)
//            .padding(.vertical, 10)
//            .background(
//                Capsule()
//                    .fill(accentColor.opacity(0.1))
//            )
//        }
//    }
//    
//    private func correlations() -> some View {
//        VStack(alignment: .leading, spacing: 16) {
//            if let fastestDay = quantTrendsManager.getFastestSpeakingDay() {
//                HStack {
//                    Text("correlations")
//                        .font(.custom("PPNeueMontreal-Medium", size: 28))
//                        .foregroundColor(textColor)
//                        .padding(.bottom, 8)
//                    
//                    Spacer()
//                }
//                
//                SpeakingPatternsCard(
//                    highlight: fastestDay,
//                    averageWPM: fastestDay.wpm
//                )
//            }
//            
//            if let longestDay = quantTrendsManager.getLongestDurationDay() {
//                DurationPatternCard(highlight: longestDay)
//            }
//
//            if let mostWordsDay = quantTrendsManager.getMostWordsDay() {
//                WordCountPatternCard(highlight: mostWordsDay)
//            }
//            
//        }
//    }
//    
//    private func insightsSection(_ frequencies: AITrendsManager.TimeframeFrequencies) -> some View {
//        VStack(alignment: .leading, spacing: 16) {
//            Text("reflection patterns")
//                .font(.custom("PPNeueMontreal-Medium", size: 28))
//                .foregroundColor(textColor)
//                .padding(.bottom, 8)
//            
//            VStack(spacing: 24) {
//                EmotionalLandscapeCard(frequencies: frequencies)
////                ReflectionThemesCard(frequencies: frequencies)
////                TimeOrientationCard(frequencies: frequencies)
//            }
//        }
//    }
//    
//    private var loadingView: some View {
//        VStack(spacing: 12) {
//            ProgressView()
//                .tint(accentColor)
//            
//            Text("processing reflections...")
//                .font(.system(size: 15))
//                .foregroundColor(textColor.opacity(0.7))
//        }
//        .frame(height: 200)
//    }
//    
//    private func getFrequencies() -> AITrendsManager.TimeframeFrequencies? {
//        switch selectedTimeframe {
//        case .week: return aiTrendsManager.getWeeklyFrequencies()
//        case .month: return aiTrendsManager.getMonthlyFrequencies()
//        case .year: return aiTrendsManager.getYearlyFrequencies()
//        }
//    }
//    
//    private func refreshData() async {
//        isLoading = true
//        switch selectedTimeframe {
//        case .week:
//            await quantTrendsManager.fetchCurrentWeekStats()
//            await aiTrendsManager.fetchCurrentWeekAnalyses()
//        case .month:
//            await quantTrendsManager.fetchCurrentMonthStats()
//            await aiTrendsManager.fetchCurrentMonthAnalyses()
//        case .year:
//            await quantTrendsManager.fetchCurrentYearStats()
//            await aiTrendsManager.fetchCurrentYearAnalyses()
//        }
//        isLoading = false
//    }
//}
//
//struct EmotionalLandscapeCard: View {
//    let frequencies: AITrendsManager.TimeframeFrequencies
//    private let textColor = Color(hex: "2C3E50")
//    private let accentColor = Color(hex: "A28497")
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 20) {
//            // Header
//            VStack(alignment: .leading, spacing: 6) {
//                Text("EMOTIONAL LANDSCAPE")
//                    .font(.system(size: 13, weight: .medium))
//                    .tracking(1.5)
//                    .foregroundColor(textColor.opacity(0.5))
//                
//                Text("Your most frequent emotional states")
//                    .font(.system(size: 15))
//                    .foregroundColor(textColor.opacity(0.6))
//            }
//            
//            // Decorative separator
//            Path { path in
//                path.move(to: CGPoint(x: 0, y: 10))
//                for x in stride(from: 0, through: 400, by: 40) {
//                    path.addCurve(
//                        to: CGPoint(x: x + 40, y: 10),
//                        control1: CGPoint(x: x + 10, y: 0),
//                        control2: CGPoint(x: x + 30, y: 20)
//                    )
//                }
//            }
//            .stroke(accentColor.opacity(0.15), lineWidth: 1)
//            .frame(height: 20)
//            
//            // Emotions list
//            VStack(alignment: .leading, spacing: 16) {
//                ForEach(frequencies.topEmotions.prefix(3), id: \.value) { emotion in
//                    HStack(alignment: .center) {
//                        Text(emotion.value.capitalized)
//                            .font(.system(size: 17, weight: .medium))
//                            .foregroundColor(textColor)
//                        
//                        Spacer()
//                        
//                        // Frequency indicator
//                        HStack(spacing: 8) {
//                            Text("\(Int(emotion.percentage))%")
//                                .font(.system(size: 15, weight: .medium))
//                                .padding(.horizontal, 12)
//                                .padding(.vertical, 6)
//                                .background(
//                                    RoundedRectangle(cornerRadius: 6)
//                                        .fill(accentColor.opacity(0.1))
//                                )
//                                .foregroundColor(accentColor)
//                            
//                            Text("\(emotion.count)×")
//                                .font(.system(size: 15))
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
//}
//
////struct ReflectionThemesCard: View {
////    let frequencies: AITrendsManager.TimeframeFrequencies
////    private let textColor = Color(hex: "2C3E50")
////    private let accentColor = Color(hex: "A28497")
////    
////    var body: some View {
////        VStack(alignment: .leading, spacing: 24) {
////            // Header
////            HStack(spacing: 16) {
////                Image(systemName: "square.stack.3d.up")
////                    .font(.system(size: 20))
////                    .foregroundColor(accentColor)
////                
////                VStack(alignment: .leading, spacing: 4) {
////                    Text("THOUGHT PATTERNS")
////                        .font(.system(size: 13, weight: .medium))
////                        .tracking(1.5)
////                        .foregroundColor(textColor.opacity(0.6))
////                    
////                    Text("How you approach your reflections")
////                        .font(.system(size: 14))
////                        .foregroundColor(textColor.opacity(0.6))
////                }
////            }
////            
////            // Themes Grid
////            LazyVGrid(columns: [
////                GridItem(.flexible()),
////                GridItem(.flexible()),
////                GridItem(.flexible())
////            ], spacing: 20) {
////                ForEach(frequencies.topFocuses.prefix(3), id: \.value) { theme in
////                    VStack(spacing: 12) {
////                        Circle()
////                            .strokeBorder(accentColor.opacity(0.3), lineWidth: 1.5)
////                            .background(Circle().fill(accentColor.opacity(0.1)))
////                            .frame(width: 44, height: 44)
////                            .overlay(
////                                getThemeIcon(for: theme.value)
////                                    .font(.system(size: 20))
////                                    .foregroundColor(accentColor)
////                            )
////                        
////                        VStack(spacing: 4) {
////                            Text(theme.value.capitalized)
////                                .font(.system(size: 15))
////                                .foregroundColor(textColor)
////                                .multilineTextAlignment(.center)
////                                .lineLimit(1)
////                            
////                            Text("\(Int(theme.percentage))%")
////                                .font(.system(size: 13))
////                                .foregroundColor(textColor.opacity(0.5))
////                        }
////                    }
////                }
////            }
////        }
////        .padding(24)
////        .background(Color.white)
////        .cornerRadius(16)
////        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 2)
////    }
////    
////    private func getThemeIcon(for theme: String) -> Image {
////        let lowerTheme = theme.lowercased()
////        
////        // Using more abstract icons that represent patterns rather than specific topics
////        if lowerTheme.contains("problem") || lowerTheme.contains("solution") {
////            return Image(systemName: "circle.grid.cross")
////        } else if lowerTheme.contains("reflect") || lowerTheme.contains("contemplat") {
////            return Image(systemName: "rays")
////        } else if lowerTheme.contains("explor") || lowerTheme.contains("discover") {
////            return Image(systemName: "sparkles")
////        } else if lowerTheme.contains("process") || lowerTheme.contains("understand") {
////            return Image(systemName: "square.stack.3d.up")
////        } else if lowerTheme.contains("plan") || lowerTheme.contains("future") {
////            return Image(systemName: "square.3.layers.3d")
////        } else {
////            return Image(systemName: "circle.hexagonpath")
////        }
////    }
////}
////
////struct TimeOrientationCard: View {
////    let frequencies: AITrendsManager.TimeframeFrequencies
////    private let textColor = Color(hex: "2C3E50")
////    private let accentColor = Color(hex: "A28497")
////    
////    var body: some View {
////        VStack(alignment: .leading, spacing: 20) {
////            // Header
////            VStack(alignment: .leading, spacing: 6) {
////                Text("TIME FOCUS")
////                    .font(.system(size: 13, weight: .medium))
////                    .tracking(1.5)
////                    .foregroundColor(textColor.opacity(0.5))
////                
////                Text("How your reflections flow through time")
////                    .font(.system(size: 15))
////                    .foregroundColor(textColor.opacity(0.6))
////            }
////            
////            // Time orientations
////            VStack(spacing: 16) {
////                ForEach(frequencies.topTimeOrientations, id: \.value) { orientation in
////                    HStack(spacing: 16) {
////                        // Circular progress indicator
////                        Circle()
////                            .trim(from: 0, to: orientation.percentage / 100)
////                            .stroke(accentColor.opacity(0.3), style: StrokeStyle(lineWidth: 3, lineCap: .round))
////                            .rotationEffect(.degrees(-90))
////                            .frame(width: 36, height: 36)
////                            .overlay(
////                                Circle()
////                                    .fill(accentColor.opacity(0.1))
////                                    .frame(width: 28, height: 28)
////                            )
////                        
////                        VStack(alignment: .leading, spacing: 4) {
////                            Text(orientation.value)
////                                .font(.system(size: 16, weight: .medium))
////                                .foregroundColor(textColor)
////                            
//////                            Text(getTimeDescription(for: orientation.value))
//////                                .font(.system(size: 14))
//////                                .foregroundColor(textColor.opacity(0.6))
//////                                .lineLimit(1)
////                        }
////                        
////                        Spacer()
////                        
////                        Text("\(Int(orientation.percentage))%")
////                            .font(.system(size: 15, weight: .medium))
////                            .foregroundColor(accentColor)
////                    }
////                }
////            }
////        }
////        .padding(24)
////        .background(Color.white)
////        .cornerRadius(16)
////        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 2)
////    }
////    
////    private func getTimeDescription(for orientation: String) -> String {
////        switch orientation.lowercased() {
////        case "past":
////            return "Drawing from experience"
////        case "present":
////            return "Living in the moment"
////        case "future":
////            return "Looking ahead"
////        default:
////            return "Time orientation"
////        }
////    }
////}
//
//struct TimeframeOption: View {
//    let timeframe: Timeframe
//    let isSelected: Bool
//    let action: () -> Void
//    
//    private let accentColor = Color(hex: "A28497")
//    private let textColor = Color(hex: "2C3E50")
//    
//    var body: some View {
//        Button(action: action) {
//            HStack {
//                Text(timeframe.rawValue)
//                    .font(.system(size: 16, weight: .medium))
//                    .foregroundColor(isSelected ? accentColor : textColor)
//                
//                Spacer()
//                
//                if isSelected {
//                    Image(systemName: "checkmark")
//                        .font(.system(size: 12, weight: .semibold))
//                        .foregroundColor(accentColor)
//                }
//            }
//            .padding(.vertical, 12)
//            .padding(.horizontal, 20)
//        }
//    }
//}
//
enum Timeframe: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
}

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

#Preview {
   let previewData: [DailyStats] = [
       DailyStats(
           date: Date(),
           year: 2024,
           month: 1,
           weekOfYear: 1,
           weekday: 1,
           averageWPM: 100,
           averageDuration: 120,
           averageWordCount: 200,
           averageUniqueWordCount: 100,
           vocabularyDiversityRatio: 0.5,
           loopCount: 3,
           lastUpdated: Date()
       ),
       DailyStats(
           date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
           year: 2024,
           month: 1,
           weekOfYear: 1,
           weekday: 1,
           averageWPM: 100,
           averageDuration: 90,
           averageWordCount: 200,
           averageUniqueWordCount: 100,
           vocabularyDiversityRatio: 0.5,
           loopCount: 3,
           lastUpdated: Date()
       ),
       DailyStats(
           date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
           year: 2024,
           month: 1,
           weekOfYear: 1,
           weekday: 1,
           averageWPM: 100,
           averageDuration: 150,
           averageWordCount: 200,
           averageUniqueWordCount: 100,
           vocabularyDiversityRatio: 0.5,
           loopCount: 3,
           lastUpdated: Date()
       )
   ]

   let previousData: [DailyStats] = [
       DailyStats(
           date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
           year: 2024,
           month: 1,
           weekOfYear: 1,
           weekday: 1,
           averageWPM: 100,
           averageDuration: 100,
           averageWordCount: 200,
           averageUniqueWordCount: 100,
           vocabularyDiversityRatio: 0.5,
           loopCount: 3,
           lastUpdated: Date()
       ),
       DailyStats(
           date: Calendar.current.date(byAdding: .day, value: -8, to: Date())!,
           year: 2024,
           month: 1,
           weekOfYear: 1,
           weekday: 1,
           averageWPM: 100,
           averageDuration: 130,
           averageWordCount: 200,
           averageUniqueWordCount: 100,
           vocabularyDiversityRatio: 0.5,
           loopCount: 3,
           lastUpdated: Date()
       ),
       DailyStats(
           date: Calendar.current.date(byAdding: .day, value: -9, to: Date())!,
           year: 2024,
           month: 1,
           weekOfYear: 1,
           weekday: 1,
           averageWPM: 100,
           averageDuration: 110,
           averageWordCount: 200,
           averageUniqueWordCount: 100,
           vocabularyDiversityRatio: 0.5,
           loopCount: 3,
           lastUpdated: Date()
       )
   ]

    return TrendsView(previewData: (previewData, previousData))
}
