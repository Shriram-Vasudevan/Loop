//
//  LoopInsightProgressView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/17/24.
//

import SwiftUI

struct PulsingDots: View {
    let accentColor: Color
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(accentColor)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// Progress indicator for incomplete loops
struct LoopProgress: View {
    let completedLoops: Int
    let isAnalyzing: Bool
    let accentColor: Color
    let textColor: Color
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress circles
            HStack(spacing: 20) {
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(accentColor.opacity(0.2), lineWidth: 2)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .fill(index < completedLoops ? accentColor : Color.clear)
                                .frame(width: 16, height: 16)
                        )
                }
            }
            
            // Status text
            Text(isAnalyzing ? "Analyzing your responses..." : "\(completedLoops)/3 loops completed")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
            
            if isAnalyzing {
                PulsingDots(accentColor: accentColor)
                    .padding(.top, 8)
            }
        }
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
