//
//  RecordLoopsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/3/24.
//
import SwiftUI

struct RecordLoopsView: View {
    @ObservedObject var loopManager = LoopManager.shared
    @ObservedObject var audioManager = AudioManager.shared
    
    @State private var isRecording = false
    @State private var showPromptText = true
    @State private var promptOpacity: Double = 0
    @State private var animationProgress: CGFloat = 0
    
    @Environment(\.dismiss) var dismiss
    
    let gradientColors = [Color(hex: "F0F0F0"), Color.white, Color(hex: "F8F8F8")]
    let accentColor = Color(hex: "A28497")
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Enhanced gradient background
                LinearGradient(gradient: Gradient(colors: gradientColors), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all)
                
                // Random decorative curves
                RandomCurvesBackground(accentColor: accentColor)
                
                VStack(spacing: 0) {
                    topBar
                    
                    Spacer()
                    
                    promptArea
                    
                    Spacer()
                    
                    recordingButton
                        .padding(.bottom, 10)
                }
                .padding(.horizontal, 16)
            }
        }
        .onAppear {
            animatePromptText()
        }
    }
    
    private var topBar: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: {
                    loopManager.nextPrompt()
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(Color(hex: "CCCCCC"))
                }
                Spacer()
            }
            
            // Prompt indicator dots
            HStack(spacing: 8) {
                ForEach(0..<loopManager.prompts.count, id: \.self) { index in
                    Circle()
                        .fill(index == loopManager.currentPromptIndex ? accentColor : Color(hex: "DDDDDD"))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(.top, 16)
    }
    
    private var promptArea: some View {
        VStack(spacing: isRecording ? 16 : 40) {
            if showPromptText {
                Text("Find a quiet space")
                    .font(.system(size: 40, weight: .ultraLight))
                    .foregroundColor(Color(hex: "333333"))
                    .multilineTextAlignment(.center)
                    .opacity(promptOpacity)
                    .transition(.opacity)
            } else {
                Text(loopManager.getCurrentPrompt())
                    .font(.system(size: 44, weight: .ultraLight))
                    .foregroundColor(Color(hex: "333333"))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
                
                if isRecording {
                    Text("Recording...")
                        .font(.system(size: 26, weight: .ultraLight))
                        .foregroundColor(accentColor)
                        .transition(.opacity)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var recordingButton: some View {
        Button(action: toggleRecording) {
            ZStack {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 90, height: 90)
                    .overlay(
                        Circle()
                            .stroke(isRecording ? accentColor : Color(hex: "4A4A4A").opacity(0.8), lineWidth: 6)
                    )
                
                if isRecording {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(accentColor)
                        .frame(width: 31, height: 31)
                } else {
                    Circle()
                        .fill(Color(hex: "4A4A4A"))
                        .frame(width: 72, height: 72)
                        .opacity(0.8)
                }

                Circle()
                    .stroke(isRecording ? accentColor.opacity(0.5) : Color.clear, lineWidth: 3)
                    .frame(width: 100, height: 100)
                    .scaleEffect(animationProgress)
                    .opacity(1 - animationProgress)
                    .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: animationProgress)
            }
        }
        .onChange(of: isRecording) { _ in
            animationProgress = 0
            withAnimation {
                animationProgress = 1
            }
        }
    }

    
    private func toggleRecording() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isRecording.toggle()
        }
        if !isRecording {
            loopManager.nextPrompt()
            if loopManager.areAllPromptsDone() {
                dismiss()
            }
        }
        // Logic to record audio would go here
    }
    
    private func animatePromptText() {
        withAnimation(.easeIn(duration: 1.5)) {
            promptOpacity = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeOut(duration: 1.5)) {
                promptOpacity = 0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            withAnimation {
                showPromptText = false
            }
        }
    }
}

struct RandomCurvesBackground: View {
    @State private var phase: CGFloat = 0
    let accentColor: Color
    
    var body: some View {
        // Timer-driven animation, decoupled from rendering
        GeometryReader { geometry in
            Canvas { context, size in
                context.opacity = 0.3
                
                let colors = [Color(hex: "EEEEEE"), Color(hex: "DDDDDD"), accentColor.opacity(0.3), Color(hex: "CCCCCC")]
                
                for i in 0..<8 {
                    var path = Path()
                    
                    let startY = CGFloat.random(in: 0...size.height)
                    let endY = CGFloat.random(in: 0...size.height)
                    let controlY1 = CGFloat.random(in: 0...size.height)
                    let controlY2 = CGFloat.random(in: 0...size.height)
                    
                    let offset = phase * size.width * 0.1
                    
                    path.move(to: CGPoint(x: -offset, y: startY))
                    path.addCurve(
                        to: CGPoint(x: size.width + offset, y: endY),
                        control1: CGPoint(x: size.width * 0.3 + offset, y: controlY1),
                        control2: CGPoint(x: size.width * 0.7 - offset, y: controlY2)
                    )
                    
                    context.stroke(path, with: .color(colors[i % colors.count]), lineWidth: CGFloat.random(in: 1...3))
                }
            }
            .onAppear {
                startAnimation() // Trigger animation
            }
        }
    }
    
    // Trigger animation on view appearance
    private func startAnimation() {
        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
            phase = 1 // Animate phase from 0 to 1 indefinitely
        }
    }
}


#Preview {
    RecordLoopsView()
}
