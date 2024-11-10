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
    
    
    @State var waveformData: [CGFloat] = Array(repeating: 0, count: 60)
    @State private var showBars = false
    
    var body: some View {
        ZStack {
            ParticleBackground()
            
            VStack(spacing: 20) {
                ZStack {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.black)

                        }
                        
                        Spacer()
                    }
                    
                    VStack(alignment: .center, spacing: 8) {
                        Text(loop.promptText)
                            .font(.system(size: 28, weight: .light))
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color(hex: "2C3E50"))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 32)
                        
                        Text(formattedDate)
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(Color(hex: "A28497"))
                    }
                }
                .padding([.top, .horizontal])
                
                
                Spacer()
                
                if loop.isVideo {
                    if let videoURL = loop.data.fileURL {
                        VideoPlayer(player: AVPlayer(url: videoURL))
                            .frame(height: 300)
                            .cornerRadius(16)
                            .padding(.horizontal)
                    } else {
                        Text("Video unavailable.")
                            .foregroundColor(.red)
                            .font(.headline)
                            .padding()
                    }
                } else {
                    if let audioURL = loop.data.fileURL {
                        VStack {
                            HStack(spacing: 4) {
                                ForEach(Array(waveformData.enumerated()), id: \.offset) { index, height in
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color(hex: "A28497"))
                                        .frame(width: 2, height: showBars ? height : 0)
                                        .animation(
                                            .spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.02),
                                            value: showBars
                                        )
                                }
                            }
                            .onAppear {
                                generateWaveFormData()
                            }
                            .padding(.bottom)
                            
                            VStack(spacing: 20) {
                                Button(action: {
                                    toggleAudioPlayback(audioURL: audioURL)
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
                        }
                    } else {
                        Text("Audio unavailable.")
                            .foregroundColor(.red)
                            .font(.headline)
                            .padding()
                    }
                }
            }
            .padding(.bottom, 60)
            .navigationTitle("Loop Details")
            .onDisappear {
                stopAudioPlayback()
            }
        }
    }

    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval / 60)
        let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func setupAudioPlayer(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
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
    
    func generateWaveFormData() {
        let numBars = waveformData.count
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            waveformData = (0..<numBars).map { _ in CGFloat.random(in: 12...64) }
            showBars = true
        }
    }
    
    var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy"
        return dateFormatter.string(from: loop.timestamp)
    }
}
