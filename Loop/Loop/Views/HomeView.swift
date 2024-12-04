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
    @State private var backgroundOpacity: Double = 0
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
            HomeBackground()
                .opacity(backgroundOpacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.2)) {
                        backgroundOpacity = 1
                    }
                }
            
            
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

                    
                    if loopManager.pastLoops.count > 0 {
                        memoryLaneSection
                            .transition(.opacity)
                    }
                    
                    insightsCard
                        .transition(.opacity)
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
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("good \(timeOfDay)")
                    .font(.system(size: 32, weight: .ultraLight))
                    .foregroundColor(textColor)
    //            if loopManager.currentStreak > 0 {
    //                Text("\(loopManager.currentStreak) day streak")
    //                    .font(.system(size: 16, weight: .light))
    //                    .foregroundColor(accentColor)
    //            }
                
                Text("day eighteen on loop")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(accentColor)
            }
            
            Spacer()
            
            if let currentStreak = loopManager.currentStreak?.currentStreak {
                VStack(spacing: 6) {
                    Text("\(currentStreak)")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(accentColor)
                    
                    Image(systemName: "flame.fill")
                        .foregroundColor(accentColor)
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(accentColor.opacity(0.1))
                )
            }
            
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 16)
    }
    
    private var todaysPromptCard: some View {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("today's reflection")
                        .font(.system(size: 24, weight: .ultraLight))
                        .foregroundColor(textColor)
                    
                    ProgressIndicator(
                        totalSteps: loopManager.dailyPrompts.count,
                        currentStep: loopManager.currentPromptIndex,
                        accentColor: accentColor
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.top, 28)
                .padding(.bottom, 24)

                Rectangle()
                    .fill(LinearGradient(
                        colors: [accentColor.opacity(0.1), accentColor.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(height: 1)
                    .padding(.horizontal, 20)
        
                VStack(alignment: .leading, spacing: 24) {
                    if !loopManager.hasCompletedToday && !loopManager.dailyPrompts.isEmpty {
                        Text(loopManager.getCurrentPrompt())
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(textColor)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("thanks for looping")
                            .font(.system(size: 28, weight: .ultraLight))
                            .foregroundColor(textColor)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
                
                Button(action: {
                    showingRecordLoopsView = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "mic")
                            .font(.system(size: 18, weight: .light))
                        Text("record your loops")
                            .font(.system(size: 18, weight: .light))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                accentColor,
                                accentColor.opacity(0.9)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(28)
                    .shadow(color: accentColor.opacity(0.15), radius: 12, y: 6)
                    .opacity(loopManager.hasCompletedToday ? 0.5 : 1)
                    .disabled(loopManager.hasCompletedToday)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(
                        color: Color.black.opacity(0.04),
                        radius: 20,
                        x: 0,
                        y: 10
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(accentColor.opacity(0.05), lineWidth: 1)
            )
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
        VStack(alignment: .leading, spacing: 20) {
            // Header with loop count
            HStack {
                Text("memory lane")
                    .font(.system(size: 24, weight: .ultraLight))
                    .foregroundColor(textColor)
                
                Spacer()
                
                if !loopManager.pastLoops.isEmpty {
                    Text("\(loopManager.pastLoops.count) loops")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(accentColor)
                }
            }
            
            if loopManager.pastLoops.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "waveform")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(accentColor.opacity(0.6))
                    
                    Text("Your past loops will appear here")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(textColor.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(surfaceColor)
                )
            } else {
                // Scrolling loop cards
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(loopManager.pastLoops) { loop in
                            Button {
                                selectedLoop = loop
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
                                    
                                    // Prompt text
                                    Text(loop.promptText)
                                        .font(.system(size: 18, weight: .light))
                                        .foregroundColor(textColor)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(3)
                                    
                                    Spacer()
                                    
                                    // Date with small icon
                                    HStack {
                                        Image(systemName: "calendar")
                                            .font(.system(size: 14, weight: .light))
                                        Text(formatDate(loop.timestamp))
                                            .font(.system(size: 14, weight: .light))
                                    }
                                    .foregroundColor(textColor.opacity(0.6))
                                }
                                .frame(width: 240, height: 180)
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 24)
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.04), radius: 15, x: 0, y: 8)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(accentColor.opacity(0.05), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.bottom, 12) // For shadow
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
    
    private var additionalLoops: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("try these too")
                    .font(.system(size: 24, weight: .ultraLight))
                    .foregroundColor(textColor)
                
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(loopManager.pastLoops, id: \.self) { loop in
//                        PastLoopCard(loop: loop, accentColor: accentColor) {
//                            selectedLoop = loop
//                        }
                    }
                }
                .padding(.bottom, 12)
            }
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
