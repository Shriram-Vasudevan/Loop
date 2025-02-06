//
//  TopicMoodGraph.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/23/25.
//

import SwiftUI

enum TrendType: String, CaseIterable {
    case topics = "Topics"
    case mood = "Mood"
    case sleep = "Sleep"
}

struct TrendGraphsView: View {
    private let textColor = Color(hex: "2C3E50")
    @State private var selectedTrend = TrendType.topics
    @Binding var timeframe: Timeframe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
//            HStack {
//                TrendPicker(selectedTrend: $selectedTrend)
//                
//                
//                Spacer()
//            }

            switch selectedTrend {
            case .topics:
                TopicSentimentView(timeframe: $timeframe)
            case .mood:
                MoodTimelineView(timeframe: $timeframe)
            case .sleep:
                SleepTimelineView(timeframe: $timeframe)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct TrendPicker: View {
    @Binding var selectedTrend: TrendType
    let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        Menu {
            Picker("Trend", selection: $selectedTrend) {
                ForEach(TrendType.allCases, id: \.self) { trend in
                    Text(trend.rawValue)
                        .tag(trend)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selectedTrend.rawValue)
                    .font(.system(size: 15))
                    .foregroundColor(textColor)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(textColor.opacity(0.6))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(textColor.opacity(0.15), lineWidth: 1)
                    .background(Color.white.cornerRadius(8))
            )
        }
    }
}

#Preview {
    TrendGraphsView(timeframe: .constant(.week))
        .background(Color(hex: "F5F5F5"))
}

private struct HasNoDataKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var hasNoData: Bool {
        get { self[HasNoDataKey.self] }
        set { self[HasNoDataKey.self] = newValue }
    }
}


struct TopicSentimentView: View {
    let sadColor = Color(hex: "1E3D59")
    let happyColor = Color(hex: "B784A7")
    
    @StateObject private var trendsManager = TrendsManager.shared
    @Binding var timeframe: Timeframe
    @State private var topics: [TopicData] = []
    
    @State var hasEnoughData: Bool = true
    @State private var selectedTopic: TopicData?
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 24) {
            GeometryReader { geometry in
                ZStack {
                    // Background line
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "2C3E50").opacity(0.1),
                                    Color(hex: "2C3E50").opacity(0.05)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                    
                    // Topics
                    ForEach(getTopFiveTopics()) { topic in
                        TopicBubble(
                            topic: topic,
                            size: calculateSize(for: topic, in: geometry.size),
                            position: calculatePosition(for: topic, in: geometry.size),
                            isSelected: selectedTopic?.id == topic.id,
                            sadColor: sadColor,
                            happyColor: happyColor,
                            hasEnoughData: hasEnoughData
                        )
                        .opacity(isAnimating ? 1 : 0)
                        .animation(
                            .spring(
                                response: 0.6,
                                dampingFraction: 0.8,
                                blendDuration: 0
                            ).delay(Double(topics.firstIndex(where: { $0.id == topic.id }) ?? 0) * 0.1),
                            value: isAnimating
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTopic = selectedTopic?.id == topic.id ? nil : topic
                            }
                        }
                    }
                    
                    if !hasEnoughData {
                        InsufficientDataOverlay()
                    }
                }
            }
            .frame(height: 260)
            
            // Legend
            HStack(spacing: 20) {
                legendItem(color: happyColor, text: "Positive sentiment")
                legendItem(color: sadColor, text: "Negative sentiment")
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .onAppear {
            withAnimation {
                isAnimating = true
            }
        }
        .task {
            await fetchTopics()
        }
        .onChange(of: timeframe) { _ in
            Task {
                await fetchTopics()
            }
        }
    }
    
    private func getTopFiveTopics() -> [TopicData] {
        return Array(topics.sorted { $0.mentions > $1.mentions }.prefix(5))
    }
    
    private func calculateSize(for topic: TopicData, in size: CGSize) -> CGFloat {
        let totalMentions = topics.reduce(0) { $0 + $1.mentions }
        let proportion = Double(topic.mentions) / Double(totalMentions)

        let maxSize = size.width * 0.3
        let minSize = size.width * 0.1
        
        return max(minSize, proportion * maxSize * 2)
    }
    
    private func calculatePosition(for topic: TopicData, in size: CGSize) -> CGPoint {
        let topFive = getTopFiveTopics()
        guard let index = topFive.firstIndex(where: { $0.id == topic.id }) else {
            return .zero
        }
        

        let totalTopics = Double(topFive.count)
        let xSpacing = size.width / (totalTopics + 1)
        let x = xSpacing * Double(index + 1)
        
        let midY = size.height / 2
        let maxOffset = size.height * 0.35
        let y = midY - (maxOffset * topic.sentiment)
        
        return CGPoint(x: x, y: y)
    }
    
    private func fetchTopics() async {
        let sentiments = await trendsManager.getTopicSentiments(for: timeframe)
        if sentiments.isEmpty {
            self.hasEnoughData = false
            self.topics = [
                TopicData(name: "Work", sentiment: 0.7, mentions: 24),
                TopicData(name: "Family", sentiment: 0.85, mentions: 18),
                TopicData(name: "Exercise", sentiment: 0.4, mentions: 12),
                TopicData(name: "Sleep", sentiment: -0.3, mentions: 15),
                TopicData(name: "School", sentiment: -0.6, mentions: 20)
            ]
        } else {
            self.topics = sentiments.map { summary in
                TopicData(
                    name: summary.topic,
                    sentiment: summary.averageSentiment,
                    mentions: summary.mentionCount
                )
            }
        }
    }
    
    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "2C3E50").opacity(0.6))
        }
    }
}

struct TopicBubble: View {
    let topic: TopicData
    let size: CGFloat
    let position: CGPoint
    let isSelected: Bool
    let sadColor: Color
    let happyColor: Color
    let hasEnoughData: Bool
    
    private var bubbleColor: Color {
        topic.sentiment > 0 ? happyColor : sadColor
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: size + 4, height: size + 4)
                .shadow(color: bubbleColor.opacity(0.3), radius: isSelected ? 15 : 10, x: 0, y: 4)

            Circle()
                .fill(bubbleColor.opacity(isSelected ? 1 : 0.8))
                .frame(width: size, height: size)
            
            VStack(spacing: 2) {
                Text(topic.name)
                    .font(.system(size: min(size * 0.15, 14), weight: .semibold))
                    .foregroundColor(.white)
                    .blur(radius: hasEnoughData ? 0.0 : 4.0)
                
                if isSelected {
                    Text("\(Int(abs(topic.sentiment * 100)))%")
                        .font(.system(size: min(size * 0.12, 12), weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
        .position(x: position.x, y: position.y)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct TopicData: Identifiable {
    let id = UUID()
    let name: String
    let sentiment: Double
    let mentions: Int
}

#Preview {
    ZStack {
        Color(hex: "F5F5F5")
            .edgesIgnoringSafeArea(.all)
        
        TopicSentimentView(timeframe: .constant(.week))
            .padding()
    }
}

struct InsufficientDataOverlay: View {
    
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        ZStack {          
            VStack(spacing: 8) {
                
//                WavePattern()
//                    .fill(accentColor.opacity(0.7))
//                    .frame(height: 60)
//                    .padding(.horizontal, 50)
                Text("Not enough data")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "2C3E50"))
                
                Text("Complete more daily reflections\nto see topic insights")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "2C3E50").opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white)
            )
        }
    }
}

struct SleepTimelineView: View {
    let deepBlue = Color(hex: "1E3D59")
    let textColor = Color(hex: "2C3E50")
    
    @Binding var timeframe: Timeframe
    @StateObject private var trendsManager = TrendsManager.shared
    @State private var timeframeData: [Double] = []
    @State private var hasEnoughData: Bool = false
    @State private var lineProgress: CGFloat = 0
    
    private var maxHours: Double {
        let maxValue = timeframeData.max() ?? 11
        return maxValue > 0 ? maxValue : 11
    }
    
    private var minHours: Double {
        let minValue = timeframeData.filter { $0 > 0 }.min() ?? 0
        return minValue > 0 ? minValue : 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SLEEP PATTERNS")
                .font(.system(size: 14, weight: .semibold))
                .tracking(1.5)
                .foregroundColor(textColor.opacity(0.5))
            
            GeometryReader { geometry in
                ZStack {
                    // Reference lines
                    
                    
                    if !timeframeData.isEmpty {
                        ExtendedLineGraph(
                            dataPoints: generateDataPoints(),
                            geometry: geometry,
                            minY: minHours,
                            maxY: maxHours,
                            getValue: { $0.hours }
                        )
                        .trim(from: 0, to: lineProgress)
                        .stroke(
                            deepBlue,
                            style: StrokeStyle(
                                lineWidth: 9,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                        .padding(.horizontal, -20)
                        .blur(radius: hasEnoughData ? 0 : 10)
                    }
                    
                    ReferenceLines(
                        maxY: calculateYPosition(maxHours, in: geometry),
                        minY: calculateYPosition(minHours, in: geometry),
                        maxValue: maxHours,
                        minValue: minHours
                    )
                    .zIndex(1)
                    
                    if !hasEnoughData {
                        TimelineEmptyState()
                    }
                }
                
            }
            .frame(height: 300)
            .padding(.top, 4)

            TimelineXAxisLabels(timeframe: timeframe)
            
        }
        .padding(.vertical, 12)
        .task {
            await fetchData()
        }
        .onChange(of: timeframe) { _ in
            Task {
                await fetchData()
            }
        }
    }
    
    private func fetchData() async {
        timeframeData = await trendsManager.getSleepAverages(for: timeframe)

        let daysWithData = timeframeData.filter { $0 > 0 }.count
        hasEnoughData = daysWithData >= 3

        lineProgress = 0
        withAnimation(.easeOut(duration: 1.5)) {
            lineProgress = 1
        }
    }
    
    private func generateDataPoints() -> [SleepDataPoint] {
        timeframeData.enumerated().map { index, hours in
            SleepDataPoint(
                date: Calendar.current.date(byAdding:
                    timeframe == .week ? .day :
                    timeframe == .month ? .weekOfMonth : .month,
                    value: index,
                    to: Date()
                ) ?? Date(),
                hours: hours
            )
        }
    }
    
    private func calculateYPosition(_ value: Double, in geometry: GeometryProxy) -> CGFloat {
        let padding: CGFloat = 20
        let availableHeight = geometry.size.height - (padding * 2)
        return padding + ((1 - CGFloat((value - minHours) / (maxHours - minHours))) * availableHeight)
    }
}

struct TimelineEmptyState: View {
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Not enough data")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(textColor)
            
            Text("Complete 3 daily check-ins\nto see your patterns")
                .font(.system(size: 14))
                .foregroundColor(textColor.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
    }
}

struct MoodTimelineView: View {
    let accentColor = Color(hex: "A28497")
    let textColor = Color(hex: "2C3E50")
    
    @Binding var timeframe: Timeframe
    @StateObject private var trendsManager = TrendsManager.shared
    @State private var timeframeData: [Double] = []
    @State private var hasEnoughData: Bool = false
    @State private var lineProgress: CGFloat = 0
    
    private var maxRating: Double {
        max(timeframeData.max() ?? 10, 10)
    }

    private var minRating: Double {
        let minValue = timeframeData.filter { $0 > 0 }.min() ?? 0
        return minValue
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MOOD PATTERNS")
                .font(.system(size: 14, weight: .semibold))
                .tracking(1.5)
                .foregroundColor(textColor.opacity(0.5))
            
            GeometryReader { geometry in
                ZStack {
                    // Main graph
                    if !timeframeData.isEmpty {
                        ExtendedLineGraph(
                            dataPoints: generateDataPoints(),
                            geometry: geometry,
                            minY: minRating,
                            maxY: maxRating,
                            getValue: { $0.rating }
                        )
                        .trim(from: 0, to: lineProgress)
                        .stroke(
                            accentColor,
                            style: StrokeStyle(
                                lineWidth: 9,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                        .padding(.horizontal, -20)
                        .blur(radius: hasEnoughData ? 0 : 10)
                    }
                    
                    // Overlay if not enough data
                    if !hasEnoughData {
                        TimelineEmptyState()
                    }
                }
            }
            .frame(height: 300)
            .padding(.top, 4)
            
            // X-axis labels
            TimelineXAxisLabels(timeframe: timeframe)
        }
        .padding(.vertical, 12)
        .task {
            await fetchData()
        }
        .onChange(of: timeframe) { _ in
            Task {
                await fetchData()
            }
        }
    }
    
    private func fetchData() async {
        timeframeData = await trendsManager.getMoodAverages(for: timeframe)
        
        let daysWithData = timeframeData.filter { $0 > 0 }.count
        hasEnoughData = daysWithData >= 3

        lineProgress = 0
        withAnimation(.easeOut(duration: 1.5)) {
            lineProgress = 1
        }
    }
    
    private func generateDataPoints() -> [GraphMoodDataPoint] {
        timeframeData.enumerated().map { index, rating in
            GraphMoodDataPoint(
                date: Calendar.current.date(byAdding:
                    timeframe == .week ? .day :
                    timeframe == .month ? .weekOfMonth : .month,
                    value: index,
                    to: Date()
                ) ?? Date(),
                rating: rating
            )
        }
    }
    
    private func calculateYPosition(_ value: Double, in geometry: GeometryProxy) -> CGFloat {
        let padding: CGFloat = 20
        let availableHeight = geometry.size.height - (padding * 2)
        return padding + ((1 - CGFloat((value - minRating) / (maxRating - minRating))) * availableHeight)
    }
}

struct GraphMoodDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let rating: Double
}

struct ExtendedLineGraph<T>: Shape where T: Identifiable {
    let dataPoints: [T]
    let geometry: GeometryProxy
    let minY: Double
    let maxY: Double
    let getValue: (T) -> Double?
    
    func path(in rect: CGRect) -> Path {
        Path { path in
            let points = dataPoints.enumerated().compactMap { index, point -> CGPoint? in
                guard let value = getValue(point) else { return nil }
                return CGPoint(
                    x: (CGFloat(index) / CGFloat(dataPoints.count - 1)) * rect.width,
                    y: calculateY(value, in: rect)
                )
            }
            
            guard let firstPoint = points.first, let lastPoint = points.last else { return }

            path.move(to: CGPoint(x: -20, y: firstPoint.y))
            path.addLine(to: firstPoint)

            for i in 1..<points.count {
                let current = points[i]
                let previous = points[i - 1]
                
                let deltaX = current.x - previous.x
                let controlLength = deltaX * 0.5
                
                let previousSlope = getSmoothSlope(points: points, index: i - 1)
                let currentSlope = getSmoothSlope(points: points, index: i)
                
                let control1 = CGPoint(
                    x: previous.x + controlLength,
                    y: previous.y + previousSlope * controlLength * 0.4
                )
                
                let control2 = CGPoint(
                    x: current.x - controlLength,
                    y: current.y - currentSlope * controlLength * 0.4
                )
                
                path.addCurve(
                    to: current,
                    control1: control1,
                    control2: control2
                )
            }

            path.addLine(to: CGPoint(x: rect.width + 20, y: lastPoint.y))
        }
    }
    
    private func calculateY(_ value: Double, in rect: CGRect) -> CGFloat {
        let padding: CGFloat = 20
        let availableHeight = rect.height - (padding * 2)
        return padding + ((1 - CGFloat((value - minY) / (maxY - minY))) * availableHeight)
    }
    
    private func getSmoothSlope(points: [CGPoint], index: Int) -> CGFloat {
        if index <= 0 || index >= points.count - 1 {
            return 0
        }
        
        let previous = points[max(0, index - 1)]
        let next = points[min(points.count - 1, index + 1)]
        let deltaX = next.x - previous.x
        
        guard deltaX != 0 else { return 0 }
        
        let deltaY = next.y - previous.y
        return (deltaY / deltaX) * 0.7
    }
}

struct ReferenceLines: View {
    let maxY: CGFloat
    let minY: CGFloat
    let maxValue: Double
    let minValue: Double
    
    var body: some View {
        GeometryReader { geometry in
            referenceLineView(
                value: maxValue,
                width: geometry.size.width
            )
            .position(x: geometry.size.width / 2, y: maxY)

            referenceLineView(
                value: minValue,
                width: geometry.size.width
            )
            .position(x: geometry.size.width / 2, y: minY)
        }
    }
    
    private func referenceLineView(value: Double, width: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Line()
                .stroke(Color(hex: "2C3E50").opacity(0.15), lineWidth: 1)
                .frame(width: width - 40, height: 1)
            
            Text(String(format: "%.1f", value))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "2C3E50").opacity(0.5))
        }
    }
}


struct TimelineXAxisLabels: View {
    let timeframe: Timeframe
    let textColor = Color(hex: "2C3E50")
    
    private var labels: [String] {
        switch timeframe {
        case .week:
            return ["S", "M", "T", "W", "T", "F", "S"]
        case .month:
            return ["1", "2", "3", "4"]
        case .year:
            let calendar = Calendar.current
            let now = Date()
            return (0..<12).compactMap { monthsAgo -> String in
                guard let date = calendar.date(byAdding: .month, value: -(11 - monthsAgo), to: now) else {
                    return ""
                }
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM"
                return String(formatter.string(from: date).prefix(1))
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(labels.indices, id: \.self) { index in
                Text(labels[index])
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(textColor.opacity(0.5))
                    .frame(maxWidth: .infinity)
            }
        }
    }
}


struct SmoothLineGraph: Shape {
    let dataPoints: [SleepDataPoint]
    let geometry: GeometryProxy
    let minY: Double
    let maxY: Double
    
    func path(in rect: CGRect) -> Path {
        Path { path in
            let points = dataPoints.enumerated().compactMap { index, point -> CGPoint? in
                guard let hours = point.hours else { return nil }
                return CGPoint(
                    x: (CGFloat(index) / CGFloat(dataPoints.count - 1)) * (rect.width + 40) - 20,
                    y: (1 - CGFloat((hours - minY) / (maxY - minY))) * rect.height
                )
            }
            
            guard !points.isEmpty else { return }
            
            path.move(to: points[0])
            
            for i in 1..<points.count {
                let current = points[i]
                let previous = points[i - 1]
                
                let deltaX = current.x - previous.x
                let controlLength = deltaX * 0.5 // Increased for smoother curves
                
                let previousSlope = getSmoothSlope(points: points, index: i - 1)
                let currentSlope = getSmoothSlope(points: points, index: i)
                
                let control1 = CGPoint(
                    x: previous.x + controlLength,
                    y: previous.y + previousSlope * controlLength * 0.5 // Dampened for smoother curves
                )
                
                let control2 = CGPoint(
                    x: current.x - controlLength,
                    y: current.y - currentSlope * controlLength * 0.5 // Dampened for smoother curves
                )
                
                path.addCurve(
                    to: current,
                    control1: control1,
                    control2: control2
                )
            }
        }
    }
    
    private func getSmoothSlope(points: [CGPoint], index: Int) -> CGFloat {
        if index <= 0 || index >= points.count - 1 {
            return 0
        }
        
        let previous = points[max(0, index - 1)]
        let next = points[min(points.count - 1, index + 1)]
        let deltaX = next.x - previous.x
        
        guard deltaX != 0 else { return 0 }
        
        let deltaY = next.y - previous.y
        return deltaY / deltaX
    }
}
struct FormatDateView: View {
    let date: Date?
    
    var body: some View {
        if let date = date {
            Text(format(date: date))
        }
    }
    
    private func format(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let str = formatter.string(from: date)
        return str.uppercased()
    }
}

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: 0, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        }
    }
}

struct SleepDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let hours: Double?
}
