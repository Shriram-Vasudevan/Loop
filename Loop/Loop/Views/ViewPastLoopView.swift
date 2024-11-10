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
    
    @Environment(\.dismiss) var dismiss
    
    @State var waveformData: [CGFloat] = Array(repeating: 0, count: 40)
    @State private var showBars = false
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(loop.promptText)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text(formattedDate)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Spacer()
                    }
                }
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.black)

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
    
    func generateWaveFormData() {
        let numBars = waveformData.count
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            waveformData = (0..<numBars).map { _ in CGFloat.random(in: 12...64) }
            showBars = true
        }
    }
}

//#Preview {
//    let mockAudioLoop = Loop(
//        loopID: "123",
//        data: CKAsset(fileURL: Bundle.main.url(forResource: "sample_audio", withExtension: "mp3")!),
//        timestamp: Date(),
//        lastRetrieved: Date(),
//        promptText: "What are you grateful for today?",
//        mood: "Happy",
//        freeResponse: false, isVideo: false
//    )
//    
//    ViewPastLoopView(loop: mockAudioLoop)
//}

