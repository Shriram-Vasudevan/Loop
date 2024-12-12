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
    @State private var animateCards = false
    @State private var selectedTimeframe = Timeframe.today
    @State private var selectedInsightType: InsightType?
    @State private var expandedSections: Set<Section> = [.overview]
    @State private var selectedLoop: LoopAnalysis?
    @State private var showingLoopDetail = false
    
    @State private var selectedTab = "today"
    
    private let accentColor = Color(hex: "A28497")
    private let backgroundColor = Color(hex: "FAFBFC")
    private let surfaceColor = Color(hex: "F8F5F7")
    private let textColor = Color(hex: "2C3E50")
    

    enum Timeframe: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
    }
    
    enum InsightType: String, CaseIterable {
        case pace = "Speaking Pace"
        case vocabulary = "Vocabulary"
        case patterns = "Patterns"
        case duration = "Duration"
    }
    
    enum Section: String {
        case overview = "Overview"
        case vocabulary = "Vocabulary Analysis"
        case patterns = "Speaking Patterns"
        case relationships = "Loop Relationships"
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {

            ScrollView {
                VStack(spacing: 10) {
                    header
                        .opacity(animateCards ? 1 : 0)
                        .offset(y: animateCards ? 0 : 20)
                    
                    if selectedTab == "today" {
                        if analysisManager.todaysLoops.count == 3
                        {
                            TodayAnalysisView(analysisManager: analysisManager)
                        }
                        else {
                            Text("Complete Today's Loops for Analysis!")
                        }
                    }
                    else {
                        Text("Working on it.")
                    }
                }
                .padding(.horizontal, 24)
            }
        }

        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateCards = true
            }
        }
    }
    
    private var header: some View {
        VStack(spacing: 24) {
            Menu {
                Button("today") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = "today"
                    }
                }
                Button("trends") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = "trends"
                    }
                }
            } label: {
                ZStack {

                    HStack(spacing: 8) {
                        Text(selectedTab)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.black)
                    }
                    .frame(height: 56)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        backgroundColor,
                                        Color(hex: "F5F5F5")
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .cornerRadius(28)
                    .shadow(color: accentColor.opacity(0.15), radius: 12, y: 6)
                    .padding(.horizontal)
                    
                    HStack {
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.black)
                            .padding(.trailing)
                    }
                    .padding(.horizontal)
                }
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.top, 16)
    }
    private var noDataView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundColor(accentColor)
            
            Text("No Insights Yet")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(textColor)
            
            Text("Complete your daily reflection loops to see insights about your speaking patterns.")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(textColor.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .cardStyle()
    }
    
   
}

struct InsightWave: Shape {
   func path(in rect: CGRect) -> Path {
       var path = Path()
       let width = rect.width
       let height = rect.height
       
       path.move(to: CGPoint(x: 0, y: 0))
       path.addLine(to: CGPoint(x: width, y: 0))
       path.addLine(to: CGPoint(x: width, y: height))
       
       // Create wave
       path.addCurve(
           to: CGPoint(x: 0, y: height),
           control1: CGPoint(x: width * 0.75, y: height * 0.8),
           control2: CGPoint(x: width * 0.25, y: height * 1.2)
       )
       
       path.closeSubpath()
       return path
   }
}

struct TodayAnalysisView: View {
    @ObservedObject var analysisManager: AnalysisManager
    @State private var selectedComparison = "week"
    @State private var selectedLoop = 0
    private let accentColor = Color(hex: "A28497")
    private let backgroundColor = Color(hex: "FAFBFC")
    private let textColor = Color(hex: "2C3E50")
    let surfaceColor = Color(hex: "F8F5F7")
    
    var body: some View {
        VStack(spacing: 20) {
            aiAnalysis
            
            VStack(spacing: 12) {
                Text("loop recap")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(textColor.opacity(0.6))
                    .padding(.top, 5)
                
                loopCard
            }
            
            HStack(spacing: 12) {
                Text("compare with")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(textColor.opacity(0.6))
                
                Menu {
                    Button("week", action: { selectedComparison = "week" })
                    Button("month", action: { selectedComparison = "month" })
                    Button("all time", action: { selectedComparison = "all time" })
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedComparison)
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(accentColor.opacity(0.1))
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                Text("speaking patterns")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(textColor.opacity(0.6))
                    .padding(.top, 15)
                
                VStack(spacing: 3) {
                    wpmCard
                    durationCard
                    selfReferenceCard
                }
            }
            
            VStack(spacing: 12) {
                Text("patterns")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(textColor.opacity(0.6))
                    .padding(.top, 15)
                
                VStack(spacing: 3) {
                    loopRelationshipsCard
                }
            }
        }
    }
    
    private var aiAnalysis: some View {
        ZStack {
            
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .fill(accentColor)
                                .frame(width: 4, height: 4)
                        )
                    
                    Text("AI ANALYSIS")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(accentColor)
                        .tracking(1.2)
                }
                
                if let analysis = analysisManager.currentDailyAnalysis?.aiAnalysis {
                    Text(analysis.feeling.capitalized)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(textColor)
                    
                    Text(analysis.description)
                        .font(.system(size: 16))
                        .foregroundColor(textColor.opacity(0.7))
                        .lineSpacing(4)
                }
                else {
                    VStack(spacing: 6) {
                        HStack {
                            Text("analyzing...")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(textColor)
                            
                            Spacer()
        
                        }
                        
                        HStack {
                            Text("we're working on it")
                                .font(.system(size: 16))
                                .foregroundColor(textColor.opacity(0.7))
                                .lineSpacing(4)
                            Spacer()
                        }
                    }
                }

            }
            .padding(.top, 24)
            .overlay (
                HStack {
                    Spacer()
                    
                    Circle()
                        .stroke(accentColor.opacity(0.1), lineWidth: 1)
                        .frame(width: 45, height: 45)
                        .overlay(
                            Circle()
                                .stroke(accentColor.opacity(0.1), lineWidth: 1)
                                .frame(width: 30, height: 30)
                        )
                }
                    .padding([.top, .trailing]),
                alignment: .topTrailing
            )
//            .background(
//                ZStack {
//                    Color.white
//                    
//                    WavyBackground()
//                        .background(surfaceColor)
//                }
//            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        }
        
        

    }
    
    private var loopCard: some View {
        VStack(spacing: 12) {
            if !analysisManager.todaysLoops.isEmpty {
                TabView(selection: $selectedLoop) {
                    ForEach(analysisManager.todaysLoops.indices, id: \.self) { index in
                        let loop = analysisManager.todaysLoops[index]
                        VStack(alignment: .leading, spacing: 20) {
                            // Header
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(accentColor.opacity(0.2))
                                        .frame(width: 8, height: 8)
                                        .overlay(
                                            Circle()
                                                .fill(accentColor)
                                                .frame(width: 4, height: 4)
                                        )
                                    
                                    Text("LOOP \(index + 1)")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(accentColor)
                                        .tracking(1.2)
                                }
                                
                                Text(formatTime(loop.timestamp))
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(textColor.opacity(0.6))
                                
                                // Prompt with decorative element
                                HStack(spacing: 8) {
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(accentColor)
                                        .frame(width: 2, height: 16)
                                    
                                    Text(loop.promptText)
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(textColor)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            
                            // Primary metrics with unique visual style
                            HStack(spacing: 32) {
                                // WPM
                                VStack(alignment: .leading, spacing: 4) {
                                    ZStack(alignment: .leading) {
                                        HStack(spacing: 4) {
                                            Text("\(Int(loop.metrics.wordsPerMinute))")
                                                .font(.system(size: 22, weight: .medium))
                                                .foregroundColor(textColor)
                                            
                                            // Unique speed indicator
                                            ForEach(0..<3) { i in
                                                Circle()
                                                    .fill(accentColor.opacity(
                                                        loop.metrics.wordsPerMinute > Double(50 + i * 50) ? 0.8 : 0.2
                                                    ))
                                                    .frame(width: 4, height: 4)
                                            }
                                        }
                                    }
                                    
                                    Text("words/min")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(textColor.opacity(0.6))
                                        .textCase(.lowercase)
                                }
                                
                                // Duration
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 4) {
                                        Text(formatDuration(loop.metrics.duration))
                                            .font(.system(size: 22, weight: .medium))
                                            .foregroundColor(textColor)
                                        
                                        // Time indicator
                                        Circle()
                                            .stroke(accentColor.opacity(0.2), lineWidth: 1)
                                            .frame(width: 12, height: 12)
                                            .overlay(
                                                Circle()
                                                    .trim(from: 0, to: loop.metrics.duration / 180) // Normalized to 3 minutes
                                                    .stroke(accentColor, lineWidth: 1)
                                                    .rotationEffect(.degrees(-90))
                                            )
                                    }
                                    
                                    Text("duration")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(textColor.opacity(0.6))
                                        .textCase(.lowercase)
                                }
                            }
                            
                            Divider()
                                .background(textColor.opacity(0.1))
                            
                            // Secondary metrics with unique styling
                            HStack(spacing: 32) {
                                // Word counts
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                                        Text("\(loop.metrics.wordCount)")
                                            .font(.system(size: 22, weight: .medium))
                                            .foregroundColor(textColor)
                                        
                                        // Unique count indicator
                                        Text("\(loop.metrics.uniqueWordCount)")
                                            .font(.system(size: 13, weight: .regular))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(accentColor.opacity(0.1))
                                            .cornerRadius(4)
                                            .foregroundColor(accentColor)
                                    }
                                    
                                    Text("words (unique)")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(textColor.opacity(0.6))
                                        .textCase(.lowercase)
                                }
                                
                                // Self references
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Text("\(loop.metrics.selfReferenceCount)")
                                            .font(.system(size: 22, weight: .medium))
                                            .foregroundColor(textColor)
                                        
                                        // Unique reference indicator
                                        ForEach(0..<min(loop.metrics.selfReferenceCount, 3)) { _ in
                                            Circle()
                                                .fill(accentColor.opacity(0.3))
                                                .frame(width: 4, height: 4)
                                        }
                                    }
                                    
                                    Text("self references")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(textColor.opacity(0.6))
                                        .textCase(.lowercase)
                                }
                            }
                            
                            // Most used words with unique design
                            if !loop.wordAnalysis.mostUsedWords.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("frequently used")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(textColor.opacity(0.6))
                                        .textCase(.lowercase)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(loop.wordAnalysis.mostUsedWords.prefix(3), id: \.word) { word in
                                                HStack(spacing: 6) {
                                                    Text(word.word)
                                                        .font(.system(size: 13, weight: .medium))
                                                    
                                                    // Frequency indicator
                                                    Text("\(word.count)×")
                                                        .font(.system(size: 13, weight: .regular))
                                                        .foregroundColor(textColor.opacity(0.6))
                                                }
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(accentColor.opacity(0.15), lineWidth: 1)
                                                        .background(surfaceColor)
                                                )
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 24)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page)
                .frame(height: 320)
                
                // Page indicator with unique style
                HStack(spacing: 6) {
                    ForEach(0..<analysisManager.todaysLoops.count, id: \.self) { index in
                        Capsule()
                            .fill(index == selectedLoop ? accentColor : accentColor.opacity(0.2))
                            .frame(width: 12, height: 3)
                    }
                }
                .padding(.top, -8)
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    private var wpmCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header section with icon
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(accentColor.opacity(0.2))
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .fill(accentColor)
                                    .frame(width: 4, height: 4)
                            )
                        
                        Text("SPEAKING PACE")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(accentColor)
                            .tracking(1.2)
                    }
                    
                    Text("Time spent reflecting")
                        .font(.system(size: 15, weight: .light))
                        .foregroundColor(textColor.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "waveform")
                    .font(.system(size: 24))
                    .foregroundColor(accentColor)
            }
            
            // Main metric
            VStack(alignment: .leading, spacing: 8) {
                Text("\(Int(analysisManager.currentDailyAnalysis?.aggregateMetrics.averageWPM ?? 0))")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(textColor)
                
                Text("words per minute")
                    .font(.system(size: 16))
                    .foregroundColor(textColor.opacity(0.7))
            }
            
            // Comparison with last week
            if let comparison = analysisManager.weeklyComparison?.wpmComparison {
                HStack(spacing: 8) {
                    Image(systemName: comparison.direction == .increase ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(accentColor)
                    
                    Text("\(Int(abs(comparison.percentageChange)))% \(comparison.direction == .increase ? "faster" : "slower")")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(textColor)
                    
                    Text("than last week")
                        .font(.system(size: 15, weight: .light))
                        .foregroundColor(textColor.opacity(0.7))
                }
                .padding(.vertical, 4)
            }
            
            // Range section
            if let range = analysisManager.currentDailyAnalysis?.rangeAnalysis.wpmRange {
                HStack(spacing: 32) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(Int(range.min))")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(textColor)
                        
                        Text("slowest")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(textColor.opacity(0.6))
                            .textCase(.lowercase)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(Int(range.max))")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(textColor)
                        
                        Text("fastest")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(textColor.opacity(0.6))
                            .textCase(.lowercase)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
        
    private var durationCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header section with icon
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(accentColor.opacity(0.2))
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .fill(accentColor)
                                    .frame(width: 4, height: 4)
                            )
                        
                        Text("SPEAKING DURATION")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(accentColor)
                            .tracking(1.2)
                    }
                    
                    Text("Time spent on each loop")
                        .font(.system(size: 15, weight: .light))
                        .foregroundColor(textColor.opacity(0.6))
                }
                
                Spacer()
                
                // Unique circular timer visual
                ZStack {
                    Circle()
                        .stroke(accentColor.opacity(0.1), lineWidth: 2)
                        .frame(width: 32, height: 32)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(accentColor, lineWidth: 2)
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(-90))
                    
                    Image(systemName: "clock")
                        .font(.system(size: 14))
                        .foregroundColor(accentColor)
                }
            }
            
            // Main duration display with visual separator
            HStack(spacing: 16) {
                Text(formatDuration(analysisManager.currentDailyAnalysis?.aggregateMetrics.averageDuration ?? 0))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(textColor)
                
                // Unique visual element - time markers
                HStack(spacing: 4) {
                    ForEach(0..<3) { i in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(accentColor.opacity(0.2))
                            .frame(width: 2, height: i == 1 ? 20 : 12)
                    }
                }
                .padding(.leading, 8)
            }
            
            // Timeline visualization (unique to duration card)
            HStack(spacing: 0) {
                ForEach(0..<5) { i in
                    Rectangle()
                        .fill(accentColor.opacity(Double(5-i) / 10))
                        .frame(height: 3)
                }
            }
            .clipShape(Capsule())
            .padding(.vertical, 8)
            
            // Comparison with last week
            if let comparison = analysisManager.weeklyComparison?.durationComparison {
                HStack(spacing: 8) {
                    Image(systemName: comparison.direction == .increase ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(accentColor)
                    
                    Text("\(Int(abs(comparison.percentageChange)))% \(comparison.direction == .increase ? "longer" : "shorter")")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(textColor)
                    
                    Text("than last week")
                        .font(.system(size: 15, weight: .light))
                        .foregroundColor(textColor.opacity(0.7))
                }
            }
            
            // Range section with unique time-based styling
            if let range = analysisManager.currentDailyAnalysis?.rangeAnalysis.durationRange {
                HStack(spacing: 32) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatDuration(range.min))
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(textColor)
                        
                        HStack(spacing: 4) {
                            Rectangle()
                                .fill(accentColor.opacity(0.2))
                                .frame(width: 16, height: 2)
                            
                            Text("shortest")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(textColor.opacity(0.6))
                                .textCase(.lowercase)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatDuration(range.max))
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(textColor)
                        
                        HStack(spacing: 4) {
                            Rectangle()
                                .fill(accentColor.opacity(0.2))
                                .frame(width: 16, height: 2)
                            
                            Text("longest")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(textColor.opacity(0.6))
                                .textCase(.lowercase)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    private var selfReferenceCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header section
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(accentColor.opacity(0.2))
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .fill(accentColor)
                                    .frame(width: 4, height: 4)
                            )
                        
                        Text("SELF EXPRESSION")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(accentColor)
                            .tracking(1.2)
                    }
                    
                    Text("How you reference yourself")
                        .font(.system(size: 15, weight: .light))
                        .foregroundColor(textColor.opacity(0.6))
                }
                
                Spacer()
                
                // Unique layered circles icon
                ZStack {
                    Circle()
                        .stroke(accentColor.opacity(0.1), lineWidth: 2)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 14))
                        .foregroundColor(accentColor)
                    
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(accentColor.opacity(0.1), lineWidth: 1)
                            .frame(width: CGFloat(40 + i * 8))
                    }
                }
            }
            
            // Main metrics with unique visual style
            HStack(spacing: 40) {
                // Total references
                VStack(alignment: .leading, spacing: 8) {
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(accentColor.opacity(0.1))
                            .frame(width: 60, height: 40)
                        
                        Text("\(Int(analysisManager.currentDailyAnalysis?.aggregateMetrics.averageSelfReferences ?? 0))")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(textColor)
                            .padding(.leading, 8)
                    }
                    
                    Text("total mentions")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(textColor.opacity(0.6))
                        .textCase(.lowercase)
                }
                
                // Per loop average
                VStack(alignment: .leading, spacing: 8) {
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(accentColor.opacity(0.1))
                            .frame(width: 60, height: 40)
                        
                        Text("\(Int(analysisManager.currentDailyAnalysis?.aggregateMetrics.averageSelfReferences ?? 0) / 3)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(textColor)
                            .padding(.leading, 8)
                    }
                    
                    Text("per loop")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(textColor.opacity(0.6))
                        .textCase(.lowercase)
                }
            }
            
            // Unique personal pronouns section
            VStack(alignment: .leading, spacing: 12) {
                Text("personal pronouns")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(textColor.opacity(0.6))
                    .textCase(.lowercase)
                
                HStack(spacing: 12) {
                    ForEach(analysisManager.todaysLoops.first?.wordAnalysis.selfReferenceTypes.prefix(3) ?? [], id: \.self) { word in
                        // Unique pronoun pill design
                        HStack(spacing: 6) {
                            Circle()
                                .fill(accentColor)
                                .frame(width: 4, height: 4)
                            
                            Text(word)
                                .font(.system(size: 15, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(accentColor.opacity(0.2), lineWidth: 1)
                                .background(accentColor.opacity(0.05))
                        )
                        .foregroundColor(accentColor)
                    }
                }
            }
            
            // Weekly comparison
            if let comparison = analysisManager.weeklyComparison?.selfReferenceComparison {
                HStack(spacing: 8) {
                    Image(systemName: comparison.direction == .increase ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(accentColor)
                    
                    Text("\(Int(abs(comparison.percentageChange)))% \(comparison.direction == .increase ? "more" : "fewer")")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(textColor)
                    
                    Text("than last week")
                        .font(.system(size: 15, weight: .light))
                        .foregroundColor(textColor.opacity(0.7))
                }
            }
            
            // Range section with unique styling
            if let range = analysisManager.currentDailyAnalysis?.rangeAnalysis.selfReferenceRange {
                HStack(spacing: 32) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(range.min)")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(textColor)
                            
                            Text("×")
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(textColor.opacity(0.4))
                        }
                        
                        Text("fewest")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(textColor.opacity(0.6))
                            .textCase(.lowercase)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(range.max)")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(textColor)
                            
                            Text("×")
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(textColor.opacity(0.4))
                        }
                        
                        Text("most")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(textColor.opacity(0.6))
                            .textCase(.lowercase)
                    }
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
        private var vocabularyCard: some View {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Vocabulary")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(textColor)
                        
                        Text("Word choice diversity")
                            .font(.system(size: 15, weight: .light))
                            .foregroundColor(textColor.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "textformat.abc")
                        .font(.system(size: 24))
                        .foregroundColor(accentColor)
                }
                
                Text("\(Int((analysisManager.currentDailyAnalysis?.aggregateMetrics.vocabularyDiversityRatio ?? 0) * 100))%")
                    .font(.system(size: 56, weight: .medium))
                    .foregroundColor(textColor)
                
                if let comparison = analysisManager.weeklyComparison?.vocabularyDiversityComparison {
                    HStack(spacing: 8) {
                        Image(systemName: comparison.direction == .increase ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(accentColor)
                        
                        Text("\(Int(abs(comparison.percentageChange)))% \(comparison.direction == .increase ? "more" : "less")")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(textColor)
                        
                        Text("diverse than last week")
                            .font(.system(size: 15, weight: .light))
                            .foregroundColor(textColor.opacity(0.7))
                    }
                }
                
                if let wordPatterns = analysisManager.currentDailyAnalysis?.wordPatterns {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("most used words")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(textColor.opacity(0.6))
                            .textCase(.lowercase)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(wordPatterns.mostUsedWords.prefix(5), id: \.word) { word in
                                HStack(spacing: 4) {
                                    Text(word.word)
                                        .font(.system(size: 15, weight: .medium))
                                    Text("\(word.count)")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(textColor.opacity(0.6))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(accentColor.opacity(0.1))
                                .foregroundColor(accentColor)
                                .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            .padding(24)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        }

    private var loopRelationshipsCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header section
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(accentColor.opacity(0.2))
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .fill(accentColor)
                                    .frame(width: 4, height: 4)
                            )
                        
                        Text("LOOP CONNECTIONS")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(accentColor)
                            .tracking(1.2)
                    }
                    
                    Text("Patterns across reflections")
                        .font(.system(size: 15, weight: .light))
                        .foregroundColor(textColor.opacity(0.6))
                }
                
                Spacer()
                
                // Unique connected circles icon
                ZStack {
                    // Connection lines
                    Path { path in
                        path.move(to: CGPoint(x: 8, y: 16))
                        path.addLine(to: CGPoint(x: 24, y: 16))
                        path.move(to: CGPoint(x: 16, y: 8))
                        path.addLine(to: CGPoint(x: 16, y: 24))
                    }
                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
                    
                    // Corner circles
                    ForEach(0..<4) { i in
                        Circle()
                            .fill(accentColor.opacity(0.1))
                            .frame(width: 8, height: 8)
                            .offset(
                                x: i % 2 == 0 ? -8 : 8,
                                y: i < 2 ? -8 : 8
                            )
                    }
                    
                    // Center circle
                    Circle()
                        .fill(accentColor)
                        .frame(width: 8, height: 8)
                }
                .frame(width: 32, height: 32)
            }
            
            if let overlapAnalysis = analysisManager.currentDailyAnalysis?.overlapAnalysis {
                // Main similarity score with unique visualization
                HStack(spacing: 24) {
                    // Circular connection visualization
                    ZStack {
                        ForEach(0..<3) { i in
                            Circle()
                                .stroke(accentColor.opacity(0.1), lineWidth: 1)
                                .frame(width: CGFloat(60 + i * 20))
                        }
                        
                        // Connection lines
                        ForEach(0..<3) { i in
                            Path { path in
                                let angle = Double(i) * (2 * .pi / 3)
                                path.move(to: CGPoint(x: 40, y: 40))
                                path.addLine(to: CGPoint(
                                    x: 40 + cos(angle) * 30,
                                    y: 40 + sin(angle) * 30
                                ))
                            }
                            .stroke(accentColor.opacity(0.2), lineWidth: 1)
                        }
                        
                        // Similarity percentage
                        Text("\(Int(overlapAnalysis.overallSimilarity * 100))%")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(textColor)
                    }
                    .frame(width: 80, height: 80)
                    
                    // Connection description
                    VStack(alignment: .leading, spacing: 4) {
                        Text("thematic")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(textColor.opacity(0.6))
                            .textCase(.lowercase)
                        
                        Text("similarity")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(textColor)
                    }
                }
                
                // Shared themes section
                VStack(spacing: 16) {
                    ForEach(Array(overlapAnalysis.commonWords.keys.prefix(2)), id: \.self) { key in
                        if let words = overlapAnalysis.commonWords[key] {
                            VStack(alignment: .leading, spacing: 8) {
                                // Connection indicator
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(accentColor)
                                        .frame(width: 4, height: 4)
                                    
                                    Text("shared elements")
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(textColor.opacity(0.6))
                                        .textCase(.lowercase)
                                }
                                
                                // Common words with unique styling
                                FlowLayout(spacing: 8) {
                                    ForEach(words.prefix(3), id: \.self) { word in
                                        Text(word)
                                            .font(.system(size: 15, weight: .medium))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(accentColor.opacity(0.2), lineWidth: 1)
                                                    .background(
                                                        LinearGradient(
                                                            colors: [
                                                                accentColor.opacity(0.05),
                                                                accentColor.opacity(0.02)
                                                            ],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                            )
                                            .foregroundColor(accentColor)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date).lowercased()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return seconds == 0 ? "\(minutes)m" : "\(minutes)m \(seconds)s"
    }
}

    struct FlowLayout: Layout {
        var spacing: CGFloat = 8
        
        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
            return result.size
        }
        
        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
            let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
            for (index, frame) in result.frames {
                let position = CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY)
                subviews[index].place(at: position, proposal: ProposedViewSize(frame.size))
            }
        }
        
        struct FlowResult {
            var size: CGSize
            var frames: [Int: CGRect]
            
            init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
                var height: CGFloat = 0
                var maxWidth: CGFloat = 0
                var x: CGFloat = 0
                var y: CGFloat = 0
                var row: CGFloat = 0
                var frames = [Int: CGRect]()
                
                for (index, subview) in subviews.enumerated() {
                    let size = subview.sizeThatFits(.unspecified)
                    
                    if x + size.width > width {
                        x = 0
                        y += row + spacing
                        row = 0
                    }
                    
                    frames[index] = CGRect(x: x, y: y, width: size.width, height: size.height)
                    row = max(row, size.height)
                    x += size.width + spacing
                    maxWidth = max(maxWidth, x)
                    height = max(height, y + row)
                }
                
                self.size = CGSize(width: maxWidth, height: height)
                self.frames = frames
            }
        }
    }
    
extension AnalysisManager {
    static var mock: AnalysisManager {
        let manager = AnalysisManager()
        
        // Mock LoopAnalysis
        let mockLoop = LoopAnalysis(
            id: UUID().uuidString,
            timestamp: Date(),
            promptText: "Describe your day",
            category: "Reflection", transcript: "",
            metrics: LoopMetrics(
                duration: 180.0,
                wordCount: 120,
                uniqueWordCount: 80,
                wordsPerMinute: 40.0,
                selfReferenceCount: 10,
                uniqueSelfReferenceCount: 2,
                averageWordLength: 4.5
            ),
            wordAnalysis: WordAnalysis(
                words: ["today", "was", "great", "I", "went", "to", "the", "park"],
                uniqueWords: ["today", "great", "park"],
                mostUsedWords: [
                    WordCount(word: "today", count: 5),
                    WordCount(word: "great", count: 4),
                    WordCount(word: "park", count: 3)
                ],
                selfReferenceTypes: ["I", "myself"]
            )
        )
        
        let mockDailyAnalysis = DailyAnalysis(
            date: Date(),
            loops: [mockLoop, mockLoop, mockLoop],
            aggregateMetrics: AggregateMetrics(
                averageDuration: 180.0,
                averageWordCount: 120.0,
                averageUniqueWordCount: 80.0,
                averageWPM: 40.0,
                averageSelfReferences: 10.0,
                vocabularyDiversityRatio: 0.67
            ),
            wordPatterns: WordPatterns(
                totalUniqueWords: ["today", "great", "park"],
                wordsInAllResponses: ["today", "great"],
                mostUsedWords: [
                    WordCount(word: "today", count: 15),
                    WordCount(word: "great", count: 12)
                ]
            ),
            overlapAnalysis: OverlapAnalysis(
                pairwiseOverlap: ["1-2": 0.75, "1-3": 0.60],
                commonWords: ["1-2": ["today", "great"]],
                overallSimilarity: 0.65
            ),
            rangeAnalysis: RangeAnalysis(
                wpmRange: MinMaxRange(min: 35.0, max: 45.0),
                durationRange: MinMaxRange(min: 160.0, max: 200.0),
                wordCountRange: IntRange(min: 110, max: 130),
                selfReferenceRange: IntRange(min: 8, max: 12)
            ),
            aiAnalysis: AIAnalysisResult(feeling: "Contemplative", description: "Your reflections today show deep introspection and thoughtful consideration of personal experiences, with a focus on emotional awareness.")
        )
        
        manager.currentDailyAnalysis = mockDailyAnalysis
        manager.todaysLoops = [mockLoop, mockLoop, mockLoop]
        manager.weeklyComparison = LoopComparison(
            date: Date(),
            pastLoopDate: Date().addingTimeInterval(-7 * 24 * 60 * 60),
            durationComparison: MetricComparison(direction: .increase, percentageChange: 10.0),
            wpmComparison: MetricComparison(direction: .increase, percentageChange: 5.0),
            wordCountComparison: MetricComparison(direction: .decrease, percentageChange: 3.0),
            uniqueWordComparison: MetricComparison(direction: .increase, percentageChange: 8.0),
            vocabularyDiversityComparison: MetricComparison(direction: .increase, percentageChange: 15.0),
            averageWordLengthComparison: MetricComparison(direction: .same, percentageChange: 0.0),
            selfReferenceComparison: MetricComparison(direction: .decrease, percentageChange: 2.0),
            similarityScore: 0.75,
            commonWords: ["today", "great"]
        )
        
        return manager
    }
}

struct InsightWavyBackground: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: 0, y: height * 0.5))
        
        // Create a flowing, wavy path
        path.addCurve(
            to: CGPoint(x: width, y: height * 0.5),
            control1: CGPoint(x: width * 0.3, y: height * 0.35),
            control2: CGPoint(x: width * 0.7, y: height * 0.65)
        )
        
        // Complete the shape
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

// Preview
struct InsightsView_Previews: PreviewProvider {
    static var previews: some View {
        InsightsView(analysisManager: AnalysisManager.mock)
            .previewDevice("iPhone 14 Pro")
            .previewDisplayName("Insights View")
    }
}
