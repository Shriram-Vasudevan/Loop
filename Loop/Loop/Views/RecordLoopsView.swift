//
//  RecordLoopsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/3/24.
//

import SwiftUI
import AVKit

import SwiftUI
import AVKit

struct RecordLoopsView: View {
    @ObservedObject var loopManager = LoopManager.shared
    @ObservedObject var audioManager = AudioManager.shared
    
    @State private var isRecording = false
    @State private var isPostRecording = false
    @State private var isAllPromptsCompleted = false
    @State private var retryAttempts = 1
    @State private var recordingTimer: Timer?
    @State private var timeRemaining: Int = 30
    @State private var showingFirstLaunchScreen = true
    @State var isFirstLaunch: Bool
    @State private var backgroundOpacity: Double = 0
    
    @Environment(\.dismiss) var dismiss
    
    let accentColor = Color(hex: "A28497")
    let textColor = Color(hex: "333333")
    
    var body: some View {
        ZStack {
            RecordLoopsBackground()
                .opacity(backgroundOpacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.2)) {
                        backgroundOpacity = 1
                    }
                }
            
            VStack(spacing: 0) {
                if isAllPromptsCompleted {
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
            .padding(.horizontal, 24)
        }
        .onAppear {
            audioManager.resetRecording()
        }
    }
    
    private var recordingScreen: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                topBar
                    .padding(.bottom, 32)
                
                Spacer()
                
                promptArea
                
                Spacer()
                
                recordingButton
                    .padding(.bottom, 48)
            }
        }
    }
    
    private var topBar: some View {
        VStack(spacing: 20) {
            HStack {
                Button(action: {
                    if isPostRecording {
                        retryRecording()
                    } else {
                        dismiss()
                    }
                }) {
                    Image(systemName: isPostRecording ? "arrow.backward" : "xmark")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(accentColor.opacity(0.7))
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
            
            // Centered progress indicators with fixed width
            HStack(spacing: 8) {
                Spacer()
                HStack(spacing: 6) {
                    ForEach(0..<loopManager.prompts.count, id: \.self) { index in
                        Capsule()
                            .fill(index == loopManager.currentPromptIndex ? accentColor : Color(hex: "DDDDDD"))
                            .frame(width: 24, height: 2)
                    }
                }
                .frame(height: 2)
                Spacer()
            }
        }
        .padding(.top, 16)
    }
    
    private var promptArea: some View {
        VStack(spacing: isRecording ? 16 : 40) {
            Text(loopManager.getCurrentPrompt())
                .font(.system(size: 44, weight: .ultraLight))
                .foregroundColor(Color(hex: "333333"))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .transition(.opacity)

            if isRecording {
                Text("Recording... \(timeRemaining)s")
                    .font(.system(size: 26, weight: .ultraLight))
                    .foregroundColor(accentColor)
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
                    .frame(width: 88)
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                
                // Main button circle
                Circle()
                    .fill(isRecording ? accentColor : .white)
                    .frame(width: 84)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                
                if isRecording {
                    // Stop recording symbol
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white)
                        .frame(width: 28, height: 28)
                } else {
                    // Record symbol with gradient
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    accentColor,
                                    accentColor.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72)
                        .shadow(color: accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
            .scaleEffect(isRecording ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isRecording)
        }
    }
    
    private var postRecordingView: some View {
        VStack {
            LoopAudioConfirmationView(
                audioURL: audioManager.getRecordedAudioFile() ?? URL(fileURLWithPath: ""),
                waveformData: generateRandomWaveform(count: 30),
                onComplete: { completeRecording() },
                onRetry: { retryRecording() }
            )
        }
    }
    
    private var thankYouScreen: some View {
        VStack(spacing: 20) {
            Text("thank you for looping")
                .font(.system(size: 32, weight: .thin))
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Text("see you tomorrow for more loops")
                .font(.system(size: 22, weight: .thin))
                .foregroundColor(Color.gray)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            audioManager.resetRecording()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                dismiss()
            }
        }
    }
    
    private var firstLaunchOrQuietSpaceScreen: some View {
        Group {
            if isFirstLaunch {
                Text("it's time to loop")
                    .font(.system(size: 32, weight: .thin))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation {
                                isFirstLaunch = false
                            }
                        }
                    }
            } else {
                Text("find a quiet space")
                    .font(.system(size: 32, weight: .thin))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation {
                                showingFirstLaunchScreen = false
                            }
                        }
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
        let currentPrompt = loopManager.getCurrentPrompt()
        if let audioFileURL = audioManager.getRecordedAudioFile() {
            loopManager.addLoop(mediaURL: audioFileURL, isVideo: false, prompt: currentPrompt)
            loopManager.fetchRandomPastLoop()
            proceedToNextPrompt()
        }
    }
    
    private func proceedToNextPrompt() {
        if loopManager.isLastLoop() {
            loopManager.nextPrompt()
            isAllPromptsCompleted = true
        } else {
            loopManager.nextPrompt()
            isPostRecording = false
            isRecording = false
            timeRemaining = 30
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
    
    func generateRandomWaveform(count: Int, minHeight: CGFloat = 10, maxHeight: CGFloat = 60) -> [CGFloat] {
        (0..<count).map { _ in
            CGFloat.random(in: minHeight...maxHeight)
        }
    }
}

struct RecordLoopsBackground: View {
    let accentColor = Color(hex: "A28497")
    let complementaryColor = Color(hex: "84A297")
    @State private var animate = false
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Base background color
            Color(hex: "F5F5F5").edgesIgnoringSafeArea(.all)
            
            // Large gradient spheres
            ZStack {
                // Bottom right sphere
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                complementaryColor.opacity(0.2),
                                complementaryColor.opacity(0.05)
                            ]),
                            center: .center,
                            startRadius: 100,
                            endRadius: 300
                        )
                    )
                    .frame(width: 600, height: 600)
                    .offset(x: 150, y: 300)
                    .blur(radius: 60)
                    .scaleEffect(animate ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 8)
                        .repeatForever(autoreverses: true),
                        value: animate
                    )
                
                // Top left sphere
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                accentColor.opacity(0.2),
                                accentColor.opacity(0.05)
                            ]),
                            center: .center,
                            startRadius: 50,
                            endRadius: 250
                        )
                    )
                    .frame(width: 500, height: 500)
                    .offset(x: -100, y: -200)
                    .blur(radius: 50)
                    .scaleEffect(animate ? 1.15 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 10)
                        .repeatForever(autoreverses: true),
                        value: animate
                    )
            }
            
            // Pulsating rings
            ZStack {
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(
                            accentColor.opacity(0.1),
                            lineWidth: 1
                        )
                        .frame(width: 200 + CGFloat(index * 80))
                        .scaleEffect(pulseScale)
                        .animation(
                            Animation.easeInOut(duration: 3)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.5),
                            value: pulseScale
                        )
                }
            }
            .offset(y: -50) // Adjust position of rings
            
            // Additional subtle animated elements
            ForEach(0..<2) { index in
                Circle()
                    .fill(accentColor.opacity(0.05))
                    .frame(width: 100)
                    .offset(
                        x: index == 0 ? -120 : 120,
                        y: index == 0 ? 200 : -150
                    )
                    .blur(radius: 20)
                    .scaleEffect(animate ? 1.2 : 0.8)
                    .animation(
                        Animation.easeInOut(duration: 6)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 1.5),
                        value: animate
                    )
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1)) {
                animate = true
                pulseScale = 1.15
            }
        }
    }
}

#Preview {
    RecordLoopsView(isFirstLaunch: true)
}
