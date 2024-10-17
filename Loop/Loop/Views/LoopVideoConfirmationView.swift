//
//  LoopVideoConfirmationView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/6/24.
//

import SwiftUI
import AVKit

struct LoopVideoConfirmationView: View {
    let videoURL: URL
    let accentColor = Color(hex: "A28497")
    let backgroundColor = Color(hex: "F5F5F5")
    
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var progress: Float = 0
    @State private var duration: Float = 0
    
    let onComplete: () -> Void
    let onRetry: () -> Void
    
    var body: some View {
        ZStack {
            backgroundColor.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                Text("Review Your Recording")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(Color(hex: "333333"))
                
                videoPlayerView
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(accentColor, lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                progressBar
                
                playbackControls
                
                retryAndCompleteButtons
            }
            .padding()
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
    
    private var videoPlayerView: some View {
        VideoPlayer(player: player)
            .onAppear {
                player?.play()
                isPlaying = true
            }
    }
    
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color(hex: "DDDDDD"))
                    .frame(height: 4)
                
                Rectangle()
                    .fill(accentColor)
                    .frame(width: geometry.size.width * CGFloat(progress), height: 4)
            }
        }
        .frame(height: 4)
        .cornerRadius(2)
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
        let currentTime = duration * progress
        return String(format: "%.2f / %.2f", currentTime, duration)
    }
    
    private func setupPlayer() {
        player = AVPlayer(url: videoURL)
        
        player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main) { time in
            guard let duration = player?.currentItem?.duration.seconds, duration > 0 else { return }
            self.duration = Float(duration)
            self.progress = Float(time.seconds / duration)
        }
    }
    
    private func togglePlayback() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
    }
}
