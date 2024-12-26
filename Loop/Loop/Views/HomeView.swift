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
    @State private var thematicPrompt: ThematicPrompt?
    @State private var scrollOffset: CGFloat = 0
    @State private var backgroundOpacity: Double = 0.2
    

    // Maintain existing color scheme
    let accentColor = Color(hex: "A28497")
    let backgroundColor = Color(hex: "FAFBFC")
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
//            
            ScrollView {
                VStack(spacing: 32) {
                    // Welcome header with subtle animation
                    welcomeHeader
                        .padding(.top, 45)
                        .padding(.horizontal, 24)
                    
//                        // Keep your original schedule bar if needed
//                        ScheduleBar(
//                            weekSchedule: loopManager.weekSchedule,
//                            accentColor: accentColor
//                        )
//                        .padding(.horizontal, 24)
                    
                    // Main recording interface - using original logic
                    recordingInterface
                        .padding(.horizontal, 24)
                    
                    // Thematic prompts section
                    thematicPromptsSection
                        .padding(.horizontal, 24)
                    
                    // Past loop showcase
                    if let pastLoop = loopManager.pastLoop {
                        pastLoopSection(pastLoop)
                            .padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 32)
            }
            .onPreferenceChange(ScrollOffsetKey.self) { offset in
                scrollOffset = offset
            }
        }
        .onAppear {
            withAnimation {  // Keep your original initialization
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
        .fullScreenCover(item: $thematicPrompt) { prompt in
            RecordThematicLoopPromptsView(prompt: prompt)
        }
    }
    
    // MARK: - Header Section
    private var welcomeHeader: some View {
        HStack(alignment: .bottom, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
//                    Text("December 24th")
//                        .font(.system(size: 35, weight: .medium))
//                        .foregroundColor(textColor)
                
                Text("December 24th")
                    .font(.custom("PPNeueMontreal-Medium", size: 37))

                
                Text("time to reflect")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(accentColor)
            }
            
            Spacer()
//
//                // Daily progress indicator
//                if let currentStreak = loopManager.currentStreak?.currentStreak {
//                    HStack(spacing: 8) {
//                        Text("\(currentStreak)")
//                            .font(.system(size: 20, weight: .medium))
//                            .foregroundColor(accentColor)
//
//                        Image(systemName: "flame.fill")
//                            .foregroundColor(accentColor)
//                            .font(.system(size: 16))
//                    }
//                    .padding(.horizontal, 16)
//                    .padding(.vertical, 8)
//                    .background(
//                        RoundedRectangle(cornerRadius: 12)
//                            .fill(accentColor.opacity(0.08))
//                    )
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 12)
//                            .stroke(accentColor.opacity(0.1), lineWidth: 1)
//                    )
//                }
        }
    }
 
    private var recordingInterface: some View {
        Button(action: { showingRecordLoopsView = true }) {
            VStack(spacing: 24) {
                // Top section with subtle paper texture feel
                VStack(spacing: 16) {
                    if !loopManager.hasCompletedToday && !loopManager.dailyPrompts.isEmpty {
                        // Entry number indicator with a handwritten feel
                        Text("entry \(loopManager.currentPromptIndex + 1) of 3")
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(accentColor.opacity(0.7))
                            .padding(.top, 8)
                        
                        // Prompt text styled like handwritten journal prompts
                        Text(loopManager.getCurrentPrompt())
                            .font(.system(size: 26, weight: .light))
                            .multilineTextAlignment(.center)
                            .foregroundColor(textColor)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                        
                        // Subtle separator line
                        Rectangle()
                            .fill(accentColor.opacity(0.1))
                            .frame(width: 60, height: 1)
                        
                        // Record indicator that feels like a journal annotation
                        HStack(spacing: 6) {
                            // Minimalist waveform
                            HStack(spacing: 3) {
                                ForEach(0..<5) { index in
                                    RoundedRectangle(cornerRadius: 0.5)
                                        .fill(accentColor.opacity(0.5))
                                        .frame(width: 1, height: CGFloat([12, 16, 20, 16, 12][index]))
                                }
                            }
                            
                            Text("tap to record")
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(accentColor)
                        }
                        .padding(.vertical, 8)
                    } else {
                        Text("complete for today")
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(textColor)
                            .padding(.vertical, 40)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 2) // Very subtle rounding
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(accentColor.opacity(0.08), lineWidth: 0.5)
                )
            }
        }
    }
    // MARK: - Thematic Section
    private var thematicPromptsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("themes")
                .font(.system(size: 24, weight: .regular))
                .foregroundColor(textColor)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(loopManager.thematicPrompts.enumerated()), id: \.element.id) { index, prompt in
                        ThematicPromptCard(prompt: prompt, accentColor: accentColor, isEven: index % 2 == 0) {
                            thematicPrompt = prompt
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
    }
    
    // MARK: - Past Loop Section
    private func pastLoopSection(_ loop: Loop) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("from your past")
                .font(.system(size: 24, weight: .regular))
                .foregroundColor(textColor)
            
            PastLoopCard(loop: loop, accentColor: accentColor) {
                selectedLoop = loop
            }
        }
    }
}

// MARK: - Supporting Views
struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct DailyProgressRing: View {
    let completed: Int
    let total: Int
    let accentColor: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(accentColor.opacity(0.2), lineWidth: 2)
            
            Circle()
                .trim(from: 0, to: CGFloat(completed) / CGFloat(total))
                .stroke(accentColor, lineWidth: 2)
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 40, height: 40)
    }
}

import SwiftUI

// MARK: - Dynamic Background
struct DynamicBackground: View {
    let scrollOffset: CGFloat
    
    var body: some View {
        ZStack {
            Color(hex: "FAFBFC")
            
            // Dynamic gradient elements that respond to scroll
            GeometryReader { geometry in
                let size = geometry.size
                
                // Gradient shapes that move with scroll
                ZStack {
                    // Top gradient blob
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "A28497").opacity(0.08),
                                    Color(hex: "A28497").opacity(0.02)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: size.width * 0.8)
                        .offset(x: -size.width * 0.2, y: -size.height * 0.1 + (scrollOffset * 0.2))
                        .blur(radius: 30)
                    
                    // Bottom gradient blob
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "A28497").opacity(0.06),
                                    Color(hex: "A28497").opacity(0.02)
                                ],
                                startPoint: .bottomTrailing,
                                endPoint: .topLeading
                            )
                        )
                        .frame(width: size.width * 0.7)
                        .offset(x: size.width * 0.2, y: size.height * 0.3 + (scrollOffset * 0.1))
                        .blur(radius: 25)
                }
            }
        }
    }
    
    func formatDate() -> String {
        let dayNumber = Calendar.current.component(.day, from: Date())
        
        let formatString = "MMMM d"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = formatString
        var formattedDate = dateFormatter.string(from: Date())
        
        var suffix: String
        switch dayNumber {
            case 1, 21, 31: suffix = "st"
            case 2, 22: suffix = "nd"
            case 3, 23: suffix = "rd"
            default: suffix = "th"
        }
        
        formattedDate.append(suffix)
        
        return formattedDate
    }
}

// MARK: - Waveform View
struct HomeWaveformView: View {
    let accentColor: Color
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<30) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(accentColor.opacity(0.6))
                    .frame(width: 2, height: getHeight(for: index))
                    .animation(
                        Animation
                            .easeInOut(duration: 1)
                            .repeatForever()
                            .delay(Double(index) * 0.05),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    private func getHeight(for index: Int) -> CGFloat {
        let baseHeight: CGFloat = 20
        let variance: CGFloat = isAnimating ? 30 : 10
        return baseHeight + sin(Double(index) * 0.5) * variance
    }
}

struct ThematicPromptCard: View {
    let prompt: ThematicPrompt
    let accentColor: Color
    let isEven: Bool
    let onTap: () -> Void
    
    private let surfaceColor = Color(hex: "F8F5F7")
    
    var body: some View {
        Button(action: onTap) {
            GeometryReader { geometry in
                VStack {
                    if isEven {
                        contentLayout(height: geometry.size.height)
                            .padding(.top, 8)
                        Spacer()
                    } else {
                        Spacer()
                        contentLayout(height: geometry.size.height)
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .frame(width: 160, height: 220)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.white)
                    
                    WavyBackground()
                        .foregroundColor(surfaceColor)
                        .rotation3DEffect(
                            .degrees(isEven ? 0 : 180),
                            axis: (x: 1, y: 0, z: 0)
                        )
                        .offset(y: isEven ? 25 : -25)
    //
                        .cornerRadius(10)
                }
            )
//            .overlay(
//                RoundedRectangle(cornerRadius: 20)
//                   // .stroke(accentColor.opacity(0.08), lineWidth: 1)
//            )
        }
    }
    
    @ViewBuilder
    private func contentLayout(height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(prompt.name)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(hex: "2C3E50"))
                
                Text(prompt.description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(hex: "2C3E50").opacity(0.7))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var themeIcon: some View {
        ZStack {
            Circle()
                .fill(accentColor.opacity(0.1))
            
            Image(systemName: getIconName(for: prompt.name))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(accentColor)
        }
    }
    
    private func getIconName(for theme: String) -> String {
        switch theme.lowercased() {
        case "growth": return "leaf"
        case "gratitude": return "heart"
        case "reflection": return "sparkles"
        default: return "circle"
        }
    }
}

// MARK: - Past Loop Card
struct PastLoopCard: View {
    let loop: Loop
    let accentColor: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 24) {
                // Header with date and play button
                HStack {
                    Label(formatDate(loop.timestamp), systemImage: "calendar")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(hex: "2C3E50").opacity(0.6))
                    
                    Spacer()
                    
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
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(Color(hex: "2C3E50"))
                    .lineLimit(3)
                
                // Waveform
                HomeWaveformView(accentColor: accentColor)
                    .frame(height: 40)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(accentColor.opacity(0.08), lineWidth: 1)
            )
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

#Preview {
    HomeView()
}
