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
    @State private var selectedLoop: Loop? // Optional Loop
    
    let accentColor = Color(hex: "A28497")
    let backgroundColor = Color.white
    let groupBackgroundColor = Color(hex: "F8F5F7")

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                topBar
                loopsWidget
                
                if loopManager.pastLoops.count > 0 {
                    pastLoopsCarousel
                }
                
                insightsView
            }
            .padding(.horizontal)
            .padding(.top, 20)
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
                .font(.system(size: 36, weight: .light, design: .default))
                .foregroundColor(.black)
            Spacer()
        }
    }

    private var loopsWidget: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(spacing: 10) {
                Text("Today's Reflection")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                progressView
            }
            
            promptView
            
            if !loopManager.areAllPromptsDone() {
                Button(action: {
                    showingRecordLoopsView = true
                }) {
                    HStack {
                        Image(systemName: "mic")
                        Text("Record Loop")
                    }
                    .padding()
                    .background(accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(25)
                }
            }
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(groupBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(accentColor.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var progressView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Progress")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
            
            HStack(spacing: 6) {
                ForEach(0..<loopManager.prompts.count, id: \.self) { index in
                    Capsule()
                        .fill(index <= loopManager.currentPromptIndex ? accentColor : Color(hex: "DDDDDD"))
                        .frame(height: 4)
                }
            }
            
            Text("\(loopManager.areAllPromptsDone() ? loopManager.currentPromptIndex : loopManager.currentPromptIndex + 1) / \(loopManager.prompts.count)")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(accentColor)
        }
    }

    private var promptView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(loopManager.areAllPromptsDone() ? "All Prompts Completed!" : "Next Prompt")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
            
            if !loopManager.areAllPromptsDone() {
                Text(loopManager.getCurrentPrompt())
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.black)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var pastLoopsCarousel: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Memory Lane")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.black)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(LoopManager.shared.pastLoops, id: \.self) { loop in
                        PastLoopCard(loop: loop, accentColor: accentColor, onClicked: {
                            self.selectedLoop = loop
                        })
                    }
                }
            }
        }
        .padding(.vertical, 10)
    }

    private var insightsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Loop Insights")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.black)
            
            Text("You've mentioned 'stress' 8 times this month")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.gray)
            
            Text("Goal Suggestion: Meditate for 5 minutes today")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(accentColor)
                .padding(.top, 5)
        }
        .padding()
        .background(groupBackgroundColor)
        .cornerRadius(15)
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


struct PastLoopCard: View {
    let loop: Loop
    let accentColor: Color
    
    var onClicked: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "waveform")
                    .foregroundColor(accentColor)
                Spacer()
                Text(formattedDate(loop.timestamp))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(loop.promptText)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.black)
                .lineLimit(2)
            
            if let mood = loop.mood {
                HStack {
                    Text("Mood:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(mood)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(accentColor)
                }
            }
            
            Button(action: {
                onClicked()
            }) {
                Text("Listen")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    HomeView()
}
