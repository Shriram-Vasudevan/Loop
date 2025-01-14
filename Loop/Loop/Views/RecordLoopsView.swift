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
    
    @ObservedObject private var checkinManager = DailyCheckinManager.shared
    @State private var dayRating: Double = 0.5
    @State private var showingDayRating: Bool = true
    
    @State private var selectedColorHex: String = "#B5D5E2" // Default to base color
    
    var body: some View {
        ZStack {
            if loopManager.currentPromptIndex > 1 {
                AnimatedBackground()
                    .opacity(backgroundOpacity)
                    .onAppear {
                        withAnimation(.easeIn(duration: 1.2)) {
                            backgroundOpacity = 1
                        }
                    }
                    .edgesIgnoringSafeArea(.all)
            }
            
            VStack(spacing: 0) {
                if isShowingMemory {
                    memoryPlaybackView
                } else if loopManager.hasCompletedToday {
                    thankYouScreen
                } else if isPostRecording {
                    postRecordingView
                } else if showingFirstLaunchScreen, loopManager.currentPromptIndex == 0 {
                    firstLaunchOrQuietSpaceScreen
                } else {
                    recordingScreen
                }
            }
            .padding(.horizontal, 32)
            
            if showingPromptOptions && !isRecording && !isPostRecording && loopManager.currentPromptIndex > 2 {
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
            
            promptArea
            
            Spacer()
            
            recordingButton
                .padding(.bottom, 60)
        }
    }
    
    private var topBar: some View {
        VStack(spacing: 24) {
            ZStack {
                Text("DAILY REFLECTION")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.5))
                
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
  
    private var dayRatingView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 24) {
                VStack (spacing: 10) {
                    Text("before we begin")
                        .font(.system(size: 36, weight: .ultraLight))
                        .foregroundColor(textColor)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                            .foregroundColor(accentColor.opacity(0.3))
                        
                        Text("HOW ARE YOU FEELING TODAY?")
                            .font(.system(size: 11, weight: .medium))
                            .tracking(1.5)
                            .foregroundColor(textColor.opacity(0.5))
                    }
                }
            
                VStack(spacing: 40) {
                    VStack(spacing: 24) {

                        HStack(alignment: .bottom, spacing: 4) {
                            Text(String(format: "%.1f", dayRating * 10))
                                .font(.system(size: 54, weight: .medium))
                                .foregroundColor(textColor)
                                .contentTransition(.numericText())
                            
                            Text("/10")
                                .font(.system(size: 24, weight: .light))
                                .foregroundColor(textColor.opacity(0.3))
                                .offset(y: -12)
                        }
                    }
                    
                    // Slider
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(hex: "F8F9FA"))
                                .overlay(
                                    Capsule()
                                        .stroke(accentColor.opacity(0.1), lineWidth: 1)
                                )
                            
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            accentColor.opacity(0.15),
                                            accentColor.opacity(0.1)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * CGFloat(dayRating))
                            
                            Circle()
                                .fill(Color.white)
                                .frame(width: 28, height: 28)
                                .shadow(color: accentColor.opacity(0.1), radius: 8, x: 0, y: 2)
                                .overlay(
                                    Circle()
                                        .stroke(accentColor.opacity(0.15), lineWidth: 1)
                                )
                                .overlay(
                                    Circle()
                                        .fill(accentColor.opacity(0.1))
                                        .frame(width: 8, height: 8)
                                )
                                .offset(x: (geometry.size.width - 28) * CGFloat(dayRating))
                        }
                        .frame(height: 44)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { gesture in
                                    let newValue = gesture.location.x / geometry.size.width
                                    dayRating = min(max(0, newValue), 1)
                                }
                        )
                    }
                    .frame(height: 44)
                }
                
                VStack(spacing: 16) {
                    Button(action: {
                        checkinManager.saveDailyCheckin(rating: dayRating * 10)
                        withAnimation {
                            showingFirstLaunchScreen = false
                        }
                    }) {
                        Text("continue")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(.white)
                            .frame(height: 56)
                            .frame(maxWidth: .infinity)
                            .background(accentColor)
                            .cornerRadius(28)
                    }
                    
                    Button(action: {
                        withAnimation {
                            showingFirstLaunchScreen = false
                        }
                    }) {
                        Text("skip")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(accentColor)
                    }
                }
                .padding(.top, 40)
            }
            .padding(32)
        }
    }
    
    private var promptArea: some View {
        VStack(spacing: isRecording ? 20 : 20) {
            if loopManager.needsCategorySelection() {
                CategorySelectionView(
                    loopManager: loopManager,
                    onCategorySelected: { category in
                        Task {
                            await loopManager.selectCategory(category)
                        }
                    },
                    isDailyPrompt: loopManager.currentPromptIndex == 2,
                    accentColor: accentColor,
                    textColor: textColor
                )
            } else {
                VStack(spacing: 30) {
                    if loopManager.currentPromptIndex > 1 {
                        VStack(spacing: isRecording ? 20 : 20) {
                            Text(loopManager.getCurrentPrompt())
                                .font(.system(size: 28, weight: .medium))
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
                            } else if !isPostRecording && loopManager.currentPromptIndex > 1 && loopManager.currentPromptIndex < 4 {
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
                    } else {
                        VStack (spacing: 20) {
                            HStack {
                                Text(loopManager.getCurrentPrompt())
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundColor(textColor)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
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
                        .padding(.top, 40)
                        
                        InitialReflectionVisual(index: loopManager.currentPromptIndex)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
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
                onRetry: { retryRecording() },
                retryAttempts: loopManager.retryAttemptsLeft
            )
        }
    }
        
    private var memoryPlaybackView: some View {
        VStack(spacing: 32) {
            Group {
                if isLoadingMemory && !userDaysThresholdNotMet {
                    loadingView
                } else if userDaysThresholdNotMet {
                    thresholdNotMetView
                } else if let pastLoop = pastLoop {
                    pastLoopContent(pastLoop)
                }
            }
            .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
        .padding(.bottom, 40)
    }

    private var loadingView: some View {
        VStack(spacing: 24) {
            Text("loading from your past")
                .font(.system(size: 24, weight: .ultraLight))
                .foregroundColor(textColor)
            
            LoadingWaveform(accentColor: accentColor)
        }
    }

    private var thresholdNotMetView: some View {
        Text("loop for three days to get memories")
            .font(.system(size: 28, weight: .medium))
            .foregroundColor(textColor)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func pastLoopContent(_ loop: Loop) -> some View {
        VStack(spacing: 24) {
            MemoryPlaybackView(loop: loop)
                .padding(.top)
            
            continueButton
        }
    }

    private var continueButton: some View {
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
//                
//                Text("see your insights")
//                    .font(.system(size: 24, weight: .thin))
//                    .foregroundColor(Color.gray)
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
                dayRatingView
            }
        }
    }
    
    private var welcomeView: some View {
        VStack(spacing: 24) {
            Text("it's time to loop")
                .font(.system(size: 36, weight: .ultraLight))
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
                .font(.system(size: 36, weight: .ultraLight))
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
        guard let audioFileURL = audioManager.getRecordedAudioFile() else { return }
        
        let currentPromptIndex = loopManager.currentPromptIndex
        let prompts = loopManager.dailyPrompts
        
        Task {
            let loop = await loopManager.addLoop(
                mediaURL: audioFileURL,
                isVideo: false,
                prompt: prompts[currentPromptIndex],
                isDailyLoop: true,
                isFollowUp: false, isSuccess: false, isUnguided: false
            )
            
          // await analysisManager.startAnalysis(loop.0, transcript: loop.1)
        }
        
        if loopManager.isLastPrompt() {
            allPrompts = loopManager.dailyPrompts
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                loopManager.hasCompletedToday = true
                loopManager.saveCachedState()
                isShowingMemory = false
            }
            audioManager.cleanup()

        } else {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                loopManager.moveToNextPrompt()
                isPostRecording = false
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

import SwiftUI

struct EmotionElevationSelector: View {
    @Binding var selectedColor: String
    let onColorSelected: (String) -> Void
    
    // Define emotional range colors with more distinct steps
    private let colorSteps = [
        0.0: Color(hex: "1E3D59"),
        0.2: Color(hex: "2E5C8A"),
        0.3: Color(hex: "4682B4"),
        0.4: Color(hex: "6CA0CF"),
        0.5: Color(hex: "95A5A6"),
        0.6: Color(hex: "F4D03F"),
        0.7: Color(hex: "F5B041"),
        0.8: Color(hex: "F39C12"),
        1.0: Color(hex: "E67E22")
    ]
    
    @State private var offset: CGFloat = UIScreen.main.bounds.height / 2
    @State private var startLocation: CGFloat?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(getCurrentColor(in: geometry))
                    .animation(.easeOut(duration: 0.2), value: offset)
                
                HStack(spacing: 2) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    RoundedRectangle(cornerRadius: 2)
                        .frame(width: 30, height: 4)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(8)
                .background(Color.black.opacity(0.15))
                .cornerRadius(8)
                .offset(y: offset - geometry.size.height/2)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if startLocation == nil {
                                startLocation = offset
                            }
                            
                            let newOffset = startLocation! + value.translation.height
                            offset = min(max(0, newOffset), geometry.size.height)
                            
                            let position = 1 - (offset / geometry.size.height)
                            updateColor(position)
                        }
                        .onEnded { _ in
                            startLocation = nil
                            onColorSelected(selectedColor)
                        }
                )
            }
        }
        .onAppear {
            updateColor(0.5)
        }
    }
    
    private func getCurrentColor(in geometry: GeometryProxy) -> LinearGradient {
        let position = 1 - (offset / geometry.size.height)
        let color = getColorForPosition(position)
        
        return LinearGradient(
            gradient: Gradient(colors: [
                color,
                color.opacity(0.85)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private func getColorForPosition(_ position: CGFloat) -> Color {
        let sortedSteps = colorSteps.keys.sorted()
        var closestStep = sortedSteps[0]
        
        for step in sortedSteps {
            if abs(position - step) < abs(position - closestStep) {
                closestStep = step
            }
        }
        
        return colorSteps[closestStep] ?? Color(hex: "95A5A6") 
    }
    
    private func updateColor(_ position: CGFloat) {
        selectedColor = getColorForPosition(position).toHex()
    }
}

struct CategorySelectionView: View {
    @ObservedObject var loopManager: LoopManager
    let onCategorySelected: (PromptCategory) -> Void
    let isDailyPrompt: Bool
    let accentColor: Color
    let textColor: Color
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                Text(isDailyPrompt ? "daily reflection" : "general reflection")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(accentColor.opacity(0.1))
                    )
                
                Text("select a topic to talk about")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(textColor)
            }
            
            // Categories Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(loopManager.getAvailableCategories(), id: \.self) { category in
                    CategoryButton(
                        category: category,
                        accentColor: accentColor,
                        textColor: textColor
                    ) {
                        onCategorySelected(category)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }
}

struct CategoryButton: View {
    let category: PromptCategory
    let accentColor: Color
    let textColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Category Icon
                Image(systemName: iconName(for: category))
                    .font(.system(size: 24))
                    .foregroundColor(accentColor)
                
                // Category Name
                Text(category.rawValue)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: accentColor.opacity(0.1), radius: 8, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(accentColor.opacity(0.1), lineWidth: 1)
            )
        }
    }
    
    private func iconName(for category: PromptCategory) -> String {
        switch category {
        case .emotionalWellbeing: return "heart"
        case .challenges: return "mountain.2"
        case .growth: return "leaf"
        case .connections: return "person.2"
        case .curiosity: return "sparkles"
        case .extraPrompts: return "star"
        case .freeform: return "square.and.pencil"
        }
    }
}

struct UnfoldingDayWave: Shape {
    var phase: Double
    var frequency: Double = 1
    var amplitudeFactor: Double = 1
    
    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath()
        let width = rect.width
        let height = rect.height
        let midHeight = height / 2
        let amplitude = height * 0.25 * amplitudeFactor
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let normalizedX = relativeX * .pi * frequency + phase
            let y = midHeight + sin(normalizedX * 4) * cos(normalizedX) * amplitude
            
            if x == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        return Path(path.cgPath)
    }
}

struct MomentWave: Shape {
    var phase: Double
    var frequency: Double = 1
    var focusPoint: CGFloat // 0 to 1, represents where waves concentrate
    
    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath()
        let width = rect.width
        let height = rect.height
        let midHeight = height / 2
        let focusX = width * focusPoint
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, through: width, by: 1) {
            let distanceFromFocus = abs(x - focusX) / width
            let amplitude = height * 0.2 * (1 - distanceFromFocus)
            let relativeX = x / width
            let normalizedX = relativeX * .pi * frequency + phase
            let y = midHeight + sin(normalizedX * 3) * amplitude
            
            if x == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        return Path(path.cgPath)
    }
}

struct InitialReflectionVisual: View {
    let index: Int
    @State private var phase = 0.0
    
    private let accentColor = Color(hex: "A28497")
    private let blueColor = Color(hex: "1E3D59")
    
    var body: some View {
        ZStack {
            if index == 0 {
                WavePattern()
                    .fill(accentColor.opacity(0.7))
                    .frame(height: 100)
            } else {
                WavePattern()
                    .fill(blueColor.opacity(0.7))
                    .frame(height: 100)
            }
        }
        .frame(height: 150)
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                phase = 2 * .pi
            }
        }
    }
}

struct InitialReflectionConfirmation: View {
    let audioURL: URL
    let index: Int
    let onComplete: () -> Void
    let onRetry: () -> Void
    let retryAttempts: Int
    
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var phase = 0.0
    @State private var amplitude: CGFloat = 0
    
    private let accentColor = Color(hex: "A28497")
    private let blueColor = Color(hex: "1E3D59")
    
    var body: some View {
        VStack(spacing: 40) {
            Text(index == 0 ? "your day unfolded" : "a moment captured")
                .font(.system(size: 32, weight: .thin))
                .foregroundColor(index == 0 ? accentColor : blueColor)
            
            // Audio visualization
            ZStack {
                // Wave visualization that responds to audio
                ForEach(0..<3) { i in
                    if index == 0 {
                        UnfoldingDayWave(
                            phase: phase,
                            frequency: Double(i + 1),
                            amplitudeFactor: isPlaying ? 1.0 / Double(i + 1) : 0.3 / Double(i + 1)
                        )
                        .stroke(accentColor, lineWidth: 1.5)
                        .opacity(0.3 - Double(i) * 0.08)
                    } else {
                        MomentWave(
                            phase: phase,
                            frequency: Double(i + 1) * 0.8,
                            focusPoint: 0.5
                        )
                        .stroke(blueColor, lineWidth: 1.5)
                        .opacity(0.3 - Double(i) * 0.08)
                    }
                }
                
                // Playback button
                Button(action: togglePlayback) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 60, height: 60)
                        .shadow(color: Color.black.opacity(0.1), radius: 8)
                        .overlay(
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 24))
                                .foregroundColor(index == 0 ? accentColor : blueColor)
                                .offset(x: isPlaying ? 0 : 2)
                        )
                }
            }
            .frame(height: 200)
            
            // Action buttons
            VStack(spacing: 16) {
                Button(action: onComplete) {
                    HStack(spacing: 8) {
                        Text("continue")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(index == 0 ? accentColor : blueColor)
                    )
                }
                
                if retryAttempts > 0 {
                    Button(action: onRetry) {
                        Text("reflect again")
                            .font(.system(size: 18, weight: .light))
                            .foregroundColor(index == 0 ? accentColor : blueColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(index == 0 ? accentColor : blueColor, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            setupAudioPlayer()
            startWaveAnimation()
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
            })
        } catch {
            print("Error setting up audio player: \(error)")
        }
    }
    
    private func togglePlayback() {
        if isPlaying {
            audioPlayer?.pause()
        } else {
            audioPlayer?.play()
        }
        isPlaying.toggle()
    }
    
    private func startWaveAnimation() {
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            phase = 2 * .pi
        }
    }
    
    private func cleanup() {
        audioPlayer?.stop()
        audioPlayer = nil
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Error cleaning up audio session: \(error)")
        }
    }
}


extension Color {
    func toHex() -> String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let rgb: Int = (Int)(red * 255) << 16 | (Int)(green * 255) << 8 | (Int)(blue * 255) << 0
        return String(format: "#%06x", rgb)
    }
}


#Preview {
    RecordLoopsView(isFirstLaunch: true)
}
