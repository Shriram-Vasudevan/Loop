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
    
    let accentColor = Color(hex: "A28497")
    let secondaryColor = Color(hex: "B7A284")
    let backgroundColor = Color(hex: "FAFBFC")
    let surfaceColor = Color(hex: "F8F5F7")
    let textColor = Color(hex: "2C3E50")
    
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
                    
                    todayPromptCard
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
                loopManager.checkAndResetIfNeeded()
                loopManager.fetchWeekSchedule()
            }
        }
        .fullScreenCover(item: $selectedLoop) { loop in
            ViewPastLoopView(loop: loop)
        }
        .fullScreenCover(isPresented: $showingRecordLoopsView) {
            RecordLoopsView(isFirstLaunch: false)
        }
    }
    
    private var topBar: some View {
        HStack {
            Text("loop")
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundColor(textColor)
            
            Spacer()
            
            Text(formattedDate)
//            CircularProgressRing(
//                progress: Double(loopManager.currentPromptIndex) / Double(loopManager.prompts.count),
//                color: accentColor
//            )
//            .frame(width: 32, height: 32)
        }
    }
    
    private var todayPromptCard: some View {
        VStack(spacing: 28) {
            HStack {
                VStack(alignment: .leading, spacing: 20) {
                    Text("today's reflection")
                        .font(.system(size: 24, weight: .ultraLight))
                        .foregroundColor(textColor)
                    
                    ProgressIndicator(
                        totalSteps: loopManager.prompts.count,
                        currentStep: loopManager.currentPromptIndex,
                        accentColor: accentColor
                    )
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 16) {
                if !loopManager.hasCompletedToday {
                    Text(loopManager.getCurrentPrompt())
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(textColor)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                else {
                    Text("thanks for looping")
                        .font(.system(size: 28, weight: .ultraLight))
                        .foregroundColor(textColor)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            Button(action: {
                showingRecordLoopsView = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "mic")
                        .font(.system(size: 18, weight: .light))
                    Text("record your loop")
                        .font(.system(size: 18, weight: .light))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [accentColor, accentColor.opacity(0.9)]),
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
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(
                    color: Color.black.opacity(0.04),
                    radius: 20,
                    x: 0,
                    y: 10
                )
        )
    }
    
    private var memoryLaneSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("memory lane")
                    .font(.system(size: 24, weight: .ultraLight))
                    .foregroundColor(textColor)
                
                Spacer()
                
                Text("\(loopManager.pastLoops.count) loops")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(accentColor)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(loopManager.pastLoops, id: \.self) { loop in
                        PastLoopCard(loop: loop, accentColor: accentColor) {
                            selectedLoop = loop
                        }
                    }
                }
                .padding(.bottom, 12)
            }
        }
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

#Preview {
    HomeView()
}
