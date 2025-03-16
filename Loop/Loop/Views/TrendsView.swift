//
//  TrendsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/28/24.
//

import SwiftUI

import SwiftUI

struct TrendWaveBackground: View {
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                
                // Starting point
                path.move(to: CGPoint(x: 0, y: 0))
                
                // First major wave
                path.addCurve(
                    to: CGPoint(x: width, y: 0),
                    control1: CGPoint(x: width * 0.35, y: height * 0.3),
                    control2: CGPoint(x: width * 0.65, y: -height * 0.3)
                )
                
                // Complete the shape
                path.addLine(to: CGPoint(x: width, y: height))
                path.addLine(to: CGPoint(x: 0, y: height))
                path.closeSubpath()
            }
            .fill(color.opacity(0.15))
            
            // Second wave
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                
                path.move(to: CGPoint(x: 0, y: 0))
                path.addCurve(
                    to: CGPoint(x: width, y: 0),
                    control1: CGPoint(x: width * 0.5, y: height * 0.4),
                    control2: CGPoint(x: width * 0.8, y: -height * 0.2)
                )
                path.addLine(to: CGPoint(x: width, y: height))
                path.addLine(to: CGPoint(x: 0, y: height))
                path.closeSubpath()
            }
            .fill(color.opacity(0.1))
        }
    }
}

struct TrendsView: View {
    @Binding var pageType: PageType
    @ObservedObject private var trendsManager = TrendsManager.shared
    @Binding var selectedTimeframe: Timeframe
    @State private var currentDate = Date()
    @State private var moodData: [MoodDataPoint] = []
    @State private var topHeight: CGFloat = 0
    
    private let textColor = Color(hex: "2C3E50")
    
    private var moodColor: Color {
        let rating = moodData.last?.rating ?? 5.0
        if rating <= 5 {
            let t = (rating - 1) / 4
            return interpolateColor(from: Color(hex: "1E3D59"), to: Color(hex: "94A7B7"), with: t)
        } else {
            let t = (rating - 5) / 5
            return interpolateColor(from: Color(hex: "94A7B7"), to: Color(hex: "B784A7"), with: t)
        }
    }
    
    private func interpolateColor(from: Color, to: Color, with percentage: Double) -> Color {
        let fromUIColor = UIColor(from)
        let toUIColor = UIColor(to)
        
        var fromR: CGFloat = 0, fromG: CGFloat = 0, fromB: CGFloat = 0, fromA: CGFloat = 0
        var toR: CGFloat = 0, toG: CGFloat = 0, toB: CGFloat = 0, toA: CGFloat = 0
        
        fromUIColor.getRed(&fromR, green: &fromG, blue: &fromB, alpha: &fromA)
        toUIColor.getRed(&toR, green: &toG, blue: &toB, alpha: &toA)
        
        let r = fromR + (toR - fromR) * CGFloat(percentage)
        let g = fromG + (toG - fromG) * CGFloat(percentage)
        let b = fromB + (toB - fromB) * CGFloat(percentage)
        let a = fromA + (toA - fromA) * CGFloat(percentage)
        
        return Color(UIColor(red: r, green: g, blue: b, alpha: a))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 24) {
                    HStack {
                        TimeframeSelector(selected: $selectedTimeframe)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    OverallMoodVisualization(timeframe: $selectedTimeframe, pageType: $pageType)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 24)
                .background(
                    GeometryReader { geo in
                        Color.clear.onAppear {
                            topHeight = geo.size.height
                        }
                    }
                )
                
                VStack (spacing: 4) {
                    EmotionsCard(timeframe: $selectedTimeframe)
                        .padding(.horizontal)
                    
                    TopicsCard(
                        title: "What brings you up",
                        subtitle: "Your reflections are most positive when discussing:",
                        timeframe: $selectedTimeframe,
                        fetchTopics: trendsManager.getPositiveTopics
                    )
                    .padding(.horizontal)
                    
                    TopicsCard(
                        title: "What makes you down",
                        subtitle: "Your reflections show more difficulty with:",
                        timeframe: $selectedTimeframe,
                        fetchTopics: trendsManager.getNegativeTopics
                    )
                    .padding(.horizontal)
                }
                
                Text("FROM YOUR REFLECTIONS")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.5))
                    .padding(.top, 16)
                    .padding(.bottom, -4)
                
                VStack(spacing: 4) {
                    KeyMomentsCard(timeframe: $selectedTimeframe)
                        .padding(.horizontal)

                    AchievementsCard(timeframe: $selectedTimeframe)
                        .padding(.horizontal)
                    
                    AffirmationsCard(timeframe: $selectedTimeframe)
                        .padding(.horizontal)
                }
                
            }
            .padding(.bottom, 32)
        }
        .background(
            VStack {
                TrendWaveBackground(color: moodColor)
                    .frame(height: topHeight)
                    .ignoresSafeArea()
                
            }
        )
        .background(Color(hex: "F5F5F5").ignoresSafeArea())
        .task {
            let metrics = await trendsManager.getDailyMetrics(for: selectedTimeframe)
            moodData = metrics.map { MoodDataPoint(date: $0.date, rating: $0.mood) }
        }
    }
}

struct MoodDataPoint: Equatable {
    let date: Date
    let rating: Double
    
    static func == (lhs: MoodDataPoint, rhs: MoodDataPoint) -> Bool {
        return lhs.date == rhs.date && lhs.rating == rhs.rating
    }
}

struct OverallMoodVisualization: View {
    @ObservedObject private var trendsManager = TrendsManager.shared
    @Binding var timeframe: Timeframe
    @Binding var pageType: PageType
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    @State private var moodData: [MoodDataPoint] = []
    @State private var moodDistribution: [(label: String, percentage: Double, color: Color)] = []
    
    private var currentMood: Double {
        guard let lastMood = moodData.last?.rating else { return 5.0 }
        return lastMood
    }
    
    private var moodColor: Color {
        if currentMood <= 5 {
            let t = (currentMood - 1) / 4
            return interpolateColor(from: Color(hex: "1E3D59"), to: Color(hex: "94A7B7"), with: t)
        } else {
            let t = (currentMood - 5) / 5
            return interpolateColor(from: Color(hex: "94A7B7"), to: Color(hex: "B784A7"), with: t)
        }
    }
    
    private var moodLabel: String {
        getMoodLabel(for: currentMood)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            
            if !moodData.isEmpty {
                HStack(spacing: 24) {
                    VStack(alignment: .center, spacing: 8) {
                        
                        MoodShape(rating: currentMood)
                            .fill(moodColor)
                            .frame(width: 200, height: 200)
                        
                        
                        VStack (spacing: 4) {
                            Text("YOU'VE BEEN")
                                .font(.system(size: 13, weight: .medium))
                                .tracking(1.5)
                                .foregroundColor(textColor.opacity(0.5))
                            
                            Text(moodLabel)
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(textColor)
                                .padding(.bottom, 20)
                        }
                        
                        
//
//                        Text("you've been")
//                            .font(.system(size: 17))
//                            .foregroundColor(textColor)

                    }
        
                }
                
                // Mood Distribution Section
//                VStack(spacing: 16) {
//                    Divider()
//                        .background(textColor.opacity(0.1))
//
//                    VStack(spacing: 12) {
//                        ForEach(moodDistribution, id: \.label) { mood in
//                            HStack(spacing: 12) {
//                                HStack (spacing: 6) {
//                                    Circle()
//                                        .fill(mood.color)
//                                        .frame(width: 8, height: 8)
//
//                                    Text(mood.label)
//                                        .font(.system(size: 15, weight: .medium))
//                                        .foregroundColor(textColor)
//
//                                }
//
//                                Spacer()
//
//                                Text("\(Int(round(mood.percentage)))%")
//                                    .font(.system(size: 15, weight: .medium))
//                                    .foregroundColor(textColor)
//                            }
//                        }
//                    }
//                }
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    
                    HStack {
                        VStack (alignment: .leading, spacing: 8) {
                            Text("add more check-ins")
                                .font(.system(size: 17))
                                .foregroundColor(textColor)
                            
                            Text("to see your mood")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(textColor)
                        }
                        
                        Spacer()
                        
                        MoodShape(rating: 5.0)
                            .fill(interpolateColor(from: Color(hex: "1E3D59"), to: Color(hex: "94A7B7"), with: 0.5))
                            .frame(width: 130, height: 130)
                        
                    }
                
                
                }
            }
        }

        .onAppear {
            Task {
                let metrics = await trendsManager.getDailyMetrics(for: timeframe)
                print("MoodShapeCard received \(metrics.count) mood data points")
                switch timeframe {
                case .week:
                    if metrics.count > 0 {
                        moodData = metrics.map { MoodDataPoint(date: $0.date, rating: $0.mood) }
                    }
                case .month:
                    if metrics.count > 5 {
                        moodData = metrics.map { MoodDataPoint(date: $0.date, rating: $0.mood) }
                    }
                case .year:
                    if metrics.count > 20 {
                        moodData = metrics.map { MoodDataPoint(date: $0.date, rating: $0.mood) }
                    }
                }
                calculateMoodDistribution(from: moodData)
            }
        }

    }
    
    private func calculateMoodDistribution(from data: [MoodDataPoint]) {
        guard !data.isEmpty else { return }

        var feelingGreat = 0
        var prettyGood = 0
        var okay = 0
        var notGreat = 0
        var feelingDown = 0

        for point in data {
            switch point.rating {
            case 8...10:
                feelingGreat += 1
            case 6..<8:
                prettyGood += 1
            case 4..<6:
                okay += 1
            case 3..<4:
                notGreat += 1
            case 0..<3:
                feelingDown += 1
            default:
                break
            }
        }
        
        let total = Double(data.count)
        
        var distribution = [
            (label: "feeling great", count: feelingGreat, color: interpolateColor(from: Color(hex: "94A7B7"), to: Color(hex: "B784A7"), with: 0.8)),
            (label: "pretty good", count: prettyGood, color: interpolateColor(from: Color(hex: "94A7B7"), to: Color(hex: "B784A7"), with: 0.4)),
            (label: "okay", count: okay, color: Color(hex: "94A7B7")),
            (label: "not great", count: notGreat, color: interpolateColor(from: Color(hex: "1E3D59"), to: Color(hex: "94A7B7"), with: 0.6)),
            (label: "feeling down", count: feelingDown, color: interpolateColor(from: Color(hex: "1E3D59"), to: Color(hex: "94A7B7"), with: 0.2))
        ]
        
        distribution.sort { $0.count > $1.count }
        moodDistribution = distribution
            .filter { $0.count > 0 }
            .map { (label: $0.label, percentage: (Double($0.count) / total) * 100, color: $0.color) }
    }
    
    private func getMoodLabel(for rating: Double) -> String {
        switch rating {
        case 0...3:
            return "feeling down"
        case 3...4:
            return "not great"
        case 4...6:
            return "okay"
        case 6...8:
            return "pretty good"
        case 8...10:
            return "feeling great"
        default:
            return "okay"
        }
    }
    
    private func interpolateColor(from: Color, to: Color, with percentage: Double) -> Color {
        let fromUIColor = UIColor(from)
        let toUIColor = UIColor(to)
        
        var fromR: CGFloat = 0, fromG: CGFloat = 0, fromB: CGFloat = 0, fromA: CGFloat = 0
        var toR: CGFloat = 0, toG: CGFloat = 0, toB: CGFloat = 0, toA: CGFloat = 0
        
        fromUIColor.getRed(&fromR, green: &fromG, blue: &fromB, alpha: &fromA)
        toUIColor.getRed(&toR, green: &toG, blue: &toB, alpha: &toA)
        
        let r = fromR + (toR - fromR) * CGFloat(percentage)
        let g = fromG + (toG - fromG) * CGFloat(percentage)
        let b = fromB + (toB - fromB) * CGFloat(percentage)
        let a = fromA + (toA - fromA) * CGFloat(percentage)
        
        return Color(UIColor(red: r, green: g, blue: b, alpha: a))
    }
}

struct MoodShape: Shape {
    let rating: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        let normalizedRating = (rating - 1) / 9

        let points = (0...5).map { i -> CGPoint in
            let angle = 2 * .pi * Double(i) / 5
            let radiusVariation = sin(angle * 2) * 0.2 + 1
            let radius = rect.width/2 * radiusVariation * (0.7 + normalizedRating * 0.3)
            

            let moodOffset = (normalizedRating - 0.5) * rect.height * 0.2
            
            return CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius + moodOffset
            )
        }
    
        path.move(to: points[0])
        for i in 0...points.count {
            let point = points[i % points.count]
            let nextPoint = points[(i + 1) % points.count]
            let midPoint = CGPoint(
                x: (point.x + nextPoint.x)/2,
                y: (point.y + nextPoint.y)/2
            )
            
            path.addQuadCurve(
                to: midPoint,
                control: CGPoint(
                    x: point.x + (nextPoint.x - point.x)/4,
                    y: point.y + (nextPoint.y - point.y)/4
                )
            )
        }
        
        return path
    }
}

struct EmotionsCard: View {
    @ObservedObject private var trendsManager = TrendsManager.shared
    
    @Binding var timeframe: Timeframe
    @State private var moodDistribution: [(label: String, percentage: Double, color: Color)] = []
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack (alignment: .leading, spacing: 8) {
                HStack {
                    Text("Your top emotions this \(timeframe.displayText.lowercased())")
                        .font(.system(size: 18, weight: .bold))
                    
                    Spacer()
                }
                
                Text("Based on your mood check-ins")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            if moodDistribution.isEmpty {
                NewEmptyStateView(showWavePattern: true)
            } else {
                NewEmotionsChart(data: moodDistribution)
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
        .onAppear {
            Task {
                let metrics = await trendsManager.getDailyMetrics(for: timeframe)
                print("MoodShapeCard received \(metrics.count) mood data points")
                let moodData = metrics.map { MoodDataPoint(date: $0.date, rating: $0.mood)}
                
                calculateMoodDistribution(from: moodData)
            }
        }
    }
    
    private func calculateMoodDistribution(from data: [MoodDataPoint]) {
        guard !data.isEmpty else { return }

        var feelingGreat = 0
        var prettyGood = 0
        var okay = 0
        var notGreat = 0
        var feelingDown = 0

        for point in data {
            switch point.rating {
            case 8...10:
                feelingGreat += 1
            case 6..<8:
                prettyGood += 1
            case 4..<6:
                okay += 1
            case 3..<4:
                notGreat += 1
            case 0..<3:
                feelingDown += 1
            default:
                break
            }
        }
        
        let total = Double(data.count)
        
        var distribution = [
            (label: "feeling great", count: feelingGreat, color: interpolateColor(from: Color(hex: "94A7B7"), to: Color(hex: "B784A7"), with: 0.8)),
            (label: "pretty good", count: prettyGood, color: interpolateColor(from: Color(hex: "94A7B7"), to: Color(hex: "B784A7"), with: 0.4)),
            (label: "okay", count: okay, color: Color(hex: "94A7B7")),
            (label: "not great", count: notGreat, color: interpolateColor(from: Color(hex: "1E3D59"), to: Color(hex: "94A7B7"), with: 0.6)),
            (label: "feeling down", count: feelingDown, color: interpolateColor(from: Color(hex: "1E3D59"), to: Color(hex: "94A7B7"), with: 0.2))
        ]
        
        distribution.sort { $0.count > $1.count }
        moodDistribution = distribution
            .filter { $0.count > 0 }
            .map { (label: $0.label, percentage: (Double($0.count) / total) * 100, color: $0.color) }
    }
    
    private func getMoodLabel(for rating: Double) -> String {
        switch rating {
        case 0...3:
            return "feeling down"
        case 3...4:
            return "not great"
        case 4...6:
            return "okay"
        case 6...8:
            return "pretty good"
        case 8...10:
            return "feeling great"
        default:
            return "okay"
        }
    }
    
    private func interpolateColor(from: Color, to: Color, with percentage: Double) -> Color {
        let fromUIColor = UIColor(from)
        let toUIColor = UIColor(to)
        
        var fromR: CGFloat = 0, fromG: CGFloat = 0, fromB: CGFloat = 0, fromA: CGFloat = 0
        var toR: CGFloat = 0, toG: CGFloat = 0, toB: CGFloat = 0, toA: CGFloat = 0
        
        fromUIColor.getRed(&fromR, green: &fromG, blue: &fromB, alpha: &fromA)
        toUIColor.getRed(&toR, green: &toG, blue: &toB, alpha: &toA)
        
        let r = fromR + (toR - fromR) * CGFloat(percentage)
        let g = fromG + (toG - fromG) * CGFloat(percentage)
        let b = fromB + (toB - fromB) * CGFloat(percentage)
        let a = fromA + (toA - fromA) * CGFloat(percentage)
        
        return Color(UIColor(red: r, green: g, blue: b, alpha: a))
    }
}

struct NewEmptyStateView: View {
    @State var showWavePattern: Bool
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                if showWavePattern {
                    WavePattern()
                        .fill(accentColor.opacity(0.7))
                        .frame(height: 60)
                    
                }
                
                HStack {
                    Text("No data yet")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                        .bold()
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct NewEmotionsChart: View {
    let data: [(label: String, percentage: Double, color: Color)]
    
    var body: some View {
        ZStack {
            VStack (spacing: 8) {
                ForEach(0..<data.count, id: \.self) { index in
                    HStack {
                        Text(data[index].label)
                            .font(.system(size: 13, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(data[index].color.opacity(0.8))
                        
                        
                        Spacer()
                        
                        Text("\(Int(data[index].percentage))%")
                            .font(.system(size: 13, weight: .medium))
                            .tracking(1.5)
                            .foregroundColor(data[index].color.opacity(0.5))
                        
                        
                    }
                }
            }
        }
    }
}

struct NewEmotionArc: View {
    let value: Double
    let index: Int
    let total: Int
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let radius = min(geometry.size.width, geometry.size.height) / 2
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let segmentAngle = .pi * 2 / Double(total)
                let startAngle = segmentAngle * Double(index) - .pi / 2
                let endAngle = startAngle + segmentAngle * (value / 100)
                
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: Angle(radians: startAngle),
                    endAngle: Angle(radians: endAngle),
                    clockwise: false
                )
            }
            .stroke(color, lineWidth: 20)
        }
    }
}

struct WeeklyOverviewCard: View {
    @Binding var timeframe: Timeframe
    @ObservedObject private var trendsManager = TrendsManager.shared
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(dateRangeText)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(textColor)
            
            // Date range selector with arrows
            HStack {
                Button(action: { /* Previous week */ }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(textColor)
                }
                
                Spacer()
                
                Text("This week")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(textColor)
                
                Spacer()
                
                Button(action: { /* Next week */ }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(textColor)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.white)
            .cornerRadius(12)
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
    }
    
    private var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let now = Date()
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        return "\(formatter.string(from: weekAgo)) - \(formatter.string(from: now))"
    }
}

// Helper views for emotion visualization
struct EmotionsChart: View {
    let emotions: [String: Double]
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(Array(emotions.keys), id: \.self) { emotion in
                    EmotionArc(
                        percentage: emotions[emotion] ?? 0,
                        index: Array(emotions.keys).firstIndex(of: emotion) ?? 0,
                        total: emotions.count,
                        size: geometry.size
                    )
                    .fill(accentColor.opacity(Double(emotions[emotion] ?? 0)))
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct EmotionArc: Shape {
    let percentage: Double
    let index: Int
    let total: Int
    let size: CGSize
    
    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let startAngle = Angle(degrees: Double(index) * (360.0 / Double(total)))
        let endAngle = startAngle + Angle(degrees: (360.0 / Double(total)) * percentage)
        
        var path = Path()
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        return path
    }
}

struct TimeframeSelector: View {
    @Binding var selected: Timeframe
    
    var body: some View {
        Menu {
            Picker("Timeframe", selection: $selected) {
                ForEach(Timeframe.allCases, id: \.self) { timeframe in
                    Text(timeframe.displayText)
                        .tag(timeframe)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selected.displayText)
                    .font(.system(size: 17))
                Image(systemName: "chevron.down")
                    .font(.system(size: 13))
            }
            .foregroundColor(.black)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.white)
            .clipShape(Capsule())
        }
    }
}


struct TopicsCard: View {
    let title: String
    let subtitle: String
    @Binding var timeframe: Timeframe
    @State private var topics: [String] = []
    let fetchTopics: (Timeframe) async -> [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack (alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                    
                    Spacer()
                }
               
                HStack {
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                }
            }
            
            if topics.isEmpty {
                Text("No data yet")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            } else {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(topics, id: \.self) { topic in
                            Text(topic)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color(hex: "2C3E50"))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(hex: topic.hashValue % 2 == 0 ? "94A7B7" : "B784A7").opacity(0.15),
                                            Color(hex: topic.hashValue % 2 == 0 ? "B784A7" : "94A7B7").opacity(0.05)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            Color(hex: topic.hashValue % 2 == 0 ? "94A7B7" : "B784A7").opacity(0.3),
                                            lineWidth: 1
                                        )
                                )
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                    }
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(10)
        .task(id: timeframe) {
            topics = await fetchTopics(timeframe)
            
            print("the topics \(topics)")
        }
        
    }
}

struct WeekSelector: View {
    @Binding var currentDate: Date
    let dateRange: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(dateRange)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.gray)
            
            HStack {
                Button(action: { adjustWeek(-1) }) {
                    Image(systemName: "chevron.left")
                }
                
                Spacer()
                
                Text("This week")
                    .font(.system(size: 17, weight: .medium))
                
                Spacer()
                
                Button(action: { adjustWeek(1) }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    private func adjustWeek(_ value: Int) {
        if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: value, to: currentDate) {
            currentDate = newDate
        }
    }
}

struct FlowLayout: Layout {
    let spacing: CGFloat
    
    struct Row {
        var views: [LayoutSubviews.Element]
        var height: CGFloat
        var y: CGFloat
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.last.map { $0.y + $0.height } ?? 0
        return CGSize(width: proposal.width ?? 0, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        
        for row in rows {
            var x = bounds.minX
            for subview in row.views {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(
                    at: CGPoint(x: x, y: row.y),
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
        }
    }
    
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row(views: [], height: 0, y: 0)
        var x: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if x + size.width > (proposal.width ?? 0) && !currentRow.views.isEmpty {
                rows.append(currentRow)
                currentRow = Row(views: [], height: 0, y: currentRow.y + currentRow.height + spacing)
                x = 0
            }
            
            currentRow.views.append(subview)
            currentRow.height = max(currentRow.height, size.height)
            x += size.width + spacing
        }
        
        if !currentRow.views.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
}

// Premium-restricted KeyMomentsCard
struct KeyMomentsCard: View {
    @Binding var timeframe: Timeframe
    @ObservedObject private var trendsManager = TrendsManager.shared
    @ObservedObject private var premiumManager = PremiumManager.shared
    @State private var currentIndex = 0
    @State private var keyMoments: [KeyMoment] = []
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        Group {
            if premiumManager.isUserPremium() {
                // Regular card content for premium users
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Key Moments")
                                .font(.system(size: 18, weight: .bold))
                            Spacer()
                        }
                        
                        Text("Highlights from your reflections")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    if keyMoments.isEmpty {
                        NewEmptyStateView(showWavePattern: false)
                    } else {
                        TabView(selection: $currentIndex) {
                            ForEach(Array(keyMoments.prefix(3).enumerated()), id: \.element.date) { index, moment in
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Text(moment.category.rawValue.capitalized)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(accentColor)
                                        
                                        Text("•")
                                            .foregroundColor(.gray)
                                        
                                        Text(moment.date.formatted(date: .abbreviated, time: .omitted))
                                            .font(.system(size: 13))
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Text(moment.content)
                                        .font(.system(size: 20, weight: .light))
                                        .foregroundColor(textColor)
                                        .lineSpacing(8)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.horizontal)
                                .tag(index)
                            }
                        }
                        .tabViewStyle(.page)
                        .frame(height: 180)
                    }
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(16)
                .task {
                    keyMoments = await trendsManager.getKeyMoments(for: timeframe)
                }
            } else {
                // Premium placeholder for non-premium users
                PremiumCardPlaceholder(
                    title: "Key Moments",
                    description: "Highlights from your reflections"
                )
            }
        }
    }
}

// Premium-restricted AchievementsCard
struct AchievementsCard: View {
    @Binding var timeframe: Timeframe
    @ObservedObject private var trendsManager = TrendsManager.shared
    @ObservedObject private var premiumManager = PremiumManager.shared
    @State private var achievements: [Achievement] = []
    
    // Mauve color variants
    private let lightMauve = Color(hex: "D5C5CC")
    private let midMauve = Color(hex: "BBA4AD")
    
    var body: some View {
        Group {
            if premiumManager.isUserPremium() {
                // Regular card content for premium users
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Recent Wins")
                                .font(.system(size: 18, weight: .bold))
                            Spacer()
                        }
                        
                        Text("Your notable achievements")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    if achievements.isEmpty {
                        NewEmptyStateView(showWavePattern: false)
                    } else {
                        ZStack {
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    lightMauve.opacity(0.3),
                                    Color.white.opacity(0.9)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            
                            GeometricMountains()
                                .fill(midMauve)
                                .opacity(0.2)
                                .frame(height: 120)
                                .offset(y: 40)
                            
                            VStack(spacing: 16) {
                                ForEach(achievements.prefix(2), id: \.win) { achievement in
                                    AchievementRow(achievement: achievement)
                                }
                            }
                        }
                    }
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(16)
                .task {
                    achievements = await trendsManager.getAchievements(for: timeframe)
                }
            } else {
                // Premium placeholder for non-premium users
                PremiumCardPlaceholder(
                    title: "Recent Wins",
                    description: "Your notable achievements"
                )
            }
        }
    }
}

struct AchievementRow: View {
    let achievement: Achievement
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color(hex: "A28497").opacity(0.1))
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .fill(Color(hex: "A28497"))
                        .frame(width: 8, height: 8)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.win)
                    .font(.system(size: 16))
                    .foregroundColor(textColor)
                
                Text(achievement.category.rawValue.capitalized)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.8))
        .cornerRadius(12)
    }
}

struct AffirmationsCard: View {
    @Binding var timeframe: Timeframe
    @ObservedObject private var trendsManager = TrendsManager.shared
    @ObservedObject private var premiumManager = PremiumManager.shared
    @State private var affirmations: [Affirmation] = []
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        Group {
            if premiumManager.isUserPremium() {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Positive Beliefs")
                                .font(.system(size: 18, weight: .bold))
                            Spacer()
                        }
                        
                        Text("Things you've acknowledged about yourself")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    if affirmations.isEmpty {
                        NewEmptyStateView(showWavePattern: false)
                    } else {
                        VStack(spacing: 16) {
                            ForEach(affirmations.prefix(3), id: \.affirmation) { affirmation in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(affirmation.affirmation)
                                        .font(.system(size: 16))
                                        .foregroundColor(textColor)
                                    
                                    Text(affirmation.theme.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                                        .font(.system(size: 13))
                                        .foregroundColor(accentColor)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(accentColor.opacity(0.1))
                                        .cornerRadius(12)
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    LinearGradient(
                                        colors: [accentColor.opacity(0.05), .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(16)
                .task {
                    affirmations = await trendsManager.getAffirmations(for: timeframe)
                }
            } else {
                // Premium placeholder for non-premium users
                PremiumCardPlaceholder(
                    title: "Positive Beliefs",
                    description: "Things you've acknowledged about yourself"
                )
            }
        }
    }
}


struct PremiumCardPlaceholder: View {
    let title: String
    let description: String
    let accentColor = Color(hex: "A28497")
    
    @ObservedObject var premiumManager = PremiumManager.shared
    @State private var isPurchasing = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Top section with card info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                    
                    Spacer()
                    
                    Image(systemName: "crown.fill")
                        .foregroundColor(accentColor)
                }
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            // Premium placeholder with blur effect
            ZStack {
                // Background pattern or visualization
                WavePattern()
                    .fill(accentColor.opacity(0.2))
                    .frame(height: 80)
                    .blur(radius: 3)
                
                // Premium lock overlay
                VStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 24))
                        .foregroundColor(accentColor)
                    
                    Text("Premium Feature")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "2C3E50"))
                    
                    Button(action: {
                        purchasePremium()
                    }) {
                        HStack {
                            Text("Upgrade")
                                .font(.system(size: 15, weight: .medium))
                            
                            if isPurchasing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                    }
                    .disabled(isPurchasing)
                }
                .padding()
                .background(Color.white.opacity(0.8))
                .cornerRadius(12)
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Premium"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func purchasePremium() {
        isPurchasing = true
        
        Task {
            do {
                let success = try await premiumManager.purchasePremium()
                
                await MainActor.run {
                    isPurchasing = false
                    if success {
                        alertMessage = "Thank you for upgrading to Premium!"
                    } else {
                        alertMessage = "Purchase could not be completed."
                    }
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    alertMessage = "Purchase failed: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
}


#Preview {
    TrendsView(pageType: .constant(.trends), selectedTimeframe: .constant(.week))
}
