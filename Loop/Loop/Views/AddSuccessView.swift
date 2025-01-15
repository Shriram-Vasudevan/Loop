//
//  AddSuccessView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/9/25.
//

import SwiftUI

import SwiftUI
import AVFoundation

import SwiftUI
import AVFoundation

struct AddSuccessView: View {
    @ObservedObject var loopManager = LoopManager.shared
    @ObservedObject var audioManager = AudioManager.shared
    @AppStorage("hideSuccessIntro") private var hideSuccessIntro = false
    
    @State private var isRecording = false
    @State private var isPostRecording = false
    @State private var showingThankYouScreen = false
    @State private var recordingTimer: Timer?
    @State private var timeRemaining: Int = 60
    @State private var retryAttempts = 100
    @State private var showIntro = true
    @State private var dontShowAgain = false
    @State private var backgroundOpacity: Double = 0
    @State private var messageOpacity: Double = 0
    
    @Environment(\.dismiss) var dismiss
    
    private let accentColor = Color(hex: "A28497")
    private let secondaryColor = Color(hex: "B7A284")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        ZStack {
            AnimatedBackground()
                .opacity(backgroundOpacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.2)) {
                        backgroundOpacity = 1
                    }
                }
                .edgesIgnoringSafeArea(.all)
            
            if showIntro && !hideSuccessIntro {
                introView
            } else {
                mainRecordingView
            }
        }
        .onAppear {
            audioManager.cleanup()
        }
    }
    
    private var introView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Text("successes")
                .font(.custom("PPNeueMontreal-Bold", size: 36))
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            DarkBlueWaveView()
                .padding(.horizontal, 32)
            
            Text("A space to celebrate your achievements - big and small. Loop will save these successes and bring them back to remind you of your progress.")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(textColor.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 20)
            
            Spacer()
            
            VStack(spacing: 20) {
                
                HStack {
                    Text("Don't show this introduction again")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(textColor.opacity(0.6))
                    
                    Spacer()
                    
                    MinimalToggle(isOn: $dontShowAgain)
                }
                
                Button(action: {
                    hideSuccessIntro = dontShowAgain
                    withAnimation {
                        showIntro = false
                    }
                }) {
                    Text("begin")
                        .font(.custom("PPNeueMontreal-Bold", size: 18))
                        .foregroundColor(.white)
                        .frame(height: 56)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(accentColor)
                        )
                }
            }
            .padding(32)
        }
    }
    
    private var mainRecordingView: some View {
        VStack(spacing: 0) {
            if showingThankYouScreen {
                completionView
            } else if isPostRecording {
                confirmationView
            } else {
                recordingView
            }
        }
    }
    
    private var recordingView: some View {
        VStack {
            headerSection
            
            Spacer()
            
            VStack(spacing: isRecording ? 40 : 24) {
                if isRecording {
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            PulsingDot()
                            Text("\(timeRemaining)s")
                                .font(.system(size: 20, weight: .regular))
                                .foregroundColor(accentColor)
                        }
                        
                        Text("Recording your thoughts...")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            recordButton
                .padding(.bottom, 40)
        }
        .padding(.horizontal, 32)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(formattedDate())
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.gray)
                }
            }
            .padding(.top, 16)
            
            Text("Success Journal")
                .font(.custom("PPNeueMontreal-Bold", size: 28))
                .foregroundColor(textColor)
            
            Text("Record an achievement or win from your day")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.gray)
            
            Divider()
        }
    }
    
    private var recordButton: some View {
       Button(action: {
           withAnimation {
               toggleRecording()
           }
       }) {
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
   
    

    private var confirmationView: some View {
        FreeResponseAudioConfirmationView(
            audioURL: audioManager.getRecordedAudioFile() ?? URL(fileURLWithPath: ""),
            waveformData: generateRandomWaveform(count: 40),
            onComplete: {
                withAnimation {
                    isPostRecording = false
                    showingThankYouScreen = true
                    completeRecording()
                }
            },
            onRetry: { retryRecording() },
            retryAttempts: retryAttempts,
            accentColor: accentColor,
            textColor: textColor
        )
    }
    
    private var completionView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Text("Entry Saved")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(textColor)
            
            Text("Thank you for sharing your thoughts")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.gray)
            
            Spacer()
        }
        .onAppear {
            audioManager.cleanup()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                dismiss()
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
        try? audioManager.prepareForNewRecording()
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
            Task {
                let loop = await loopManager.addLoop(
                    mediaURL: audioFileURL,
                    isVideo: false,
                    prompt: "Moment: " + formattedDate(),
                    isDailyLoop: false,
                    isFollowUp: false,
                    isSuccess: true,
                    isUnguided: true
                )
            }
        }
        
        audioManager.cleanup()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                showingThankYouScreen = true
            }
        }
    }
    
    private func retryRecording() {
        if retryAttempts > 0 {
            audioManager.cleanup()
            isPostRecording = false
            isRecording = false
            timeRemaining = 30
        }
    }
    
    private func generateRandomWaveform(count: Int) -> [CGFloat] {
        (0..<count).map { _ in CGFloat.random(in: 12...64) }
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: Date())
    }
}

struct FloatingCircles: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            ForEach(0..<5) { i in
                Circle()
                    .stroke(Color(hex: "A28497").opacity(0.2), lineWidth: 1)
                    .frame(width: 20 + CGFloat(i * 30))
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .opacity(isAnimating ? 0.8 : 0.3)
                    .animation(
                        Animation.easeInOut(duration: 2)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct FloatingRings: View {
    let isAnimating: Bool
    
    var body: some View {
        ZStack {
            ForEach(0..<3) { i in
                Circle()
                    .stroke(Color(hex: "A28497").opacity(0.15), lineWidth: 1)
                    .frame(width: 60 + CGFloat(i * 40))
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .opacity(isAnimating ? 0.8 : 0.3)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.3),
                        value: isAnimating
                    )
            }
        }
    }
}

struct CustomAudioConfirmationView: View {
    let audioURL: URL
    let waveformData: [CGFloat]
    let onComplete: () -> Void
    let onRetry: () -> Void
    let retryAttempts: Int
    let accentColor: Color
    let textColor: Color
    
    @State private var isWaveformVisible = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var playbackProgress: Double = 0
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Animated circles with waveform
            ZStack {
                // Background circles
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(accentColor.opacity(0.1))
                        .frame(width: 160 + CGFloat(i * 40))
                }
                
                // Waveform
                HStack(spacing: 3) {
                    ForEach(Array(waveformData.enumerated()), id: \.offset) { index, height in
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(accentColor.opacity(0.8))
                            .frame(width: 2.5, height: isWaveformVisible ? height : 0)
                            .animation(
                                .spring(response: 0.4, dampingFraction: 0.7)
                                .delay(Double(index) * 0.01),
                                value: isWaveformVisible
                            )
                    }
                }
                .frame(width: 200)
            }
            .frame(height: 200)
            
            // Playback controls
            VStack(spacing: 24) {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 3)
                        
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(accentColor)
                            .frame(width: geometry.size.width * playbackProgress, height: 3)
                    }
                }
                .frame(height: 3)
                
                // Play button
                Button(action: togglePlayback) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 64, height: 64)
                            .shadow(color: accentColor.opacity(0.15), radius: 15, x: 0, y: 6)
                        
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 24))
                            .foregroundColor(accentColor)
                            .offset(x: isPlaying ? 0 : 2)
                    }
                }
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 16) {
                Button(action: onComplete) {
                    HStack(spacing: 12) {
                        Text("capture")
                            .font(.custom("PPNeueMontreal-Bold", size: 18))
                        
                        FloatingDots()
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(accentColor)
                    )
                }
                
                if retryAttempts > 0 {
                    Button(action: {
                        cleanup()
                        onRetry()
                    }) {
                        Text("try again")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(accentColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 28)
                                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 30)
        }
        .onAppear {
            setupAudioPlayer()
            withAnimation { isWaveformVisible = true }
        }
        .onDisappear(perform: cleanup)
    }
    
    private func setupAudioPlayer() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.delegate = AudioPlayerDelegate(onComplete: {
                isPlaying = false
                playbackProgress = 0
                timer?.invalidate()
            })
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
            playbackProgress = player.currentTime / player.duration
        }
    }
    
    private func cleanup() {
        timer?.invalidate()
        timer = nil
        audioPlayer?.stop()
        audioPlayer = nil
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
}

struct FloatingDots: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color.white)
                    .frame(width: 4, height: 4)
                    .opacity(isAnimating ? 0.4 : 1)
                    .animation(
                        Animation.easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}


#Preview {
    AddSuccessView()
}
