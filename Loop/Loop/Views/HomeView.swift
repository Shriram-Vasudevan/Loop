//
//  HomeView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/1/24.
//


import SwiftUI

struct HomeView: View {
    @Binding var pageType: PageType
    @Binding var selectedScheduleDate: Date?
        
    @ObservedObject var loopManager = LoopManager.shared
    @ObservedObject var scheduleManager = ScheduleManager.shared
    @ObservedObject var reflectionSessionManager = ReflectionSessionManager.shared
    
    @State private var showingRecordLoopsView = false
    @State private var showPastLoopSheet = false
    @State private var selectedLoop: Loop?
    @State private var thematicPrompt: ThematicPrompt?
    @State private var scrollOffset: CGFloat = 0
    @State private var backgroundOpacity: Double = 0.2
    @State private var featuredPrompt: FeaturedPrompt?
    
    @State var navigateToAllThemesView: Bool = false
    @State var navigateToSettingsView: Bool = false
    @State var navigateToDaySummary: Bool = false
    
    @State private var showUnlockReminder = true
    @State private var distinctDays: Int = 0
    
    var displayedPrompts: [ThematicPrompt] {
        Array(loopManager.thematicPrompts.sorted(by: { a, b in
            a.id > b.id
        }))
    }

    @State private var showTutorial = FirstLaunchManager.shared.showTutorial
    
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
    
    let sampleData: [Date: String] = [
        Calendar.current.startOfDay(for: Date()): "Joy",
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -1, to: Date())!): "Calm",
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!): "Peace"
    ]
    
    // Sample color mappings based on frequency
    let sampleColors: [String: Color] = [
        "Joy": Color(hex: "A28497"),
        "Calm": Color(hex: "B5D5E2"),
        "Peace": Color(hex: "C2E5C9")
    ]
    
    var body: some View {
        ZStack {
            FlowingBackground(color: accentColor)
                .opacity(backgroundOpacity)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    VStack (spacing: 12) {
//                        HStack {
//                            StreakIndicator()
//                            
//                            Spacer()
//                        }
//                        .padding(.horizontal, 24)
//                        .padding(.top, 22)
//                        
//                        welcomeHeader
//                            .padding(.horizontal, 24)
//                            .padding(.top, 44)
////                        LoopHomeHeader()
////                            .padding(.horizontal, 24)
//
//                        VStack (spacing: 6) {
//                            EmotionSchedulePreviewView(pageType: $pageType, selectedScheduleDate: $selectedScheduleDate)
//                              
//                            Divider()
//                        }
                        
                        JournalHeader(navigateToSettingsView: $navigateToSettingsView)
                    }
                    
                    VStack (spacing: 16) {
                        recordingInterface
                            .padding(.horizontal, 24)

                    }
                    thematicPromptsSection
                        .padding(.horizontal, 24)
                    
//                    featuredReflectionsSection
//                        .padding(.horizontal, 24)
//                    
//                    DayRatingSlider()
//                        .padding(.horizontal, 24)
//                        .padding(.top, 6)
                    
//                    notificationsSection
                    
                   
                    
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
            Task {
                await loopManager.loadThematicPrompts()
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
        .fullScreenCover(item: $featuredPrompt) { prompt in
            RecordFeaturedLoopView(prompt: prompt.prompt)
        }
        .navigationDestination(isPresented: $navigateToAllThemesView) {
            AllThemesView()
        }
        .navigationDestination(isPresented: $navigateToSettingsView) {
            SettingsView()
        }
        .navigationDestination(isPresented: $navigateToDaySummary) {
            DaySummaryView()
        }
    }
    
    // MARK: - Header Section
    private var welcomeHeader: some View {
        ZStack {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(getGreeting())
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(textColor)
                    
                    Text(formatDate())
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(textColor.opacity(0.6))
                }
                
                Spacer()
                
                Button {
                    navigateToSettingsView = true
                } label: {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(textColor)
                        .padding(.bottom, 7)
                }

            }
        }
    }
    
    private var recordingInterface: some View {
        Button(action: { showingRecordLoopsView = true }) {
            Group {
                if !ReflectionSessionManager.shared.hasCompletedForToday {
                    VStack (spacing: 8) {
                        if showTutorial {
                            DailyReflectionTutorial {
                                withAnimation(.spring(response: 0.3)) {
                                    showTutorial = false
                                    FirstLaunchManager.shared.showTutorial = false
                                }
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        SunsetReflectionView()
                        
                    }
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("DAILY REFLECTION")
                            .font(.system(size: 13, weight: .medium))
                            .tracking(1.5)
                            .foregroundColor(accentColor.opacity(0.5))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("complete for today")
                                .font(.system(size: 24, weight: .light))
                                .foregroundColor(textColor)
                            
                            if let summary = AnalysisManager.shared.currentDailyAnalysis?.aiAnalysis.dailySummary {
                                Button {
                                    navigateToDaySummary = true
                                } label: {
                                    Text("see your daily summary")
                                        .font(.system(size: 13, weight: .medium))
                                        .tracking(1.5)
                                        .foregroundColor(textColor)
                                        .underline()
                                }

                            } else {
                                Text("great work!")
                                    .font(.system(size: 13, weight: .medium))
                                    .tracking(1.5)
                                    .foregroundColor(textColor)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(32)
                    .background(
                        ZStack(alignment: .bottomTrailing) {
                            Color.white
                            Image(systemName: "quote.closing")
                                .font(.system(size: 160))
                                .foregroundColor(accentColor.opacity(0.05))
                                .rotationEffect(.degrees(8))
                                .padding(.trailing, -20)
                                .padding(.bottom, -20)
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        }
    }
    
    // MARK: - Thematic Section
    private var thematicPromptsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("themes")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(textColor)
                
                Spacer()
                
                Button(action: {
                    navigateToAllThemesView = true
                }, label: {
                    Text("SEE MORE")
                        .font(.system(size: 11, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(textColor.opacity(0.5))
                })
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(displayedPrompts.prefix(3).enumerated()), id: \.element.id) { index, prompt in
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
    
//    private var featuredReflectionsSection: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            Text("featured reflections")
//                .font(.system(size: 13, weight: .medium))
//                .tracking(1.5)
//                .foregroundColor(textColor)
//            
//            ScrollView(.horizontal, showsIndicators: false) {
//                HStack(spacing: 16) {
//                    ForEach(loopManager.featuredReflections, id: \.text) { prompt in
//                        Button(action: {
//                            self.featuredPrompt = FeaturedPrompt(prompt: prompt.text)
//                        }) {
//                            VStack(alignment: .leading, spacing: 16) {
//                                HStack {
//                                    Text(prompt.text)
//                                        .font(.system(size: 14, weight: .medium))
//                                        .foregroundColor(textColor)
//                                        .multilineTextAlignment(.leading)
//                                        .lineLimit(2)
//                                        .frame(width: 200)
//                                    
//                                    Spacer()
//                                }
//                                
//                                HStack(spacing: 6) {
//                                    Image(systemName: "mic.fill")
//                                        .font(.system(size: 10))
//                                    Text("RECORD")
//                                        .font(.system(size: 11, weight: .medium))
//                                        .tracking(1.5)
//                                    
//                                    Spacer()
//                                }
//                                .foregroundColor(accentColor.opacity(0.6))
//                            }
//                            .frame(width: 240)
//                            .padding(24)
//                            .background(
//                                ZStack {
//                                    RoundedRectangle(cornerRadius: 10)
//                                        .fill(.white)
//                                    
//                                    WavyBackgroundGrey()
//                                        .cornerRadius(10)
//                                }
//                            )
//                            .overlay(
//                                RoundedRectangle(cornerRadius: 16)
//                                    .stroke(accentColor.opacity(0.05), lineWidth: 1)
//                            )
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("more")
                .font(.system(size: 24, weight: .regular))
                .foregroundColor(textColor)
            
            VStack(spacing: 4) {
                if !loopManager.hasRemovedUnlockReminder {
                    // Unlock Past Loops Notification
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 12))
                                
                                Text("PAST REFLECTIONS")
                                    .font(.system(size: 11, weight: .medium))
                                    .tracking(1.5)
                            }
                            .foregroundColor(accentColor.opacity(0.6))
                            
                            Text("Complete 3 days of Loop to unlock your reflection archive")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(textColor)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Spacer()
                        
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                loopManager.dismissUnlockReminder()
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12))
                                .foregroundColor(accentColor.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 28)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.03), radius: 15, x: 0, y: 4)
                    )
                }
                
                // Insights Notification
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 12))
                            
                            Text("WEEKLY INSIGHTS")
                                .font(.system(size: 11, weight: .medium))
                                .tracking(1.5)
                        }
                        .foregroundColor(accentColor.opacity(0.6))
                        
                        Text("Track your weekly reflection patterns and growth")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(textColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    Text("VIEW")
                        .font(.system(size: 11, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(accentColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(accentColor.opacity(0.08))
                        )
                        .onTapGesture {
                            self.pageType = .trends
                        }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 28)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.03), radius: 15, x: 0, y: 4)
                )
            }
        }
        .padding(.horizontal, 24)
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
    
    private func fetchDistinctLoopingDays() async {
        do {
            let dates = try await loopManager.fetchDistinctLoopingDays()
            await MainActor.run {
                distinctDays = dates
            }
        } catch {
            print("Failed to fetch distinct days: \(error)")
        }
    }
    
    func getGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 0..<12:
            return "good morning."
        case 12..<17:
            return "good afternoon."
        case 17..<24:
            return "good evening."
        default:
            return "hey there."
        }
    }
}


struct DailyReflectionTutorial: View {
    let onDismiss: () -> Void
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header with close button
            HStack {
                Text("Begin Your First Reflection")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(textColor)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(accentColor.opacity(0.6))
                }
            }
            
            Text("Your daily reflection is a personalized space to process your day.")
                .font(.system(size: 16))
                .foregroundColor(textColor.opacity(0.7))
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
            
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accentColor.opacity(0.08), lineWidth: 1)
        )
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
//                        .foregroundColor(accentColor)
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
                    .lineLimit(3)
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

struct RecordingInterface: View {
    let prompt: String
    let currentIndex: Int
    let totalPrompts: Int
    let accentColor: Color
    let textColor: Color
    let isCompleted: Bool
    let onTap: () -> Void
    
    private var safeCurrentIndex: Int {
        max(0, min(currentIndex, totalPrompts - 1))
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 32) {
                if !isCompleted {
                    VStack(alignment: .leading, spacing: 40) {
                        // Header with minimal styling
                        VStack(alignment: .center, spacing: 8) {
                            Text("TODAY'S REFLECTION")
                                .font(.system(size: 13, weight: .medium))
                                .tracking(1.5)
                                .foregroundColor(textColor.opacity(0.5))
                            
                            Text(prompt)
                                .font(.system(size: 26, weight: .light))
                                .foregroundColor(textColor)
                                .lineSpacing(8)
                        }
                        
                        // Safe progress indicator
                        if totalPrompts > 0 {
                            HStack(spacing: 24) {
                                ForEach(0..<totalPrompts, id: \.self) { index in
                                    Circle()
                                        .fill(index == safeCurrentIndex ? accentColor : accentColor.opacity(0.15))
                                        .frame(width: 8, height: 8)
                                }
                            }
                        }
                    }
                } else {
                    // Completed state with minimal design
                    VStack(alignment: .leading, spacing: 16) {
                        Text("complete for today")
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(textColor)
                        
                        Text("GREAT WORK!")
                            .font(.system(size: 13, weight: .medium))
                            .tracking(1.5)
                            .foregroundColor(accentColor.opacity(0.5))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WavyOverlay: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: 0, y: 0.8 * height))
        
        // First wave
        path.addCurve(
            to: CGPoint(x: width, y: 0.4 * height),
            control1: CGPoint(x: width * 0.4, y: 0.5 * height),
            control2: CGPoint(x: width * 0.6, y: 0.7 * height)
        )
        
        // Complete the shape
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

struct StreakIndicator: View {
    @ObservedObject private var scheduleManager = ScheduleManager.shared
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        if scheduleManager.currentStreak > 0 {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12))
                    .foregroundColor(accentColor)
                
                Text("\(scheduleManager.currentStreak) day streak")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(textColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(accentColor.opacity(0.08))
            )
        }
        else {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12))
                    .foregroundColor(accentColor)
                
                Text("\(scheduleManager.currentStreak)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(textColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(accentColor.opacity(0.08))
            )
        }
    }
}

struct LoopHomeHeader: View {
    @ObservedObject var scheduleManager = ScheduleManager.shared
    let accentColor = Color(hex: "A28497")
    let textColor = Color(hex: "2C3E50")
    
    @State private var headerOffset: CGFloat = 0
    @State private var animateBackground = false
    
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
            // Animated background elements
            GeometryReader { geometry in
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.06))
                        .frame(width: 150, height: 150)
                        .offset(x: animateBackground ? -20 : -10, y: animateBackground ? -30 : -20)
                        .blur(radius: 20)
                    
                    Circle()
                        .fill(accentColor.opacity(0.04))
                        .frame(width: 100, height: 100)
                        .offset(x: animateBackground ? geometry.size.width - 100 : geometry.size.width - 90,
                                y: animateBackground ? 20 : 30)
                        .blur(radius: 15)
                }
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateBackground)
            }
            
            VStack(spacing: 24) {
                // Top row with time icon and streak
                HStack(alignment: .center) {
                    // Time of day indicator
                    HStack(spacing: 8) {
                        Image(systemName: timeOfDay == "evening" ? "moon.stars.fill" : "sun.max.fill")
                            .font(.system(size: 16))
                            .foregroundColor(timeOfDay == "evening" ? .purple : .orange)
//                            .symbolEffect(.bounce, options: .repeat(2))
                        
                        Text(getGreeting())
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(textColor)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.8))
                    )
                    
                    Spacer()
                    
                    // Streak indicator with animation
                    if scheduleManager.currentStreak > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.orange)
                               // .symbolEffect(.bounce, options: .repeat(2))
                            
                            Text("\(scheduleManager.currentStreak) day streak")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(textColor)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(accentColor.opacity(0.08))
                        )
                    }
                }
                
                // Date and insights row
                HStack(alignment: .bottom) {
                    Text(formatDate())
                        .font(.custom("PPNeueMontreal-Bold", size: 35))
                        .foregroundColor(textColor)
                    
                    Spacer()
                    
                    // Insights button
                    Button(action: {
                        // Add your insights navigation action here
                    }) {
                        HStack(spacing: 4) {
                            Text("insights")
                                .font(.system(size: 15, weight: .medium))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .stroke(accentColor.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.9))
                    .shadow(color: Color.black.opacity(0.03), radius: 15, x: 0, y: 4)
            )
        }
        .onAppear {
            withAnimation {
                animateBackground = true
            }
        }
    }
    
    private func formatDate() -> String {
        let dayNumber = Calendar.current.component(.day, from: Date())
        let formatString = "MMMM d"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = formatString
        var formattedDate = dateFormatter.string(from: Date())
        
        let suffix: String
        switch dayNumber {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }
        
        formattedDate.append(suffix)
        return formattedDate
    }
    
    private func getGreeting() -> String {
        switch timeOfDay {
        case "morning": return "good morning"
        case "afternoon": return "good afternoon"
        case "evening": return "good evening"
        default: return "hello"
        }
    }
}

struct JournalHeader: View {
    @Binding var navigateToSettingsView: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Today")
                    .font(.system(size: 34, weight: .medium))
                
                Spacer()
                
                Button {
                    navigateToSettingsView = true
                } label: {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.black)
                }
            }
            
            Text(formatDate().uppercased())
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color.black.opacity(0.5))
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
    
    private func formatDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
}

// Preview
struct JournalHeader_Previews: PreviewProvider {
    static var previews: some View {
        JournalHeader(navigateToSettingsView: .constant(false))
            .background(Color.white)
    }
}

#Preview {
    HomeView(pageType: .constant(.home), selectedScheduleDate: .constant(.now))
}
