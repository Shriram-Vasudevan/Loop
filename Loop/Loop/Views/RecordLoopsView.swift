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
    @ObservedObject var videoManager = VideoManager()

    @State private var isRecording = false
    @State private var isPostRecording = false
    @State private var isAllPromptsCompleted = false
    @State private var retryAttempts = 1
    @State private var recordingTimer: Timer?
    @State private var timeRemaining: Int = 30

    @State private var showingFirstLaunchScreen = true
    @State var isFirstLaunch: Bool
    @State private var isVideoMode = false

    @Environment(\.dismiss) var dismiss

    let accentColor = Color(hex: "A28497")
    let complementaryColor = Color(hex: "84A297")
    let backgroundColor = Color(hex: "F5F5F5")
    let strokeColor = Color(hex: "6B7280")
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
                        
            WaveBackground()
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                if isAllPromptsCompleted {
                    thankYouScreen
                        .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                } else if isPostRecording {
                    postRecordingView
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

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "F0F4F8"),
                Color(hex: "E2E8F0"),
                Color(hex: "D5DDE8")
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .edgesIgnoringSafeArea(.all)
    }

    private var recordingScreen: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                topBar
                    .padding(.bottom, 20)

                promptArea

                Spacer()

                if isVideoMode {
                    videoRecordingView(geometry: geometry)
                } else {
                    recordingButton
                        .padding(.bottom, 40)
                }

                recordingModeToggle
                    .padding(.bottom, 20)
            }
        }
    }

    private func videoRecordingView(geometry: GeometryProxy) -> some View {
        ZStack {
            VideoRecordingView(videoManager: videoManager)
                .frame(width: geometry.size.width * 0.9, height: geometry.size.height * 0.6)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(strokeColor, lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)

            recordingButton
                .offset(y: geometry.size.height * 0.2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.05))
        )
        .padding(.vertical, 20)
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
                    .fill(isRecording ? .red : .white)
                    .frame(width: 65)

                if isRecording {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(accentColor)
                        .frame(width: 31, height: 31)
                } else {
                    Circle()
                        .stroke(.white, lineWidth: 2)
                        .frame(width: 75)
                }
            }
        }
    }

    private var recordingModeToggle: some View {
        HStack {
            Spacer()
            
            Button(action: {
                withAnimation {
                    isVideoMode.toggle()
                    isRecording = false
                    timeRemaining = 30
                    if isVideoMode {
                        audioManager.stopRecording()
                    } else {
                        videoManager.stopRecording()
                    }
                }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: isVideoMode ? "video.fill" : "mic.fill")
                        .foregroundColor(isVideoMode ? .white : accentColor)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(isVideoMode ? accentColor : .white)
                                .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 2)
                        )
                    
                    Image(systemName: isVideoMode ? "mic" : "video")
                        .foregroundColor(isVideoMode ? accentColor : .white)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(isVideoMode ? .white : accentColor)
                                .shadow(color: .gray.opacity(0.3), radius: 3, x: 0, y: 2)
                        )
                }
                .padding(5)
                .background(Color.white.opacity(0.8))
                .cornerRadius(25)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(accentColor, lineWidth: 1)
                )
            }
            
            Spacer()
        }
    }

    private var postRecordingView: some View {
        VStack {
            if isVideoMode {
                LoopVideoConfirmationView(
                    videoURL: videoManager.videoFileURL ?? URL(fileURLWithPath: ""),
                    onComplete: {
                        completeRecording()
                    },
                    onRetry: {
                        retryRecording()
                    })
            } else {
                LoopAudioConfirmationView(
                    audioURL: audioManager.getRecordedAudioFile() ?? URL(fileURLWithPath: ""),
                    waveformData: generateRandomWaveform(count: 30),
                    onComplete: {
                        completeRecording()
                    },
                    onRetry: {
                        retryRecording()
                    })
            }
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
            videoManager.resetRecording()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                dismiss()
            }
        }
    }

    private var firstLaunchOrQuietSpaceScreen: some View {
        Group {
            if isFirstLaunch {
                Text("It's time to Loop")
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


    private func completeRecording() {
        let currentPrompt = loopManager.getCurrentPrompt()
        if isVideoMode, let videoFileURL = videoManager.videoFileURL {
            loopManager.addLoop(mediaURL: videoFileURL, isVideo: true, prompt: currentPrompt)
            loopManager.fetchRandomPastLoop()
            
            proceedToNextPrompt()
        } else if let audioFileURL = audioManager.getRecordedAudioFile() {
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
            videoManager.resetRecording()
            isPostRecording = false
            isRecording = false
            timeRemaining = 30
        }
    }

    private func toggleRecording() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isRecording.toggle()
        }

        if !isRecording {
            if isVideoMode {
                videoManager.stopRecording()
            } else {
                audioManager.stopRecording()
            }
            stopTimer()
            isPostRecording = true
        } else {
            startRecordingWithTimer()
        }
    }

    private func startRecordingWithTimer() {
        if isVideoMode {
            videoManager.startRecording()
        } else {
            audioManager.startRecording()
        }
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
                if isVideoMode {
                    videoManager.stopRecording()
                } else {
                    audioManager.stopRecording()
                }
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
