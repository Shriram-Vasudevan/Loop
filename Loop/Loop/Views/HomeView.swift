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
    @State private var showingNewLoops = false
    
    let accentColor = Color(hex: "A28497")
    let secondaryColor = Color(hex: "B7A284")
    let backgroundColor = Color(hex: "FAFBFC")
    let surfaceColor = Color(hex: "F8F5F7")
    let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        ZStack {
            HomeBackground(accentColor: accentColor, secondaryColor: secondaryColor)
                .opacity(backgroundOpacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.2)) {
                        backgroundOpacity = 1
                    }
                }
            
            ScrollView {
                VStack(spacing: 24) {
                    topBar
                        .padding(.top, 16)
                    
                    weekScheduleView
                        .transition(.opacity)
                    
                    recordLoopCard
                        .transition(.scale.combined(with: .opacity))
                    
                    memoryLaneSection
                        .transition(.opacity)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            loopManager.checkAndResetIfNeeded()
//            loopManager.showQueuedLoopsIfAvailable()
            loopManager.fetchWeekSchedule()
        }
        .fullScreenCover(item: $selectedLoop) { loop in
            ViewPastLoopView(loop: loop)
        }
        .fullScreenCover(isPresented: $showingRecordLoopsView) {
            RecordLoopsView(isFirstLaunch: false)
        }
    }
    
    var topBar: some View {
            VStack(spacing: 16) {
                HStack(alignment: .center) {
                    Text("loop")
                        .font(.system(size: 40, weight: .ultraLight))
                        .foregroundColor(textColor)
                    
                    Spacer()
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            // Add settings action here if needed
                        }) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 18, weight: .light))
                                .foregroundColor(textColor.opacity(0.6))
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: "flame")
                                .font(.system(size: 16, weight: .light))
                            Text("\(loopManager.weekSchedule.values.filter({ $0 }).count)")
                                .font(.system(size: 16, weight: .light))
                        }
                        .foregroundColor(accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(accentColor.opacity(0.1))
                        )
                    }
                }
                
                if loopManager.isLoadingSchedule {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("loading schedule...")
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(textColor.opacity(0.6))
                    }
                }
            }
            .padding(.bottom, 8)
        }
    
    private var weekScheduleView: some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return VStack(spacing: 16) {
            Text("reflection schedule")
                .font(.system(size: 24, weight: .ultraLight))
                .foregroundColor(textColor)
            
            HStack(spacing: 20) {
                ForEach(-3...3, id: \.self) { dayOffset in
                    if let date = calendar.date(byAdding: .day, value: dayOffset, to: today) {
                        let isToday = calendar.isDate(date, inSameDayAs: today)
                        let wasCompleted = loopManager.weekSchedule[calendar.startOfDay(for: date)] ?? false
                        let isPast = date < today
                        
                        VStack(spacing: 8) {
                            Text(formatWeekDay(date))
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(isToday ? accentColor : textColor.opacity(0.6))
                            
                            ZStack {
                                Circle()
                                    .fill(isToday ? accentColor.opacity(0.1) : Color.clear)
                                    .frame(width: 36, height: 36)
                                
                                if wasCompleted {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .light))
                                        .foregroundColor(isToday ? accentColor : accentColor.opacity(0.6))
                                } else if isPast {
                                    Circle()
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        .frame(width: 24, height: 24)
                                }
                                
                                Text("\(calendar.component(.day, from: date))")
                                    .font(.system(size: 16, weight: isToday ? .medium : .light))
                                    .foregroundColor(isToday ? accentColor : textColor.opacity(0.8))
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 15, x: 0, y: 8)
        )
    }
    
    private var recordLoopCard: some View {
        VStack(spacing: 32) {
            VStack(spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("today's reflection")
                            .font(.system(size: 28, weight: .ultraLight))
                            .foregroundColor(textColor)
                        
                        ProgressIndicator(
                            totalSteps: loopManager.prompts.count,
                            currentStep: loopManager.currentPromptIndex,
                            accentColor: accentColor
                        )
                    }
                    
                    Spacer()
                    
                    CircleProgress(
                        progress: Double(loopManager.currentPromptIndex) / Double(loopManager.prompts.count),
                        color: accentColor
                    )
                    .frame(width: 44, height: 44)
                }
                
                if !loopManager.hasCompletedToday {
                    Text(loopManager.getCurrentPrompt())
                        .font(.system(size: 32, weight: .ultraLight))
                        .foregroundColor(textColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineSpacing(4)
                }
            }
            
            Button(action: {
                showingRecordLoopsView = true
            }) {
                HStack(spacing: 16) {
                    Image(systemName: "mic")
                        .font(.system(size: 20, weight: .light))
                    Text("record your loop")
                        .font(.system(size: 20, weight: .light))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(
                    LinearGradient(
                        colors: [accentColor, accentColor.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(color: accentColor.opacity(0.25), radius: 20, y: 8)
                .opacity(loopManager.hasCompletedToday ? 0.5 : 1)
            }
            .disabled(loopManager.hasCompletedToday)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 30, y: 15)
        )
    }
    
    private var memoryLaneSection: some View {
        VStack(spacing: 24) {
            HStack {
                Text("memory lane")
                    .font(.system(size: 24, weight: .ultraLight))
                    .foregroundColor(textColor)
                Spacer()
            }
            
            Group {
                if case .ready = loopManager.memoryBankStatus {
                    if loopManager.pastLoops.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 32))
                                .foregroundColor(accentColor)
                            Text("Loop to get memories")
                                .font(.system(size: 20, weight: .light))
                                .foregroundColor(textColor)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        memoriesScrollView
                    }
                } else if case .building(let daysRemaining) = loopManager.memoryBankStatus {
                    VStack(spacing: 16) {
                        Image(systemName: "lock")
                            .font(.system(size: 32))
                            .foregroundColor(accentColor)
                        Text("Keep looping to unlock memories")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(textColor)
                        Text("\(daysRemaining) days remaining")
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(textColor.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 15, x: 0, y: 8)
            )
        }
    }
    
    private var memoriesScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(loopManager.pastLoops, id: \.self) { loop in
                    PastLoopCard(loop: loop, accentColor: accentColor) {
                        selectedLoop = loop
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }
    
    private func formatWeekDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
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


struct CircleProgress: View {
    let progress: Double
    let color: Color
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            // Track Circle
            Circle()
                .stroke(color.opacity(0.1), lineWidth: 3)
            
            // Progress Circle
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        colors: [color, color.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.6), value: animatedProgress)
            
            // Center Text
            Text("\(Int(progress * 100))%")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)
        }
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { newProgress in
            animatedProgress = newProgress
        }
    }
}

struct PastLoopCard: View {
    let loop: Loop
    let accentColor: Color
    let onTap: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: "waveform")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(accentColor)
                    
                    Spacer()
                    
                    Text(formatDate(loop.timestamp))
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(Color(hex: "2C3E50").opacity(0.6))
                }
                
                Text(loop.promptText)
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(Color(hex: "2C3E50"))
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                
                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(accentColor.opacity(0.2))
                            .frame(width: 2, height: CGFloat.random(in: 10...20))
                    }
                }
            }
            .frame(width: 260)
            .padding(24)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                    
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(accentColor.opacity(isHovered ? 0.1 : 0), lineWidth: 1)
                }
            )
            .shadow(
                color: Color.black.opacity(isHovered ? 0.08 : 0.04),
                radius: isHovered ? 20 : 15,
                x: 0,
                y: isHovered ? 10 : 8
            )
            .scaleEffect(isHovered ? 1.02 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct HomeBackground: View {
    let accentColor: Color
    let secondaryColor: Color
    @State private var phase = 0.0
    @State private var isAnimating = false
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                // Update phase for continuous animation
                let timeStep = timeline.date.timeIntervalSince1970
                let baseHeight = size.height * 0.5

                // Draw multiple wave layers
                context.opacity = 0.08
                drawWave(in: context, size: size, phase: phase,
                         amplitude: 50, wavelength: size.width * 0.9,
                         color: accentColor)
                
                context.opacity = 0.06
                drawWave(in: context, size: size, phase: phase * 0.8,
                         amplitude: 35, wavelength: size.width * 0.7,
                         color: secondaryColor)
                
                context.opacity = 0.04
                drawWave(in: context, size: size, phase: phase * 1.2,
                         amplitude: 25, wavelength: size.width * 0.5,
                         color: accentColor)

                // Circular shapes for depth with simulated gradient effect
                context.opacity = 0.08
                var path = Path()
                path.addEllipse(in: CGRect(x: -size.width * 0.2,
                                           y: -size.height * 0.2,
                                           width: size.width * 0.8,
                                           height: size.height * 0.8))
                context.drawLayer { ctx in
                    ctx.fill(path, with: .color(accentColor.opacity(0.08)))
                }

                context.opacity = 0.06
                path = Path()
                path.addEllipse(in: CGRect(x: size.width * 0.4,
                                           y: size.height * 0.4,
                                           width: size.width * 0.6,
                                           height: size.height * 0.6))
                context.drawLayer { ctx in
                    ctx.fill(path, with: .color(secondaryColor.opacity(0.06)))
                }
            }
            .onChange(of: timeline.date) { _ in
                phase += 0.01
            }
        }
        .background(Color(hex: "FAFBFC"))
    }
    
    private func drawWave(in context: GraphicsContext, size: CGSize,
                         phase: Double, amplitude: Double, wavelength: Double,
                         color: Color) {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: size.height))
        
        let steps = Int(size.width)
        for x in 0...steps {
            let relativeX = Double(x) / Double(steps)
            let y = sin(relativeX * 2 * .pi * (size.width / wavelength) + phase) * amplitude
            path.addLine(to: CGPoint(x: Double(x), y: size.height / 2 + y))
        }
        
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.closeSubpath()
        
        context.fill(path, with: .color(color))
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

//struct ProgressIndicator: View {
//    let totalSteps: Int
//    let currentStep: Int
//    let accentColor: Color
//    
//    var body: some View {
//        HStack(spacing: 6) {
//            ForEach(0..<totalSteps, id: \.self) { index in
//                Capsule()
//                    .fill(index <= currentStep ? accentColor : Color(hex: "E8ECF1"))
//                    .frame(height: 2)
//            }
//        }
//        .animation(.easeInOut, value: currentStep)
//    }
//}

#Preview {
    HomeView()
}
