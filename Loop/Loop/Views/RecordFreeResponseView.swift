//
//  RecordFreeResponseView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/5/25.
//

import SwiftUI
import AVFoundation

struct RecordFreeResponseView: View {
    @ObservedObject var loopManager = LoopManager.shared
    @ObservedObject var audioManager = AudioManager.shared
    @ObservedObject var transcriptionManager = LiveTranscriptionManager.shared
    
    @State private var isRecording = false
    @State private var isPostRecording = false
    @State private var showingThankYouScreen = false
    @State private var recordingTimer: Timer?
    @State private var liveTranscriptionEnabled = true
    
    @State private var timeRemaining: Int = 1000
    @State private var retryAttempts = 100
    @Environment(\.dismiss) var dismiss
    
    let accentColor = Color(hex: "A28497")
    let secondaryColor = Color(hex: "B7A284")
    let textColor = Color(hex: "2C3E50")
    let lightBackgroundColor = Color(hex: "F8F9FA")
    
    var body: some View {
        ZStack {
//            // Beautiful animated background
//            GradientWaveBackground(
//                primaryColor: accentColor,
//                secondaryColor: secondaryColor.opacity(0.7),
//                tertiaryColor: textColor.opacity(0.05)
//            )
            
            InitialReflectionVisual(index: 0)
                .edgesIgnoringSafeArea(.all)
                .scaleEffect(y: -1)
            
            VStack(spacing: 0) {
                if showingThankYouScreen {
                    thankYouView
                } else if isPostRecording {
                    postRecordingView
                        .padding(.top, 50)
                } else {
                    mainRecordingView
                }
            }
            
            VStack {
                headerSection
                
                Spacer()
            }
        }
        .background(lightBackgroundColor)
        .onAppear {
            audioManager.cleanup()
            transcriptionManager.checkSpeechRecognitionAuthorization()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(formattedDate())
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray)
                
                Spacer()
                
                // Optional subtle glowing indicator
                if isRecording {
                    HStack(spacing: 8) {
                        PulsingDot()
                            .frame(width: 8, height: 8)
                        Text("Recording")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(accentColor)
                    }
                    .transition(.opacity)
                }
            }
            .padding(.top, 16)
            
            Text(getGreeting())
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(textColor)
            
            Text("This is your space. Take a moment to share your thoughts, unfiltered and unguided")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.gray)
                .padding(.bottom, 8)
            
            Divider()
        }
        .padding(.horizontal, 32)
        .background(
            Rectangle()
                .fill(LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: lightBackgroundColor, location: 0),
                        .init(color: lightBackgroundColor.opacity(0.95), location: 0.7),
                        .init(color: lightBackgroundColor.opacity(0), location: 1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .frame(height: 200)
                .offset(y: -40)
        )
    }
    
    private var mainRecordingView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            if isRecording {
                VStack(spacing: 20) {
                    if liveTranscriptionEnabled && !transcriptionManager.transcribedText.isEmpty {
                        CleanTranscriptionView(text: transcriptionManager.transcribedText)
                            .padding(.top, 10)
                            .transition(.opacity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.7))
                                    .shadow(color: accentColor.opacity(0.1), radius: 15, x: 0, y: 8)
                            )
                            .padding(.horizontal, 16)
                    }
                }
            }
            
            Spacer()
            
            recordingButton
                .padding(.bottom, 30)
        }
        .padding(.horizontal, 32)
    }
    
    private var recordingButton: some View {
       Button(action: {
           withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
               toggleRecording()
           }
       }) {
           ZStack {
               // Outer shadow
               Circle()
                   .fill(Color.white)
                   .frame(width: 96)
                   .shadow(color: accentColor.opacity(0.2), radius: 20, x: 0, y: 8)

               // Main button background
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
               
               // Button icon
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
           
               // Pulsing animation when recording
               if isRecording {
                   PulsingRing(color: accentColor)
               }
           }
           .scaleEffect(isRecording ? 1.08 : 1.0)
           .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isRecording)
       }
   }
   
    private var postRecordingView: some View {
        FreeResponseAudioConfirmationView(
            audioURL: audioManager.getRecordedAudioFile() ?? URL(fileURLWithPath: ""),
            waveformData: generateRandomWaveform(count: 60),
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
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.8))
                .shadow(color: accentColor.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 24)
    }
    
    private var thankYouView: some View {
        VStack(spacing: 8) {
            Spacer()
            
            ZStack {
                // Success checkmark with beautiful glow effect
                Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 100)
                
                Circle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 85)
                    .shadow(color: accentColor.opacity(0.3), radius: 15, x: 0, y: 0)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(accentColor)
            }
            .padding(.bottom, 20)
            
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
            transcriptionManager.resetTranscription()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                dismiss()
            }
        }
    }
    
    // Helper functions
    private func toggleRecording() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isRecording.toggle()
        }
        
        if !isRecording {
            if liveTranscriptionEnabled {
                transcriptionManager.stopTranscription()
            }
            audioManager.stopRecording()
            stopTimer()
            isPostRecording = true
        } else {
            startRecordingWithTimer()
            if liveTranscriptionEnabled {
                transcriptionManager.startTranscription()
            }
        }
    }
    
    private func startRecordingWithTimer() {
        try? audioManager.prepareForNewRecording()
        audioManager.startRecording()
        timeRemaining = 60
        startTimer()
    }
    
    private func startTimer() {
        recordingTimer?.invalidate()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopTimer()
                if liveTranscriptionEnabled {
                    transcriptionManager.stopTranscription()
                }
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
                    prompt: formattedDate(),
                    isDailyLoop: true,
                    isFollowUp: false, isSuccess: false, isUnguided: true, isDream: false, isMorningJournal: false
                )
                
                // Here we don't need to modify addLoop, we just send the final transcript for analysis
                let transcriptForAnalysis = liveTranscriptionEnabled ? transcriptionManager.transcribedText : loop.1
                AnalysisManager.shared.performAnalysisForUnguidedEntry(transcript: transcriptForAnalysis)
            }
        }
    }
    
    private func retryRecording() {
        if retryAttempts > 0 {
            audioManager.cleanup()
            transcriptionManager.resetTranscription()
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
    
    func getGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
            case 0...11:
                return "Good Morning"
            case 12...16:
                return "Good Afternoon"
            case 17...23:
                return "Good Evening"
            default:
                return "Hey there"
        }
    }
}

// Beautiful animated gradient wave background
struct GradientWaveBackground: View {
    let primaryColor: Color
    let secondaryColor: Color
    let tertiaryColor: Color
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            Canvas { context, size in
                // Create a gradient background at the top that fades out
                let gradientRect = CGRect(origin: .zero, size: size)
                let backgroundGradient = Gradient(colors: [
                    primaryColor.opacity(0.05),
                    Color.white.opacity(0.2),
                    Color.white.opacity(0.6),
                    Color.white.opacity(0.9)
                ])
                
                context.fill(
                    Path(gradientRect),
                    with: .linearGradient(
                        backgroundGradient,
                        startPoint: CGPoint(x: size.width/2, y: 0),
                        endPoint: CGPoint(x: size.width/2, y: size.height * 0.8)
                    )
                )
                
                let timeOffset = timeline.date.timeIntervalSinceReferenceDate
                let phase = timeOffset.truncatingRemainder(dividingBy: 10) * 0.2
                
                // Create multiple wave layers with different colors and phases
                drawWaveLayer(in: context, size: size, phase: phase, amplitude: 0.02, frequency: 3, color: primaryColor, opacity: 0.2, yPosition: 0.2)
                drawWaveLayer(in: context, size: size, phase: phase * 0.7, amplitude: 0.015, frequency: 4, color: secondaryColor, opacity: 0.15, yPosition: 0.3)
                drawWaveLayer(in: context, size: size, phase: phase * 1.3, amplitude: 0.01, frequency: 5, color: tertiaryColor, opacity: 0.1, yPosition: 0.25)
                
                // Add some floating particles
                drawFloatingParticles(in: context, size: size, timeOffset: timeOffset)
            }
        }
    }
    
    private func drawWaveLayer(in context: GraphicsContext, size: CGSize, phase: Double, amplitude: Double, frequency: Double, color: Color, opacity: Double, yPosition: Double) {
        let width = size.width
        let height = size.height
        let steps = Int(width / 2)
        let dx = width / CGFloat(steps)
        
        var path = Path()
        path.move(to: CGPoint(x: 0, y: height))
        
        // Calculate the base y position (as a percentage of the height)
        let baseY = height * CGFloat(yPosition)
        
        // Generate the wave points
        for step in 0...steps {
            let x = CGFloat(step) * dx
            let relativeX = x / width * CGFloat(frequency)
            
            // Create a smooth wave with sine function
            let waveHeight = sin(relativeX * 2 * .pi + CGFloat(phase)) * CGFloat(amplitude) * height
            let y = baseY + waveHeight
            
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        // Close the path by adding lines to the bottom corners
        path.addLine(to: CGPoint(x: width, y: baseY))
        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()
        
        // Fill the wave with a gradient
        let gradient = Gradient(colors: [
            color.opacity(0.8),
            color.opacity(0.4),
            color.opacity(0.1)
        ])
        
        var contextCopy = context
        contextCopy.opacity = opacity
        contextCopy.fill(
            path,
            with: .linearGradient(
                gradient,
                startPoint: CGPoint(x: width/2, y: baseY),
                endPoint: CGPoint(x: width/2, y: baseY + height * 0.3)
            )
        )
    }
    
    private func drawFloatingParticles(in context: GraphicsContext, size: CGSize, timeOffset: TimeInterval) {
        // Create a set of "fixed" particle positions that move slowly over time
        let particleCount = 40
        let baseOffset = timeOffset * 0.05
        
        for i in 0..<particleCount {
            let seed = Double(i) * 0.1
            
            // Position calculation with some randomness
            let xPercent = (sin(seed * 7.5 + baseOffset * 0.3) + 1) / 2
            let yOffset = cos(seed * 3.2 + baseOffset * 0.2) * 0.2
            let yPercent = 0.1 + yOffset * 0.3 // Keep particles in the top 30% of the screen
            
            let x = size.width * CGFloat(xPercent)
            let y = size.height * CGFloat(yPercent)
            
            // Size calculation (smaller near the top)
            let sizeFactor = 0.2 + (yPercent * 0.8)
            let particleSize = CGFloat(2 + (sizeFactor * 2))
            
            // Opacity calculation (fade based on y position and time)
            let opacityBase = 0.2 + 0.3 * sin(seed * 5.4 + baseOffset)
            let opacity = max(0.05, min(0.3, opacityBase)) * Double(yPercent * 3)
            
            // Choose color based on index
            let particleColor: Color
            if i % 3 == 0 {
                particleColor = primaryColor
            } else if i % 3 == 1 {
                particleColor = secondaryColor
            } else {
                particleColor = Color.white
            }
            
            // Draw the particle
            let particleRect = CGRect(
                x: x - particleSize/2,
                y: y - particleSize/2,
                width: particleSize,
                height: particleSize
            )
            
            var particleContext = context
            particleContext.opacity = opacity
            particleContext.fill(
                Circle().path(in: particleRect),
                with: .color(particleColor)
            )
            
            // Add a subtle glow for some particles
            if i % 5 == 0 {
                let glowSize = particleSize * 2.5
                let glowRect = CGRect(
                    x: x - glowSize/2,
                    y: y - glowSize/2,
                    width: glowSize,
                    height: glowSize
                )
                
                var glowContext = context
                glowContext.opacity = opacity * 0.3
                glowContext.fill(
                    Circle().path(in: glowRect),
                    with: .color(particleColor)
                )
            }
        }
    }
}

//// Enhanced PulsingDot with smoother animation
//struct PulsingDot: View {
//    @State private var pulsing = false
//    
//    var body: some View {
//        Circle()
//            .fill(Color(hex: "A28497"))
//            .frame(width: 8, height: 8)
//            .scaleEffect(pulsing ? 1.2 : 0.8)
//            .opacity(pulsing ? 1.0 : 0.6)
//            .animation(
//                Animation.easeInOut(duration: 0.8)
//                    .repeatForever(autoreverses: true),
//                value: pulsing
//            )
//            .onAppear {
//                pulsing = true
//            }
//    }
//}
//
//// Enhanced PulsingRing with multiple layers
//struct PulsingRing: View {
//    var color: Color
//    @State private var isAnimating = false
//    
//    var body: some View {
//        ZStack {
//            // Multiple expanding rings with staggered animations
//            ForEach(0..<3) { index in
//                Circle()
//                    .stroke(color.opacity(0.2), lineWidth: 1.5)
//                    .scaleEffect(isAnimating ? 1.6 - (CGFloat(index) * 0.15) : 1)
//                    .opacity(isAnimating ? 0 : 0.6)
//                    .animation(
//                        Animation.easeInOut(duration: 1.8)
//                            .repeatForever(autoreverses: false)
//                            .delay(Double(index) * 0.3),
//                        value: isAnimating
//                    )
//            }
//        }
//        .frame(width: 88, height: 88)
//        .onAppear {
//            isAnimating = true
//        }
//    }
//}

struct FreeResponseAudioConfirmationView: View {
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
    @State private var showTranscript = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            HStack(spacing: 3) {
                ForEach(Array(waveformData.enumerated()), id: \.offset) { index, height in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(accentColor.opacity(0.8))
                        .frame(width: 2, height: isWaveformVisible ? height : 0)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.7)
                            .delay(Double(index) * 0.015),
                            value: isWaveformVisible
                        )
                }
            }
            .frame(height: 60)
            .padding(.horizontal, 32)
            .padding(.bottom, 12)

            Button(action: togglePlayback) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 65)
                        .shadow(color: accentColor.opacity(0.15), radius: 15, x: 0, y: 6)
                    
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 25))
                        .foregroundColor(accentColor)
                        .offset(x: isPlaying ? 0 : 2)
                }
            }
            
            Spacer()

            VStack(spacing: 12) {
                Button(action: onComplete) {
                    Text("Save Entry")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(accentColor)
                        )
                }
                
                if retryAttempts > 0 {
                    Button(action: {
                        cleanup()
                        onRetry()
                    }) {
                        Text("Try Again")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(accentColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
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
    
    private func cleanup() {
        audioPlayer?.stop()
        audioPlayer = nil
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
}

struct CleanTranscriptionView: View {
    let text: String
    let textColor = Color(hex: "2C3E50")
    let accentColor = Color(hex: "A28497")
    
    @State private var scrollViewProxy: ScrollViewProxy? = nil
    @State private var bottomID = UUID()
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    if !text.isEmpty {
                        // Process text into paragraphs with decreasing opacity
                        ForEach(splitTextIntoSections(), id: \.self) { section in
                            Text(section.text)
                                .font(.system(size: 24, weight: section.isRecent ? .semibold : .regular))
                                .foregroundColor(textColor.opacity(section.opacity))
                                .lineSpacing(8)
                                .padding(.vertical, 3)
                                .multilineTextAlignment(.leading)
                                .transition(.opacity)
                                .id(section.isLast ? bottomID : nil)
                        }
                    } else {
                        // Empty state
                        Text("Your words will appear here...")
                            .font(.system(size: 24, weight: .regular))
                            .foregroundColor(textColor.opacity(0.3))
                            .padding(.vertical, 16)
                            .id(bottomID)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .onChange(of: text) { _ in
                withAnimation {
                    proxy.scrollTo(bottomID, anchor: .bottom)
                }
            }
            .onAppear {
                scrollViewProxy = proxy
                proxy.scrollTo(bottomID, anchor: .bottom)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .frame(maxHeight: 220)
    }
    
    // Splits text into sections with decreasing opacity levels
    private func splitTextIntoSections() -> [TextSection] {
        guard !text.isEmpty else { return [] }
        
        let wordList = text.components(separatedBy: " ")
        
        // If the text is short, just return it as a single section
        if wordList.count <= 20 {
            return [TextSection(text: text, opacity: 1.0, isRecent: true, isLast: true)]
        }
        
        // Divide longer texts into sections with decreasing opacity
        var sections: [TextSection] = []
        let sectionSize = max(10, wordList.count / 4)
        
        for i in stride(from: 0, to: wordList.count, by: sectionSize) {
            let endIndex = min(i + sectionSize, wordList.count)
            let sectionWords = Array(wordList[i..<endIndex])
            let sectionText = sectionWords.joined(separator: " ")
            
            // Calculate opacity based on recency (newest text is most opaque)
            let sectionPosition = Double(i) / Double(wordList.count)
            let opacity = 0.4 + (0.6 * (1.0 - sectionPosition))
            
            // Determine if this is the most recent section
            let isRecent = (endIndex == wordList.count)
            let isLast = (endIndex == wordList.count)
            
            sections.append(TextSection(
                text: sectionText,
                opacity: opacity,
                isRecent: isRecent,
                isLast: isLast
            ))
        }
        
        return sections
    }
    
    // Model for text sections with variable opacity
    struct TextSection: Hashable {
        let text: String
        let opacity: Double
        let isRecent: Bool
        let isLast: Bool
    }
}

#Preview {
    RecordFreeResponseView()
}
