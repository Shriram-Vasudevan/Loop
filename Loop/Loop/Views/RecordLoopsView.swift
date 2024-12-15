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
    @ObservedObject var analysisManager = AnalysisManager.shared
    
    @State private var isRecording = false
    @State private var isPostRecording = false
    @State private var isShowingMemory = false
    @State private var isLoadingMemory = false
    @State private var userDaysThresholdNotMet = false
    @State private var noMemoryFound = false
    @State private var recordingTimer: Timer?
    @State private var timeRemaining: Int = 30
    @State private var showingFirstLaunchScreen = true
    @State private var showingPromptOptions = false
    @State var isFirstLaunch: Bool
    @State private var backgroundOpacity: Double = 0
    @State private var messageOpacity: Double = 0
    
    @State private var allPrompts: [String] = []
    @State private var pastLoop: Loop?
    
    let accentColor = Color(hex: "A28497")
    let secondaryColor = Color(hex: "B7A284")
    let textColor = Color(hex: "2C3E50")
    
        
    @Environment(\.dismiss) var dismiss
    
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
            
            VStack(spacing: 0) {
                if isShowingMemory {
                    memoryPlaybackView
                } else if loopManager.hasCompletedToday {
                    thankYouScreen
                } else if isPostRecording {
                    postRecordingView
                } else if showingFirstLaunchScreen {
                    firstLaunchOrQuietSpaceScreen
                } else {
                    recordingScreen
                }
            }
            .padding(.horizontal, 32)
            
            if showingPromptOptions && !isRecording && !isPostRecording && loopManager.currentPromptIndex < 2 {
                promptSwitcherOverlay
            }
        }
        .onAppear {
            audioManager.cleanup()
        }
    }
    
    private var recordingScreen: some View {
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
    
    private var topBar: some View {
        VStack(spacing: 24) {
            ZStack {
                if let category = loopManager.getCategoryForPrompt(loopManager.getCurrentPrompt()) {
                    Text(category.rawValue)
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(accentColor.opacity(0.8))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(accentColor.opacity(0.1))
                        )
                }
                
                HStack {

                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(accentColor.opacity(0.8))
                    }
                    
                    Spacer()
                }
            }
            
            ProgressIndicator(
                totalSteps: loopManager.dailyPrompts.count,
                currentStep: loopManager.currentPromptIndex,
                accentColor: accentColor
            )
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
            } else if !isPostRecording && loopManager.currentPromptIndex > 0 {
                Button(action: {
                    withAnimation {
                        showingPromptOptions.toggle()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("try another prompt")
                    }
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .stroke(accentColor.opacity(0.3), lineWidth: 1)
                    )
                }
                .opacity(isRecording ? 0 : 1)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var promptSwitcherOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        showingPromptOptions = false
                    }
                }
            
            VStack(spacing: 24) {
                Text("Choose another prompt")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.black)
                
                VStack(spacing: 16) {
                    ScrollView(.vertical) {
                        ForEach(loopManager.getAlternativePrompts(), id: \.text) { prompt in
                            Button(action: {
                                withAnimation {
                                    loopManager.switchToPrompt(prompt)
                                    showingPromptOptions = false
                                }
                            }) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(prompt.category.rawValue)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(accentColor)
                                    
                                    Text(prompt.text)
                                        .font(.system(size: 18, weight: .light))
                                        .foregroundColor(.black)
                                        .multilineTextAlignment(.leading)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "FFFFFF").opacity(0.95))
            )
            .padding(24)
        }
        .transition(.opacity.combined(with: .scale(scale: 1.1)))
    }
    
    private var recordingButton: some View {
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
    
    private var postRecordingView: some View {
        VStack {
            LoopAudioConfirmationView(
                audioURL: audioManager.getRecordedAudioFile() ?? URL(fileURLWithPath: ""),
                waveformData: generateRandomWaveform(count: 40),
                onComplete: { completeRecording() },
                onRetry: { retryRecording() }, retryAttempts: loopManager.retryAttemptsLeft
            )
        }
    }
        
    private var memoryPlaybackView: some View {
        VStack(spacing: 32) {
            if isLoadingMemory && !userDaysThresholdNotMet {
                Text("loading from your past")
                    .font(.system(size: 24, weight: .ultraLight))
                    .foregroundColor(textColor)
                
                LoadingWaveform(accentColor: accentColor)
                    .transition(.opacity)
            }  else if userDaysThresholdNotMet {
                Text("loop for three days to get memories")
                    .font(.system(size: 44, weight: .ultraLight))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
                    .animation(.easeInOut, value: userDaysThresholdNotMet)
            } else if let pastLoop = pastLoop {
                ViewPastLoopView(loop: pastLoop, isThroughRecordLoopsView: true)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
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
                    .padding(.horizontal, 32)
                }
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
                
                Text("see your insights")
                    .font(.system(size: 24, weight: .thin))
                    .foregroundColor(Color.gray)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            audioManager.cleanup()
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
            let loop = loopManager.addLoop(
                mediaURL: audioFileURL,
                isVideo: false,
                prompt: loopManager.getCurrentPrompt(), isDailyLoop: true, isFollowUp: false
            )
            
            Task {
                do {
                     try await analysisManager.startAnalysis(loop, isPastLoop: false)
                } catch {
                    print("Analysis error: \(error)")
                }
            }

            if loopManager.isLastPrompt() {
                allPrompts = loopManager.dailyPrompts
                
                withAnimation {
                    isShowingMemory = true
                    isLoadingMemory = true
                }
                
                Task {
                    guard let userDays = try? await LoopCloudKitUtility.fetchDistinctLoopingDays() else {
                        userDaysThresholdNotMet = true
                        return
                    }
                    
                    if userDays < 3 {
                        await MainActor.run {
                            withAnimation {
                                userDaysThresholdNotMet = true
                            }
                            
                            // Use DispatchQueue with a completion handler
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    loopManager.hasCompletedToday = true
                                    loopManager.saveCachedState()
                                    isShowingMemory = false
                                }
                            }
                        }
                        return
                    }
                    
                    if let pastLoop = try? await loopManager.getPastLoopForComparison(
                        recordedPrompts: allPrompts
                    ) {
                        await MainActor.run {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                self.pastLoop = pastLoop
                                isPostRecording = false
                                isLoadingMemory = false
                            }
                            audioManager.cleanup()
                        }
                    } else {
                        await MainActor.run {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                loopManager.hasCompletedToday = true
                                loopManager.saveCachedState()
                                isShowingMemory = false
                            }
                            audioManager.cleanup()
                        }
                    }
                }
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    loopManager.moveToNextPrompt()
                    isPostRecording = false
                }
            }
        }
    }
    
    private func retryRecording() {
        if loopManager.retryAttemptsLeft > 0 {
            loopManager.retryRecording()
            audioManager.cleanup()
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

//struct PastLoopPlayer: View {
//    let loop: Loop
//    @State private var isPlaying = false
//    @State private var progress: Double = 0
//    @State private var audioPlayer: AVAudioPlayer?
//    @State private var timer: Timer?
//    @State private var waveformData: [CGFloat] = []
//
//    let accentColor = Color(hex: "A28497")
//
//    var body: some View {
//        VStack(spacing: 32) {
//            WaveformView(
//                waveformData: waveformData,
//                color: accentColor
//            )
//
//            // Enhanced playback controls
//            HStack(spacing: 40) {
//                Button(action: togglePlayback) {
//                    Circle()
//                        .fill(Color.white)
//                        .frame(width: 56, height: 56)
//                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
//                        .overlay(
//                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
//                                .font(.system(size: 22))
//                                .foregroundColor(accentColor)
//                                .offset(x: isPlaying ? 0 : 2)
//                        )
//                }
//            }
//
//            // Progress bar
//            GeometryReader { geometry in
//                ZStack(alignment: .leading) {
//                    RoundedRectangle(cornerRadius: 2)
//                        .fill(Color.gray.opacity(0.2))
//                        .frame(height: 4)
//
//                    RoundedRectangle(cornerRadius: 2)
//                        .fill(accentColor)
//                        .frame(width: geometry.size.width * progress, height: 4)
//                }
//            }
//            .frame(height: 4)
//            .padding(.horizontal)
//        }
//        .onAppear {
//            setupAudioPlayer()
//            generateWaveform()
//        }
//        .onDisappear(perform: cleanup)
//    }
//
//    private func generateWaveform() {
//        // Generate random waveform data for visualization
//        waveformData = (0..<50).map { _ in
//            CGFloat.random(in: 10...50)
//        }
//    }
//
//    private func togglePlayback() {
//        if isPlaying {
//            stopPlayback()
//        } else {
//            startPlayback()
//        }
//    }
//
//    private func setupAudioPlayer() {
//        guard let url = loop.data.fileURL else { return }
//
//        do {
//            audioPlayer = try AVAudioPlayer(contentsOf: url)
//            audioPlayer?.prepareToPlay()
//            audioPlayer?.delegate = AudioPlayerDelegate(onComplete: {
//                isPlaying = false
//                progress = 0
//            })
//        } catch {
//            print("Error setting up audio player: \(error)")
//        }
//    }
//
//    private func startPlayback() {
//        audioPlayer?.play()
//        isPlaying = true
//        startProgressTimer()
//    }
//
//    private func stopPlayback() {
//        audioPlayer?.pause()
//        isPlaying = false
//        timer?.invalidate()
//    }
//
//    private func startProgressTimer() {
//        timer?.invalidate()
//        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
//            guard let player = audioPlayer else { return }
//            progress = player.currentTime / player.duration
//        }
//    }
//
//    private func cleanup() {
//        timer?.invalidate()
//        timer = nil
//        audioPlayer?.stop()
//        audioPlayer = nil
//    }
//}





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
