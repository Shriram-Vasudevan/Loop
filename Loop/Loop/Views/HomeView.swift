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
    @State private var currentMood: Int = 3 // Default to neutral
    
    let accentColor = Color(hex: "A28497")
    let backgroundColor = Color.white
    let groupBackgroundColor = Color(hex: "F8F5F7")
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                topBar
                loopsWidget
                pastLoopPlayer
                insightsView
            }
            .padding(.horizontal)
            .padding(.top, 20)
        }
        .background(
            WaveBackground()
                .edgesIgnoringSafeArea(.all)
        )
        .onAppear {
            loopManager.selectRandomPrompts()
        }
        .fullScreenCover(isPresented: $showingRecordLoopsView) {
            RecordLoopsView()
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
            
            Text("\(loopManager.currentPromptIndex + 1) / \(loopManager.prompts.count)")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(accentColor)
        }
    }
    
    private var promptView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(loopManager.areAllPromptsDone() ? "Nothing to Record!" : "Next Prompt")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
            
            Text(loopManager.getCurrentPrompt())
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var pastLoopPlayer: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Memory Replay")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.black)
            
            HStack {
                Image(systemName: "play.circle.fill")
                    .foregroundColor(accentColor)
                    .font(.system(size: 24))
                Text("Loop from the Past")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                Spacer()
                Image(systemName: "lock")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(groupBackgroundColor)
            .cornerRadius(15)
        }
    }
    
    private func moodEmoji(for value: Int) -> String {
        switch value {
        case 1: return "😢"
        case 2: return "😕"
        case 3: return "😐"
        case 4: return "🙂"
        case 5: return "😄"
        default: return "😐"
        }
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


#Preview {
    HomeView()
}
