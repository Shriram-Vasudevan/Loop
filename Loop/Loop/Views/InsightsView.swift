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
        @State private var selectedTab = "today"
        @State private var animateIn = false
        
        private let accentColor = Color(hex: "A28497")
        private let backgroundColor = Color(hex: "FAFBFC")
        private let textColor = Color(hex: "2C3E50")
        
        var body: some View {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                ArtisticBackground(baseColor: accentColor)
                    .opacity(0.3)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        header
                        
                        // Debug info
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Debug Info:")
                                .font(.headline)
                            Text("Number of analyzed loops: \(analysisManager.analyzedLoops.count)")
                            Text("Is analyzing: \(analysisManager.isAnalyzing ? "Yes" : "No")")
                            if let current = analysisManager.currentLoopAnalysis {
                                Text("Current loop ID: \(current.loopId)")
                            } else {
                                Text("No current loop analysis")
                            }
                            Text("Session stats exist: \(analysisManager.sessionStats.analysisCount > 0 ? "Yes" : "No")")
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        
                        if analysisManager.analyzedLoops.count == 3 {
                            TabView(selection: $selectedTab) {
//                                TodayAnalysisView(
//                                    sessionStats: analysisManager.sessionStats,
//                                    loops: analysisManager.analyzedLoops
//                                )
//                                .tag("today")
//                                
                                ComingSoonView(title: "compare",
                                             description: "Compare analysis between multiple loops")
                                .tag("compare")
                                
                                ComingSoonView(title: "trends",
                                             description: "View your progress over time")
                                .tag("trends")
                            }
                            .tabViewStyle(.page(indexDisplayMode: .never))
                        } else {
                            incompleteLoopsView
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 32)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 1.2)) {
                    animateIn = true
                }
                print("InsightsView appeared")
                print("Analyzed loops count: \(analysisManager.analyzedLoops.count)")
                print("Current loop analysis exists: \(analysisManager.currentLoopAnalysis != nil)")
            }
        }
    
    private var header: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("loop insights")
                        .font(.system(size: 40, weight: .ultraLight))
                        .foregroundColor(textColor)
                    
                    Text(headerSubtitle)
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(textColor.opacity(0.7))
                }
                Spacer()
            }
            .offset(y: animateIn ? 0 : 20)
            .opacity(animateIn ? 1 : 0)
            
            if analysisManager.analyzedLoops.count == 3 {
                InsightsTabBar(selection: $selectedTab)
            }
        }
    }
    
    private var headerSubtitle: String {
        if analysisManager.analyzedLoops.count == 3 {
            return "your daily reflection analysis"
        } else {
            return "complete your daily loops"
        }
    }
    
    private var incompleteLoopsView: some View {
        VStack(spacing: 32) {
            // Progress circle showing completed loops
            ZStack {
                Circle()
                    .stroke(accentColor.opacity(0.1), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: CGFloat(analysisManager.analyzedLoops.count) / 3.0)
                    .stroke(
                        AngularGradient(
                            colors: [accentColor, accentColor.opacity(0.6)],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("\(analysisManager.analyzedLoops.count)")
                        .font(.system(size: 32, weight: .medium))
                    Text("of 3")
                        .font(.system(size: 16, weight: .light))
                }
                .foregroundColor(textColor)
            }
            
            VStack(spacing: 16) {
                Text("Complete Your Daily Loops")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(textColor)
                
                Text("\(3 - analysisManager.analyzedLoops.count) more loops needed")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(textColor.opacity(0.7))
                
                if !analysisManager.analyzedLoops.isEmpty {
                    Text("Previous loops completed: \(analysisManager.analyzedLoops.count)")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(accentColor)
                }
            }
            .multilineTextAlignment(.center)
            
            // Decorative elements
            HStack(spacing: 24) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(index < analysisManager.analyzedLoops.count ? accentColor : accentColor.opacity(0.2))
                        .frame(width: 12, height: 12)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
    }
}

struct InsightsTabBar: View {
    @Binding var selection: String
    
    private let tabs = [
        ("today", "Today", "calendar"),
        ("compare", "Compare", "square.on.square"),
        ("trends", "Trends", "chart.xyaxis.line")
    ]
    
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.0) { tab in
                InsightsTabButton(
                    title: tab.1,
                    icon: tab.2,
                    isSelected: selection == tab.0,
                    action: { selection = tab.0 }
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: accentColor.opacity(0.1), radius: 20)
        )
    }
}

struct InsightsTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.system(size: 16, weight: .light))
            }
            .foregroundColor(isSelected ? .white : accentColor)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(isSelected ? accentColor : accentColor.opacity(0.1))
            )
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

struct ComingSoonView: View {
    let title: String
    let description: String
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundColor(accentColor)
            
            Text(title)
                .font(.system(size: 24, weight: .light))
                .foregroundColor(textColor)
            
            Text(description)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(textColor.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct InsightCard<Content: View>: View {
    let intensity: Double
    let content: Content
    
    private let accentColor = Color(hex: "A28497")
    private let surfaceColor = Color(hex: "F8F5F7")
    
    init(_ intensity: Double, @ViewBuilder content: () -> Content) {
        self.intensity = intensity
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(24)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.white)
                    
                    FlowingGradient(
                        intensity: intensity,
                        baseColor: accentColor
                    )
                    .opacity(0.05)
                }
                .shadow(color: accentColor.opacity(0.05), radius: 20)
            )
    }
}

struct MetricValue: View {
    let value: Double
    let label: String
    let sublabel: String?
    let icon: String?
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    init(value: Double, label: String, sublabel: String? = nil, icon: String? = nil) {
        self.value = value
        self.label = label
        self.sublabel = sublabel
        self.icon = icon
    }
    
    var body: some View {
        VStack(spacing: 8) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(accentColor)
            }
            
            Text(String(format: "%.1f", value))
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(textColor)
            
            Text(label)
                .font(.system(size: 14, weight: .light))
                .foregroundColor(textColor.opacity(0.7))
            
            if let sublabel = sublabel {
                Text(sublabel)
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(textColor.opacity(0.5))
            }
        }
    }
}

struct ProgressBar: View {
    let value: Double
    let maxValue: Double
    let label: String
    let color: Color
    
    private let height: CGFloat = 8
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 14, weight: .light))
                Spacer()
                Text("\(Int((value / maxValue) * 100))%")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(textColor)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(color.opacity(0.1))
                        .frame(height: height)
                        .cornerRadius(height / 2)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(min(value / maxValue, 1)), height: height)
                        .cornerRadius(height / 2)
                }
            }
            .frame(height: height)
        }
    }
}

//struct CircularProgress: View {
//    let value: Double
//    let maxValue: Double
//    let size: CGFloat
//    let lineWidth: CGFloat
//    let color: Color
//    
//    private let textColor = Color(hex: "2C3E50")
//    
//    var body: some View {
//        ZStack {
//            Circle()
//                .stroke(color.opacity(0.1), lineWidth: lineWidth)
//            
//            Circle()
//                .trim(from: 0, to: min(value / maxValue, 1))
//                .stroke(
//                    color,
//                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
//                )
//                .rotationEffect(.degrees(-90))
//                .animation(.easeInOut, value: value)
//        }
//        .frame(width: size, height: size)
//    }
//}

struct SectionHeader: View {
    let title: String
    let icon: String
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .light))
                .foregroundColor(accentColor)
            
            Text(title)
                .font(.system(size: 24, weight: .ultraLight))
                .foregroundColor(textColor)
        }
    }
}

struct FlowingGradient: View {
    let intensity: Double
    let baseColor: Color
    @State private var phase: Double = 0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                phase = time.truncatingRemainder(dividingBy: 4)
                
                for i in 0..<3 {
                    let path = createFlowingPath(
                        in: size,
                        offset: phase + Double(i) * .pi / 3,
                        scale: 0.3 + intensity * 0.7
                    )
                    
                    context.fill(
                        path,
                        with: .linearGradient(
                            Gradient(colors: [
                                baseColor.opacity(0.05),
                                baseColor.opacity(0.02)
                            ]),
                            startPoint: CGPoint(x: 0, y: size.height/2),
                            endPoint: CGPoint(x: size.width, y: size.height/2)
                        )
                    )
                }
            }
        }
    }
    
    private func createFlowingPath(in size: CGSize, offset: Double, scale: Double) -> Path {
        var path = Path()
        let midY = size.height / 2
        
        path.move(to: CGPoint(x: 0, y: size.height))
        
        for x in stride(from: 0, through: size.width, by: 5) {
            let normalizedX = x / size.width
            let y = midY + sin(normalizedX * 4 * .pi + offset) * midY * scale
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.closeSubpath()
        return path
    }
}

struct MetricRow: View {
    let title: String
    let value: String
    let subtitle: String
    let interpretation: String?
    let color: Color
    
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(textColor.opacity(0.8))
                    
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(value)
                            .font(.system(size: 24, weight: .medium))
                        Text(subtitle)
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(textColor.opacity(0.6))
                    }
                }
                
                Spacer()
                
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .strokeBorder(color.opacity(0.2), lineWidth: 1)
                    )
            }
            
            if let interpretation = interpretation {
                Text(interpretation)
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(textColor.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(color.opacity(0.05))
                    .cornerRadius(8)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: color.opacity(0.05), radius: 20)
    }
}

struct InsightSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    let accentColor: Color
    
    private let textColor = Color(hex: "2C3E50")
    
    init(
        title: String,
        icon: String,
        accentColor: Color = Color(hex: "A28497"),
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.accentColor = accentColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .light))
                
                Text(title)
                    .font(.system(size: 24, weight: .ultraLight))
            }
            .foregroundColor(accentColor)
            
            content
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white)
                .shadow(color: accentColor.opacity(0.05), radius: 20)
        )
    }
}

struct WaveformBackground: View {
    let color: Color
    @State private var phase: CGFloat = 0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let timeValue = timeline.date.timeIntervalSinceReferenceDate
                phase = CGFloat(timeValue.truncatingRemainder(dividingBy: 2))
                
                for i in 0..<3 {
                    let path = createWavePath(
                        in: size,
                        frequency: 1.5,
                        amplitude: 0.1,
                        phase: phase + CGFloat(i) * 0.5
                    )
                    
                    context.stroke(
                        path,
                        with: .linearGradient(
                            Gradient(colors: [
                                color.opacity(0.1),
                                color.opacity(0.05)
                            ]),
                            startPoint: CGPoint(x: 0, y: size.height/2),
                            endPoint: CGPoint(x: size.width, y: size.height/2)
                        ),
                        lineWidth: 1
                    )
                }
            }
        }
    }
    
    private func createWavePath(
        in size: CGSize,
        frequency: CGFloat,
        amplitude: CGFloat,
        phase: CGFloat
    ) -> Path {
        var path = Path()
        let steps = Int(size.width)
        
        path.move(to: CGPoint(x: 0, y: size.height/2))
        
        for step in 0..<steps {
            let x = CGFloat(step) / CGFloat(steps) * size.width
            let angle = 2 * .pi * frequency * CGFloat(step) / CGFloat(steps) + phase
            let y = size.height/2 + sin(angle) * size.height * amplitude
            
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        return path
    }
}
