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
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(loop.promptText)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal)
                
                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            }
            .padding(.top)
            
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
                // Play Button for audio loop
                if let audioURL = loop.data.fileURL {
                    VStack {
                        Button(action: {
                            toggleAudioPlayback(audioURL: audioURL)
                        }) {
                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .resizable()
                                .frame(width: 80, height: 80)
                                .foregroundColor(Color(hex: "A28497"))
                        }
                    }
                } else {
                    Text("Audio unavailable.")
                        .foregroundColor(.red)
                        .font(.headline)
                        .padding()
                }
            }
            
            Spacer()
        }
        .navigationTitle("Loop Details")
        .onDisappear {
            stopAudioPlayback()
        }
    }

    var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy"
        return dateFormatter.string(from: loop.timestamp)
    }
    
    private func toggleAudioPlayback(audioURL: URL) {
        if isPlaying {
            stopAudioPlayback()
        } else {
            playAudio(audioURL: audioURL)
        }
    }
    
    private func playAudio(audioURL: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("Error playing audio: \(error.localizedDescription)")
        }
    }
    
    private func stopAudioPlayback() {
        audioPlayer?.stop()
        isPlaying = false
    }
}

#Preview {
    let mockAudioLoop = Loop(
        loopID: "123",
        data: CKAsset(fileURL: Bundle.main.url(forResource: "sample_audio", withExtension: "mp3")!),
        timestamp: Date(),
        lastRetrieved: Date(),
        promptText: "What are you grateful for today?",
        mood: "Happy",
        freeResponse: false, isVideo: false
    )
    
    ViewPastLoopView(loop: mockAudioLoop)
}

