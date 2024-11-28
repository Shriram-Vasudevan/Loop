//
//  LoadingWaveform.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/22/24.
//

import SwiftUI

struct LoadingWaveform: View {
    let accentColor: Color
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            
            HStack(spacing: 4) {
                ForEach(0..<30) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(accentColor.opacity(0.3))
                        .frame(width: 3, height: calculateHeight(index: index, time: time))
                }
            }
            .frame(height: 70)
        }
    }
    
    private func calculateHeight(index: Int, time: Double) -> CGFloat {
        let baseHeight: CGFloat = 20
        let maxAmplitude: CGFloat = 20
        
        // Create multiple wave components with different frequencies and phases
        let wave1 = sin(time * 2 + Double(index) / 4) * maxAmplitude
        let wave2 = sin(time * 1.5 + Double(index) / 3) * (maxAmplitude * 0.5)
        let wave3 = sin(time * 3 + Double(index) / 2) * (maxAmplitude * 0.3)
        
        // Combine waves and ensure minimum height
        return baseHeight + wave1 + wave2 + wave3
    }
}

//#Preview {
//    LoadingWaveform()
//}
