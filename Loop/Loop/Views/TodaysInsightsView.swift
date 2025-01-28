//
//  TodaysInsightsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/27/24.
//

import SwiftUI

struct TodaysInsightsView: View {
    @ObservedObject var analysisManager = AnalysisManager.shared
    @ObservedObject private var checkinManager = DailyCheckinManager.shared
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    private let coolBlue = Color(hex: "B5D5E2")
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ReflectionMetricsCard(analysis: analysisManager.currentDailyAnalysis)

                TodaysMoodCard(rating: checkinManager.getAverageDailyRating())
            
                if let analysis = analysisManager.currentDailyAnalysis?.aiAnalysis,
                   let standoutAnalysis = analysis.standoutAnalysis {
                    if standoutAnalysis.exists,
                       let moment = standoutAnalysis.keyMoment,
                       let topic = standoutAnalysis.primaryTopic {
                        // Filled state
                        KeyMomentCard(moment: moment, topic: topic)
                    } else {
                        // Empty state - no moment selected yet
                        KeyMomentCard(moment: nil, topic: nil)
                    }
                } else {
                    // No analysis available yet
                    KeyMomentCard(moment: nil, topic: nil)
                }
                
                FollowUpCard()

                SleepCard()
                
//                if let analysis = analysisManager.currentDailyAnalysis?.aiAnalysis {
//                    FillerWordsCard(analysis: analysis)
//                }

//                
                // Additional Insights
                if let analysis = analysisManager.currentDailyAnalysis,
                   let additionalMoments = analysis.aiAnalysis.additionalKeyMoments?.moments,
                   !additionalMoments.isEmpty {
                    AdditionalInsightsCard(moments: additionalMoments)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .background(Color(hex: "F5F5F5"))
    }
}

struct TodaysMoodCard: View {
    let rating: Double?
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var moodColor: Color {
        guard let rating = rating else { return Color(hex: "94A7B7") }
        if rating <= 5 {
            let t = (rating - 1) / 4
            return interpolateColor(from: Color(hex: "1E3D59"), to: Color(hex: "94A7B7"), with: t)
        } else {
            let t = (rating - 5) / 5
            return interpolateColor(from: Color(hex: "94A7B7"), to: Color(hex: "B784A7"), with: t)
        }
    }
    
    var moodLabel: String {
        guard let rating = rating else { return "okay" }
        switch rating {
        case 0...3: return "feeling down"
        case 3...4: return "not great"
        case 4...6: return "okay"
        case 6...8: return "pretty good"
        case 8...10: return "feeling great"
        default: return "okay"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header section
            HStack(spacing: 12) {
                Circle()
                    .fill(moodColor)
                    .frame(width: 8, height: 8)
                
                Text("Today's Mood")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.5))
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)
            
            if let rating = rating {
                // Content section with mood
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("you've been")
                            .font(.system(size: 17))
                            .foregroundColor(textColor.opacity(0.7))
                        
                        Text(moodLabel)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(textColor)
                    }
                    
                    Spacer()
                    
                    MoodShape(rating: rating)
                        .fill(moodColor)
                        .frame(width: 110, height: 110)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            } else {
                // Empty state
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("complete a check-in")
                            .font(.system(size: 17))
                            .foregroundColor(textColor.opacity(0.7))
                        
                        Text("to track your mood")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(textColor)
                    }
                    
                    Spacer()
                    
                    MoodShape(rating: 5.0)
                        .fill(Color(hex: "94A7B7"))
                        .opacity(0.5)
                        .frame(width: 110, height: 110)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .background(
            ZStack {
                Color.white
                
                // Extremely subtle organic pattern
                OrganicMoodPattern(rating: rating ?? 5.0)
                    .stroke(moodColor, lineWidth: 0.5)
                    .opacity(0.04)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.black.opacity(0.03), lineWidth: 1)
        )
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

struct OrganicMoodPattern: Shape {
    let rating: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.width * 0.7, y: rect.height * 0.5)
        
        // Create organic, flowing lines based on mood
        let points = 6
        let radius = min(rect.width, rect.height) * 0.4
        let variation = rating > 5 ? 0.3 : 0.15 // More dynamic for positive moods
        
        for i in 0..<points {
            let angle = Double(i) * 2 * .pi / Double(points)
            let nextAngle = Double(i + 1) * 2 * .pi / Double(points)
            
            let point = CGPoint(
                x: center.x + cos(angle) * radius * (1 + Double.random(in: -variation...variation)),
                y: center.y + sin(angle) * radius * (1 + Double.random(in: -variation...variation))
            )
            
            let nextPoint = CGPoint(
                x: center.x + cos(nextAngle) * radius * (1 + Double.random(in: -variation...variation)),
                y: center.y + sin(nextAngle) * radius * (1 + Double.random(in: -variation...variation))
            )
            
            let control1 = CGPoint(
                x: point.x + cos(angle + .pi/2) * radius * variation,
                y: point.y + sin(angle + .pi/2) * radius * variation
            )
            
            let control2 = CGPoint(
                x: nextPoint.x - cos(nextAngle + .pi/2) * radius * variation,
                y: nextPoint.y - sin(nextAngle + .pi/2) * radius * variation
            )
            
            if i == 0 {
                path.move(to: point)
            }
            path.addCurve(to: nextPoint, control1: control1, control2: control2)
        }
        
        return path
    }
}

struct KeyMomentCard: View {
    let moment: String?
    let topic: TopicCategory?
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    private let coolBlue = Color(hex: "B5D5E2")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("What stood out to you")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.5))
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 20)
                
                Spacer()
            }
            
            if let moment = moment {
                VStack(alignment: .leading, spacing: 16) {
                    Text(moment)
                        .font(.system(size: 17))
                        .foregroundColor(textColor)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(topic?.rawValue.capitalized ?? "key")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(accentColor.opacity(0.1))
                        )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            } else {
                HStack(alignment: .center, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Share your Moment")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(textColor)
                        
                        Text("Share today's meaningful moment in your daily reflection")
                            .font(.system(size: 15))
                            .foregroundColor(textColor.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(coolBlue.opacity(0.15))
                            .frame(width: 90, height: 90)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(accentColor.opacity(0.15))
                            .frame(width: 40, height: 40)
                            .rotationEffect(.degrees(15))
                            .offset(x: -5, y: 5)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white)
                            .frame(width: 40, height: 40)
                            .rotationEffect(.degrees(-15))
                            .offset(x: 5, y: -5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(accentColor.opacity(0.3), lineWidth: 1.5)
                            )
                    }
                    .padding(.trailing, 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .background(
            ZStack {
                Color.white
                
                SparklePattern()
                    .stroke(accentColor, lineWidth: 0.5)
                    .opacity(moment != nil ? 0.04 : 0.02)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.black.opacity(0.03), lineWidth: 1)
        )
    }
}

struct SleepCard: View {
    @ObservedObject var sleepManager = SleepCheckinManager.shared
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    private let nightBlue = Color(hex: "B5D5E2")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Section
            HStack(spacing: 12) {
                Circle()
                    .fill(nightBlue)
                    .frame(width: 8, height: 8)
                
                Text("Last Night's Rest")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.5))
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)
            
            if let hours = sleepManager.todaysSleep?.hours {
                HStack(alignment: .center, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("you slept for")
                            .font(.system(size: 17))
                            .foregroundColor(textColor.opacity(0.7))
                        
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("\(Int(hours))")
                                .font(.system(size: 34, weight: .medium))
                                .foregroundColor(textColor)
                            
                            Text("hours")
                                .font(.system(size: 17))
                                .foregroundColor(textColor.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                     
                    ZStack {
                        Circle()
                            .stroke(nightBlue.opacity(0.15), lineWidth: 6)
                            .frame(width: 90, height: 90)
                        
//                        Circle()
//                            .trim(from: 0, to: min(CGFloat(hours/12), 1))
//                            .stroke(nightBlue, lineWidth: 6)
//                            .frame(width: 90, height: 90)
//                            .rotationEffect(.degrees(-90))
                        
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 30))
                            .foregroundColor(nightBlue)
                            .scaleEffect(x: -1)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            } else {
                // Empty State
                HStack(alignment: .center, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Track Your Rest")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(textColor)
                        
                        Text("Add your hours of sleep in a check-in")
                            .font(.system(size: 15))
                            .foregroundColor(textColor.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(nightBlue.opacity(0.15))
                            .frame(width: 90, height: 90)
                        
                        Image(systemName: "moon.fill")
                            .font(.system(size: 37))
                            .foregroundColor(Color.white)
                            .scaleEffect(x: -1)
                            .opacity(0.95)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .background(
            ZStack {
                Color.white
                
                // Subtle star pattern
                StarryPattern()
                    .stroke(nightBlue, lineWidth: 0.5)
                    .opacity(0.04)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.black.opacity(0.03), lineWidth: 1)
        )
    }
}

struct StarryPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 40
        
        for row in 0...Int(rect.height/spacing) {
            for col in 0...Int(rect.width/spacing) {
                let x = CGFloat(col) * spacing
                let y = CGFloat(row) * spacing
                let offset = row % 2 == 0 ? spacing/2 : 0
                
                if (row + col) % 2 == 0 {
                    // Small star
                    let center = CGPoint(x: x + offset, y: y)
                    for i in 0..<4 {
                        let angle = Double(i) * .pi / 2
                        let length: CGFloat = 2
                        path.move(to: center)
                        path.addLine(to: CGPoint(
                            x: center.x + Darwin.cos(angle) * length,
                            y: center.y + Darwin.sin(angle) * length
                        ))
                    }
                } else {
                    // Dot
                    path.addEllipse(in: CGRect(
                        x: x + offset - 1,
                        y: y - 1,
                        width: 2,
                        height: 2
                    ))
                }
            }
        }
        
        return path
    }
}

struct ReflectionMetricsCard: View {
    let analysis: DailyAnalysis?
    private let accentColor = Color(hex: "94A3B8")
    
    @State private var isAppearing = false
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 32) {
                // Elegant header
                Text("OVERVIEW")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(4)
                    .foregroundColor(accentColor)
                    .padding(.top, 28)
                
                // Metrics display
                HStack(spacing: 45) {
                    // Entries metric with elegant styling
                    MetricDisplay(
                        value: "\(AnalysisManager.shared.currentDayMetrics?.entryCount ?? 0)",
                        label: "entries",
                        alignment: .leading,
                        isAppearing: isAppearing
                    )
                    
                    // Subtle divider
                    Rectangle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 1, height: 60)
                    
                    // Words metric with elegant styling
                    MetricDisplay(
                        value: "\(analysis?.quantitativeMetrics.totalWordCount ?? 0)",
                        label: "words",
                        alignment: .trailing,
                        isAppearing: isAppearing
                    )
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .background(
            ZStack {
                // Elegant gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white,
                        Color(hex: "F8FAFC")
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Subtle pattern overlay
                GeometryReader { geometry in
                    Path { path in
                        let width = geometry.size.width
                        let height = geometry.size.height
                        let spacing: CGFloat = 20
                        
                        for x in stride(from: 0, through: width, by: spacing) {
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: height))
                        }
                        
                        for y in stride(from: 0, through: height, by: spacing) {
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: width, y: y))
                        }
                    }
                    .stroke(accentColor, lineWidth: 0.2)
                    .opacity(0.1)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: Color.black.opacity(0.03), radius: 20, x: 0, y: 10)
        .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAppearing = true
            }
        }
    }
}

struct MetricDisplay: View {
    let value: String
    let label: String
    let alignment: HorizontalAlignment
    let isAppearing: Bool
    
    var body: some View {
        VStack(alignment: alignment, spacing: 8) {
            Text(value)
                .font(.system(size: 44, weight: .light))
                .opacity(isAppearing ? 1 : 0)
                .offset(y: isAppearing ? 0 : 20)
            
            Text(label)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color(hex: "94A3B8").opacity(0.8))
                .opacity(isAppearing ? 1 : 0)
                .offset(y: isAppearing ? 0 : 10)
        }
        .frame(maxWidth: .infinity)
    }
}

struct RefinedLinePattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let lineSpacing: CGFloat = 60
        let lineLength: CGFloat = 30
        
        for x in stride(from: -lineLength, through: rect.width + lineLength, by: lineSpacing) {
            for y in stride(from: -lineLength, through: rect.height + lineLength, by: lineSpacing) {
                let startPoint = CGPoint(x: x, y: y)
                path.move(to: startPoint)
                path.addLine(to: CGPoint(x: x + lineLength, y: y + lineLength))
            }
        }
        
        return path
    }
}

struct MetricsLinePattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let lineSpacing: CGFloat = 80
        let lineLength: CGFloat = 40
        
        for x in stride(from: 0, through: rect.width, by: lineSpacing) {
            for y in stride(from: 0, through: rect.height, by: lineSpacing) {
                let startPoint = CGPoint(x: x, y: y)
                path.move(to: startPoint)
                path.addLine(to: CGPoint(x: x + lineLength, y: y + lineLength))
            }
        }
        
        return path
    }
}

struct WordsPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 40
        
        for row in 0...Int(rect.height/spacing) {
            for col in 0...Int(rect.width/spacing) {
                let x = CGFloat(col) * spacing
                let y = CGFloat(row) * spacing
                let offset = row % 2 == 0 ? spacing/2 : 0
                
                if (row + col) % 2 == 0 {
                    path.move(to: CGPoint(x: x + offset - 4, y: y))
                    path.addLine(to: CGPoint(x: x + offset + 4, y: y))
                } else {
                    path.move(to: CGPoint(x: x + offset, y: y - 4))
                    path.addLine(to: CGPoint(x: x + offset, y: y + 4))
                }
            }
        }
        
        return path
    }
}

struct AdditionalInsightsCard: View {
    let moments: [KeyMomentModel]
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        ZStack {
            DiagonalPattern()
                .stroke(accentColor.opacity(0.1), lineWidth: 1)
            
            VStack(alignment: .leading, spacing: 24) {
                Text("MORE INSIGHTS")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.5))
                
                VStack(spacing: 20) {
                    ForEach(moments, id: \.keyMoment) { moment in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(moment.category.rawValue.uppercased())
                                .font(.system(size: 11, weight: .medium))
                                .tracking(1.5)
                                .foregroundColor(accentColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(accentColor.opacity(0.1))
                                )
                            
                            Text(moment.keyMoment)
                                .font(.system(size: 16))
                                .foregroundColor(textColor)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.white)
                                        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                                )
                        }
                        
                        if moment.keyMoment != moments.last?.keyMoment {
                            Rectangle()
                                .fill(accentColor.opacity(0.1))
                                .frame(height: 1)
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 4)
    }
}

struct FollowUpCard: View {
    @ObservedObject var analysisManager = AnalysisManager.shared
    @State private var showingFollowUp = false
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    private let coolBlue = Color(hex: "B5D5E2")
    
    var followUpPrompt: String? {
        analysisManager.currentDailyAnalysis?.aiAnalysis.followUpSuggestion.suggestion
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header section
            HStack(spacing: 12) {
                Circle()
                    .fill(coolBlue)
                    .frame(width: 8, height: 8)
                
                Text("Further Reflection")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.5))
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)
            
            if let prompt = followUpPrompt {
                VStack(alignment: .leading, spacing: 16) {
                    Text(prompt)
                        .font(.system(size: 17))
                        .foregroundColor(textColor)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if !analysisManager.isFollowUpCompleted {
                        Button(action: {
                            showingFollowUp = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "mic.circle.fill")
                                    .font(.system(size: 20))
                                Text("Record Follow-up")
                                    .font(.system(size: 15, weight: .medium))
                            }
                            .foregroundColor(accentColor)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(accentColor.opacity(0.1))
                            )
                        }
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                            Text("Completed")
                                .font(.system(size: 15))
                        }
                        .foregroundColor(Color.gray.opacity(0.6))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            } else {
                // Empty state
                VStack(alignment: .leading, spacing: 12) {
                    Text("Further Reflection")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(textColor)
                    
                    Text("Complete your daily reflection to unlock a personalized follow-up prompt")
                        .font(.system(size: 15))
                        .foregroundColor(textColor.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .background(
            ZStack {
                Color.white
                
                // Evening sky-inspired pattern
                EveningPattern()
                    .stroke(coolBlue, lineWidth: 0.5)
                    .opacity(0.04)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.black.opacity(0.03), lineWidth: 1)
        )
        .fullScreenCover(isPresented: $showingFollowUp) {
            if let prompt = followUpPrompt {
                RecordFollowUpLoopView(prompt: prompt)
            }
        }
    }
}

// Evening pattern for the card background
struct EveningPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 40
        let starCount = 12
        
        // Create a scattered star pattern
        for _ in 0..<starCount {
            let x = CGFloat.random(in: 0...rect.width)
            let y = CGFloat.random(in: 0...rect.height)
            let size = CGFloat.random(in: 2...4)
            
            // Draw a small star
            let starPath = Path { p in
                for i in 0..<5 {
                    let angle = Double(i) * .pi * 2 / 5
                    let point = CGPoint(
                        x: x + cos(angle) * size,
                        y: y + sin(angle) * size
                    )
                    if i == 0 {
                        p.move(to: point)
                    } else {
                        p.addLine(to: point)
                    }
                }
                p.closeSubpath()
            }
            path.addPath(starPath)
        }
        
        // Add some gentle waves
        for y in stride(from: 0, through: rect.height, by: spacing) {
            var currentPath = Path()
            currentPath.move(to: CGPoint(x: 0, y: y))
            
            for x in stride(from: 0, through: rect.width, by: 2) {
                let yOffset = 4 * sin(x / 20 + Double(y))
                currentPath.addLine(to: CGPoint(x: x, y: y + yOffset))
            }
            
            path.addPath(currentPath)
        }
        
        return path
    }
}

struct EmptyMoodCard: View {
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack (alignment: .leading, spacing: 4) {
                HStack {
                    Text("How You're Feeling")
                        .font(.system(size: 18, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(textColor)
                    
                    Spacer()
                }
                
                Text("Mood check-ins from today")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Complete check-ins for insights")
                    .font(.system(size: 17))
                    .foregroundColor(textColor.opacity(0.6))
                    .lineSpacing(4)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.white
        )
        .cornerRadius(10)
    }
}

struct EmptyKeyMomentCard: View {
    let hasCompletedToday: Bool
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack (alignment: .leading, spacing: 4) {
                Text("What Stood Out")
                    .font(.system(size: 18, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor)
                
                Text("You chose to focus on...")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.5))
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text(hasCompletedToday ? "Tomorrow's reflection awaits" : "Share today's highlights")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(textColor)
                
                Text(hasCompletedToday ?
                     "Return tomorrow to uncover new moments" :
                     "Complete your daily reflection to capture key moments"
                )
                    .font(.system(size: 17))
                    .foregroundColor(textColor.opacity(0.6))
                    .lineSpacing(4)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.white
        )
        .cornerRadius(10)
    }
}


// Helper Views for Patterns
struct DiagonalPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 24
        
        for x in stride(from: 0, through: rect.width + rect.height, by: spacing) {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x - rect.height, y: rect.height))
        }
        
        return path
    }
}

struct InsightsWavePattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 20
        let amplitude: CGFloat = 4
        
        for x in stride(from: 0, through: rect.width, by: 2) {
            let y = amplitude * sin(x / spacing)
            if x == 0 {
                path.move(to: CGPoint(x: x, y: rect.height/2 + y))
            } else {
                path.addLine(to: CGPoint(x: x, y: rect.height/2 + y))
            }
        }
        
        return path
    }
}

struct MetricBar: View {
    let value: Double
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: 2)
                .fill(accentColor.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .fill(accentColor)
                        .frame(width: geometry.size.width * value)
                    , alignment: .leading
                )
        }
    }
}

struct GeometryPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 40
        let size: CGFloat = 3
        
        for row in stride(from: 0, through: rect.height, by: spacing) {
            for col in stride(from: 0, through: rect.width, by: spacing) {
                let rect = CGRect(x: col, y: row, width: size, height: size)
                path.addRect(rect)
            }
        }
        
        return path
    }
}
