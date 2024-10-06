//
//  LoopAudioConfirmationView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/6/24.
//

import SwiftUI

struct LoopAudioConfirmationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var playAnimation = false
    
    let audioWaveform: [CGFloat]
    
    let onComplete: () -> Void
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Your Recording")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
                .padding(.top, 16)
            
            // Waveform visualization
            HStack(spacing: 3) {
                ForEach(audioWaveform, id: \.self) { height in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 3, height: height * (playAnimation ? 1.0 : 0.6))
                        .animation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: playAnimation)
                }
            }
            .padding(.horizontal, 32)
            .onAppear {
                playAnimation = true
            }
            
            Spacer()
            
            // Retry button
            Button(action: {
                onRetry()
            }) {
                Text("Retry")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 150)
                    .background(Color.red)
                    .cornerRadius(12)
            }
            
            // Complete button
            Button(action: {
                onComplete()
            }) {
                Text("Complete")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 150)
                    .background(Color.black)
                    .cornerRadius(12)
            }
            .padding(.bottom, 30)
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
}
//
//#Preview {
//    LoopAudioConfirmationView()
//}
