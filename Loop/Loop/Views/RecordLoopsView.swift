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
    @State private var retryAttempts = 1
    @State private var recordingTimer: Timer?
    @State private var timeRemaining: Int = 30
    
    @State private var showingFirstLaunchScreen = true
    @State var isFirstLaunch: Bool
    
    @Environment(\.dismiss) var dismiss

    let accentColor = Color(hex: "A28497")
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            WavyBackground()
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                if isAllPromptsCompleted {
                    thankYouScreen
                        .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                        .edgesIgnoringSafeArea(.all)
                } else if isPostRecording {
                    LoopAudioConfirmationView(
                        audioURL: audioManager.getRecordedAudioFile() ?? URL(fileURLWithPath: ""),
                        waveformData: generateRandomWaveform(count: 30),
                        onComplete: {
                            completeRecording()
                        },
                        onRetry: {
                            retryRecording()
                        })
                    .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                } else if showingFirstLaunchScreen {
                    firstLaunchOrQuietSpaceScreen
                        .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                } else {
                    recordingScreen
                        .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                }
            }
            .padding(.horizontal, 16)
        }
        .onAppear {
            audioManager.resetRecording()
        }
    }

    private var firstLaunchOrQuietSpaceScreen: some View {
        Group {
            if isFirstLaunch {
                Text("It’s time to Loop")
                    .font(.system(size: 44, weight: .ultraLight))
                    .foregroundColor(Color(hex: "333333"))
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
                Text("Find a Quiet Space")
                    .font(.system(size: 44, weight: .ultraLight))
                    .foregroundColor(Color(hex: "333333"))
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
    
    // MARK: - Recording Screen (Main screen for recording the loop)
    private var recordingScreen: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.bottom, 30)
            
            promptArea
            
            Spacer()
            
            recordingButton
                .padding(.bottom, 10)
        }
    }

    private var thankYouScreen: some View {
        VStack(spacing: 16) {
            Text("Thanks for Looping!")
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundColor(Color(hex: "333333"))
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Text("See you tomorrow for more Loops.")
                .font(.system(size: 24, weight: .thin))
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

    private var postRecordingScreen: some View {
        VStack(spacing: 16) {
            Text("Review Your Recording")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Color(hex: "333333"))
                .padding(.top, 16)
            
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
            playAudioIfAvailable()
        }
    }

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

    private func retryRecording() {
        loopManager.retryRecording()
        audioManager.resetRecording()
        isPostRecording = false
    }

    private func completeRecording() {
        if let audioFileURL = audioManager.getRecordedAudioFile() {
            let currentPrompt = loopManager.getCurrentPrompt()
            loopManager.addLoop(audioURL: audioFileURL, prompt: currentPrompt)
            loopManager.fetchRandomPastLoop()
            
            print("the index \(loopManager.currentPromptIndex)")
            print("the count \(loopManager.prompts.count)")
            if loopManager.isLastLoop() {
                loopManager.nextPrompt()
                print("the index \(loopManager.currentPromptIndex)")
                isAllPromptsCompleted = true
            }
            else {
                isPostRecording = false
                loopManager.nextPrompt()
                print("the index \(loopManager.currentPromptIndex)")
            }

            
        }
    }

    private func playAudio(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Error playing audio: \(error.localizedDescription)")
        }
    }

    private func playAudioIfAvailable() {
        if let audioFileURL = audioManager.getRecordedAudioFile() {
            playAudio(url: audioFileURL)
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
    
    func generateRandomWaveform(count: Int, minHeight: CGFloat = 10, maxHeight: CGFloat = 60) -> [CGFloat] {
        (0..<count).map { _ in
            CGFloat.random(in: minHeight...maxHeight)
        }
    }
}

#Preview {
    RecordLoopsView(isFirstLaunch: true)
}
