//
//  InsightsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/7/24.
//

import SwiftUI
import Charts

//
//  InsightsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/7/24.
//

struct InsightsView: View {
    @ObservedObject var analysisManager: AnalysisManager = AnalysisManager.shared
    @State private var animateCards = false
    @State private var selectedTab = "today"
    
    @State var selectedFollowUp: FollowUp?
    
    private let accentColor = Color(hex: "A28497")
    private let backgroundColor = Color(hex: "FAFBFC")
    private let surfaceColor = Color(hex: "F8F5F7")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("insights")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(textColor)
                                
                                Text("dive deeper")
                                    .font(.system(size: 15, weight: .light))
                                    .foregroundColor(textColor.opacity(0.6))
                                    .tracking(2)
                            }
                            Spacer()
                        }
                        .padding(.top, 16)
                        .opacity(animateCards ? 1 : 0)
                        .offset(y: animateCards ? 0 : 20)
                        
                        if selectedTab == "today" {
                            if analysisManager.todaysLoops.count == 3 {
                                TodayInsightsContent(analysisManager: analysisManager, selectedFollowUp: $selectedFollowUp)
                                    .opacity(animateCards ? 1 : 0)
                                    .offset(y: animateCards ? 0 : 20)
                            } else {
                                Text("Complete Today's Loops for Analysis")
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundColor(textColor.opacity(0.7))
                            }
                        } else {
                            TrendsInsightsView(analysisManager: analysisManager)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                tabToggle
                    .padding(.bottom, 10)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateCards = true
            }
        }
        .fullScreenCover(item: $selectedFollowUp) { selectedFollowUp in
            RecordFollowUpLoopView(prompt: selectedFollowUp.prompt)
        }
    }
    
    private var tabToggle: some View {
        Menu {
            Button("today") {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = "today"
                }
            }
            Button("trends") {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = "trends"
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text(selectedTab)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(textColor)
                Image(systemName: "chevron.up")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(textColor.opacity(0.7))
            }
            .frame(height: 55)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(color: accentColor.opacity(0.15), radius: 10, y: 4)
            .padding(.horizontal)
        }
    }
}

struct TodayInsightsContent: View {
    @ObservedObject var analysisManager: AnalysisManager
    private let accentColor = Color(hex: "A28497")
    private let backgroundColor = Color(hex: "FAFBFC")
    private let surfaceColor = Color(hex: "F8F5F7")
    private let textColor = Color(hex: "2C3E50")
    
    @Binding var selectedFollowUp: FollowUp?
    
    var body: some View {
        VStack(spacing: 32) {
            VStack (spacing: 16) {
                aiAnalysisCard
                
                if let followUp = analysisManager.currentDailyAnalysis?.aiAnalysis?.followUp {
                    FollowUpWidget(
                        followUpQuestion: followUp,
                        onRecordTapped: {
                            self.selectedFollowUp = FollowUp(id: UUID().uuidString, prompt: followUp)
                        }
                    )
                }
                
            }
            
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("speaking patterns")
                
                VStack(spacing: 3) {
                    speakingRhythmCard
                    durationCard
                    selfReferenceCard
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("focus")
                
                VStack(spacing: 3) {
                    actionReflectionCard
                    solutionFocusCard
                    loopConnectionsCard
                }
            }
        }
    }
    
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .regular))
            .foregroundColor(textColor.opacity(0.5))
            .tracking(0.5)
    }
    
    private var aiAnalysisCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 8) {
                Circle()
                    .fill(accentColor.opacity(0.2))
                    .frame(width: 6, height: 6)
                    .overlay(
                        Circle()
                            .fill(accentColor)
                            .frame(width: 3, height: 3)
                    )
                
                Text("AI ANALYSIS")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(accentColor)
                    .tracking(1)
            }
            
            if let analysis = analysisManager.currentDailyAnalysis?.aiAnalysis {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(analysis.feeling.capitalized)
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(textColor)
                        
                        Spacer()
                    }
                    
                    Text(analysis.feelingDescription)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(textColor.opacity(0.7))
                        .lineSpacing(4)
                }
            } else {
                Text("Analyzing your responses...")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(textColor.opacity(0.7))
            }
        }
        .padding(24)
        .background(
            ZStack {
                Color.white
                WavyBackground()
                    .foregroundColor(surfaceColor)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var speakingRhythmCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Speaking Rhythm")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(textColor)
                
                Text("A measure of your natural speaking pace")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(textColor.opacity(0.6))
            }
            
            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Int(analysisManager.currentDailyAnalysis?.aggregateMetrics.averageWPM ?? 0))")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundColor(textColor)
                    
                    Text("words/min")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(textColor.opacity(0.6))
                }
                
                Text("You maintain a steady, thoughtful pace that allows for clear articulation")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(textColor.opacity(0.7))
                    .lineSpacing(4)
            }
            
            waveformView
        }
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var durationCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Speaking Duration")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(textColor)
                
                Text("Time spent on each reflection")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(textColor.opacity(0.6))
            }
            
            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDuration(analysisManager.currentDailyAnalysis?.aggregateMetrics.averageDuration ?? 0))
                        .font(.system(size: 34, weight: .medium))
                        .foregroundColor(textColor)
                    
                    Text("average")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(textColor.opacity(0.6))
                }
                
                Text("Your responses are thoughtfully paced, allowing for detailed reflection")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(textColor.opacity(0.7))
                    .lineSpacing(4)
            }
            
            durationBar
        }
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var selfReferenceCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Self References")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(textColor)
                
                Text("How you express personal experiences")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(textColor.opacity(0.6))
            }
            
            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(analysisManager.currentDailyAnalysis?.aiAnalysis?.selfReferenceCount ?? 0)")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundColor(textColor)
                    
                    Text("mentions")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(textColor.opacity(0.6))
                }
                
                Text(analysisManager.currentDailyAnalysis?.aiAnalysis?.tenseDescription ?? "")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(textColor.opacity(0.7))
                    .lineSpacing(4)
            }
            
            selfReferenceIndicators
        }
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var actionReflectionCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Action vs Reflection")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(textColor)
                
                Text("Balance between doing and thinking")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(textColor.opacity(0.6))
            }
            
            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(analysisManager.currentDailyAnalysis?.aiAnalysis?.actionReflectionRatio ?? "")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundColor(textColor)
                    
                    Text("action/reflection")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(textColor.opacity(0.6))
                }
                
                Text(analysisManager.currentDailyAnalysis?.aiAnalysis?.actionReflectionDescription ?? "")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(textColor.opacity(0.7))
                    .lineSpacing(4)
            }
            
            balanceBar
        }
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var solutionFocusCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Solution Focus")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(textColor)
                
                Text("How you approach challenges")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(textColor.opacity(0.6))
            }
            
            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(analysisManager.currentDailyAnalysis?.aiAnalysis?.solutionFocus ?? "")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundColor(textColor)
                    
                    Text("solution/problem")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(textColor.opacity(0.6))
                }
                
                Text(analysisManager.currentDailyAnalysis?.aiAnalysis?.solutionFocusDescription ?? "")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(textColor.opacity(0.7))
                    .lineSpacing(4)
            }
            
            solutionFocusIndicator
        }
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var loopConnectionsCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Loop Connections")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(textColor)
                
                Text("Themes across your reflections")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(textColor.opacity(0.6))
            }
            
            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Int((analysisManager.currentDailyAnalysis?.overlapAnalysis.overallSimilarity ?? 0) * 100))%")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundColor(textColor)
                    
                    Text("thematic similarity")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(textColor.opacity(0.6))
                }
                
                Text("Your reflections share common themes while exploring different perspectives")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(textColor.opacity(0.7))
                    .lineSpacing(4)
            }
            
            connectionIndicator
        }
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var waveformView: some View {
        HStack(spacing: 3) {
            ForEach(0..<30) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(accentColor.opacity(0.3))
                    .frame(width: 2, height: CGFloat(sin(Double(i) * 0.3) * 20 + 25))
            }
        }
        .frame(height: 50)
    }
    
    private var durationBar: some View {
        GeometryReader { geometry in
            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(accentColor.opacity(0.2))
                        .frame(height: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .fill(accentColor)
                                .frame(width: geometry.size.width / 3 * 0.8)
                                .offset(x: CGFloat(i) * 4),
                            alignment: .leading
                        )
                }
            }
        }
        .frame(height: 4)
    }
    
    private var selfReferenceIndicators: some View {
        HStack(spacing: 12) {
            ForEach(0..<min(analysisManager.currentDailyAnalysis?.aiAnalysis?.selfReferenceCount ?? 0, 5)) { _ in
                Circle()
                    .fill(accentColor.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
    
    private var balanceBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(accentColor.opacity(0.2))
                    .frame(height: 4)
                
                let ratio = getActionRatio()
                RoundedRectangle(cornerRadius: 2)
                    .fill(accentColor)
                    .frame(width: geometry.size.width * ratio, height: 4)
            }
        }
        .frame(height: 4)
    }
    
    private var solutionFocusIndicator: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(accentColor.opacity(0.2))
                    .frame(height: 4)
                
                let ratio = getSolutionRatio()
                RoundedRectangle(cornerRadius: 2)
                    .fill(accentColor)
                    .frame(width: geometry.size.width * ratio, height: 4)
            }
        }
        .frame(height: 4)
    }
    
    private var connectionIndicator: some View {
        HStack(spacing: 20) {
            ForEach(0..<3) { i in
                Circle()
                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .fill(accentColor.opacity(0.2))
                            .frame(width: 6, height: 6)
                    )
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return seconds == 0 ? "\(minutes)m" : "\(minutes)m \(seconds)s"
    }
    
    private func getActionRatio() -> CGFloat {
        guard let ratio = analysisManager.currentDailyAnalysis?.aiAnalysis?.actionReflectionRatio else { return 0.5 }
        let components = ratio.split(separator: "/")
        guard components.count == 2,
              let action = Double(components[0]),
              let reflection = Double(components[1]) else {
            return 0.5
        }
        let total = action + reflection
        return CGFloat(action / total)
    }

    private func getSolutionRatio() -> CGFloat {
        guard let ratio = analysisManager.currentDailyAnalysis?.aiAnalysis?.solutionFocus else { return 0.5 }
        let components = ratio.split(separator: "/")
        guard components.count == 2,
              let solution = Double(components[0]),
              let problem = Double(components[1]) else {
            return 0.5
        }
        let total = solution + problem
        return CGFloat(solution / total)
    }
}

struct FollowUpWidget: View {
    let followUpQuestion: String
    let onRecordTapped: () -> Void
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 8) {
                Circle()
                    .fill(accentColor.opacity(0.2))
                    .frame(width: 6, height: 6)
                    .overlay(
                        Circle()
                            .fill(accentColor)
                            .frame(width: 3, height: 3)
                    )
                
                Text("FOLLOW UP")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(accentColor)
                    .tracking(1)
            }
            
            Text(followUpQuestion)
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(textColor)
                .lineSpacing(4)
            
            Button(action: onRecordTapped) {
                HStack(spacing: 8) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 16))
                    Text("Record Now")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 25))
            }
        }
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct TrendsInsightsView: View {
    @ObservedObject var analysisManager: AnalysisManager
    @State private var selectedPeriod = "week"
    @State private var selectedMetric: GraphData.MetricType = .wpm
    
    private let accentColor = Color(hex: "A28497")
    private let backgroundColor = Color(hex: "FAFBFC")
    private let surfaceColor = Color(hex: "F8F5F7")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 0) {
            // Time Period Selector
            VStack(spacing: 16) {
                HStack {
                    Text("insights")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(textColor)
                    Spacer()
                }
                .padding(.top, 16)
                
                periodSelector
            }
            .padding(.horizontal, 24)
            
            // Main Content
            ScrollView {
                VStack(spacing: 24) {
                    // Metric Selector and Value
                    HStack {
                        if let currentValue = getCurrentValue() {
                            VStack(alignment: .leading) {
                                Text(selectedMetric.rawValue)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(textColor.opacity(0.6))
                                Text(String(format: "%.1f", currentValue))
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(textColor)
                            }
                        }
                        
                        Spacer()
                        
                        Menu {
                            ForEach(GraphData.MetricType.allCases, id: \.self) { metric in
                                Button(metric.rawValue) {
                                    withAnimation {
                                        selectedMetric = metric
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "chart.xyaxis.line")
                                    .font(.system(size: 14, weight: .medium))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(textColor)
                            .padding(8)
                            .background(surfaceColor)
                            .clipShape(Circle())
                        }
                    }
                    .padding(.top, 8)
                    
                    // Graph Section
                    ZStack {
                        if isLoading {
                            StatsLoadingView()
                        } else if let graphData = createGraphData() {
                            TrendsGraphView(data: graphData)
                        } else {
                            Text("No data available")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(textColor.opacity(0.6))
                        }
                    }
                    .frame(height: 300)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                }
                .padding(.horizontal, 24)
            }
        }
        .task {
            await loadDataForPeriod()
        }
    }
    
    private var periodSelector: some View {
        HStack(spacing: 24) {
            ForEach(["week", "month", "year"], id: \.self) { period in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedPeriod = period
                    }
                    Task {
                        await loadDataForPeriod()
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(period.capitalized)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(selectedPeriod == period ? textColor : textColor.opacity(0.5))
                        
                        Rectangle()
                            .fill(selectedPeriod == period ? accentColor : Color.clear)
                            .frame(height: 2)
                    }
                }
            }
        }
    }
    
    private var isLoading: Bool {
        switch selectedPeriod {
        case "week":
            return analysisManager.isLoadingWeekStats
        case "month":
            return analysisManager.isLoadingMonthStats
        case "year":
            return analysisManager.isLoadingYearStats
        default:
            return false
        }
    }
    
    private func loadDataForPeriod() async {
        switch selectedPeriod {
        case "week":
            await analysisManager.fetchCurrentWeekStats()
        case "month":
            await analysisManager.fetchCurrentMonthWeeklyStats()
        case "year":
            await analysisManager.fetchCurrentYearMonthlyStats()
        default:
            break
        }
    }
    
    private func getCurrentValue() -> Double? {
        switch selectedPeriod {
        case "week":
            return analysisManager.currentWeekStats.last?.averageWPM
        case "month":
            return analysisManager.currentMonthWeeklyStats.last?.averageWPM
        case "year":
            return analysisManager.currentYearMonthlyStats.last?.averageWPM
        default:
            return nil
        }
    }
    
    private func createGraphData() -> GraphData? {
        switch selectedPeriod {
        case "week":
            return createWeekGraphData()
        case "month":
            return createMonthGraphData()
        case "year":
            return createYearGraphData()
        default:
            return nil
        }
    }
}

extension TrendsInsightsView {
    private func createWeekGraphData() -> GraphData? {
        let stats = analysisManager.currentWeekStats
        guard !stats.isEmpty else { return nil }
        
        let points = stats.map { stat in
            GraphPoint(
                date: stat.date ?? Date(),
                value: getValue(from: stat),
                label: formatDate(stat.date ?? Date(), for: "week")
            )
        }
        
        let values = points.map { $0.value }
        return GraphData(
            points: points,
            maxY: values.max() ?? 0,
            minY: values.min() ?? 0,
            average: values.reduce(0, +) / Double(values.count),
            metric: selectedMetric
        )
    }
    
    private func createMonthGraphData() -> GraphData? {
        let stats = analysisManager.currentMonthWeeklyStats
        guard !stats.isEmpty else { return nil }
        
        let points = stats.map { stat in
            GraphPoint(
                date: stat.lastUpdated ?? Date(),
                value: getValue(from: stat),
                label: "Week \(stat.weekNumber)"
            )
        }
        
        let values = points.map { $0.value }
        return GraphData(
            points: points,
            maxY: values.max() ?? 0,
            minY: values.min() ?? 0,
            average: values.reduce(0, +) / Double(values.count),
            metric: selectedMetric
        )
    }
    
    private func createYearGraphData() -> GraphData? {
        let stats = analysisManager.currentYearMonthlyStats
        guard !stats.isEmpty else { return nil }
        
        let points = stats.map { stat in
            GraphPoint(
                date: stat.lastUpdated ?? Date(),
                value: getValue(from: stat),
                label: formatDate(stat.lastUpdated ?? Date(), for: "year")
            )
        }
        
        let values = points.map { $0.value }
        return GraphData(
            points: points,
            maxY: values.max() ?? 0,
            minY: values.min() ?? 0,
            average: values.reduce(0, +) / Double(values.count),
            metric: selectedMetric
        )
    }
    
        private func getValue(from stat: DailyStats) -> Double {
            switch selectedMetric {
            case .wpm: return stat.averageWPM
            case .duration: return stat.averageDuration
            case .wordCount: return stat.averageWordCount
            case .uniqueWords: return stat.averageUniqueWordCount
            case .selfReferences: return stat.averageSelfReferences
            case .vocabularyDiversity: return stat.vocabularyDiversityRatio
            }
        }
    
    private func getValue(from stat: WeeklyStats) -> Double {
        switch selectedMetric {
        case .wpm: return stat.averageWPM
        case .duration: return stat.averageDuration
        case .wordCount: return stat.averageWordCount
        case .uniqueWords: return stat.averageUniqueWordCount
        case .selfReferences: return stat.averageSelfReferences
        case .vocabularyDiversity: return stat.vocabularyDiversityRatio
        }
    }
    
    private func getValue(from stat: MonthlyStats) -> Double {
        switch selectedMetric {
        case .wpm: return stat.averageWPM
        case .duration: return stat.averageDuration
        case .wordCount: return stat.averageWordCount
        case .uniqueWords: return stat.averageUniqueWordCount
        case .selfReferences: return stat.averageSelfReferences
        case .vocabularyDiversity: return stat.vocabularyDiversityRatio
        }
    }
    
    private func formatDate(_ date: Date, for period: String) -> String {
        let formatter = DateFormatter()
        switch period {
        case "week":
            formatter.dateFormat = "EEE"
        case "month":
            formatter.dateFormat = "MMM d"
        case "year":
            formatter.dateFormat = "MMM"
        default:
            formatter.dateFormat = "MMM d"
        }
        return formatter.string(from: date)
    }
}

struct TrendsGraphView: View {
    let data: GraphData
    @State private var selectedPoint: GraphPoint?
    @State private var showingPopover = false
    @State private var popoverPosition: CGPoint = .zero
    
    private let accentColor = Color(hex: "A28497")
    private let backgroundColor = Color(hex: "FAFBFC")
    private let surfaceColor = Color(hex: "F8F5F7")
    private let textColor = Color(hex: "2C3E50")
    
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background grid
                VStack(spacing: 0) {
                    ForEach(0..<4) { _ in
                        Divider()
                            .frame(height: 1)
                            .opacity(0.1)
                        Spacer()
                    }
                }
                
                // Graph content
                if data.points.count > 1 {
                    // Area fill beneath line
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: geometry.size.height))
                        
                        for (index, point) in data.points.enumerated() {
                            let x = getX(for: index, width: geometry.size.width)
                            let y = getY(for: point.value, height: geometry.size.height)
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                let control = CGPoint(x: x - (geometry.size.width / CGFloat(data.points.count * 2)),
                                                    y: getY(for: data.points[index - 1].value, height: geometry.size.height))
                                let control2 = CGPoint(x: x, y: y)
                                path.addCurve(to: CGPoint(x: x, y: y),
                                            control1: control,
                                            control2: control2)
                            }
                        }
                        
                        // Complete the path to create area
                        path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                        path.addLine(to: CGPoint(x: 0, y: geometry.size.height))
                    }
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [
                            accentColor.opacity(0.3),
                            accentColor.opacity(0.1),
                            accentColor.opacity(0.05)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    
                    // Main line
                    Path { path in
                        for (index, point) in data.points.enumerated() {
                            let x = getX(for: index, width: geometry.size.width)
                            let y = getY(for: point.value, height: geometry.size.height)
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                let control = CGPoint(x: x - (geometry.size.width / CGFloat(data.points.count * 2)),
                                                    y: getY(for: data.points[index - 1].value, height: geometry.size.height))
                                let control2 = CGPoint(x: x, y: y)
                                path.addCurve(to: CGPoint(x: x, y: y),
                                            control1: control,
                                            control2: control2)
                            }
                        }
                    }
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    
                    // Data points
                    ForEach(Array(data.points.enumerated()), id: \.element.id) { index, point in
                        Circle()
                            .fill(accentColor)
                            .frame(width: 8, height: 8)
                            .background(
                                Circle()
                                    .fill(.white)
                                    .frame(width: 16, height: 16)
                            )
                            .position(
                                x: getX(for: index, width: geometry.size.width),
                                y: getY(for: point.value, height: geometry.size.height)
                            )
                            .gesture(
                                TapGesture()
                                    .onEnded { _ in
                                        selectedPoint = point
                                        popoverPosition = CGPoint(
                                            x: getX(for: index, width: geometry.size.width),
                                            y: getY(for: point.value, height: geometry.size.height)
                                        )
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            showingPopover = true
                                        }
                                    }
                            )
                    }
                }
                
                // X-axis labels
                VStack {
                    Spacer()
                    HStack {
                        ForEach(data.points, id: \.id) { point in
                            Text(point.label)
                                .font(.system(size: 12))
                                .foregroundColor(textColor.opacity(0.6))
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            
            // Value popover
            if showingPopover, let point = selectedPoint {
                VStack(alignment: .leading, spacing: 4) {
                    Text(point.label)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(textColor.opacity(0.6))
                    Text(numberFormatter.string(from: NSNumber(value: point.value)) ?? "")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(textColor)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                .position(x: popoverPosition.x, y: popoverPosition.y - 40)
            }
        }
        .padding(.vertical)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                showingPopover = false
            }
        }
    }
    
    private func getX(for index: Int, width: CGFloat) -> CGFloat {
        let spacing = width / CGFloat(max(1, data.points.count - 1))
        return spacing * CGFloat(index)
    }
    
    private func getY(for value: Double, height: CGFloat) -> CGFloat {
        let range = data.maxY - data.minY
        guard range > 0 else { return height / 2 }
        
        let normalized = (value - data.minY) / range
        return height - (normalized * (height - 40)) - 20 // Padding for top and bottom
    }
}


extension AnalysisManager {
    static var mock: AnalysisManager {
        let manager = AnalysisManager()
        
        // Mock LoopAnalysis
        let mockLoop = LoopAnalysis(
            id: UUID().uuidString,
            timestamp: Date(),
            promptText: "Describe your day",
            category: "Reflection", transcript: "",
            metrics: LoopMetrics(
                duration: 180.0,
                wordCount: 120,
                uniqueWordCount: 80,
                wordsPerMinute: 40.0,
                selfReferenceCount: 10,
                uniqueSelfReferenceCount: 2,
                averageWordLength: 4.5
            ),
            wordAnalysis: WordAnalysis(
                words: ["today", "was", "great", "I", "went", "to", "the", "park"],
                uniqueWords: ["today", "great", "park"],
                mostUsedWords: [
                    WordCount(word: "today", count: 5),
                    WordCount(word: "great", count: 4),
                    WordCount(word: "park", count: 3)
                ],
                selfReferenceTypes: ["I", "myself"]
            )
        )
        
        let mockDailyAnalysis = DailyAnalysis(
            date: Date(),
            loops: [mockLoop, mockLoop, mockLoop],
            aggregateMetrics: AggregateMetrics(
                averageDuration: 180.0,
                averageWordCount: 120.0,
                averageUniqueWordCount: 80.0,
                averageWPM: 40.0,
                averageSelfReferences: 10.0,
                vocabularyDiversityRatio: 0.67
            ),
            wordPatterns: WordPatterns(
                totalUniqueWords: ["today", "great", "park"],
                wordsInAllResponses: ["today", "great"],
                mostUsedWords: [
                    WordCount(word: "today", count: 15),
                    WordCount(word: "great", count: 12)
                ]
            ),
            overlapAnalysis: OverlapAnalysis(
                pairwiseOverlap: ["1-2": 0.75, "1-3": 0.60],
                commonWords: ["1-2": ["today", "great"]],
                overallSimilarity: 0.65
            ),
            rangeAnalysis: RangeAnalysis(
                wpmRange: MinMaxRange(min: 35.0, max: 45.0),
                durationRange: MinMaxRange(min: 160.0, max: 200.0),
                wordCountRange: IntRange(min: 110, max: 130),
                selfReferenceRange: IntRange(min: 8, max: 12)
            ),
            aiAnalysis: AIAnalysisResult(
                feeling: "Contemplative",
                feelingDescription: "Your reflections today show deep introspection and thoughtful consideration of personal experiences",
                tense: "Present",
                tenseDescription: "You're focused on understanding your current state of mind",
                selfReferenceCount: 12,
                followUp: "How do these moments of reflection influence your daily choices?",
                actionReflectionRatio: "30/70",
                actionReflectionDescription: "You spend more time in thought than planning next steps",
                solutionFocus: "40/60",
                solutionFocusDescription: "Your responses explore situations more than seeking solutions"
            )
        )
        
        manager.currentDailyAnalysis = mockDailyAnalysis
        manager.todaysLoops = [mockLoop, mockLoop, mockLoop]
        manager.weeklyComparison = LoopComparison(
            date: Date(),
            pastLoopDate: Date().addingTimeInterval(-7 * 24 * 60 * 60),
            durationComparison: MetricComparison(direction: .increase, percentageChange: 10.0),
            wpmComparison: MetricComparison(direction: .increase, percentageChange: 5.0),
            wordCountComparison: MetricComparison(direction: .decrease, percentageChange: 3.0),
            uniqueWordComparison: MetricComparison(direction: .increase, percentageChange: 8.0),
            vocabularyDiversityComparison: MetricComparison(direction: .increase, percentageChange: 15.0),
            averageWordLengthComparison: MetricComparison(direction: .same, percentageChange: 0.0),
            selfReferenceComparison: MetricComparison(direction: .decrease, percentageChange: 2.0),
            similarityScore: 0.75,
            commonWords: ["today", "great"]
        )
        
        return manager
    }
}

struct InsightWavyBackground: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: 0, y: height * 0.5))
        
        // Create a flowing, wavy path
        path.addCurve(
            to: CGPoint(x: width, y: height * 0.5),
            control1: CGPoint(x: width * 0.3, y: height * 0.35),
            control2: CGPoint(x: width * 0.7, y: height * 0.65)
        )
        
        // Complete the shape
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

// Preview
struct InsightsView_Previews: PreviewProvider {
    static var previews: some View {
        InsightsView(analysisManager: AnalysisManager.mock)
            .previewDevice("iPhone 14 Pro")
            .previewDisplayName("Insights View")
    }
}



struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, frame) in result.frames {
            let position = CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY)
            subviews[index].place(at: position, proposal: ProposedViewSize(frame.size))
        }
    }
    
    struct FlowResult {
        var size: CGSize
        var frames: [Int: CGRect]
        
        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var height: CGFloat = 0
            var maxWidth: CGFloat = 0
            var x: CGFloat = 0
            var y: CGFloat = 0
            var row: CGFloat = 0
            var frames = [Int: CGRect]()
            
            for (index, subview) in subviews.enumerated() {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > width {
                    x = 0
                    y += row + spacing
                    row = 0
                }
                
                frames[index] = CGRect(x: x, y: y, width: size.width, height: size.height)
                row = max(row, size.height)
                x += size.width + spacing
                maxWidth = max(maxWidth, x)
                height = max(height, y + row)
            }
            
            self.size = CGSize(width: maxWidth, height: height)
            self.frames = frames
        }
    }
}
    
