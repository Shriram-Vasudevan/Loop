//
//  TrendGraph.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/28/24.
//

import SwiftUI

struct TrendGraphCard: View {
    @Binding var selectedMetric: TrendsView.MetricType
    @Binding var timeframe: TrendsView.Timeframe
    @ObservedObject var quantTrendsManager = QuantitativeTrendsManager.shared
    
    @State private var selectedPointIndex: Int?
    @State private var showMetricPicker = false
    @State private var animateGraph = false
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 24) {
            headerSection
            
            ZStack {
                if hasEnoughData {
                    graphSection
                } else {
                    EmptyGraphView(timeframe: timeframe)
                }
            }
        }
        .padding(.horizontal, 24)
        .overlay(
            Group {
                if showMetricPicker {
                    VStack {
                        metricsDropdown
                        Spacer()
                    }
                    .padding(.top, 75)
                    .padding(.horizontal, 24)
                    .background(
                        Color.black.opacity(0.001)
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    showMetricPicker = false
                                }
                            }
                    )
                }
            }
        )
        .onChange(of: selectedMetric) { _ in
            animateGraph = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    animateGraph = true
                }
            }
        }
        .onAppear {
            animateGraph = true
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.spring()) {
                    showMetricPicker.toggle()
                }
            }) {
                HStack {
                    Text(selectedMetric.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(textColor)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(accentColor)
                        .rotationEffect(.degrees(showMetricPicker ? 180 : 0))
                }
            }
            
            if let (min, max) = getValueRange() {
                Text("\(formatValue(min, for: selectedMetric)) – \(formatValue(max, for: selectedMetric))")
                    .font(.system(size: 12))
                    .foregroundColor(textColor.opacity(0.5))
            }
        }
    }
    
    private var metricsDropdown: some View {
        VStack(spacing: 0) {
            ForEach(TrendsView.MetricType.allCases, id: \.self) { metric in
                MetricOption(
                    metric: metric,
                    isSelected: selectedMetric == metric
                ) {
                    withAnimation {
                        selectedMetric = metric
                        showMetricPicker = false
                    }
                }
                
                if metric != TrendsView.MetricType.allCases.last {
                    Divider()
                        .padding(.horizontal, 8)
                }
            }
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
        .transition(.scale.combined(with: .opacity))
    }
    
    private var graphSection: some View {
        GraphView(
            data: getData(),
            labels: getLabels(),
            selectedPointIndex: $selectedPointIndex,
            animate: animateGraph,
            metricType: selectedMetric
        )
        .frame(height: 200)
    }
    
    private var hasEnoughData: Bool {
        switch timeframe {
        case .week:
            return true
        case .month:
            return (quantTrendsManager.monthlyStats?.count ?? 0) >= 5
        case .year:
            return (quantTrendsManager.yearlyStats?.count ?? 0) >= 40
        }
    }
    
    private func getData() -> [Double] {
        switch (timeframe, selectedMetric) {
        case (.week, .wpm):
            return quantTrendsManager.weeklyStats?.map { $0.averageWPM } ?? []
        case (.week, .duration):
            return quantTrendsManager.weeklyStats?.map { $0.averageDuration } ?? []
        case (.week, .wordCount):
            return quantTrendsManager.weeklyStats?.map { $0.averageWordCount } ?? []
        case (.week, .vocabulary):
            return quantTrendsManager.weeklyStats?.map { $0.vocabularyDiversityRatio } ?? []
        case (.month, .wpm):
            return quantTrendsManager.monthlyStats?.map { $0.averageWPM } ?? []
        case (.month, .duration):
            return quantTrendsManager.monthlyStats?.map { $0.averageDuration } ?? []
        case (.month, .wordCount):
            return quantTrendsManager.monthlyStats?.map { $0.averageWordCount } ?? []
        case (.month, .vocabulary):
            return quantTrendsManager.monthlyStats?.map { $0.vocabularyDiversityRatio } ?? []
        case (.year, .wpm):
            return quantTrendsManager.yearlyStats?.map { $0.averageWPM } ?? []
        case (.year, .duration):
            return quantTrendsManager.yearlyStats?.map { $0.averageDuration } ?? []
        case (.year, .wordCount):
            return quantTrendsManager.yearlyStats?.map { $0.averageWordCount } ?? []
        case (.year, .vocabulary):
            return quantTrendsManager.yearlyStats?.map { $0.vocabularyDiversityRatio } ?? []
        }
    }
    
    private func getLabels() -> [String] {
        switch timeframe {
        case .week:
            return ["S", "M", "T", "W", "T", "F", "S"]
        case .month:
            return ["W1", "W2", "W3", "W4"]
        case .year:
            return ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]
        }
    }
    
    private func getValueRange() -> (min: Double, max: Double)? {
        let values = getData().filter({ !$0.isNaN && $0 != 0 })
        guard !values.isEmpty else { return nil }
        return (values.min() ?? 0, values.max() ?? 0)
    }
    
    private func formatValue(_ value: Double, for metric: TrendsView.MetricType) -> String {
        switch metric {
        case .wpm: return String(format: "%.0f wpm", value)
        case .duration: return String(format: "%.0f sec", value)
        case .wordCount: return String(format: "%.0f words", value)
        case .vocabulary: return String(format: "%.2f", value)
        }
    }
}

struct GraphView: View {
    let data: [Double]
    let labels: [String]
    @Binding var selectedPointIndex: Int?
    let animate: Bool
    let metricType: TrendsView.MetricType
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                areaPath(in: geometry)
                    .fill(
                        LinearGradient(
                            colors: [
                                accentColor.opacity(0.12),
                                accentColor.opacity(0.04),
                                accentColor.opacity(0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .opacity(animate ? 1 : 0)
                
                linePath(in: geometry)
                    .trim(from: 0, to: animate ? 1 : 0)
                    .stroke(accentColor, lineWidth: 2)
                    .animation(.easeInOut(duration: 1), value: animate)
                
                ForEach(Array(calculatePoints(in: geometry).enumerated()), id: \.offset) { index, point in
                    Circle()
                        .fill(.white)
                        .frame(width: selectedPointIndex == index ? 12 : 8)
                        .overlay(
                            Circle()
                                .stroke(accentColor, lineWidth: 2)
                        )
                        .position(point)
                        .opacity(animate ? 1 : 0)
                        .animation(.easeInOut(duration: 0.3).delay(Double(index) * 0.05), value: animate)
                        .overlay(
                            Group {
                                if selectedPointIndex == index {
                                    valuePopup(for: data[index])
                                        .offset(y: -25)
                                }
                            }
                        )
                }
                
                HStack(spacing: 0) {
                    ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                        Text(label)
                            .font(.system(size: 12))
                            .foregroundColor(textColor.opacity(0.5))
                            .frame(width: geometry.size.width / CGFloat(labels.count))
                    }
                }
                .offset(y: 20)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        updateSelection(for: value.location, in: geometry)
                    }
                    .onEnded { _ in
                        selectedPointIndex = nil
                    }
            )
        }
    }
    
    private func valuePopup(for value: Double) -> some View {
        let formattedValue: String
        switch metricType {
        case .wpm:
            formattedValue = "\(Int(value)) wpm"
        case .duration:
            formattedValue = String(format: "%.1fs", value)
        case .wordCount:
            formattedValue = "\(Int(value))"
        case .vocabulary:
            formattedValue = String(format: "%.2f", value)
        }
        
        return Text(formattedValue)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(accentColor)
            )
    }
    
    private func calculatePoints(in geometry: GeometryProxy) -> [CGPoint] {
        guard let max = data.max(), let min = data.min(), !data.isEmpty else { return [] }
        let range = max - min
        let availableHeight = geometry.size.height - 40
        let width = geometry.size.width
        let xStep = width / CGFloat(data.count - 1)
        
        return data.enumerated().map { index, value in
            let x = CGFloat(index) * xStep
            let normalizedY = range != 0 ? (value - min) / range : 0
            let y = availableHeight - (normalizedY * availableHeight * 0.8)
            return CGPoint(x: x, y: y)
        }
    }
    
    private func linePath(in geometry: GeometryProxy) -> Path {
        Path { path in
            let points = calculatePoints(in: geometry)
            guard !points.isEmpty else { return }
            
            path.move(to: points[0])
            for i in 1..<points.count {
                let control1 = CGPoint(
                    x: points[i-1].x + (points[i].x - points[i-1].x) * 0.5,
                    y: points[i-1].y
                )
                let control2 = CGPoint(
                    x: points[i-1].x + (points[i].x - points[i-1].x) * 0.5,
                    y: points[i].y
                )
                path.addCurve(
                    to: points[i],
                    control1: control1,
                    control2: control2
                )
            }
        }
    }
    
    private func areaPath(in geometry: GeometryProxy) -> Path {
        Path { path in
            let points = calculatePoints(in: geometry)
            guard !points.isEmpty else { return }
            
            path.move(to: CGPoint(x: points[0].x, y: geometry.size.height))
            path.addLine(to: points[0])
            
            for i in 1..<points.count {
                let control1 = CGPoint(
                    x: points[i-1].x + (points[i].x - points[i-1].x) * 0.5,
                    y: points[i-1].y
                )
                let control2 = CGPoint(
                    x: points[i-1].x + (points[i].x - points[i-1].x) * 0.5,
                    y: points[i].y
                )
                path.addCurve(
                    to: points[i],
                    control1: control1,
                    control2: control2
                )
            }
            
            path.addLine(to: CGPoint(x: points[points.count-1].x, y: geometry.size.height))
            path.closeSubpath()
        }
    }
    
    private func updateSelection(for location: CGPoint, in geometry: GeometryProxy) {
        let xStep = geometry.size.width / CGFloat(data.count)
        let index = Int(location.x / xStep)
        if index >= 0 && index < data.count {
            selectedPointIndex = index
        }
    }
}

struct EmptyGraphView: View {
    let timeframe: TrendsView.Timeframe
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 12) {
            SineWave()
                .stroke(accentColor.opacity(0.1), lineWidth: 2)
                .frame(height: 100)
                .offset(x: animate ? 20 : -20)
                .animation(
                    Animation.easeInOut(duration: 2)
                        .repeatForever(autoreverses: true),
                    value: animate
                )
            
            VStack(spacing: 8) {
                Text("Gathering insights")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(textColor)
                
                Text(getRequirementText())
                    .font(.system(size: 14))
                    .foregroundColor(textColor.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(height: 200)
        .onAppear {
                    animate = true
                }
            }
            
            private func getRequirementText() -> String {
                switch timeframe {
                case .week:
                    return "Start reflecting to see your data"
                case .month:
                    return "Complete 5 days of reflection to see monthly trends"
                case .year:
                    return "Complete 40 days of reflection to see yearly patterns"
                }
            }
        }

        struct SineWave: Shape {
            func path(in rect: CGRect) -> Path {
                var path = Path()
                let width = rect.width
                let height = rect.height
                let midHeight = height / 2
                let amplitude = height / 4
                
                path.move(to: CGPoint(x: 0, y: midHeight))
                
                var x: CGFloat = 0
                while x <= width {
                    let relativeX = x / width
                    let y = midHeight + sin(relativeX * .pi * 2) * amplitude
                    if x == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    x += 1
                }
                
                return path
            }
        }

        struct MetricOption: View {
            let metric: TrendsView.MetricType
            let isSelected: Bool
            let action: () -> Void
            
            private let accentColor = Color(hex: "A28497")
            private let textColor = Color(hex: "2C3E50")
            
            var body: some View {
                Button(action: action) {
                    HStack {
                        Text(metric.title)
                            .font(.system(size: 14))
                            .foregroundColor(isSelected ? accentColor : textColor)
                        
                        Spacer()
                        
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(accentColor)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .contentShape(Rectangle())
                }
            }
        }

        extension TrendsView.MetricType {
            var title: String {
                switch self {
                case .wpm: return "Speaking Pace"
                case .duration: return "Duration"
                case .wordCount: return "Word Count"
                case .vocabulary: return "Vocabulary"
                }
            }
        }

        #if DEBUG
        struct TrendGraphCard_Previews: PreviewProvider {
            static var previews: some View {
                Group {
                    TrendGraphCard(
                        selectedMetric: .constant(.wpm),
                        timeframe: .constant(.week),
                        quantTrendsManager: .preview
                    )
                    .padding()
                    .previewDisplayName("With Data")
                    
                    TrendGraphCard(
                        selectedMetric: .constant(.wpm),
                        timeframe: .constant(.month),
                        quantTrendsManager: .emptyPreview
                    )
                    .padding()
                    .previewDisplayName("No Data")
                    
                    TrendGraphCard(
                        selectedMetric: .constant(.wpm),
                        timeframe: .constant(.week),
                        quantTrendsManager: .preview
                    )
                    .padding()
                    .previewDisplayName("Dropdown Open")
                }
            }
        }

        extension QuantitativeTrendsManager {
            static var preview: QuantitativeTrendsManager {
                let manager = QuantitativeTrendsManager()
                
                // Weekly Stats
                manager.weeklyStats = [
                    DailyStats(date: Date(), year: 2024, month: 12, weekOfYear: 52, weekday: 1,
                              averageWPM: 120, averageDuration: 45, averageWordCount: 200,
                              averageUniqueWordCount: 150, vocabularyDiversityRatio: 0.75,
                              loopCount: 3, lastUpdated: Date()),
                    DailyStats(date: Date().addingTimeInterval(-86400), year: 2024, month: 12,
                              weekOfYear: 52, weekday: 2, averageWPM: 115, averageDuration: 42,
                              averageWordCount: 190, averageUniqueWordCount: 140,
                              vocabularyDiversityRatio: 0.73, loopCount: 3, lastUpdated: Date()),
                    DailyStats(date: Date().addingTimeInterval(-172800), year: 2024, month: 12,
                              weekOfYear: 52, weekday: 3, averageWPM: 125, averageDuration: 48,
                              averageWordCount: 210, averageUniqueWordCount: 160,
                              vocabularyDiversityRatio: 0.76, loopCount: 3, lastUpdated: Date())
                ]
                
                // Monthly Stats
                manager.monthlyStats = [
                    WeeklyStats(dataPointCount: 7, averageWPM: 118, averageDuration: 44,
                               averageWordCount: 195, averageUniqueWordCount: 145,
                               vocabularyDiversityRatio: 0.74, lastUpdated: Date(),
                               weekNumber: 1, year: 2024),
                    WeeklyStats(dataPointCount: 7, averageWPM: 122, averageDuration: 46,
                               averageWordCount: 200, averageUniqueWordCount: 148,
                               vocabularyDiversityRatio: 0.76, lastUpdated: Date(),
                               weekNumber: 2, year: 2024)
                ]
                
                return manager
            }
            
            static var emptyPreview: QuantitativeTrendsManager {
                let manager = QuantitativeTrendsManager()
                manager.weeklyStats = []
                manager.monthlyStats = []
                manager.yearlyStats = []
                return manager
            }
        }
#endif
