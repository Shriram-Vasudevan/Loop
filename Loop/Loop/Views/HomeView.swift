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
    let complementaryColor = Color(hex: "84A297")
    let backgroundColor = Color.white
    let surfaceColor = Color(hex: "F8F5F7")
    
    var body: some View {
        ZStack {
            // Animated background
            HomeBackground()
                .opacity(backgroundOpacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.2)) {
                        backgroundOpacity = 1
                    }
                }
            
            ScrollView {
                VStack(spacing: 24) {
                    topBar
                    
                    if !loopManager.areAllPromptsDone() {
                        todayPromptCard
                    }
                    
                    if loopManager.pastLoops.count > 0 {
                        memoryLaneSection
                    }
                    
                    insightsCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .onAppear {
            loopManager.checkAndResetIfNeeded()
        }
        .fullScreenCover(item: $selectedLoop) { loop in
            ViewPastLoopView(loop: loop)
        }
        .fullScreenCover(isPresented: $showingRecordLoopsView) {
            RecordLoopsView(isFirstLaunch: false)
                .onDisappear {
                    if loopManager.areAllPromptsDone() {
                        loopManager.fetchRandomPastLoop()
                    } else {
                        loopManager.nextPrompt()
                    }
                }
        }
    }
    
    private var topBar: some View {
        HStack {
            Text("loop")
                .font(.system(size: 36, weight: .light))
                .foregroundColor(.black)
            Spacer()
        }
    }
    
    private var todayPromptCard: some View {
        VStack(spacing: 24) {
            // Progress section
            HStack {
                VStack(alignment: .leading, spacing: 16) {
                    Text("today's reflection")
                        .font(.system(size: 22, weight: .light))
                        .foregroundColor(Color.black.opacity(0.8))
                    
                    // Progress indicators
                    HStack(spacing: 6) {
                        ForEach(0..<loopManager.prompts.count, id: \.self) { index in
                            Capsule()
                                .fill(index <= loopManager.currentPromptIndex ? accentColor : Color(hex: "DDDDDD"))
                                .frame(width: 24, height: 2)
                        }
                    }
                    
                    Text("\(loopManager.currentPromptIndex + 1)/\(loopManager.prompts.count)")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(accentColor)
                }
                
                Spacer()
            }
            
            // Prompt section
            VStack(alignment: .leading, spacing: 12) {
                Text(loopManager.getCurrentPrompt())
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.black)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Record button
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
                .frame(height: 54)
                .background(accentColor)
                .foregroundColor(.white)
                .cornerRadius(27)
                .shadow(color: accentColor.opacity(0.2), radius: 10, y: 5)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.05), radius: 20, y: 10)
        )
    }
    
    private var memoryLaneSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("memory lane")
                .font(.system(size: 22, weight: .light))
                .foregroundColor(Color.black.opacity(0.8))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(loopManager.pastLoops, id: \.self) { loop in
                        PastLoopCard(loop: loop, accentColor: accentColor) {
                            selectedLoop = loop
                        }
                    }
                }
                .padding(.bottom, 8) // For shadow space
            }
        }
    }
    
    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("loop insights")
                .font(.system(size: 22, weight: .light))
                .foregroundColor(Color.black.opacity(0.8))
            
            VStack(alignment: .leading, spacing: 12) {
                InsightRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "monthly reflection",
                    detail: "you've mentioned 'stress' 8 times"
                )
                
                Divider()
                    .background(accentColor.opacity(0.1))
                
                InsightRow(
                    icon: "leaf",
                    title: "goal suggestion",
                    detail: "meditate for 5 minutes today"
                )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(surfaceColor)
            )
        }
    }
}

struct InsightRow: View {
    let icon: String
    let title: String
    let detail: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .light))
                .foregroundColor(Color(hex: "A28497"))
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.gray)
                
                Text(detail)
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(.black)
            }
        }
    }
}

struct HomeBackground: View {
    let accentColor = Color(hex: "A28497")
    let complementaryColor = Color(hex: "84A297")
    @State private var phase: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white,
                        Color(hex: "F8F5F7").opacity(0.8)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Animated waves
                ForEach(0..<3) { index in
                    Wave(
                        phase: phase + Double(index) * .pi / 2,
                        amplitude: 8 + Double(index) * 4,
                        frequency: 0.3 - Double(index) * 0.05
                    )
                    .fill(
                        index % 2 == 0 ? accentColor : complementaryColor
                    )
                    .opacity(0.05 - Double(index) * 0.01)
                    .blendMode(.plusLighter)
                }
                
                // Gradient overlays for depth
                RadialGradient(
                    gradient: Gradient(colors: [
                        accentColor.opacity(0.05),
                        Color.clear
                    ]),
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: geometry.size.width * 0.8
                )
                
                RadialGradient(
                    gradient: Gradient(colors: [
                        complementaryColor.opacity(0.05),
                        Color.clear
                    ]),
                    center: .bottomTrailing,
                    startRadius: 0,
                    endRadius: geometry.size.width * 0.8
                )
            }
            .onAppear {
                withAnimation(
                    .linear(duration: 20)
                    .repeatForever(autoreverses: false)
                ) {
                    phase += 2 * .pi
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct Wave: Shape {
    let phase: Double
    let amplitude: Double
    let frequency: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height * 0.5
        
        let points = stride(
            from: 0,
            to: width + 10, // Overlap slightly
            by: 5 // Adjust point density for performance
        ).map { x -> CGPoint in
            let relativeX = x / width
            let y = midHeight +
                amplitude * sin(relativeX * frequency * 2 * .pi + phase)
            return CGPoint(x: x, y: y)
        }
        
        path.move(to: CGPoint(x: 0, y: height))
        path.addLine(to: points[0])
        
        for idx in 0..<points.count - 1 {
            let control = CGPoint(
                x: (points[idx].x + points[idx + 1].x) / 2,
                y: (points[idx].y + points[idx + 1].y) / 2
            )
            path.addQuadCurve(
                to: points[idx + 1],
                control: control
            )
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Wave Background
struct WaveBackground: View {
    @State private var waveOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.white, Color(hex: "F8F5F7")]),
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all)
                
                WaveLayer(phase: waveOffset, amplitude: 20, frequency: 1.5, color: Color(hex: "A28497").opacity(0.2), size: geometry.size)
            }
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                    waveOffset = 30 // Slow vertical oscillation for calmness
                }
            }
        }
    }
}

struct WaveLayer: View {
    let phase: CGFloat
    let amplitude: CGFloat
    let frequency: CGFloat
    let color: Color
    let size: CGSize

    var body: some View {
        Path { path in
            let midHeight = size.height * 0.5
            let width = size.width

            let stepSize: CGFloat = 5.0 // Reduce the number of points calculated

            path.move(to: CGPoint(x: 0, y: midHeight))

            for x in stride(from: 0, to: width, by: stepSize) {
                let relativeX = x / width
                let y = midHeight + amplitude * sin(relativeX * frequency * 2 * .pi + phase)
                path.addLine(to: CGPoint(x: x, y: y))
            }

            path.addLine(to: CGPoint(x: width, y: size.height))
            path.addLine(to: CGPoint(x: 0, y: size.height))
            path.closeSubpath()
        }
        .fill(color)
        .offset(y: phase) // Vertical oscillation
    }
}


#Preview {
    HomeView()
}
