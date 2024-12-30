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
    @ObservedObject var quantTrendsManager: QuantitativeTrendsManager
    
    @State private var selectedPointIndex: Int?
    @State private var animateGraph = false
    @State private var showTooltip = false
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 24) {
            // Value Range
            if let (min, max) = getValueRange() {
                HStack {
                    Text(formatValue(min, for: selectedMetric))
                        .font(.system(size: 15))
                        .foregroundColor(textColor.opacity(0.6))
                    
                    Spacer()
                    
                    Text(formatValue(max, for: selectedMetric))
                        .font(.system(size: 15))
                        .foregroundColor(textColor.opacity(0.6))
                }
            }
            
            // Graph Section
            ZStack {
                if hasEnoughData {
                    graphSection
                } else {
                    InsufficientDataView(
                        timeframe: timeframe,
                        accentColor: accentColor,
                        textColor: textColor
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
        .onChange(of: selectedMetric) { _ in
            resetAnimation()
        }
        .onAppear {
            animateGraph = true
        }
    }
    
    private var graphSection: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Background Grid
                gridLines(in: geometry)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                
                // Area Fill
                areaPath(in: geometry)
                    .fill(
                        LinearGradient(
                            colors: [
                                accentColor.opacity(0.2),
                                accentColor.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .opacity(animateGraph ? 1 : 0)
                
                // Line
                linePath(in: geometry)
                    .trim(from: 0, to: animateGraph ? 1 : 0)
                    .stroke(
                        accentColor,
                        style: StrokeStyle(
                            lineWidth: 2.5,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .animation(.easeInOut(duration: 1.2), value: animateGraph)
                
                // Data Points
                ForEach(Array(calculatePoints(in: geometry).enumerated()), id: \.offset) { index, point in
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: selectedPointIndex == index ? 16 : 12)
                            .shadow(color: accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
                        
                        Circle()
                            .fill(accentColor)
                            .frame(width: selectedPointIndex == index ? 8 : 6)
                    }
                    .position(point)
                    .opacity(animateGraph ? 1 : 0)
                    .animation(
                        .spring(response: 0.3, dampingFraction: 0.7)
                        .delay(Double(index) * 0.05),
                        value: selectedPointIndex == index
                    )
                    .overlay(
                        Group {
                            if selectedPointIndex == index {
                                tooltipView(for: getData()[index])
                                    .offset(y: -40)
                            }
                        }
                    )
                }
                
                // X-Axis Labels
                HStack(spacing: 0) {
                    ForEach(Array(getLabels().enumerated()), id: \.offset) { index, label in
                        Text(label)
                            .font(.system(size: 13))
                            .foregroundColor(textColor.opacity(0.6))
                            .frame(width: geometry.size.width / CGFloat(getLabels().count))
                    }
                }
                .offset(y: 24)
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
        .frame(height: 200)
    }
    
    private func tooltipView(for value: Double) -> some View {
        Text(formatValue(value, for: selectedMetric))
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(accentColor)
                    .shadow(color: accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
            )
    }
    
    private func gridLines(in geometry: GeometryProxy) -> Path {
        Path { path in
            let width = geometry.size.width
            let height = geometry.size.height - 40 // Account for x-axis labels
            let horizontalSpacing = height / 4
            
            // Horizontal lines
            for i in 0...4 {
                let y = height - (CGFloat(i) * horizontalSpacing)
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: width, y: y))
            }
        }
    }
    
    private func calculatePoints(in geometry: GeometryProxy) -> [CGPoint] {
        let data = getData()
        guard let max = data.max(), let min = data.min(), !data.isEmpty else { return [] }
        
        let range = max - min
        let availableHeight = geometry.size.height - 40 // Account for x-axis labels
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
            
            path.move(to: CGPoint(x: points[0].x, y: geometry.size.height - 40))
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
            
            path.addLine(to: CGPoint(x: points[points.count-1].x, y: geometry.size.height - 40))
            path.closeSubpath()
        }
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
        case .wpm:
            return "\(Int(value)) wpm"
        case .duration:
            return String(format: "%.1fs", value)
        case .wordCount:
            return "\(Int(value))"
        case .vocabulary:
            return String(format: "%.2f", value)
        }
    }
    
    private func updateSelection(for location: CGPoint, in geometry: GeometryProxy) {
        let xStep = geometry.size.width / CGFloat(getData().count - 1)
        let index = Int(location.x / xStep)
        if index >= 0 && index < getData().count {
            selectedPointIndex = index
        }
    }
    
    private func resetAnimation() {
        animateGraph = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.8)) {
                animateGraph = true
            }
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
