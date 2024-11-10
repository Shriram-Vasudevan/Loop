//
//  RecordLoopsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/3/24.
//

import SwiftUI
import AVKit

struct RecordLoopsView: View {
    @ObservedObject var loopManager = LoopManager.shared
    @ObservedObject var audioManager = AudioManager.shared
    
    @State private var isRecording = false
    @State private var isPostRecording = false
    @State private var retryAttempts = 1
    @State private var recordingTimer: Timer?
    @State private var timeRemaining: Int = 30
    @State private var showingFirstLaunchScreen = true
    @State var isFirstLaunch: Bool
    @State private var backgroundOpacity: Double = 0
    @State private var wavePhase: Double = 0
    
    @Environment(\.dismiss) var dismiss
    
    let accentColor = Color(hex: "A28497")
    let secondaryColor = Color(hex: "B7A284")
    let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        ZStack {
            AnimatedBackground()
                .opacity(backgroundOpacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.2)) {
                        backgroundOpacity = 1
                    }
                }
            
            VStack(spacing: 0) {
                if loopManager.hasCompletedToday {
                    thankYouScreen
                        .transition(.opacity.animation(.easeInOut(duration: 0.8)))
                } else if isPostRecording {
                    postRecordingView
                        .transition(.opacity.animation(.easeInOut(duration: 0.8)))
                } else if showingFirstLaunchScreen {
                    firstLaunchOrQuietSpaceScreen
                        .transition(.opacity.animation(.easeInOut(duration: 0.8)))
                } else {
                    recordingScreen
                        .transition(.opacity.animation(.easeInOut(duration: 0.8)))
                }
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            audioManager.resetRecording()
        }
    }
    
    private var recordingScreen: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                topBar
                    .padding(.bottom, 40)
                
                Spacer()
                
                promptArea
                
                Spacer()
                
                recordingButton
                    .padding(.bottom, 60)
            }
        }
    }
    
    private var topBar: some View {
        VStack(spacing: 24) {
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(accentColor.opacity(0.8))
                }
                
                Spacer()
                
                if isPostRecording && loopManager.retryAttemptsLeft > 0 {
                    Button(action: retryRecording) {
                        Text("retry (\(loopManager.retryAttemptsLeft))")
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(accentColor)
                    }
                }
            }
            
            ProgressIndicator(totalSteps: loopManager.prompts.count,
                            currentStep: loopManager.currentPromptIndex,
                            accentColor: accentColor)
        }
        .padding(.top, 16)
    }
    
    private var promptArea: some View {
        VStack(spacing: isRecording ? 20 : 44) {
            Text(loopManager.getCurrentPrompt())
                .font(.system(size: 44, weight: .ultraLight))
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .transition(.opacity)
                .animation(.easeInOut, value: loopManager.getCurrentPrompt())

            if isRecording {
                HStack(spacing: 12) {
                    PulsingDot()
                    Text("\(timeRemaining)s")
                        .font(.system(size: 26, weight: .ultraLight))
                        .foregroundColor(accentColor)
                }
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var recordingButton: some View {
        Button(action: toggleRecording) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 96)
                    .shadow(color: accentColor.opacity(0.2), radius: 20, x: 0, y: 8)
                
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                isRecording ? accentColor : .white,
                                isRecording ? accentColor.opacity(0.9) : .white
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                
                if isRecording {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white)
                        .frame(width: 26, height: 26)
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    accentColor,
                                    accentColor.opacity(0.85)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 74)
                }
            
                if isRecording {
                    PulsingRing(color: accentColor)
                }
            }
            .scaleEffect(isRecording ? 1.08 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isRecording)
        }
    }
    
    private var postRecordingView: some View {
        VStack {
            LoopAudioConfirmationView(
                audioURL: audioManager.getRecordedAudioFile() ?? URL(fileURLWithPath: ""),
                waveformData: generateRandomWaveform(count: 40),
                onComplete: { completeRecording() },
                onRetry: { retryRecording() }
            )
        }
    }
    
    private var thankYouScreen: some View {
        VStack(spacing: 12) {
            Spacer()
            
            Text("thank you for looping")
                .font(.system(size: 36, weight: .thin))
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 32, weight: .thin))
                    .foregroundColor(accentColor)
                
                Text("see you tomorrow")
                    .font(.system(size: 24, weight: .thin))
                    .foregroundColor(Color.gray)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            audioManager.resetRecording()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                dismiss()
            }
        }
    }
    
    private var firstLaunchOrQuietSpaceScreen: some View {
        Group {
            if isFirstLaunch {
                welcomeView
            } else {
                quietSpaceView
            }
        }
    }
    
    private var welcomeView: some View {
        VStack(spacing: 24) {
            Text("it's time to loop")
                .font(.system(size: 36, weight: .thin))
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
            
            FloatingElements()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    isFirstLaunch = false
                }
            }
        }
    }
    
    private var quietSpaceView: some View {
        VStack(spacing: 24) {
            Text("find a quiet space")
                .font(.system(size: 36, weight: .thin))
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
            
            Image(systemName: "ear")
                .font(.system(size: 32, weight: .thin))
                .foregroundColor(accentColor.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    showingFirstLaunchScreen = false
                }
            }
        }
    }
    
    private func toggleRecording() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isRecording.toggle()
        }
        
        if !isRecording {
            audioManager.stopRecording()
            stopTimer()
            isPostRecording = true
        } else {
            startRecordingWithTimer()
        }
    }
    
    private func startRecordingWithTimer() {
        audioManager.startRecording()
        timeRemaining = 30
        startTimer()
    }
    
    private func startTimer() {
        recordingTimer?.invalidate()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopTimer()
                audioManager.stopRecording()
                isPostRecording = true
            }
        }
    }
    
    private func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    private func completeRecording() {
        if let audioFileURL = audioManager.getRecordedAudioFile() {
            loopManager.addLoop(mediaURL: audioFileURL, isVideo: false, prompt: loopManager.getCurrentPrompt())
            isPostRecording = false
            isRecording = false
            timeRemaining = 30
            
            loopManager.moveToNextPrompt()
        }
    }
    
    private func retryRecording() {
        if loopManager.retryAttemptsLeft > 0 {
            loopManager.retryRecording()
            audioManager.resetRecording()
            isPostRecording = false
            isRecording = false
            timeRemaining = 30
        }
    }
    
    func generateRandomWaveform(count: Int, minHeight: CGFloat = 12, maxHeight: CGFloat = 64) -> [CGFloat] {
        return (0..<count).map { _ in
            CGFloat.random(in: minHeight...maxHeight)
        }
    }
}

struct AnimatedBackground: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {

            Color(hex: "FAFBFC").edgesIgnoringSafeArea(.all)
            
            ForEach(0..<3) { index in
                WaveShape(frequency: Double(index + 1) * 0.5,
                         amplitude: 100 - Double(index) * 20,
                         phase: animate ? .pi * 2 : 0)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "94A7B7").opacity(0.03),
                                Color(hex: "94A7B7").opacity(0.06)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .offset(y: CGFloat(index) * 50)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                animate = true
            }
        }
    }
}

struct WaveShape: Shape {
    let frequency: Double
    let amplitude: Double
    var phase: Double
    
    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height / 2
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let y = sin(relativeX * .pi * frequency * 2 + phase) * amplitude + midHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

struct ProgressIndicator: View {
    let totalSteps: Int
    let currentStep: Int
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index == currentStep ? accentColor : Color(hex: "E8ECF1"))
                    .frame(width: 24, height: 2)
                    .animation(.easeInOut, value: currentStep)
            }
        }
    }
}

struct PulsingDot: View {
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(Color.red.opacity(0.8))
            .frame(width: 8, height: 8)
            .scaleEffect(isAnimating ? 1.5 : 1)
            .opacity(isAnimating ? 0.5 : 1)
            .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

struct PulsingRing: View {
    let color: Color
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.6
    
    var body: some View {
        Circle()
            .stroke(color.opacity(opacity), lineWidth: 2)
            .frame(width: 100, height: 100)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                    scale = 1.3
                    opacity = 0
                }
            }
    }
}

struct FloatingElements: View {
    @State private var offsetY: CGFloat = 0
    
    var body: some View {
        ZStack {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color(hex: "94A7B7").opacity(0.1))
                    .frame(width: 12, height: 12)
                    .offset(
                        x: CGFloat(index * 20 - 20),
                        y: offsetY + CGFloat(index * 15)
                    )
                    .animation(
                        Animation.easeInOut(duration: 2)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.3),
                        value: offsetY
                    )
            }
        }
        .onAppear {
            offsetY = -20
        }
    }
}




#Preview {
    RecordLoopsView(isFirstLaunch: true)
}
