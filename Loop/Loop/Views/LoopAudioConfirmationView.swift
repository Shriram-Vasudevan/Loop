//
//  LoopAudioConfirmationView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/6/24.
//

import SwiftUI
import AVKit

import SwiftUI
import AVKit

struct LoopAudioConfirmationView: View {
    @State private var isPlaying = false
    @State private var progress: CGFloat = 0
    @State private var audioPlayer: AVAudioPlayer?
    @State private var timer: Timer?
    
    let audioURL: URL
    let waveformData: [CGFloat]
    let accentColor = Color(hex: "A28497")
    
    let onComplete: () -> Void
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Review Your Recording")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Color(hex: "333333"))
            
            waveformView
                .frame(height: 60)
                .padding(.horizontal)
            
            playbackControls
            
            retryAndCompleteButtons
        }
        .padding()
        .background(Color.white)
        .onAppear(perform: setupAudioPlayer)
        .onDisappear {
            stopPlayback()
            timer?.invalidate()
        }
    }
    
    private var waveformView: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                waveformShape(for: geometry.size, progress: 1.0)
                    .fill(Color(hex: "DDDDDD"))
                
                waveformShape(for: geometry.size, progress: progress)
                    .fill(accentColor)
            }
        }
    }
    
    private func waveformShape(for size: CGSize, progress: CGFloat) -> Path {
        Path { path in
            let width = size.width
            let height = size.height
            let midY = height / 2
            let sampleCount = waveformData.count
            let step = width / CGFloat(sampleCount)
            
            for i in 0..<sampleCount {
                let x = CGFloat(i) * step
                if x > width * progress { break }
                
                let normalizedAmplitude = CGFloat(waveformData[i])
                let y1 = midY - (normalizedAmplitude * height / 2)
                let y2 = midY + (normalizedAmplitude * height / 2)
                
                path.move(to: CGPoint(x: x, y: y1))
                path.addLine(to: CGPoint(x: x, y: y2))
            }
        }
    }
    
    private var playbackControls: some View {
        HStack(spacing: 20) {
            Button(action: togglePlayback) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 44, height: 44)
                    .foregroundColor(accentColor)
            }
            
            Text(formattedProgress)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "333333"))
        }
    }
    
    private var retryAndCompleteButtons: some View {
        HStack(spacing: 20) {
            Button(action: onRetry) {
                Text("Retry")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 120, height: 44)
                    .background(Color.red)
                    .cornerRadius(8)
            }
            
            Button(action: onComplete) {
                Text("Complete")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 120, height: 44)
                    .background(accentColor)
                    .cornerRadius(8)
            }
        }
    }
    
    private var formattedProgress: String {
        let duration = audioPlayer?.duration ?? 0
        let currentTime = duration * Double(progress)
        return String(format: "%.2f / %.2f", currentTime, duration)
    }
    
    private func setupAudioPlayer() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.prepareToPlay()
        } catch {
            print("Error setting up audio player: \(error.localizedDescription)")
        }
    }
    
    private func togglePlayback() {
        if isPlaying {
            audioPlayer?.pause()
            timer?.invalidate()
        } else {
            audioPlayer?.play()
            startUpdatingProgress()
        }
        isPlaying.toggle()
    }
    
    private func stopPlayback() {
        audioPlayer?.stop()
        isPlaying = false
        progress = 0
    }
    
    private func startUpdatingProgress() {
        guard let player = audioPlayer else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if player.isPlaying {
                self.progress = CGFloat(player.currentTime / player.duration)
            } else {
                timer.invalidate()
                self.isPlaying = false
            }
        }
    }
}
