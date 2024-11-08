//
//  LoopAudioConfirmationView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/6/24.
//

import SwiftUI
import AVKit

struct LoopAudioConfirmationView: View {
    let audioURL: URL
    let waveformData: [CGFloat]
    let onComplete: () -> Void
    let onRetry: () -> Void
    
    let accentColor = Color(hex: "A28497")
    let secondaryColor = Color(hex: "B7A284")
    let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 40) {
            Text("review your loop")
                .font(.system(size: 32, weight: .thin))
                .foregroundColor(textColor)
                .padding(.top, 24)
            
            VStack(spacing: 24) {
                WaveformView(waveformData: waveformData, color: accentColor.opacity(0.8))
                AudioPlayerControls(audioURL: audioURL, accentColor: accentColor)
            }
            .padding(.vertical, 20)
            
            VStack(spacing: 16) {
                Button(action: onComplete) {
                    Text("sounds good")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(accentColor)
                        )
                }
                
                Button(action: onRetry) {
                    Text("try again")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(accentColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(accentColor, lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
}

struct WaveformView: View {
    let waveformData: [CGFloat]
    let color: Color
    @State private var showBars = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(waveformData.enumerated()), id: \.offset) { index, height in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 3, height: showBars ? height : 0)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.7)
                        .delay(Double(index) * 0.02),
                        value: showBars
                    )
            }
        }
        .frame(height: 70)
        .onAppear {
            showBars = true
        }
    }
}

struct AudioPlayerControls: View {
    let audioURL: URL
    @State private var isPlaying = false
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 24) {
            Button(action: {
                isPlaying.toggle()
            }) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .overlay(
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 22))
                            .foregroundColor(accentColor)
                            .offset(x: isPlaying ? 0 : 2)
                    )
            }
        }
    }
}

