//
//  HomeView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/1/24.
//


import SwiftUI
struct HomeView: View {
    @ObservedObject var loopManager = LoopManager.shared
    @State private var showingRecordLoopsView = false
    @State private var showPastLoopSheet = false
    @State private var selectedLoop: Loop?
    @State private var backgroundOpacity: Double = 0.2
    @State private var thematicPrompt: ThematicPrompt?
    
    let accentColor = Color(hex: "A28497")
    let secondaryColor = Color(hex: "B7A284")
    let backgroundColor = Color(hex: "FAFBFC")
    let surfaceColor = Color(hex: "F8F5F7")
    let textColor = Color(hex: "2C3E50")
    
    private var timeOfDay: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "morning"
        case 12..<17: return "afternoon"
        default: return "evening"
        }
    }
    
    var body: some View {
        ZStack {
            FlowingBackground(color: accentColor)
                .opacity(backgroundOpacity)
                .ignoresSafeArea()
            
            
            ScrollView {
                VStack(spacing: 16) {
                    topBar
                        .padding(.top, 16)
                    
                    
                    
//                    ScheduleBar(
//                        weekSchedule: loopManager.weekSchedule,
//                        accentColor: accentColor
//                    )
                    
                    todaysPromptCard
                        .transition(.opacity)
                    
                    thematicLoopsSection
                            .transition(.opacity)

                    
                    if loopManager.pastLoop != nil {
                        memoryLaneSection
                            .transition(.opacity)
                    }
                    
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            withAnimation {
                loopManager.fetchWeekSchedule()
                Task {
                    await loopManager.loadThematicPrompts()
                }

            }
        }
        .fullScreenCover(item: $selectedLoop) { loop in
            ViewPastLoopView(loop: loop, isThroughRecordLoopsView: false)
        }
        .fullScreenCover(isPresented: $showingRecordLoopsView) {
            RecordLoopsView(isFirstLaunch: false)
        }
        .fullScreenCover(item: $thematicPrompt) { thematicPrompt in
            RecordThematicLoopPromptsView(prompt: thematicPrompt)
        }
    }
    
    private var topBar: some View {
        HStack(spacing: 20) {
            // Left side greeting and day counter
            VStack(alignment: .leading, spacing: 6) {
                Text("good \(timeOfDay)")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(textColor)
                
                HStack(spacing: 4) {
                    Text("day")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(.gray)
                    Text("eighteen")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(accentColor)
                    Text("on loop")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Right side streak counter
            if let currentStreak = loopManager.currentStreak?.currentStreak {
                HStack(spacing: 8) {
                    Text("\(currentStreak)")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(accentColor)
                    
                    Image(systemName: "flame.fill")
                        .foregroundColor(accentColor)
                        .font(.system(size: 16))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(accentColor.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(accentColor.opacity(0.1), lineWidth: 1)
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
    
    private var todaysPromptCard: some View {
        Button(action: {
            showingRecordLoopsView = true
        }) {
            VStack(spacing: 0) {
                // Top section with small title
                Text("today's reflection")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 28)
                    .padding(.top, 28)
                
                // Waveform design
                HStack(spacing: 4) {
                    ForEach(0..<7) { index in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(accentColor.opacity(0.6))
                            .frame(width: 2, height: CGFloat(([20, 30, 40, 50, 40, 30, 20])[index]))
                    }
                }
                .padding(.vertical, 32)
                
                // Main prompt section
                VStack(spacing: 8) {
                    if !loopManager.hasCompletedToday && !loopManager.dailyPrompts.isEmpty {
                        Text(loopManager.getCurrentPrompt())
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(textColor)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity)
                        
                        Text(loopManager.getCategoryForPrompt(loopManager.getCurrentPrompt())?.rawValue ?? "start now")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.gray)
                    } else {
                        Text("thanks for looping")
                            .font(.system(size: 28, weight: .ultraLight))
                            .foregroundColor(textColor)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 28)
                
                Spacer()
                
                // Progress indicator at bottom
                ProgressIndicator(
                    totalSteps: loopManager.dailyPrompts.count,
                    currentStep: loopManager.currentPromptIndex,
                    accentColor: accentColor
                )
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
            }
            .frame(height: 340) // Fixed height for consistent card size
            .background(
                ZStack {
                    // Main background
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                    
                    // Gradient overlay for contrast
                    LinearGradient(
                        colors: [
                            accentColor.opacity(0.05),
                            accentColor.opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            )
            .shadow(
                color: Color.black.opacity(0.04),
                radius: 20,
                x: 0,
                y: 10
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(accentColor.opacity(0.05), lineWidth: 1)
            )
        }
    }
    
    private var thematicLoopsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("themes")
                        .font(.system(size: 24, weight: .ultraLight))
                        .foregroundColor(textColor)
                    
                    Text("explore deeper reflections")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(accentColor)
                }
                
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    // Theme cards
                    ForEach(Array(loopManager.thematicPrompts.prefix(3))) { theme in
                        Button {
                            self.thematicPrompt = theme
                        } label: {
                            VStack(spacing: 16) {
                                Text(theme.name)
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(textColor)
                                    .padding(.top, 24)
                                
                                Text(theme.description)
                                    .font(.system(size: 16, weight: .light))
                                    .foregroundColor(textColor.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 24)
                            }
                            .frame(width: 200, height: 250)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
//                            .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(accentColor.opacity(0.05), lineWidth: 1)
                            )
                        }
                    }
                    
                    // Enhanced view more button
                    Button {
                        // Handle see more action
                    } label: {
                        VStack(spacing: 12) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .light))
                                .foregroundColor(textColor.opacity(0.6))
                            
                            Text("View More")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(textColor.opacity(0.6))
                        }
                        .frame(width: 200, height: 250)
                        .background(Color(hex: "F5F5F5"))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
//                        .shadow(color: Color.black.opacity(0.03), radius: 15, x: 0, y: 8)
                    }
                }
                .padding(.bottom, 12)
            }
            .scrollIndicators(.hidden)
        }
    }
    
    private var memoryLaneSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("from your past")
                .font(.system(size: 24, weight: .ultraLight))
                .foregroundColor(textColor)
            
            if let pastLoop = loopManager.pastLoop {
                Button {
                    selectedLoop = pastLoop
                } label: {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header with quote icon
                        HStack {
                            Image(systemName: "quote.opening")
                                .font(.system(size: 24, weight: .ultraLight))
                                .foregroundColor(accentColor)
                            Spacer()
                            
                            // Small play button
                            Circle()
                                .fill(accentColor.opacity(0.1))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(accentColor)
                                )
                        }
                        
                        Text(pastLoop.promptText)
                            .font(.system(size: 18, weight: .light))
                            .foregroundColor(textColor)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                        
                        AudioWaveform(color: accentColor)
                            .padding(.vertical, 8)
                        
                        HStack {
                            Image(systemName: "calendar")
                                .font(.system(size: 14, weight: .light))
                            Text(formatDate(pastLoop.timestamp))
                                .font(.system(size: 14, weight: .light))
                        }
                        .foregroundColor(textColor.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.04), radius: 15, x: 0, y: 8)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(accentColor.opacity(0.08), lineWidth: 1)
                    )
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("loop insights")
                .font(.system(size: 24, weight: .ultraLight))
                .foregroundColor(textColor)
            
            VStack(spacing: 16) {
                InsightRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "monthly reflection",
                    detail: "you've mentioned 'stress' 8 times",
                    accentColor: accentColor
                )
                
                Divider()
                    .background(accentColor.opacity(0.1))
                
                InsightRow(
                    icon: "leaf",
                    title: "goal suggestion",
                    detail: "meditate for 5 minutes today",
                    accentColor: accentColor
                )
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(surfaceColor)
            )
        }
    }

    
    private var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM.dd.yyyy"
        return dateFormatter.string(from: Date())
    }
}

struct InsightRow: View {
    let icon: String
    let title: String
    let detail: String
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(Color(hex: "2C3E50").opacity(0.6))
                
                Text(detail)
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(Color(hex: "2C3E50"))
            }
        }
    }
}

struct CircularProgressRing: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 2)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, lineWidth: 2)
                .rotationEffect(.degrees(-90))
        }
    }
}

struct PastLoopCard: View {
    let loop: Loop
    let accentColor: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 24, weight: .ultraLight))
                        .foregroundColor(accentColor)
                    Spacer()
                }
                
                Text(loop.promptText)
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(Color(hex: "2C3E50"))
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .light))
                    Text(formatDate(loop.timestamp))
                        .font(.system(size: 14, weight: .light))
                }
                .foregroundColor(Color(hex: "2C3E50").opacity(0.6))
            }
            .frame(width: 240)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .shadow(
                        color: Color.black.opacity(0.04),
                        radius: 15,
                        x: 0,
                        y: 8
                    )
            )
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct HomeBackground: View {
    let accentColor = Color(hex: "A28497")
    let secondaryColor = Color(hex: "B7A284")
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color(hex: "FAFBFC").edgesIgnoringSafeArea(.all)
            
            GeometryReader { geometry in
                ZStack {
                    // Gradient circles
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    accentColor.opacity(0.04),
                                    accentColor.opacity(0.01)
                                ]),
                                center: .center,
                                startRadius: 50,
                                endRadius: 250
                            )
                        )
                        .frame(width: geometry.size.width * 0.8)
                        .offset(x: -geometry.size.width * 0.3, y: -geometry.size.height * 0.2)
                        .blur(radius: 40)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    secondaryColor.opacity(0.04),
                                    secondaryColor.opacity(0.01)
                                ]),
                                center: .center,
                                startRadius: 50,
                                endRadius: 200
                            )
                        )
                        .frame(width: geometry.size.width * 0.6)
                        .offset(x: geometry.size.width * 0.3, y: geometry.size.height * 0.4)
                        .blur(radius: 40)
                    
                    // Floating elements
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(accentColor.opacity(0.05))
                            .frame(width: CGFloat(40 + index * 20))
                            .offset(
                                x: CGFloat(index * 100 - 100),
                                y: CGFloat(index * 120 - 120)
                            )
                            .blur(radius: 20)
                            .opacity(isAnimating ? 0.8 : 0.4)
                            .animation(
                                Animation.easeInOut(duration: 4)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.5),
                                value: isAnimating
                            )
                    }
                }
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct ScheduleBar: View {
    let weekSchedule: [Date: Bool]
    let accentColor: Color
    
    private let calendar = Calendar.current
    
    private var sortedDates: [Date] {
        weekSchedule.keys.sorted()
    }
    
    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
    
    private func formatWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date).prefix(1).uppercased()
    }
    
    private func formatDayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 12) {
                ForEach(sortedDates, id: \.self) { date in
                    let isDateToday = isToday(date)
                    let isCompleted = weekSchedule[date] == true
                    
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isDateToday ? accentColor : Color(hex: "2C3E50").opacity(0.2),
                                lineWidth: isDateToday ? 2 : 1
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isCompleted ? accentColor : Color.clear)
                            )
                            .frame(width: 32, height: 32)
                        
                        VStack(spacing: 2) {
                            Text(formatWeekday(date))
                                .font(.system(size: 12, weight: .medium))
                            Text(formatDayNumber(date))
                                .font(.system(size: 12, weight: .light))
                        }
                        .foregroundColor(
                            isDateToday ?
                            accentColor :
                            Color(hex: "2C3E50").opacity(0.6)
                        )
                    }
                    .frame(width: (geometry.size.width - (CGFloat(sortedDates.count - 1) * 12)) / CGFloat(sortedDates.count))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 70)
    }
}

struct AdditionalLoopCard: View {
    var body: some View {
        VStack {
            
        }
    }
}

struct GeometricIcon: View {
    let themeId: String
    let accentColor = Color(hex: "A28497")
    
    var body: some View {
        ZStack {
            switch themeId {
            case "growth journey":
                // Growth theme - Ascending spiral of translucent layers
                ZStack {
                    // Base spiral
                    ForEach(0..<8) { i in
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(
                                accentColor.opacity(Double(8 - i) / 12),
                                lineWidth: 1.5
                            )
                            .frame(width: 35 + CGFloat(i * 8))
                            .rotationEffect(.degrees(Double(i) * 45))
                    }
                    
                    // Intersecting lines
                    ForEach(0..<3) { i in
                        Rectangle()
                            .fill(accentColor.opacity(0.15))
                            .frame(width: 1, height: 60)
                            .rotationEffect(.degrees(Double(i) * 60 - 30))
                            .offset(x: 20)
                    }
                }
                
            case "gratitude":
                // Reflection theme - Mandala-like pattern with gradient rings
                ZStack {
                    // Outer decorative circle
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    accentColor.opacity(0.4),
                                    accentColor.opacity(0.1),
                                    accentColor.opacity(0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .frame(width: 80)
                    
                    // Inner pattern
                    ForEach(0..<6) { i in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        accentColor.opacity(0.3),
                                        accentColor.opacity(0.1)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 2, height: 40)
                            .rotationEffect(.degrees(Double(i) * 60))
                            .overlay(
                                Circle()
                                    .fill(accentColor.opacity(0.4))
                                    .frame(width: 4)
                                    .offset(y: -20)
                            )
                    }
                    
                    // Center detail
                    Circle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 12)
                }
                
            default:
                // Focus theme - Concentric waves with dynamic spacing
                ZStack {
                    // Background circles
                    ForEach(0..<4) { i in
                        Circle()
                            .stroke(
                                accentColor.opacity(Double(4 - i) / 8),
                                lineWidth: 1
                            )
                            .frame(width: 30 + CGFloat(i * 20))
                    }
                    
                    // Overlaying pattern
                    ForEach(0..<8) { i in
                        Capsule()
                            .fill(accentColor.opacity(0.2))
                            .frame(width: 2, height: 40)
                            .rotationEffect(.degrees(Double(i) * 45))
                            .offset(y: -10)
                    }
                    
                    // Center focal point
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    accentColor.opacity(0.5),
                                    accentColor.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 15)
                }
            }
        }
        .frame(height: 120)
    }
}

#Preview {
    HomeView()
}
