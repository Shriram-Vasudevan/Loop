//
//  InsightsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/7/24.
//

import SwiftUI
import Charts


struct InsightsView: View {
    @ObservedObject var analysisManager = AnalysisManager.shared
    @State private var scrollOffset: CGFloat = 0
    @State private var showingComparison = false
    @State private var animateIn = false
    @State private var selectedSection: InsightSection = .speaking
    
    let accentColor = Color(hex: "A28497")
    let backgroundColor = Color(hex: "FAFBFC")
    let surfaceColor = Color(hex: "F8F5F7")
    let textColor = Color(hex: "2C3E50")
    
    enum InsightSection: String, CaseIterable {
        case speaking = "Speaking Flow"
        case expression = "Self Expression"
    }
    
    var body: some View {
        ZStack {
            FlowingBackground()
                .opacity(0.7)
                .ignoresSafeArea()
            
            ScrollView {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: ScrollOffsetKey.self,
                        value: proxy.frame(in: .named("scroll")).minY
                    )
                }
                .frame(height: 0)
                
                VStack(spacing: 32) {
                    headerSection
                    
                    if let analysis = analysisManager.currentLoopAnalysis {
                        mainContent(analysis)
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetKey.self) { offset in
                scrollOffset = offset
            }
        }
        .background(backgroundColor)
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                animateIn = true
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Insights")
                    .font(.system(size: 40, weight: .ultraLight))
                    .foregroundColor(textColor)
                Text("Your reflection patterns")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(textColor.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(animateIn ? 1 : 0)
            .offset(y: animateIn ? 0 : 20)
            
            if analysisManager.currentLoopAnalysis != nil {
                sectionPicker
            }
        }
    }
    
    private var sectionPicker: some View {
        HStack(spacing: 0) {
            ForEach(InsightSection.allCases, id: \.self) { section in
                Button(action: {
                    withAnimation(.spring()) {
                        selectedSection = section
                    }
                }) {
                    Text(section.rawValue)
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(selectedSection == section ? .white : accentColor)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(selectedSection == section ? accentColor : accentColor.opacity(0.1))
                        )
                }
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10)
        )
    }
    
    @ViewBuilder
    private func mainContent(_ analysis: LoopAnalysis) -> some View {
        VStack(spacing: 32) {
            switch selectedSection {
            case .speaking:
                SpeakingFlowSection(
                    speechPattern: analysis.speechPattern,
                    scrollOffset: scrollOffset
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                
            case .expression:
                SelfExpressionSection(
                    selfReference: analysis.selfReference,
                    scrollOffset: scrollOffset
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            FloatingSparkles()
                .frame(width: 120, height: 120)
            
            Text("Ready for reflection")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(textColor)
            
            Text("Record your first loop to see insights")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(textColor.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
    }
}

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct FlowingBackground: View {
    @State private var phase = 0.0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let rect = Path(CGRect(origin: .zero, size: size))
                context.clip(to: rect)
                
                let colors = [
                    Color(hex: "A28497").opacity(0.1),
                    Color(hex: "B7A284").opacity(0.1)
                ]
                
                let timeNow = timeline.date.timeIntervalSinceReferenceDate
                phase = timeNow.remainder(dividingBy: 10)
                
                let wavelength = size.width / 4
                let amplitude = size.height / 16
                let baseline = size.height * 0.5
                
                for i in 0..<2 {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: baseline))
                    
                    for x in stride(from: 0, through: size.width, by: 1) {
                        let relativeX = x / wavelength
                        let normalizedPhase = phase + Double(i) * .pi / 2
                        let y = baseline + sin(relativeX + normalizedPhase) * amplitude
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    
                    context.stroke(
                        path,
                        with: .color(colors[i]),
                        lineWidth: 2
                    )
                }
            }
        }
    }
}

struct FloatingSparkles: View {
    let particleCount = 15
    @State private var particles: [(CGPoint, Double)] = []
    
    var body: some View {
        TimelineView(.animation) { _ in
            Canvas { context, size in
                for (position, opacity) in particles {
                    context.opacity = opacity
                    context.draw(
                        Text("✧").font(.system(size: 12)),
                        at: position
                    )
                }
            }
            .onAppear {
                particles = (0..<particleCount).map { _ in
                    (
                        CGPoint(
                            x: .random(in: 0...100),
                            y: .random(in: 0...100)
                        ),
                        Double.random(in: 0.3...0.7)
                    )
                }
            }
        }
    }
}

struct SpeakingFlowSection: View {
    let speechPattern: SpeechPatternAnalysis
    let scrollOffset: CGFloat
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 24) {
            FlowingCard {
                VStack(spacing: 20) {
                    HStack(spacing: 24) {
                        SpeakingPaceRing(
                            wpm: speechPattern.wordsPerMinute,
                            scrollOffset: scrollOffset
                        )
                        .frame(width: 140, height: 140)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            PaceInsight(wpm: speechPattern.wordsPerMinute)
                            
                            Text("Words per minute")
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(textColor.opacity(0.6))
                        }
                    }
                    
                    Divider()
                        .background(accentColor.opacity(0.1))
                    
                    FlowMetrics(speechPattern: speechPattern)
                }
                .padding(24)
            }
            .offset(y: -scrollOffset * 0.1)
            
            FlowingCard {
                VStack(spacing: 16) {
                    HStack {
                        Text("Pause Patterns")
                            .font(.system(size: 18, weight: .light))
                            .foregroundColor(textColor)
                        Spacer()
                        Text("\(speechPattern.pauseCount) pauses")
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(textColor.opacity(0.7))
                    }
                    
                    PauseVisualizer(
                        pauseCount: speechPattern.pauseCount,
                        averageDuration: speechPattern.averagePauseDuration,
                        longestPause: speechPattern.longestPause,
                        scrollOffset: scrollOffset
                    )
                }
                .padding(24)
            }
            .offset(y: -scrollOffset * 0.15)
        }
    }
}

struct SpeakingPaceRing: View {
    let wpm: Double
    let scrollOffset: CGFloat
    
    private var normalizedWPM: Double {
        min(max((wpm - 80) / 100, 0), 1)
    }
    
    private var rotation: Double {
        360 * normalizedWPM - scrollOffset * 0.2
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(hex: "A28497").opacity(0.1), lineWidth: 12)
            
            Circle()
                .trim(from: 0, to: normalizedWPM)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(hex: "A28497"),
                            Color(hex: "A28497").opacity(0.6)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .rotationEffect(.degrees(rotation))
                .animation(.spring(dampingFraction: 0.8), value: rotation)
            
            VStack(spacing: 4) {
                Text("\(Int(wpm))")
                    .font(.system(size: 32, weight: .light))
                Text("WPM")
                    .font(.system(size: 14, weight: .light))
            }
            .foregroundColor(Color(hex: "2C3E50"))
        }
    }
}

struct PaceInsight: View {
    let wpm: Double
    
    var message: String {
        switch wpm {
        case ...100:
            return "Thoughtful and measured pace"
        case 100...140:
            return "Natural conversational rhythm"
        default:
            return "Energetic and swift expression"
        }
    }
    
    var body: some View {
        Text(message)
            .font(.system(size: 16, weight: .light))
            .foregroundColor(Color(hex: "2C3E50"))
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct FlowMetrics: View {
    let speechPattern: SpeechPatternAnalysis
    
    var body: some View {
        HStack(spacing: 20) {
            FlowMetricBox(
                title: "Average Pause",
                value: String(format: "%.1fs", speechPattern.averagePauseDuration),
                icon: "stopwatch"
            )
            
            FlowMetricBox(
                title: "Longest Pause",
                value: String(format: "%.1fs", speechPattern.longestPause),
                icon: "timer"
            )
        }
    }
}

struct FlowMetricBox: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .light))
                .foregroundColor(Color(hex: "A28497"))
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(hex: "2C3E50"))
                
                Text(title)
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(Color(hex: "2C3E50").opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "A28497").opacity(0.05))
        )
    }
}

struct PauseVisualizer: View {
    let pauseCount: Int
    let averageDuration: Double
    let longestPause: Double
    let scrollOffset: CGFloat
    
    private var normalizedPauses: [CGFloat] {
        (0..<pauseCount).map { i in
            let base = CGFloat(averageDuration / longestPause)
            let variation = CGFloat.random(in: -0.1...0.1)
            return max(0.2, min(1.0, base + variation))
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(normalizedPauses.indices, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: "A28497").opacity(0.3))
                    .frame(width: 4, height: 60 * normalizedPauses[index])
                    .offset(y: sin(Double(index) + scrollOffset * 0.05) * 5)
            }
        }
        .frame(height: 60)
        .animation(.easeInOut(duration: 1), value: scrollOffset)
    }
}

struct FlowingCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .shadow(color: Color(hex: "A28497").opacity(0.05), radius: 20)
            )
    }
}

struct SelfExpressionSection: View {
    let selfReference: SelfReferenceAnalysis
    let scrollOffset: CGFloat
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 24) {
            FlowingCard {
                VStack(spacing: 20) {
                    HStack(spacing: 24) {
                        PercentageRing(
                            percentage: selfReference.selfReferencePercentage,
                            scrollOffset: scrollOffset
                        )
                        .frame(width: 140, height: 140)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            PerspectiveInsight(percentage: selfReference.selfReferencePercentage)
                            
                            Text("Self references")
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(textColor.opacity(0.6))
                        }
                    }
                    
                    Divider()
                        .background(accentColor.opacity(0.1))
                    
                    TimePerspectiveChart(
                        past: selfReference.pastTensePercentage,
                        present: selfReference.presentTensePercentage,
                        future: selfReference.futureTensePercentage
                    )
                }
                .padding(24)
            }
            .offset(y: -scrollOffset * 0.1)
            
            FlowingCard {
                VStack(spacing: 16) {
                    HStack {
                        Text("Expression Patterns")
                            .font(.system(size: 18, weight: .light))
                            .foregroundColor(textColor)
                        Spacer()
                    }
                    
                    ExpressionPatterns(
                        uncertaintyCount: selfReference.uncertaintyCount,
                        reflectionCount: selfReference.reflectionCount,
                        scrollOffset: scrollOffset
                    )
                }
                .padding(24)
            }
            .offset(y: -scrollOffset * 0.15)
        }
    }
}

struct PercentageRing: View {
    let percentage: Double
    let scrollOffset: CGFloat
    
    private var normalizedPercentage: Double {
        percentage / 100
    }
    
    private var rotation: Double {
        360 * normalizedPercentage - scrollOffset * 0.2
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(hex: "A28497").opacity(0.1), lineWidth: 12)
            
            Circle()
                .trim(from: 0, to: normalizedPercentage)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(hex: "A28497"),
                            Color(hex: "A28497").opacity(0.6)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .rotationEffect(.degrees(rotation))
                .animation(.spring(dampingFraction: 0.8), value: rotation)
            
            VStack(spacing: 4) {
                Text("\(Int(percentage))%")
                    .font(.system(size: 32, weight: .light))
                Text("Self focus")
                    .font(.system(size: 14, weight: .light))
            }
            .foregroundColor(Color(hex: "2C3E50"))
        }
    }
}

struct PerspectiveInsight: View {
    let percentage: Double
    
    var message: String {
        switch percentage {
        case ...30:
            return "Focused on external observations"
        case 30...70:
            return "Balanced perspective"
        default:
            return "Deeply personal reflection"
        }
    }
    
    var body: some View {
        Text(message)
            .font(.system(size: 16, weight: .light))
            .foregroundColor(Color(hex: "2C3E50"))
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct TimePerspectiveChart: View {
    let past: Double
    let present: Double
    let future: Double
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Time Perspective")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(Color(hex: "2C3E50"))
            
            HStack(spacing: 0) {
                TimeSegment(label: "Past", percentage: past, color: .blue)
                TimeSegment(label: "Present", percentage: present, color: .green)
                TimeSegment(label: "Future", percentage: future, color: .purple)
            }
            .frame(height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}

struct TimeSegment: View {
    let label: String
    let percentage: Double
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 4) {
                Rectangle()
                    .fill(color.opacity(0.3))
                    .overlay(
                        Text("\(Int(percentage))%")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(color)
                    )
                
                Text(label)
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(Color(hex: "2C3E50"))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct ExpressionPatterns: View {
    let uncertaintyCount: Int
    let reflectionCount: Int
    let scrollOffset: CGFloat
    
    var body: some View {
        VStack(spacing: 20) {
            FloatingMetricBubble(
                count: uncertaintyCount,
                label: "Uncertainty markers",
                color: Color(hex: "A28497"),
                offset: scrollOffset
            )
            
            FloatingMetricBubble(
                count: reflectionCount,
                label: "Reflection markers",
                color: Color(hex: "B7A284"),
                offset: scrollOffset
            )
        }
    }
}

struct FloatingMetricBubble: View {
    let count: Int
    let label: String
    let color: Color
    let offset: CGFloat
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Text("\(count)")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(color)
            }
            .offset(y: sin(offset * 0.05) * 5)
            
            Text(label)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(Color(hex: "2C3E50"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: color.opacity(0.1), radius: 10)
        )
    }
}


