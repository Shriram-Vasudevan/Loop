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

    @State private var player: AVPlayer?
    @State private var isPlaying = false

    let onComplete: () -> Void
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Review Your Recording")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Color(hex: "333333"))

            videoPlayerView
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(accentColor, lineWidth: 2)
                )
                .padding(.horizontal, 16)

            playbackControls

            retryAndCompleteButtons
        }
        .padding()
        .background(Color.white)
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

    private var playbackControls: some View {
        HStack(spacing: 20) {
            Button(action: togglePlayback) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 44, height: 44)
                    .foregroundColor(accentColor)
            }
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

    private func setupPlayer() {
        player = AVPlayer(url: videoURL)
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

