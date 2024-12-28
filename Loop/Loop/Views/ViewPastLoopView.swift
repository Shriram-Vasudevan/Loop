//
//  ViewPastLoopView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/14/24.
//

import SwiftUI
import AVKit
import CloudKit

struct ViewPastLoopView: View {
    let loop: Loop
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var progress: CGFloat = 0
    @State private var timer: Timer?
    @Environment(\.dismiss) var dismiss
    
    @State private var showInitialPrompt = true
    @State private var showTranscript = false
    @State private var contentOpacity: CGFloat = 0
    @State private var waveformData: [CGFloat] = Array(repeating: 0, count: 60)
    @State private var showBars = false
    let accentColor = Color(hex: "A28497")
    let textColor = Color(hex: "2C3E50")
    
    @State var isThroughRecordLoopsView: Bool
    var body: some View {
        NavigationStack {
            ZStack {
                if !isThroughRecordLoopsView {
                    Color(hex: "FAFBFC").ignoresSafeArea()
                }
                
                if showInitialPrompt {
                    initialPromptView
                } else {
                    mainContentView
                        .safeAreaPadding(.horizontal, 24)
                }
            }
            .navigationDestination(isPresented: $showTranscript) {
                TranscriptView(
                    prompt: loop.promptText, transcript: loop.transcript ?? "",
                    accentColor: accentColor,
                    isPresented: $showTranscript
                )
            }
            .onAppear {
                setupInitialAnimation()
                if let audioURL = loop.data.fileURL {
                    setupAudioPlayer(url: audioURL)
                }
            }
            .onDisappear {
                stopAudioPlayback()
            }
        }
    }
    
    private var initialPromptView: some View {
        Text(loop.promptText)
            .font(.system(size: 32, weight: .light))
            .multilineTextAlignment(.center)
            .foregroundColor(textColor)
            .padding(.horizontal, 32)
            .transition(.opacity.combined(with: .scale(scale: 1.05)))
    }
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            promptHeader
            
            Spacer()
            
            WaveformSection(
                waveformData: waveformData,
                progress: progress,
                showBars: showBars,
                accentColor: accentColor
            )
            
            Spacer()
            
            controlsSection
        }
        .safeAreaInset(edge: .leading) { Color.clear.frame(width: 0) }
        .safeAreaInset(edge: .trailing) { Color.clear.frame(width: 0) }
        .opacity(contentOpacity)
    }
    
    private var promptHeader: some View {
        VStack(spacing: 8) {
            if !isThroughRecordLoopsView {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(textColor.opacity(0.6))
                }
                .padding(.top, 20)
            }
            
            Text(loop.promptText)
                .font(.system(size: 24, weight: .light))
                .multilineTextAlignment(.center)
                .foregroundColor(textColor)
                .padding(.horizontal, 40)
                .padding(.top, 8)
            
            Text(formattedDate)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(textColor.opacity(0.6))
        }
      //  .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }
    
    private var waveformSection: some View {
        ZStack {
            NewFlowingBackground(baseColor: accentColor)
            
            HStack(spacing: 3) {
                ForEach(Array(waveformData.enumerated()), id: \.offset) { index, height in
                    WaveformBar(
                        index: index,
                        height: height,
                        totalBars: waveformData.count,
                        progress: progress,
                        showBars: showBars,
                        accentColor: accentColor
                    )
                }
            }
            .frame(height: 64)
           // .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        //.padding(.horizontal, 24)
    }
    
    private var controlsSection: some View {
        VStack(spacing: 24) {
            TimeSlider(progress: $progress,
                      duration: audioPlayer?.duration ?? 0,
                      accentColor: accentColor,
                      onEditingChanged: { editing in
                if !editing {
                    audioPlayer?.currentTime = (audioPlayer?.duration ?? 0) * Double(progress)
                }
            })
            
            HStack {
                Text(timeString(from: progress * (audioPlayer?.duration ?? 0)))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(textColor.opacity(0.6))
                
                Spacer()
                
                Button(action: {
                    if let audioURL = loop.data.fileURL {
                        toggleAudioPlayback(audioURL: audioURL)
                    }
                }) {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 64, height: 64)
                        .shadow(color: accentColor.opacity(0.3), radius: 10, y: 5)
                        .overlay(
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .offset(x: isPlaying ? 0 : 2)
                        )
                }
                
                Spacer()
                
                Text(timeString(from: audioPlayer?.duration ?? 0))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(textColor.opacity(0.6))
            }
            
            if !isThroughRecordLoopsView {
                // Add transcript button
                TranscriptButton(accentColor: accentColor, showTranscript: $showTranscript)
                    .padding(.top, 16)
            }
        }
        .padding(.bottom, 20)
    }

    private func setupInitialAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                showInitialPrompt = false
                contentOpacity = 1
                generateWaveFormData()
            }
        }
    }
    
    private func setupAudioPlayer(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
        } catch {
            print("Error setting up audio player: \(error)")
        }
    }
    
    private func startProgressTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            if let player = audioPlayer {
                progress = CGFloat(player.currentTime / player.duration)
                if player.currentTime >= player.duration {
                    stopAudioPlayback()
                }
            }
        }
    }
    
    private func toggleAudioPlayback(audioURL: URL) {
        if isPlaying {
            stopAudioPlayback()
        } else {
            playAudio(audioURL: audioURL)
        }
    }
    
    private func playAudio(audioURL: URL) {
        audioPlayer?.play()
        isPlaying = true
        startProgressTimer()
    }
    
    private func stopAudioPlayback() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        isPlaying = false
        timer?.invalidate()
        timer = nil
        progress = 0
    }
    
    private func generateWaveFormData() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            waveformData = (0..<60).map { _ in
                CGFloat.random(in: 12...64)
            }
            showBars = true
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval / 60)
        let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy"
        return dateFormatter.string(from: loop.timestamp)
    }
}

struct TimeSlider: View {
    @Binding var progress: CGFloat
    let duration: TimeInterval
    let accentColor: Color
    let onEditingChanged: (Bool) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.black.opacity(0.1))
                    .frame(height: 4)
                    .cornerRadius(2)
                
                Rectangle()
                    .fill(accentColor)
                    .frame(width: geometry.size.width * progress, height: 4)
                    .cornerRadius(2)
            }
            .overlay(
                Circle()
                    .fill(accentColor)
                    .frame(width: 12, height: 12)
                    .position(x: geometry.size.width * progress, y: 2)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                progress = max(0, min(1, value.location.x / geometry.size.width))
                            }
                            .onEnded { _ in
                                onEditingChanged(false)
                            }
                    )
            )
        }
        .frame(height: 20)
    }
}

struct NewFlowingBackground: View {
    let baseColor: Color
    @State private var phase: Double = 0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                context.addFilter(.blur(radius: 30))
                
                let curveCount = 6
                let complementaryColors = [
                    baseColor.opacity(0.1),
                    baseColor.adjustedHue(by: 30).opacity(0.1),
                    baseColor.adjustedHue(by: -30).opacity(0.1)
                ]
                
                let time = timeline.date.timeIntervalSinceReferenceDate
                for i in 0..<curveCount {
                    let animationOffset = Double(i) * .pi / 2 + time * 0.3
                    var path = Path()
                    let points = generateCurvePoints(size: size, offset: animationOffset)
                    
                    path.addLines(points)
                    path.closeSubpath()
                    
                    context.fill(
                        path,
                        with: .color(complementaryColors[i % complementaryColors.count])
                    )
                }
            }
        }
    }
    
    private func generateCurvePoints(size: CGSize, offset: Double) -> [CGPoint] {
        var points: [CGPoint] = []
        let step = size.width / 40
        
        points.append(CGPoint(x: 0, y: size.height))
        
        for x in stride(from: 0, through: size.width, by: step) {
            let normalizedX = x / size.width
            let firstWave = sin(normalizedX * 4 * .pi + offset)
            let secondWave = cos(normalizedX * 2 * .pi + offset * 1.5)
            let combinedWave = (firstWave + secondWave) * 0.5
            let y = size.height * 0.5 + combinedWave * size.height * 0.2
            points.append(CGPoint(x: x, y: y))
        }
        
        points.append(CGPoint(x: size.width, y: size.height))
        return points
    }
}

struct WaveformSection: View {
    let waveformData: [CGFloat]
    let progress: CGFloat
    let showBars: Bool
    let accentColor: Color
    
    var body: some View {
        ZStack {
            ArtisticBackground(baseColor: accentColor)
            
            HStack(spacing: 3) {
                ForEach(Array(waveformData.enumerated()), id: \.offset) { index, height in
                    WaveformBar(
                        index: index,
                        height: height,
                        totalBars: waveformData.count,
                        progress: progress,
                        showBars: showBars,
                        accentColor: Color.white
                    )
                }
            }
            .frame(height: 64)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
    }
}


struct WaveformBar: View {
    let index: Int
    let height: CGFloat
    let totalBars: Int
    let progress: CGFloat
    let showBars: Bool
    let accentColor: Color
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(accentColor.opacity(
                progress >= CGFloat(index) / CGFloat(totalBars) ? 0.9 : 0.4
            ))
            .frame(width: 3, height: showBars ? height : 0)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.7)
                .delay(Double(index) * 0.02),
                value: showBars
            )
    }
}

struct TranscriptButton: View {
    let accentColor: Color
    @Binding var showTranscript: Bool
    
    var body: some View {
        Button(action: {
            withAnimation {
                showTranscript = true
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text")
                    .font(.system(size: 16))
                Text("View Transcript")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(accentColor)
                    .shadow(color: accentColor.opacity(0.3), radius: 8, y: 4)
            )
        }
    }
}

struct TranscriptView: View {
    let prompt: String
    let transcript: String
    let accentColor: Color
    let textColor = Color(hex: "2C3E50")
    
    @Binding var isPresented: Bool
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "F8F9FA")
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                Image(systemName: "quote.opening")
                    .font(.system(size: 200))
                    .foregroundColor(Color(hex: "E9ECEF"))
                    .offset(x: 0, y: -150)
                    .opacity(0.6)
            }
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(textColor)
                    }
                    
                    Spacer()
                    
                    Text("TRANSCRIPT")
                        .font(.system(size: 14, weight: .semibold))
                        .tracking(2)
                        .foregroundColor(textColor.opacity(0.5))
                    
                    Spacer()
                    
                    // Empty view for symmetry
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18))
                        .opacity(0)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        // Prompt
                        Text(prompt)
                            .font(.system(size: 31, weight: .bold))
                            .foregroundColor(textColor)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 15)
                        
                        // Transcript
                        Text(transcript)
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(textColor.opacity(0.8))
                            .lineSpacing(8)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarBackButtonHidden()
    }
}


#Preview {
    ViewPastLoopView(loop: Loop(id: "vvevwevwe", data: CKAsset(fileURL: URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("sampleFile.dat")), timestamp: Calendar.current.date(from: DateComponents(year: 2024, month: 9, day: 27))!, promptText: "What's a goal you're working towards?", category: "", transcript: "The transcript button uses the same accent color as the rest of the UI, and the transcript view maintains the app's clean, minimalist aesthetic while providing good readability for the transcript text.", freeResponse: false, isVideo: false, isDailyLoop: false, isFollowUp: false), isThroughRecordLoopsView: false)
}
