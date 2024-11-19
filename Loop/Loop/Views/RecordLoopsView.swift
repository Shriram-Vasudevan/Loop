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
    @State private var isShowingMemory = false
    @State private var isShowingMemoryMessage = false
    @State private var recordingTimer: Timer?
    @State private var timeRemaining: Int = 30
    @State private var showingFirstLaunchScreen = true
    @State var isFirstLaunch: Bool
    @State private var backgroundOpacity: Double = 0
    @State private var messageOpacity: Double = 0
    @State private var wavePhase: Double = 0
    
    @State private var isShowingPastReflection = false
    @State private var pastLoop: Loop?
    @State private var allPrompts: [String] = []
    
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
            
            // Main Content
            VStack(spacing: 0) {
                if isShowingPastReflection {
                    PastReflectionView(
                        loop: pastLoop!,
                        onComplete: {
                            loopManager.hasCompletedToday = true
                        }
                    )
                    .transition(.opacity.animation(.easeInOut(duration: 0.8)))
                } else if loopManager.hasCompletedToday {
                    thankYouScreen
                        .transition(.opacity.animation(.easeInOut(duration: 0.8)))
                }  else if isShowingMemoryMessage {
                    memoryMessageView
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
                // Outer shadow
                Circle()
                    .fill(Color.white)
                    .frame(width: 96)
                    .shadow(color: accentColor.opacity(0.2), radius: 20, x: 0, y: 8)
                
                // Main circle
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
                    // Stop icon
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white)
                        .frame(width: 26, height: 26)
                } else {
                    // Record icon
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
        
        private var memoryPlaybackView: some View {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Text("from your past")
                        .font(.system(size: 24, weight: .ultraLight))
                        .foregroundColor(textColor)
                    
                    if let pastLoop = loopManager.currentPastLoop {
                        Text(formatDate(pastLoop.timestamp))
                            .font(.system(size: 18, weight: .ultraLight))
                            .foregroundColor(accentColor)
                    }
                }
                
                Spacer()
                
                // Audio Player
                if let pastLoop = loopManager.currentPastLoop {
                    PastLoopPlayer(loop: pastLoop)
                }
                
                Spacer()
                
                // Continue Button
                Button(action: {
                    withAnimation {
                        isShowingMemory = false
                        loopManager.moveToNextPrompt()
                    }
                }) {
                    HStack(spacing: 8) {
                        Text("continue")
                            .font(.system(size: 18, weight: .light))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .light))
                    }
                    .frame(height: 56)
                    .frame(maxWidth: .infinity)
                    .background(accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(28)
                    .shadow(color: accentColor.opacity(0.2), radius: 10, y: 5)
                }
            }
            .padding(.bottom, 40)
        }
        
    private var memoryMessageView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44, weight: .light))
                    .foregroundColor(accentColor)
                
                Text("added to memories")
                    .font(.system(size: 32, weight: .ultraLight))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
            }
        }
        .opacity(messageOpacity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.6)) {
                messageOpacity = 1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    messageOpacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    isShowingMemoryMessage = false
                    loopManager.moveToNextPrompt()
                }
            }
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
            // Save the current loop
            loopManager.addLoop(
                mediaURL: audioFileURL,
                isVideo: false,
                prompt: loopManager.getCurrentPrompt()
            )
            
            if loopManager.isLastPrompt() {
    
                allPrompts = loopManager.prompts
                
                Task {
                    if let pastLoop = try? await loopManager.getPastLoopForComparison(
                        recordedPrompts: allPrompts
                    ) {
                        await MainActor.run {
                            self.pastLoop = pastLoop
                            isPostRecording = false
                            isShowingPastReflection = true
                        }
                    }
                    else {
                        await MainActor.run {
                                              
                           loopManager.hasCompletedToday = true
                       }
                    }
                }
            } else {
                showMemoryAddedMessage()
            }
        }
    }
    
    private func showMemoryAddedMessage() {
        isPostRecording = false
        isShowingMemoryMessage = true
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
    
    private var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy"
        return dateFormatter.string(from: Date())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func generateRandomWaveform(count: Int, minHeight: CGFloat = 12, maxHeight: CGFloat = 64) -> [CGFloat] {
        return (0..<count).map { _ in
            CGFloat.random(in: minHeight...maxHeight)
        }
    }
}

struct PastLoopPlayer: View {
    let loop: Loop
    @State private var isPlaying = false
    @State private var progress: Double = 0
    @State private var audioPlayer: AVAudioPlayer?
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 32) {
            // Waveform visualization
            HStack(spacing: 3) {
                ForEach(0..<50) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: "A28497").opacity(progress > Double(index) / 50 ? 0.8 : 0.3))
                        .frame(width: 3, height: CGFloat.random(in: 10...50))
                }
            }
            .frame(height: 50)
            
            // Playback controls
            HStack(spacing: 40) {
                Button(action: {
                    if isPlaying {
                        stopPlayback()
                    } else {
                        startPlayback()
                    }
                }) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(Color(hex: "A28497"))
                }
            }
        }
        .onAppear(perform: setupAudioPlayer)
        .onDisappear(perform: cleanup)
    }
    
    private func setupAudioPlayer() {
        guard let url = loop.data.fileURL else { return }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
        } catch {
            print("Error setting up audio player: \(error)")
        }
    }
    
    private func startPlayback() {
        audioPlayer?.play()
        isPlaying = true
        startProgressTimer()
    }
    
    private func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        isPlaying = false
        progress = 0
        timer?.invalidate()
        timer = nil
    }
    
    private func startProgressTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            guard let player = audioPlayer else { return }
            progress = player.currentTime / player.duration
            
            if player.currentTime >= player.duration {
                stopPlayback()
            }
        }
    }
    
    private func cleanup() {
        timer?.invalidate()
        timer = nil
        audioPlayer?.stop()
        audioPlayer = nil
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

struct PastReflectionView: View {
    let loop: Loop
    let onComplete: () -> Void
    
    @State private var isPlaying = false
    @State private var progress: Double = 0
    @State private var audioPlayer: AVAudioPlayer?
    @State private var timer: Timer?
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 32) {
            // Close button
            HStack {
                Spacer()
                Button(action: onComplete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(accentColor.opacity(0.8))
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Past reflection content
            VStack(spacing: 24) {
                // Header
                Text("a past reflection")
                    .font(.system(size: 32, weight: .ultraLight))
                    .foregroundColor(textColor)
                
                // Date
                Text(formatDate(loop.timestamp))
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(accentColor)
                
                // Prompt
                Text(loop.promptText)
                    .font(.system(size: 24, weight: .ultraLight))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 20)
            }
            
            Spacer()
            
            // Audio player
            VStack(spacing: 24) {
                // Waveform visualization
                HStack(spacing: 3) {
                    ForEach(0..<40) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(accentColor.opacity(
                                progress > Double(index) / 40 ? 0.8 : 0.3
                            ))
                            .frame(width: 3, height: CGFloat.random(in: 10...50))
                    }
                }
                .frame(height: 50)
                .padding(.horizontal, 32)
                
                // Play button
                Button(action: togglePlayback) {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 64, height: 64)
                        .overlay(
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        )
                }
            }
            
            Spacer()
            
            // Continue button
            Button(action: onComplete) {
                Text("continue")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(.white)
                    .frame(height: 56)
                    .frame(maxWidth: .infinity)
                    .background(accentColor)
                    .cornerRadius(28)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .onAppear(perform: setupAudioPlayer)
        .onDisappear(perform: cleanup)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func setupAudioPlayer() {
        guard let url = loop.data.fileURL else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
        } catch {
            print("Error setting up audio player: \(error)")
        }
    }
    
    private func togglePlayback() {
        if isPlaying {
            audioPlayer?.pause()
            timer?.invalidate()
        } else {
            audioPlayer?.play()
            startProgressTimer()
        }
        isPlaying.toggle()
    }
    
    private func startProgressTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            guard let player = audioPlayer else { return }
            progress = player.currentTime / player.duration
            
            if player.currentTime >= player.duration {
                stopPlayback()
            }
        }
    }
    
    private func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        isPlaying = false
        progress = 0
        timer?.invalidate()
    }
    
    private func cleanup() {
        timer?.invalidate()
        timer = nil
        audioPlayer?.stop()
        audioPlayer = nil
        
    }
}


#Preview {
    RecordLoopsView(isFirstLaunch: true)
}
