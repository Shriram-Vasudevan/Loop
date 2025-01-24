//
//  TrendsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/28/24.
//



import SwiftUI


struct TrendsView: View {
    @State private var selectedTimeframe: Timeframe = .week
    
    private let accentColor = Color(hex: "A28497")    // Mauve
    private let secondaryColor = Color(hex: "1E3D59") // Deep blue
    private let textColor = Color(hex: "2C3E50")      // Text color
    private let backgroundColor = Color(hex: "F5F5F5") // Background
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                VStack (spacing: 24){
                    headerSection
                        .padding(.top, 16)
//                    
                    MoodAnalysisView(timeframe: $selectedTimeframe)
                }
                .padding(.horizontal, 24)
                
                MoodSection(timeframe: $selectedTimeframe)
                       .padding(.horizontal, 24)
            }
        }
        .background(backgroundColor)
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
    
    // Example data - replace with actual data source
    private let totalEntries = 127
    private let totalWords = 23_842
    
    var body: some View {
        ZStack {
            // Background
            Color.white
                .cornerRadius(10)
            
            HStack(spacing: 0) {
                // Total Entries
                StatBox(
                    label: "TOTAL ENTRIES",
                    value: "\(totalEntries)",
                    textColor: textColor
                )
                
                // Divider
                Rectangle()
                    .fill(textColor.opacity(0.1))
                    .frame(width: 1)
                    .padding(.vertical, 24)
                
                // Total Words
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

// Helper view for each stat box
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
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    // Test data
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
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("PAST FEW DAYS")
                                .font(.system(size: 13, weight: .medium))
                                .tracking(1.5)
                                .foregroundColor(textColor.opacity(0.5))
                            Spacer()
                        }
                        
                        Text("you've been feeling pretty good")
                            .font(.system(size: 17))
                            .foregroundColor(textColor)
                        
                        HStack(spacing: 8) {
                            ForEach(0..<7) { index in
                                Circle()
                                    .stroke(Color(hex: "2C3E50").opacity(0.1), lineWidth: 1)
                                    .background(
                                        Circle()
                                            .fill(getColor(for: weekData[index]))
                                    )
                                    .frame(width: 28, height: 28)
                            }
                        }
                        
                        Button(action: {}) {
                            Text("see more")
                                .font(.system(size: 15))
                                .foregroundColor(textColor.opacity(0.5))
                        }
                    }
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(10)
                    
                    SleepMoodCard()
                    
                    TrendsTopicsCard()
                    
                    TrendsTopicChallengesCard()
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

struct SleepMoodCard: View {
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    // Test data
    private let avgSleepHours = 7.5
    private let moodCorrelation = 0.75
    
    var body: some View {
        ZStack {
            // Geometric Sleep Pattern Background
            SleepWavePattern()
                .fill(accentColor.opacity(0.05))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Content
            VStack(alignment: .leading, spacing: 20) {
                Text("SLEEP & MOOD")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.5))
                
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("better sleep = better mood")
                            .font(.system(size: 17))
                            .foregroundColor(textColor)
                        
                        Text("Your mood improves by 30% with 7+ hours")
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
        }
        .background(Color.white)
        .cornerRadius(10)
    }
}

struct SleepWavePattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Create two overlapping wave patterns
        let waves = 2
        let amplitudes = [rect.height * 0.15, rect.height * 0.1] // Different heights for each wave
        let frequencies = [1.0, 1.5] // Different frequencies for variation
        let yOffsets = [rect.height * 0.6, rect.height * 0.7] // Position waves near bottom
        
        for wave in 0..<waves {
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            
            // Create smooth wave curve
            let points = 100
            for point in 0...points {
                let x = rect.width * CGFloat(point) / CGFloat(points)
                let progressiveAmplitude = amplitudes[wave] * (1 - CGFloat(point) / CGFloat(points)) // Gradually decrease amplitude
                let y = yOffsets[wave] + sin(CGFloat(point) / CGFloat(points) * .pi * 2 * frequencies[wave]) * progressiveAmplitude
                
                if point == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            
            // Complete the wave shape
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.closeSubpath()
        }
        
        return path
    }
}

struct TrendsTopicsCard: View {
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    private let topics = ["Family", "Exercise", "Reading", "Nature", "Music", "Art"]
    
    var body: some View {
        ZStack {
            // New Geometric Pattern Background
            TopicsPatternBackground()
                .fill(accentColor.opacity(0.05))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Content
            VStack(alignment: .leading, spacing: 20) {
                Text("WHAT LIFTS YOU UP")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.5))
                
                Text("Your reflections are most positive when discussing:")
                    .font(.system(size: 17))
                    .foregroundColor(textColor)
                
                // Horizontal scrolling topics
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(topics, id: \.self) { topic in
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
                    .padding(.horizontal, 2) // Offset for parent padding
                }
            }
            .padding(24)
        }
        .background(Color.white)
        .cornerRadius(10)
    }
}

struct TrendsTopicChallengesCard: View {
    private let textColor = Color(hex: "2C3E50")
    private let coolBlue = Color(hex: "B5D5E2")
    
    private let challenges = ["Work Stress", "Conflict", "Health", "Sleep Issues", "Travel", "Deadlines"]
    
    var body: some View {
        ZStack {
            // Geometric Pattern Background
            TopicsPatternBackground()
                .fill(coolBlue.opacity(0.05))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Content
            VStack(alignment: .leading, spacing: 20) {
                Text("WHAT KEEPS YOU DOWN")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.5))
                
                Text("Your reflections show more difficulty when dealing with:")
                    .font(.system(size: 17))
                    .foregroundColor(textColor)
                
                // Horizontal scrolling challenges
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(challenges, id: \.self) { challenge in
                            Text(challenge)
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
                    .padding(.horizontal, 2) // Offset for parent padding
                }
            }
            .padding(24)
        }
        .background(Color.white)
        .cornerRadius(10)
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

struct TrendsView_Previews: PreviewProvider {
    static var previews: some View {
        TrendsView()
            
    }
}
