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
    
    // Animation states
    @State private var showInitialPrompt = true
    @State private var contentOpacity: CGFloat = 0
    
    // Waveform states
    @State private var waveformData: [CGFloat] = Array(repeating: 0, count: 60)
    @State private var showBars = false
    
    var body: some View {
        ZStack {
            Color(hex: "FAFBFC").ignoresSafeArea()
            
            if showInitialPrompt {
                // Initial centered prompt
                VStack(spacing: 16) {
                    Text(loop.promptText)
                        .font(.system(size: 28, weight: .light))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(hex: "2C3E50"))
                        .padding(.horizontal, 32)
                    
                    Text(formattedDate)
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(Color(hex: "A28497"))
                }
                .transition(.opacity)
            } else {
                VStack(spacing: 40) {
                    ZStack {
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 17))
                                    .foregroundColor(.black)
                            }
                            Spacer()
                        }
                        
                        VStack(spacing: 8) {
                            Text(loop.promptText)
                                .font(.system(size: 17, weight: .regular))
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color(hex: "2C3E50"))
                            
                            Text(formattedDate)
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(Color(hex: "A28497"))
                        }
                        .padding(.horizontal, 32)
                    }
                    .padding()
                    
                    Spacer()
                    
                    if !loop.isVideo {
                        VStack(spacing: 40) {
                            // Waveform
                            HStack(spacing: 4) {
                                ForEach(Array(waveformData.enumerated()), id: \.offset) { index, height in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color(hex: "A28497"))
                                        .frame(width: 2, height: showBars ? height : 0)
                                        .animation(
                                            .spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.02),
                                            value: showBars
                                        )
                                }
                            }
                            .frame(height: 64)
                            .padding(.horizontal)
                            
                            // Play button
                            Button(action: {
                                if let audioURL = loop.data.fileURL {
                                    toggleAudioPlayback(audioURL: audioURL)
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 64, height: 64)
                                        .shadow(color: Color(hex: "A28497").opacity(0.2), radius: 10)
                                    
                                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 22, weight: .regular))
                                        .foregroundColor(Color(hex: "A28497"))
                                        .offset(x: isPlaying ? 0 : 2)
                                }
                            }
                            
                            if let duration = audioPlayer?.duration {
                                Text(timeString(from: progress * duration))
                                    .font(.system(size: 14, weight: .light))
                                    .foregroundColor(Color(hex: "A28497"))
                            }
                        }
                        .padding(.bottom, 60)
                    }
                }
                .opacity(contentOpacity)
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
