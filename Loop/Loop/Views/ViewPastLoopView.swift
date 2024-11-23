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
    @State private var contentOpacity: CGFloat = 0
    @State private var waveformData: [CGFloat] = Array(repeating: 0, count: 60)
    @State private var showBars = false
    @State var accentColor = Color(hex: "A28497")
    @State private var backgroundOpacity: Double = 0
    
    var body: some View {
        ZStack {
            AnimatedBackground()
                .opacity(backgroundOpacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.2)) {
                        backgroundOpacity = 1
                    }
                }
            
            if showInitialPrompt {
                initialPromptView
            } else {
                mainContentView
            }
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
    
    private var initialPromptView: some View {
        VStack(spacing: 20) {
            Text(loop.promptText)
                .font(.system(size: 32, weight: .light))
                .multilineTextAlignment(.center)
                .foregroundColor(Color(hex: "2C3E50"))
                .padding(.horizontal, 32)
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
            
            Text(formattedDate)
                .font(.system(size: 18, weight: .light))
                .foregroundColor(accentColor)
                .opacity(0.9)
        }
        .transition(.opacity.combined(with: .scale(scale: 1.05)))
    }
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            // Header
            topBar
                .padding(.bottom, 20)
            
            // Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    promptSection
                    
                    if !loop.isVideo {
                        audioPlayerSection
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .opacity(contentOpacity)
    }
    
    private var topBar: some View {
        HStack {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    dismiss()
                }
            }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(hex: "2C3E50").opacity(0.8))
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(.white.opacity(0.8))
                            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                    )
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
    
    private var promptSection: some View {
        VStack(spacing: 12) {
            Text(loop.promptText)
                .font(.system(size: 28, weight: .light))
                .multilineTextAlignment(.center)
                .foregroundColor(Color(hex: "2C3E50"))
                .shadow(color: .black.opacity(0.03), radius: 1, y: 1)
            
            Text(formattedDate)
                .font(.system(size: 17, weight: .light))
                .foregroundColor(accentColor.opacity(0.9))
        }
        .padding(.vertical, 20)
    }
    
    private var audioPlayerSection: some View {
        VStack(spacing: 36) {
            // Waveform visualization
            waveformView
                .padding(.horizontal, 8)
            
            // Play controls
            VStack(spacing: 24) {
                playButton
                
                if let duration = audioPlayer?.duration {
                    timeIndicator(duration: duration)
                }
            }
        }
    }
    
    private var waveformView: some View {
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
    }
    
    private var playButton: some View {
        Button(action: {
            if let audioURL = loop.data.fileURL {
                toggleAudioPlayback(audioURL: audioURL)
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text(isPlaying ? "pause" : "play")
                    .font(.system(size: 18, weight: .regular))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                accentColor,
                                accentColor.opacity(0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: accentColor.opacity(0.3), radius: 8, y: 4)
            )
        }
        .scaleEffect(isPlaying ? 0.98 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPlaying)
    }
    
    private func timeIndicator(duration: TimeInterval) -> some View {
        HStack(spacing: 4) {
            Text(timeString(from: progress * duration))
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(accentColor.opacity(0.9))
        }
        .padding(.vertical, 8)
    }
    
    private func setupInitialAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
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

#Preview {
    ViewPastLoopView(loop: Loop(id: "vvevwevwe", data: CKAsset(fileURL: URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("sampleFile.dat")), timestamp: Calendar.current.date(from: DateComponents(year: 2024, month: 9, day: 27))!, promptText: "What's a goal you're working towards?", freeResponse: false, isVideo: false, isDailyLoop: false))
}

private struct WaveformBar: View {
    let index: Int
    let height: CGFloat
    let totalBars: Int
    let progress: CGFloat
    let showBars: Bool
    let accentColor: Color
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(accentColor.opacity(
                progress >= CGFloat(index) / CGFloat(totalBars) ? 0.9 : 0.3
            ))
            .frame(width: 3, height: showBars ? height : 0)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.7)
                .delay(Double(index) * 0.02),
                value: showBars
            )
    }
}
