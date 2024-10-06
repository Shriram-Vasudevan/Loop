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
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isAllPromptsCompleted = false
    @State private var retryAttempts = 1 // Retry allowed once
    @State private var recordingTimer: Timer? // Timer for recording
    @State private var timeRemaining: Int = 30 // Countdown timer starting at 30 seconds
    
    @Environment(\.dismiss) var dismiss

    let accentColor = Color(hex: "A28497")
    
    var body: some View {
        ZStack {
            // White background with oscillating dots on top
            Color.white.edgesIgnoringSafeArea(.all)
            
            // Oscillating dots background
            OscillatingDotsBackground()
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                if isAllPromptsCompleted {
                    thankYouScreen // Final thank you screen when all prompts are completed
                        .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                } else if isPostRecording {
                    postRecordingScreen
                        .transition(.opacity.animation(.easeInOut(duration: 0.5))) // Smooth fade transition
                } else {
                    recordingScreen
                        .transition(.opacity.animation(.easeInOut(duration: 0.5))) // Smooth fade transition
                }
            }
            .padding(.horizontal, 16)
        }
        .onAppear {
            audioManager.resetRecording() // Ensure fresh recording each time
        }
    }
    
    // Main recording screen with top bar, prompt, and record button
    private var recordingScreen: some View {
        VStack(spacing: 0) {
            topBar
            
            Spacer()
            
            promptArea
            
            Spacer()
            
            recordingButton
                .padding(.bottom, 10)
        }
    }
    
    // Final "Thanks for Looping" screen after all prompts are completed
    private var thankYouScreen: some View {
        VStack(spacing: 16) {
            Text("Thanks for Looping!")
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundColor(Color(hex: "333333"))
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Text("See you tomorrow for another Loop.")
                .font(.system(size: 24, weight: .thin))
                .foregroundColor(Color.gray)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            audioManager.resetRecording() // Reset when everything is done
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                dismiss()
            }
        }
    }
    
    // Post-recording screen to listen, retry or complete the loop
    private var postRecordingScreen: some View {
        VStack(spacing: 16) {
            Text("Review Your Recording")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Color(hex: "333333"))
                .padding(.top, 16)
            
            // Audio player controls
            if let audioFileURL = audioManager.getRecordedAudioFile() {
                audioPlayerControls(audioFileURL: audioFileURL)
            } else {
                Text("No recording available.")
                    .foregroundColor(Color.gray)
            }
            
            Spacer()
            
            retryAndCompleteButtons
        }
        .onAppear {
            playAudioIfAvailable() // Play audio immediately on appearance
        }
    }
    
    // Top bar with navigation and indicator dots
    private var topBar: some View {
        VStack(spacing: 16) {
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
    
    // Prompt display or recording state
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
    
    // Button to start or stop recording
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
            }
        }
    }
    
    // Playback controls for the recorded audio
    private func audioPlayerControls(audioFileURL: URL) -> some View {
        HStack {
            Button(action: {
                playAudio(url: audioFileURL)
            }) {
                Image(systemName: "play.fill")
                    .foregroundColor(accentColor)
                    .font(.system(size: 40))
            }
        }
    }
    
    // Retry and complete buttons
    private var retryAndCompleteButtons: some View {
        HStack(spacing: 16) {
            if loopManager.retryAttemptsLeft > 0 {
                Button(action: retryRecording) {
                    Text("Retry (\(loopManager.retryAttemptsLeft) left)")
                        .frame(width: 150, height: 50)
                        .foregroundColor(.white)
                        .background(Color.red)
                        .cornerRadius(10)
                }
            }
            
            Button(action: completeRecording) {
                Text("Complete")
                    .frame(width: 150, height: 50)
                    .foregroundColor(.white)
                    .background(accentColor)
                    .cornerRadius(10)
            }
        }
    }
    
    // Retry the recording and save state
    private func retryRecording() {
        loopManager.retryRecording()
        audioManager.resetRecording()
        isPostRecording = false
    }
    
    // Complete the recording and upload the loop
    private func completeRecording() {
        if let audioFileURL = audioManager.getRecordedAudioFile() {
            let currentPrompt = loopManager.getCurrentPrompt()
            loopManager.addLoop(audioURL: audioFileURL, prompt: currentPrompt)
            loopManager.nextPrompt()

            if loopManager.areAllPromptsDone() {
                isAllPromptsCompleted = true
                print("all prompts completed")
            } else {
                isPostRecording = false // Continue to the next prompt
            }
        }
    }
    
    // Play recorded audio
    private func playAudio(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Error playing audio: \(error.localizedDescription)")
        }
    }
    
    // Play audio immediately on confirm screen
    private func playAudioIfAvailable() {
        if let audioFileURL = audioManager.getRecordedAudioFile() {
            playAudio(url: audioFileURL)
        }
    }
    
    // Start/stop recording logic
    private func toggleRecording() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isRecording.toggle()
        }
        
        if !isRecording {
            audioManager.stopRecording() // Stop and store audio
            stopTimer()
            isPostRecording = true // Switch to confirm view
        } else {
            startRecordingWithTimer() // Start recording with countdown
        }
    }
    
    // Start the recording and countdown timer
    private func startRecordingWithTimer() {
        audioManager.startRecording() // Start recording
        timeRemaining = 30 // Reset countdown to 30 seconds
        startTimer()
    }
    
    // Timer to count down from 30 seconds
    private func startTimer() {
        recordingTimer?.invalidate() // Stop any existing timer
        
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopTimer()
                audioManager.stopRecording() // Stop recording at 0
                isPostRecording = true // Switch to confirm view
            }
        }
    }
    
    // Stop the timer
    private func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
}

// New Oscillating Dots Background with a circle and animated dots
struct OscillatingDotsBackground: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .fill(Color.clear)
                    .frame(width: geometry.size.width * 0.6, height: geometry.size.width * 0.6)
                    .overlay(
                        ForEach(0..<12) { index in
                            Circle()
                                .fill(Color.black.opacity(0.4))
                                .frame(width: 10 + phase * 10, height: 10 + phase * 10)
                                .position(x: geometry.size.width / 2 + CGFloat(cos(Double(index) * .pi / 6)) * (geometry.size.width * 0.25),
                                          y: geometry.size.height / 2 + CGFloat(sin(Double(index) * .pi / 6)) * (geometry.size.height * 0.25))
                        }
                    )
            }
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    phase = 1 // Animate between sizes
                }
            }
        }
    }
}


#Preview {
    RecordLoopsView()
}
