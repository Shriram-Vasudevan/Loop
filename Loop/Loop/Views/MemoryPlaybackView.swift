//
//  MemoryPlaybackView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/28/24.
//

import Foundation
import SwiftUI
import AVFoundation

struct MemoryPlaybackView: View {
    let loop: Loop
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var progress: CGFloat = 0
    @State private var timer: Timer?
    @State private var waveformData: [CGFloat] = []
    @State private var showBars = false
    
    let accentColor = Color(hex: "A28497")
    let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 24) {
            // Prompt and date
            VStack(spacing: 8) {
                Text(loop.promptText)
                    .font(.system(size: 24, weight: .light))
                    .multilineTextAlignment(.center)
                    .foregroundColor(textColor)
                
                Text(formattedDate)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(textColor.opacity(0.6))
            }
            
            Spacer()
            
            // Waveform
            WaveformSection(
                waveformData: waveformData,
                progress: progress,
                showBars: showBars,
                accentColor: accentColor
            )
            
            Spacer()
            
            // Playback controls
            VStack(spacing: 24) {
                TimeSlider(progress: $progress,
                          duration: audioPlayer?.duration ?? 0,
                          accentColor: accentColor) { editing in
                    if !editing {
                        audioPlayer?.currentTime = (audioPlayer?.duration ?? 0) * Double(progress)
                    }
                }
                
                HStack {
                    Text(timeString(from: progress * (audioPlayer?.duration ?? 0)))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(textColor.opacity(0.6))
                    
                    Spacer()
                    
                    Button(action: togglePlayback) {
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
            }
        }
        .onAppear {
            setupAudio()
            generateWaveform()
        }
        .onDisappear {
            cleanup()
        }
    }
    
    private func setupAudio() {
        guard let url = loop.data.fileURL else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
        } catch {
            print("Error setting up audio player: \(error)")
        }
    }
    
    private func togglePlayback() {
        if isPlaying {
            stopPlayback()
        } else {
            startPlayback()
        }
    }
    
    private func startPlayback() {
        audioPlayer?.play()
        isPlaying = true
        startProgressTimer()
    }
    
    private func stopPlayback() {
        audioPlayer?.pause()
        isPlaying = false
        timer?.invalidate()
    }
    
    private func cleanup() {
        timer?.invalidate()
        timer = nil
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    private func startProgressTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            if let player = audioPlayer {
                progress = CGFloat(player.currentTime / player.duration)
                if progress >= 1.0 {
                    stopPlayback()
                    progress = 0
                }
            }
        }
    }
    
    private func generateWaveform() {
        waveformData = (0..<60).map { _ in CGFloat.random(in: 12...64) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
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
