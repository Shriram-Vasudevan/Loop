//
//  TrendsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/28/24.
//

import SwiftUI

struct TrendsView: View {
    @Binding var pageType: PageType
    @ObservedObject private var trendsManager = TrendsManager.shared
    @Binding var selectedTimeframe: Timeframe
    
    // Add loading state for view
    @State private var isLoading = false
    
    private let accentColor = Color(hex: "A28497")
    private let secondaryColor = Color(hex: "1E3D59")
    private let textColor = Color(hex: "2C3E50")
    private let backgroundColor = Color(hex: "F5F5F5")
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                VStack(spacing: 24) {
                    headerSection
                    
                    MoodAnalysisView(timeframe: $selectedTimeframe)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                
                MoodSection(timeframe: $selectedTimeframe, pageType: $pageType)
                    .padding(.horizontal, 24)
            }
            .overlay {
                if trendsManager.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
        }
        .background(backgroundColor)
        .task(id: selectedTimeframe) {
            await trendsManager.fetchAllCorrelations(for: selectedTimeframe)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 4) {
                ForEach(Timeframe.allCases, id: \.self) { timeframe in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTimeframe = timeframe
                        }
                    }) {
                        Text(timeframe.displayText)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(selectedTimeframe == timeframe ?
                                accentColor : textColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedTimeframe == timeframe ?
                                        accentColor.opacity(0.1) : Color.clear)
                            )
                    }
                }
                
                Spacer()
            }
        }
        .padding(.top, 16)
    }
}

struct EntryStatsView: View {
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    private let totalEntries = 127
    private let totalWords = 23_842
    
    var body: some View {
        ZStack {
            Color.white
                .cornerRadius(10)
            
            HStack(spacing: 0) {
                StatBox(
                    label: "TOTAL ENTRIES",
                    value: "\(totalEntries)",
                    textColor: textColor
                )

                Rectangle()
                    .fill(textColor.opacity(0.1))
                    .frame(width: 1)
                    .padding(.vertical, 24)

                StatBox(
                    label: "TOTAL WORDS",
                    value: "\(totalWords.formatted())",
                    textColor: textColor
                )
            }
        }
        .frame(height: 120)
    }
}

private struct StatBox: View {
    let label: String
    let value: String
    let textColor: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .tracking(1.5)
                .foregroundColor(textColor.opacity(0.5))
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(textColor)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MoodSection: View {
    @Binding var timeframe: Timeframe
    @Binding var pageType: PageType
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")

    private let weekData = [7.0, 6.5, 8.0, 7.5, 8.5, 7.0, 8.0]
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Mood")
                        .font(.system(size: 24, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(textColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack (spacing: 4) {
                    MoodShapeCard(timeframe: $timeframe, pageType: $pageType)
                    
                    SleepMoodCard(timeframe: $timeframe)
                    
                    TrendsTopicsCard(timeframe: $timeframe)
                    
                    TrendsTopicChallengesCard(timeframe: $timeframe)
                }
            }
        }
    }
    
    private func getColor(for rating: Double) -> Color {
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
        
        var fromR: CGFloat = 0
        var fromG: CGFloat = 0
        var fromB: CGFloat = 0
        var fromA: CGFloat = 0
        fromUIColor.getRed(&fromR, green: &fromG, blue: &fromB, alpha: &fromA)
        
        var toR: CGFloat = 0
        var toG: CGFloat = 0
        var toB: CGFloat = 0
        var toA: CGFloat = 0
        toUIColor.getRed(&toR, green: &toG, blue: &toB, alpha: &toA)
        
        let r = fromR + (toR - fromR) * CGFloat(percentage)
        let g = fromG + (toG - fromG) * CGFloat(percentage)
        let b = fromB + (toB - fromB) * CGFloat(percentage)
        let a = fromA + (toA - fromA) * CGFloat(percentage)
        
        return Color(UIColor(red: r, green: g, blue: b, alpha: a))
    }
    
    private func topicIcon(for topic: String) -> String {
        switch topic {
        case "Family": return "heart.fill"
        case "Exercise": return "figure.walk"
        case "Reading": return "book.fill"
        default: return "circle.fill"
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

struct MoodShapeCard: View {
    @ObservedObject private var trendsManager = TrendsManager.shared
    @Binding var timeframe: Timeframe
    @Binding var pageType: PageType
    
    private let textColor = Color(hex: "2C3E50")
    
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
            // Header
            HStack {
                Text("MOOD JOURNEY")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.5))
                
                Spacer()
                
                Button(action: {
                    pageType = .schedule
                }, label: {
                    Text("see more")
                        .font(.system(size: 12, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(textColor.opacity(0.5))
                })
            }
            
            if !moodData.isEmpty {
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("you've been")
                            .font(.system(size: 17))
                            .foregroundColor(textColor)
                        
                        Text(moodLabel)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(textColor)
                    }
                    
                    Spacer()
                    
                    MoodShape(rating: currentMood)
                        .fill(moodColor)
                        .frame(width: 120, height: 120)
                }
                
                // Mood Distribution Section
                VStack(spacing: 16) {
                    Divider()
                        .background(textColor.opacity(0.1))
                    
                    VStack(spacing: 12) {
                        ForEach(moodDistribution, id: \.label) { mood in
                            HStack(spacing: 12) {
                                HStack (spacing: 6) {
                                    Circle()
                                        .fill(mood.color)
                                        .frame(width: 8, height: 8)
                                    
                                    Text(mood.label)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(textColor)
                                    
                                }
                                
                                Spacer()
                                
                                Text("\(Int(round(mood.percentage)))%")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(textColor)
                            }
                        }
                    }
                }
            } else {
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("add reflections")
                            .font(.system(size: 17))
                            .foregroundColor(textColor)
                        
                        Text("to see your journey")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(textColor)
                    }
                    
                    Spacer()
                    
                    MoodShape(rating: 5.0)
                        .fill(Color(hex: "94A7B7"))
                        .opacity(0.5)
                        .frame(width: 120, height: 120)
                }
            }
        }
        .padding(24)
        .background(
            ZStack {
                Color.white
            }
        )
        .cornerRadius(10)
        .task(id: timeframe) {
            let metrics = await trendsManager.getDailyMetrics(for: timeframe)
            moodData = metrics.map { MoodDataPoint(date: $0.date, rating: $0.mood) }
            calculateMoodDistribution(from: moodData)
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


struct SleepMoodCard: View {
    @ObservedObject private var trendsManager = TrendsManager.shared
    @Binding var timeframe: Timeframe
    @State private var sleepAnalysis: (message: String, effectLine: String)?
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        ZStack {
            SleepWavePattern()
                .fill(accentColor.opacity(0.05))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            if let analysis = sleepAnalysis {
                VStack(alignment: .leading, spacing: 20) {
                    Text("SLEEP & MOOD")
                        .font(.system(size: 13, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(textColor.opacity(0.5))
                    
                    HStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(analysis.message)
                                .font(.system(size: 17))
                                .foregroundColor(textColor)
                            
                            Text(analysis.effectLine)
                                .font(.system(size: 15))
                                .foregroundColor(textColor.opacity(0.6))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 54))
                            .foregroundColor(Color(hex: "B5D5E2"))
                            .scaleEffect(x: -1)
                    }
                }
                .padding(24)
            } else {
                VStack(alignment: .leading, spacing: 20) {
                    Text("SLEEP & MOOD")
                        .font(.system(size: 13, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(textColor.opacity(0.5))
                    
                    Text("Track your sleep to see insights")
                        .font(.system(size: 17))
                        .foregroundColor(textColor)
                }
                .padding(24)
            }
        }
        .background(Color.white)
        .cornerRadius(10)
        .task(id: timeframe) {
            sleepAnalysis = await trendsManager.analyzeSleepEffect(for: timeframe)
        }
    }
}

struct SleepWavePattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let waves = 2
        let amplitudes = [rect.height * 0.15, rect.height * 0.1]
        let frequencies = [1.0, 1.5]
        let yOffsets = [rect.height * 0.6, rect.height * 0.7]
        
        for wave in 0..<waves {
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))

            let points = 100
            for point in 0...points {
                let x = rect.width * CGFloat(point) / CGFloat(points)
                let progressiveAmplitude = amplitudes[wave] * (1 - CGFloat(point) / CGFloat(points)) 
                let y = yOffsets[wave] + sin(CGFloat(point) / CGFloat(points) * .pi * 2 * frequencies[wave]) * progressiveAmplitude
                
                if point == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }

            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.closeSubpath()
        }
        
        return path
    }
}

struct TrendsTopicsCard: View {
    @ObservedObject private var trendsManager = TrendsManager.shared
    @Binding var timeframe: Timeframe
    @State private var positiveTopics: [String] = []
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    private let coolBlue = Color(hex: "B5D5E2")
    
    var body: some View {
        ZStack {
            TopicsPatternBackground()
                .fill(coolBlue.opacity(0.05))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("WHAT LIFTS YOU UP")
                        .font(.system(size: 13, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(textColor.opacity(0.5))
                    
                    
                    Spacer()
                }
                
                HStack {
                    Text("Your reflections are most positive when discussing:")
                        .font(.system(size: 17))
                        .foregroundColor(textColor)
                    
                    Spacer()
                }
                
                if !positiveTopics.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(positiveTopics, id: \.self) { topic in
                                Text(topic)
                                    .font(.system(size: 17))
                                    .foregroundColor(textColor)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(accentColor.opacity(0.15))
                                    )
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                } else {
                    Text("Keep reflecting to discover topics")
                        .font(.system(size: 15))
                        .foregroundColor(textColor.opacity(0.6))
                }
            }
            .padding(24)
        }
        .background(Color.white)
        .cornerRadius(10)
        .task(id: timeframe) {
            positiveTopics = await trendsManager.getPositiveTopics(for: timeframe)
        }
    }
}

struct TrendsTopicChallengesCard: View {
    @ObservedObject private var trendsManager = TrendsManager.shared
    @Binding var timeframe: Timeframe
    @State private var negativeTopics: [String] = []
    
    private let textColor = Color(hex: "2C3E50")
    private let coolBlue = Color(hex: "B5D5E2")
    
    var body: some View {
        ZStack {
            TopicsPatternBackground()
                .fill(coolBlue.opacity(0.05))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("WHAT KEEPS YOU DOWN")
                        .font(.system(size: 13, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(textColor.opacity(0.5))
                    
                    Spacer()
                }
               
                HStack {
                    Text("Your reflections show more difficulty when dealing with:")
                        .font(.system(size: 17))
                        .foregroundColor(textColor)
                    
                    Spacer()
                }
                
                if !negativeTopics.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(negativeTopics, id: \.self) { topic in
                                Text(topic)
                                    .font(.system(size: 17))
                                    .foregroundColor(textColor)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(coolBlue.opacity(0.15))
                                    )
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                } else {
                    Text("Keep reflecting to discover topics")
                        .font(.system(size: 15))
                        .foregroundColor(textColor.opacity(0.6))
                }
            }
            .padding(24)
        }
        .background(Color.white)
        .cornerRadius(10)
        .task(id: timeframe) {
            negativeTopics = await trendsManager.getNegativeTopics(for: timeframe)
        }
    }
}


struct TopicsPatternBackground: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Create a diagonal pattern of circles and dots
        let smallCircleRadius: CGFloat = 3
        let largeCircleRadius: CGFloat = 6
        let spacing: CGFloat = 40
        
        for row in 0...Int(rect.height/spacing) {
            for col in 0...Int(rect.width/spacing) {
                let x = CGFloat(col) * spacing
                let y = CGFloat(row) * spacing
                
                // Offset every other row
                let offset = row % 2 == 0 ? spacing/2 : 0
                
                // Alternate between circles and dots
                if (row + col) % 2 == 0 {
                    let circleRect = CGRect(
                        x: x + offset - smallCircleRadius,
                        y: y - smallCircleRadius,
                        width: smallCircleRadius * 2,
                        height: smallCircleRadius * 2
                    )
                    path.addEllipse(in: circleRect)
                } else {
                    let dotRect = CGRect(
                        x: x + offset - largeCircleRadius,
                        y: y - largeCircleRadius,
                        width: largeCircleRadius * 2,
                        height: largeCircleRadius * 2
                    )
                    path.addEllipse(in: dotRect)
                }
            }
        }
        
        return path
    }
}


struct TimeframeSelector: View {
    @Binding var selected: Timeframe
    let accentColor: Color
    
    var body: some View {
        Menu {
            Picker("Timeframe", selection: $selected) {
                ForEach(Timeframe.allCases, id: \.self) { timeframe in
                    Text(timeframe.displayText)
                        .tag(timeframe)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text(selected.displayText.lowercased())
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(accentColor)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(accentColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct TrendCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .tracking(1.5)
                .foregroundColor(Color(.systemGray))
            
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(12)
    }
}



struct TopicsAnalysisView: View {
    let accentColor: Color
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(["Work", "Relationships", "Personal Growth"], id: \.self) { topic in
                VStack(spacing: 8) {
                    HStack {
                        Text(topic)
                            .font(.system(size: 15, weight: .medium))
                        Spacer()
                        Text("\([85, 70, 60][getIndex(of: topic)])%")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(.systemGray))
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [accentColor, accentColor.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width *
                                      CGFloat([85, 70, 60][getIndex(of: topic)]) / 100)
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
    }
    
    private func getIndex(of topic: String) -> Int {
        ["Work", "Relationships", "Personal Growth"].firstIndex(of: topic) ?? 0
    }
}

struct WritingPatternsCard: View {
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Key insight about writing depth
            HStack(spacing: 16) {
                Image(systemName: "text.quote")
                    .font(.system(size: 24))
                    .foregroundColor(accentColor)
                
                Text("You share most openly in the evening")
                    .font(.system(size: 15))
                    .foregroundColor(Color(.systemGray))
            }
            
            // Writing length patterns
            VStack(alignment: .leading, spacing: 16) {
                Text("Your reflection length")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(.systemGray))
                
                HStack(spacing: 12) {
                    ForEach(["Morning", "Afternoon", "Evening"], id: \.self) { time in
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [accentColor, accentColor.opacity(0.7)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: timeHeight(for: time))
                            
                            Text(time)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(.systemGray))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 100)
            }
            
            // Simple stat
            VStack(alignment: .leading, spacing: 4) {
                Text("250")
                    .font(.system(size: 32, weight: .light))
                Text("words on average")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(.systemGray))
            }
        }
    }
    
    private func timeHeight(for time: String) -> CGFloat {
        switch time {
        case "Morning": return 50
        case "Afternoon": return 70
        case "Evening": return 90
        default: return 60
        }
    }
}

struct TimeOfDayCard: View {
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Best time highlight
            HStack(spacing: 16) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text("9PM")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your golden hour")
                        .font(.system(size: 17, weight: .medium))
                    Text("Most of your meaningful reflections happen in the evening")
                        .font(.system(size: 15))
                        .foregroundColor(Color(.systemGray))
                }
            }
        }
    }
}

struct KeyMomentsCardTrend: View {
    let accentColor: Color
    let moments = [
        "Growth": 8,
        "Gratitude": 6,
        "Connection": 5
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 16) {
                Image(systemName: "star.fill")
                    .font(.system(size: 24))
                    .foregroundColor(accentColor)
                
                Text("Your reflections often highlight moments of personal growth")
                    .font(.system(size: 15))
                    .foregroundColor(Color(.systemGray))
            }
            
            Text("Most mentioned in meaningful moments")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(.systemGray))
            
            VStack(spacing: 16) {
                ForEach(moments.sorted(by: { $0.value > $1.value }), id: \.key) { theme, count in
                    HStack {
                        Circle()
                            .fill(accentColor.opacity(0.2))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text("\(count)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(accentColor)
                            )
                        
                        Text(theme)
                            .font(.system(size: 15, weight: .medium))
                        
                        Spacer()
                    }
                }
            }
        }
    }
}

struct CompletionPatternsCard: View {
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Current streak
            VStack(alignment: .leading, spacing: 4) {
                Text("8")
                    .font(.system(size: 32, weight: .light))
                Text("day reflection streak")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(.systemGray))
            }
            
            HStack(spacing: 16) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 24))
                    .foregroundColor(accentColor)
                
                Text("Most consistent in the evenings after dinner")
                    .font(.system(size: 15))
                    .foregroundColor(Color(.systemGray))
            }
            
            // Weekly completion dots
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(0..<14) { index in
                    Circle()
                        .fill(index % 3 == 0 ? accentColor : accentColor.opacity(0.2))
                        .frame(width: 12, height: 12)
                }
            }
        }
    }
}

struct TopicDetailCard: View {
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 16) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 24))
                    .foregroundColor(accentColor)
                
                Text("You're most expressive when reflecting on relationships")
                    .font(.system(size: 15))
                    .foregroundColor(Color(.systemGray))
            }
            
            // Topic length comparison
            ForEach(["Relationships", "Work", "Goals"], id: \.self) { topic in
                VStack(alignment: .leading, spacing: 8) {
                    Text(topic)
                        .font(.system(size: 15, weight: .medium))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(accentColor.opacity(0.2))
                        .frame(height: 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(accentColor)
                                .frame(width: getWidth(for: topic)),
                            alignment: .leading
                        )
                }
            }
        }
    }
    
    private func getWidth(for topic: String) -> CGFloat {
        switch topic {
        case "Relationships": return 200
        case "Work": return 150
        case "Goals": return 100
        default: return 100
        }
    }
}

// MARK: - Mock Data Structures
struct MockMoodData {
    static let moodEntries: [(date: Date, rating: Double, words: Int)] = [
        (Calendar.current.date(byAdding: .day, value: -6, to: Date())!, 7.0, 250),
        (Calendar.current.date(byAdding: .day, value: -5, to: Date())!, 6.5, 180),
        (Calendar.current.date(byAdding: .day, value: -4, to: Date())!, 8.0, 300),
        (Calendar.current.date(byAdding: .day, value: -3, to: Date())!, 7.5, 220),
        (Calendar.current.date(byAdding: .day, value: -2, to: Date())!, 8.5, 275),
        (Calendar.current.date(byAdding: .day, value: -1, to: Date())!, 7.0, 190),
        (Date(), 8.0, 260)
    ]
    
    static let topics = [
        ("Family", 12, 0.85),
        ("Exercise", 8, 0.75),
        ("Reading", 15, 0.82),
        ("Nature", 6, 0.90),
        ("Music", 10, 0.78),
        ("Art", 7, 0.85)
    ]
    
    static let challenges = [
        ("Work Stress", 8, 0.45),
        ("Conflict", 5, 0.35),
        ("Health", 6, 0.40),
        ("Sleep Issues", 7, 0.38),
        ("Travel", 4, 0.42),
        ("Deadlines", 9, 0.36)
    ]
    
    static let writingPatterns = [
        ("Morning", 50, 180),
        ("Afternoon", 70, 220),
        ("Evening", 90, 280)
    ]
}

// MARK: - Preview Helpers
extension MoodAnalysisView {
    static var mock: some View {
        MoodAnalysisView(timeframe: .constant(.week))
            .environmentObject(MockMoodStore())
    }
}

// MARK: - Mock Environment Objects
class MockMoodStore: ObservableObject {
    @Published var moodEntries = MockMoodData.moodEntries
    @Published var topics = MockMoodData.topics
    @Published var challenges = MockMoodData.challenges
    @Published var writingPatterns = MockMoodData.writingPatterns
    
    var averageMood: Double {
        moodEntries.map { $0.rating }.reduce(0, +) / Double(moodEntries.count)
    }
    
    var totalWords: Int {
        moodEntries.map { $0.words }.reduce(0, +)
    }
}

// MARK: - Preview Extension for TrendsView
extension TrendsView {
    static var mock: some View {
        let mockStore = MockMoodStore()
        return TrendsView(pageType: .constant(.trends), selectedTimeframe: .constant(.week))
            .environmentObject(mockStore)
    }
}

// MARK: - Updated Preview Provider
struct TrendsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light mode preview
            NavigationView {
                TrendsView.mock
                    .navigationBarTitleDisplayMode(.inline)
            }
            .previewDisplayName("Light Mode")
            
            // Dark mode preview
            NavigationView {
                TrendsView.mock
                    .navigationBarTitleDisplayMode(.inline)
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
            
            // iPhone SE preview for smaller screens
            NavigationView {
                TrendsView.mock
                    .navigationBarTitleDisplayMode(.inline)
            }
            .previewDevice("iPhone SE (3rd generation)")
            .previewDisplayName("iPhone SE")
        }
    }
}

// MARK: - Mock Extensions for Child Views
extension MoodSection {
    static var mock: some View {
        MoodSection(timeframe: .constant(.week), pageType: .constant(.home))
            .environmentObject(MockMoodStore())
    }
}

//extension SleepMoodCard {
//    static var mock: some View {
//        SleepMoodCard()
//            .environmentObject(MockMoodStore())
//    }
//}
//
//extension TrendsTopicsCard {
//    static var mock: some View {
//        TrendsTopicsCard()
//            .environmentObject(MockMoodStore())
//    }
//}
//
//extension TrendsTopicChallengesCard {
//    static var mock: some View {
//        TrendsTopicChallengesCard()
//            .environmentObject(MockMoodStore())
//    }
//}

// MARK: - Preview Context Extension
extension View {
    func withMockData() -> some View {
        self.environmentObject(MockMoodStore())
    }
}

// Individual component previews
struct MoodSection_Previews: PreviewProvider {
    static var previews: some View {
        MoodSection.mock
            .padding()
            .previewLayout(.sizeThatFits)
    }
}

struct MoodGraph_Previews: PreviewProvider {
    static var previews: some View {
        MoodAnalysisView.mock
            .padding()
            .previewLayout(.sizeThatFits)
    }
}

struct MoodShapePreview: View {
    private let textColor = Color(hex: "2C3E50")
    private let moodRating = 8.5 // Static test data
    
    private var moodColor: Color {
        if moodRating <= 5 {
            let t = (moodRating - 1) / 4
            return interpolateColor(from: Color(hex: "1E3D59"), to: Color(hex: "94A7B7"), with: t)
        } else {
            let t = (moodRating - 5) / 5
            return interpolateColor(from: Color(hex: "94A7B7"), to: Color(hex: "B784A7"), with: t)
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text("MOOD JOURNEY")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.5))
                
                Spacer()
                
                Button(action: {
                    
                }, label: {
                    Text("see more")
                        .font(.system(size: 12, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(textColor.opacity(0.5))
                })
            }
            
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("you've been")
                        .font(.system(size: 17))
                        .foregroundColor(textColor)
                    
                    Text("feeling great")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(textColor)
                }
                
                Spacer()
                
                MoodShape(rating: moodRating)
                    .fill(moodColor)
                    .frame(width: 120, height: 120)
            }
        }
        .padding(24)
        .background(
            ZStack {
                Color.white
                
//                // Subtle background pattern
//                MoodGeometricPattern()
//                    .opacity(0.3)
////                    .stroke(moodColor.opacity(0.05), lineWidth: 0.5)
            }
        )
        .cornerRadius(10)
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
        
        // Higher ratings create more upward, expansive shapes
        // Lower ratings create more downward, contained shapes
        let normalizedRating = (rating - 1) / 9 // 0 to 1
        
        // Create control points that vary based on the mood
        let points = (0...5).map { i -> CGPoint in
            let angle = 2 * .pi * Double(i) / 5
            let radiusVariation = sin(angle * 2) * 0.2 + 1 // Varies radius by ±20%
            let radius = rect.width/2 * radiusVariation * (0.7 + normalizedRating * 0.3)
            
            // Add some vertical bias based on mood
            let moodOffset = (normalizedRating - 0.5) * rect.height * 0.2
            
            return CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius + moodOffset
            )
        }
        
        // Create a smooth path through the points
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

struct MoodGeometricPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 40
        
        for row in 0...Int(rect.height/spacing) {
            for col in 0...Int(rect.width/spacing) {
                let offset = row % 2 == 0 ? spacing/2 : 0
                let x = CGFloat(col) * spacing + offset
                let y = CGFloat(row) * spacing
                
                if (row + col) % 2 == 0 {
                    path.move(to: CGPoint(x: x - 2, y: y))
                    path.addLine(to: CGPoint(x: x + 2, y: y))
                } else {
                    let dotRect = CGRect(x: x - 1, y: y - 1, width: 2, height: 2)
                    path.addEllipse(in: dotRect)
                }
            }
        }
        
        return path
    }
}

struct MoodShapePreview_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(hex: "F5F5F5")
                .ignoresSafeArea()
            
            MoodShapePreview()
                .padding()
        }
    }
}
//struct SleepMoodCard_Previews: PreviewProvider {
//    static var previews: some View {
//        SleepMoodCard.mock
//            .padding()
//            .previewLayout(.sizeThatFits)
//    }
//}
//
//struct TrendsTopicsCard_Previews: PreviewProvider {
//    static var previews: some View {
//        TrendsTopicsCard.mock
//            .padding()
//            .previewLayout(.sizeThatFits)
//    }
//}
//
//struct TrendsTopicChallengesCard_Previews: PreviewProvider {
//    static var previews: some View {
//        TrendsTopicChallengesCard.mock
//            .padding()
//            .previewLayout(.sizeThatFits)
//    }
//}
