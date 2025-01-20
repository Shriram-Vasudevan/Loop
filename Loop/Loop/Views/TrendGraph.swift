////
////  TrendGraph.swift
////  Loop
////
////  Created by Shriram Vasudevan on 12/28/24.
////
//
//import SwiftUI
//
//
////struct TrendGraphCard: View {
////    @Binding var selectedMetric: MetricType
////    @Binding var timeframe: Timeframe
////    @ObservedObject var quantTrendsManager = QuantitativeTrendsManager.shared
////    
////    @State private var selectedPointIndex: Int?
////    @State private var showMetricPicker = false
////    @State private var animateGraph = false
////    @State private var dropdownOffset: CGFloat = -50
////    @State private var dropdownOpacity: Double = 0
////    
////    private let accentColor = Color(hex: "A28497")
////    private let textColor = Color(hex: "2C3E50")
////    
////
////    
////    var body: some View {
////        VStack(alignment: .leading, spacing: 32) {
////            headerSection
////            
////            if hasEnoughData {
////                VStack(alignment: .leading, spacing: 24) {
////                    if let (min, max) = getValueRange() {
////                        HStack(spacing: 24) {
////                            statisticView(title: "min", value: formatValue(min, for: selectedMetric))
////                            statisticView(title: "max", value: formatValue(max, for: selectedMetric))
////                        }
////                    }
////                    
////                    graphSection
////                }
////            } else {
////                noDataView
////            }
////        }
////        .padding(24)
////        .overlay(
////            Group {
////                if showMetricPicker {
////                    Color.black.opacity(0.001)
////                        .onTapGesture {
////                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
////                                showMetricPicker = false
////                                dropdownOffset = -50
////                                dropdownOpacity = 0
////                            }
////                        }
////                        .overlay(
////                            metricPickerOverlay
////                        )
////                }
////            }
////        )
////        .onChange(of: selectedMetric) { _ in
////            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
////                animateGraph = false
////            }
////            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
////                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
////                    animateGraph = true
////                }
////            }
////        }
////        .onAppear {
////            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
////                animateGraph = true
////            }
////        }
////    }
////    
////    private var headerSection: some View {
////        Button(action: {
////            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
////                showMetricPicker.toggle()
////                dropdownOffset = showMetricPicker ? 0 : -50
////                dropdownOpacity = showMetricPicker ? 1 : 0
////            }
////        }) {
////            HStack(spacing: 12) {
////                Text(selectedMetric.title)
////                    .font(.custom("PPNeueMontreal-Medium", size: 28))
////                    .foregroundColor(textColor)
////                
////                Image(systemName: "chevron.down")
////                    .font(.system(size: 14, weight: .semibold))
////                    .foregroundColor(accentColor)
////                    .rotationEffect(.degrees(showMetricPicker ? 180 : 0))
////            }
////        }
////    }
////    
////    private var graphSection: some View {
////        let dataCount = getData().count
////        
////        return VStack(alignment: .leading, spacing: 32) {
////            ZStack {
////                if dataCount < 2 {
////                    // Placeholder graph with example data increasing from Sunday to Saturday
////                    GraphView(
////                        data: [118, 123, 115, 120, 117, 125, 118],
////                        labels: getLabels(),
////                        selectedPointIndex: $selectedPointIndex,  // We don't want interaction with placeholder
////                        animate: animateGraph,
////                        metricType: selectedMetric
////                    )
////                    .blur(radius: 3)
////                    .opacity(0.3)
////                    
////                    Text("LOOP FOR 2 DAYS THIS WEEK TO GET TRENDS")
////                        .multilineTextAlignment(.center)
////                        .font(.system(size: 13, weight: .medium))
////                        .tracking(1.5)
////                        .foregroundColor(textColor.opacity(0.5))
////                } else {
////                    GraphView(
////                        data: getData(),
////                        labels: getLabels(),
////                        selectedPointIndex: $selectedPointIndex,
////                        animate: animateGraph,
////                        metricType: selectedMetric
////                    )
////                }
////            }
////            .frame(height: 180)
////            
////            HStack(spacing: 0) {
////                ForEach(getLabels(), id: \.self) { label in
////                    Text(label)
////                        .font(.system(size: 12, weight: .medium))
////                        .foregroundColor(textColor.opacity(0.6))
////                        .frame(maxWidth: .infinity)
////                }
////            }
////        }
////    }
////    
////    private var metricPickerOverlay: some View {
////        VStack {
////            VStack(spacing: 0) {
////                ForEach(TrendsView.MetricType.allCases, id: \.self) { metric in
////                    MetricOption(
////                        metric: metric,
////                        isSelected: selectedMetric == metric
////                    ) {
////                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
////                            selectedMetric = metric
////                            showMetricPicker = false
////                            dropdownOffset = -50
////                            dropdownOpacity = 0
////                        }
////                    }
////                    
////                    if metric != TrendsView.MetricType.allCases.last {
////                        Divider()
////                    }
////                }
////            }
////            .padding(.vertical, 8)
////            .background(Color.white)
////            .cornerRadius(16)
////            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 4)
////            .offset(y: dropdownOffset)
////            .opacity(dropdownOpacity)
////            
////            Spacer()
////        }
////        .padding(.top, 70)
////        .padding(.horizontal, 24)
////    }
////    
//
////    
////    private func statisticView(title: String, value: String) -> some View {
////        VStack(alignment: .leading, spacing: 4) {
////            Text(title)
////                .font(.system(size: 12, weight: .medium))
////                .foregroundColor(textColor.opacity(0.6))
////                .textCase(.uppercase)
////            
////            Text(value)
////                .font(.system(size: 17, weight: .medium))
////                .foregroundColor(textColor)
////        }
////    }
////    
////    private var hasEnoughData: Bool {
////        switch timeframe {
////        case .week: return true
////        case .month: return (quantTrendsManager.monthlyStats?.count ?? 0) >= 5
////        case .year: return (quantTrendsManager.yearlyStats?.count ?? 0) >= 40
////        }
////    }
////    
////    private var noDataMessage: String {
////        switch timeframe {
////        case .week: return "Share your first reflection\nto see insights"
////        case .month: return "Complete 5 days of daily reflection\nto unlock monthly insights"
////        case .year: return "Complete 40 days of daily reflection\nto see yearly patterns"
////        }
////    }
////    
////    private func getData() -> [Double] {
////        switch (timeframe, selectedMetric) {
////        case (.week, .wpm):
////            return quantTrendsManager.weeklyStats?.map { $0.averageWPM } ?? []
////        case (.week, .duration):
////            return quantTrendsManager.weeklyStats?.map { $0.averageDuration } ?? []
////        case (.week, .wordCount):
////            return quantTrendsManager.weeklyStats?.map { $0.averageWordCount } ?? []
////        case (.week, .vocabulary):
////            return quantTrendsManager.weeklyStats?.map { $0.vocabularyDiversityRatio } ?? []
////        case (.month, .wpm):
////            return quantTrendsManager.monthlyStats?.map { $0.averageWPM } ?? []
////        case (.month, .duration):
////            return quantTrendsManager.monthlyStats?.map { $0.averageDuration } ?? []
////        case (.month, .wordCount):
////            return quantTrendsManager.monthlyStats?.map { $0.averageWordCount } ?? []
////        case (.month, .vocabulary):
////            return quantTrendsManager.monthlyStats?.map { $0.vocabularyDiversityRatio } ?? []
////        case (.year, .wpm):
////            return quantTrendsManager.yearlyStats?.map { $0.averageWPM } ?? []
////        case (.year, .duration):
////            return quantTrendsManager.yearlyStats?.map { $0.averageDuration } ?? []
////        case (.year, .wordCount):
////            return quantTrendsManager.yearlyStats?.map { $0.averageWordCount } ?? []
////        case (.year, .vocabulary):
////            return quantTrendsManager.yearlyStats?.map { $0.vocabularyDiversityRatio } ?? []
////        }
////    }
////    
////    private func getLabels() -> [String] {
////        switch timeframe {
////        case .week: return ["S", "M", "T", "W", "T", "F", "S"]
////        case .month: return ["W1", "W2", "W3", "W4"]
////        case .year: return ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]
////        }
////    }
////    
////    private func getValueRange() -> (min: Double, max: Double)? {
////        let values = getData().filter({ !$0.isNaN && $0 != 0 })
////        guard !values.isEmpty else { return nil }
////        return (values.min() ?? 0, values.max() ?? 0)
////    }
////    
////    private func formatValue(_ value: Double, for metric: TrendsView.MetricType) -> String {
////        switch metric {
////        case .wpm: return String(format: "%.0f wpm", value)
////        case .duration: return String(format: "%.0f sec", value)
////        case .wordCount: return String(format: "%.0f words", value)
////        case .vocabulary: return String(format: "%.2f", value)
////        }
////    }
////}
////
////struct GraphView: View {
////    let data: [Double]
////    let labels: [String]
////    @Binding var selectedPointIndex: Int?
////    let animate: Bool
////    let metricType: TrendsView.MetricType
////    
////    private let accentColor = Color(hex: "A28497")
////    private let textColor = Color(hex: "2C3E50")
////    
////    var body: some View {
////        GeometryReader { geometry in
////            ZStack(alignment: .bottom) {
////                areaPath(in: geometry)
////                    .fill(LinearGradient(
////                        colors: [
////                            accentColor.opacity(0.12),
////                            accentColor.opacity(0.05),
////                            accentColor.opacity(0)
////                        ],
////                        startPoint: .top,
////                        endPoint: .bottom
////                    ))
////                    .opacity(animate ? 1 : 0)
////                
////                linePath(in: geometry)
////                    .trim(from: 0, to: animate ? 1 : 0)
////                    .stroke(accentColor, lineWidth: 10)
////                    .animation(.easeInOut(duration: 1.2), value: animate)
////                
////                ForEach(Array(calculatePoints(in: geometry).enumerated()), id: \.offset) { index, point in
////                    Circle()
////                        .fill(.white)
////                        .frame(width: selectedPointIndex == index ? 14 : 10)
////                        .overlay(
////                            Circle()
////                                .stroke(accentColor, lineWidth: 3)
////                        )
////                        .position(point)
////                        .opacity(animate ? 1 : 0)
////                        .animation(
////                            .spring(response: 0.5, dampingFraction: 0.8)
////                            .delay(Double(index) * 0.05),
////                            value: animate
////                        )
////                        .overlay(
////                            Group {
////                                if selectedPointIndex == index {
////                                    valuePopup(for: data[index])
////                                        .offset(y: -35)
////                                }
////                            }
////                        )
////                }
////            }
////            .contentShape(Rectangle())
////            .gesture(
////                DragGesture(minimumDistance: 0)
////                    .onChanged { value in
////                        updateSelection(for: value.location, in: geometry)
////                    }
////                    .onEnded { _ in
////                        withAnimation(.easeOut(duration: 0.2)) {
////                            selectedPointIndex = nil
////                        }
////                    }
////            )
////        }
////    }
////    
////    private func valuePopup(for value: Double) -> some View {
////        let formattedValue: String
////        switch metricType {
////        case .wpm:
////            formattedValue = "\(Int(value)) wpm"
////        case .duration:
////            formattedValue = String(format: "%.1fs", value)
////        case .wordCount:
////            formattedValue = "\(Int(value))"
////        case .vocabulary:
////            formattedValue = String(format: "%.2f", value)
////        }
////        
////        return Text(formattedValue)
////            .font(.system(size: 14, weight: .medium))
////            .foregroundColor(.white)
////            .padding(.horizontal, 12)
////            .padding(.vertical, 8)
////            .background(accentColor)
////            .cornerRadius(8)
////    }
////    
////    private func calculatePoints(in geometry: GeometryProxy) -> [CGPoint] {
////        guard let max = data.max(), let min = data.min(), !data.isEmpty else { return [] }
////        let range = max - min
////        let availableHeight = geometry.size.height - 40
////        let width = geometry.size.width
////        let xStep = width / CGFloat(data.count - 1)
////        
////        return data.enumerated().map { index, value in
////            let x = CGFloat(index) * xStep
////            let normalizedY = range != 0 ? (value - min) / range : 0
////            let y = availableHeight - (normalizedY * availableHeight * 0.8)
////            return CGPoint(x: x, y: y)
////        }
////    }
////    
////    private func linePath(in geometry: GeometryProxy) -> Path {
////        Path { path in
////            let points = calculatePoints(in: geometry)
////            guard !points.isEmpty else { return }
////            
////            path.move(to: points[0])
////            for i in 1..<points.count {
////                let control1 = CGPoint(
////                    x: points[i-1].x + (points[i].x - points[i-1].x) * 0.5,
////                    y: points[i-1].y
////                )
////                let control2 = CGPoint(
////                    x: points[i-1].x + (points[i].x - points[i-1].x) * 0.5,
////                    y: points[i].y
////                )
////                path.addCurve(
////                    to: points[i],
////                    control1: control1,
////                    control2: control2
////                )
////            }
////        }
////    }
////    
////    private func areaPath(in geometry: GeometryProxy) -> Path {
////        Path { path in
////            let points = calculatePoints(in: geometry)
////            guard !points.isEmpty else { return }
////            
////            path.move(to: CGPoint(x: points[0].x, y: geometry.size.height))
////            path.addLine(to: points[0])
////            
////            for i in 1..<points.count {
////                let control1 = CGPoint(
////                    x: points[i-1].x + (points[i].x - points[i-1].x) * 0.5,
////                    y: points[i-1].y
////                )
////                let control2 = CGPoint(
////                    x: points[i-1].x + (points[i].x - points[i-1].x) * 0.5,
////                    y: points[i].y
////                )
////                path.addCurve(
////                    to: points[i],
////                    control1: control1,
////                    control2: control2
////                )
////            }
////            
////            path.addLine(to: CGPoint(x: points[points.count-1].x, y: geometry.size.height))
////            path.closeSubpath()
////        }
////    }
////
////    
////    private func updateSelection(for location: CGPoint, in geometry: GeometryProxy) {
////        let xStep = geometry.size.width / CGFloat(data.count)
////                let index = Int(location.x / xStep)
////                if index >= 0 && index < data.count {
////                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
////                        selectedPointIndex = index
////                    }
////                }
////            }
////        }
////
////struct MetricOption: View {
////    let metric: TrendsView.MetricType
////    let isSelected: Bool
////    let action: () -> Void
////    
////    private let accentColor = Color(hex: "A28497")
////    private let textColor = Color(hex: "2C3E50")
////    
////    var body: some View {
////        Button(action: action) {
////            HStack {
////                VStack(alignment: .leading, spacing: 6) {
////                    Text(metric.title)
////                        .font(.system(size: 16, weight: .medium))
////                        .foregroundColor(isSelected ? accentColor : textColor)
////                    
////                    Text(metric.description)
////                        .font(.system(size: 13))
////                        .foregroundColor(textColor.opacity(0.6))
////                        .lineLimit(1)
////                }
////                
////                Spacer()
////                
////                if isSelected {
////                    Image(systemName: "checkmark")
////                        .font(.system(size: 12, weight: .semibold))
////                        .foregroundColor(accentColor)
////                }
////            }
////            .padding(.vertical, 16)
////            .padding(.horizontal, 20)
////        }
////    }
////}
////
////extension TrendsView.MetricType {
////    var title: String {
////        switch self {
////        case .wpm: return "Speaking Pace"
////        case .duration: return "Duration"
////        case .wordCount: return "Word Count"
////        case .vocabulary: return "Vocabulary"
////        }
////    }
////    
//////            var description: String {
//////                switch self {
//////                case .wpm:
//////                    return "Track how quickly you express your thoughts"
//////                case .duration:
//////                    return "Monitor the length of your reflections"
//////                case .wordCount:
//////                    return "See how detailed your reflections are"
//////                case .vocabulary:
//////                    return "Measure the diversity of your language"
//////                }
//////            }
////}
////

////
////#if DEBUG
////struct TrendGraphCard_Previews: PreviewProvider {
////    static var previews: some View {
////        Group {
////            TrendGraphCard(
////                selectedMetric: .constant(.wpm),
////                timeframe: .constant(.week),
////                quantTrendsManager: .preview
////            )
////            .padding()
////            .previewDisplayName("With Data")
////            
////            TrendGraphCard(
////                selectedMetric: .constant(.wpm),
////                timeframe: .constant(.month),
////                quantTrendsManager: .emptyPreview
////            )
////            .padding()
////            .previewDisplayName("No Data")
////            
////            TrendGraphCard(
////                selectedMetric: .constant(.wpm),
////                timeframe: .constant(.week),
////                quantTrendsManager: .preview
////            )
////            .padding()
////            .previewDisplayName("Dropdown Open")
////        }
////    }
////}
//
//extension QuantitativeTrendsManager {
//    static var preview: QuantitativeTrendsManager {
//        let manager = QuantitativeTrendsManager()
//        
//        // Weekly Stats
//        manager.weeklyStats = [
////            DailyStats(date: Date(), year: 2024, month: 12, weekOfYear: 52, weekday: 1,
////                      averageWPM: 120, averageDuration: 45, averageWordCount: 200,
////                      averageUniqueWordCount: 150, vocabularyDiversityRatio: 0.75,
////                      loopCount: 3, lastUpdated: Date()),
////            DailyStats(date: Date().addingTimeInterval(-86400), year: 2024, month: 12,
////                      weekOfYear: 52, weekday: 2, averageWPM: 115, averageDuration: 42,
////                      averageWordCount: 190, averageUniqueWordCount: 140,
////                      vocabularyDiversityRatio: 0.73, loopCount: 3, lastUpdated: Date()),
//            DailyStats(date: Date().addingTimeInterval(-172800), year: 2024, month: 12,
//                      weekOfYear: 52, weekday: 3, averageWPM: 125, averageDuration: 48,
//                      averageWordCount: 210, averageUniqueWordCount: 160,
//                      vocabularyDiversityRatio: 0.76, loopCount: 3, lastUpdated: Date())
//        ]
//        
//        // Monthly Stats
//        manager.monthlyStats = [
//            WeeklyStats(dataPointCount: 7, averageWPM: 118, averageDuration: 44,
//                       averageWordCount: 195, averageUniqueWordCount: 145,
//                       vocabularyDiversityRatio: 0.74, lastUpdated: Date(),
//                       weekNumber: 1, year: 2024),
//            WeeklyStats(dataPointCount: 7, averageWPM: 122, averageDuration: 46,
//                       averageWordCount: 200, averageUniqueWordCount: 148,
//                       vocabularyDiversityRatio: 0.76, lastUpdated: Date(),
//                       weekNumber: 2, year: 2024)
//        ]
//        
//        return manager
//    }
//    
//    static var emptyPreview: QuantitativeTrendsManager {
//        let manager = QuantitativeTrendsManager()
//        manager.weeklyStats = []
//        manager.monthlyStats = []
//        manager.yearlyStats = []
//        return manager
//    }
//}
////#endif
