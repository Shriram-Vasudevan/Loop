//
//  AudioWaveform.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/23/24.
//

import SwiftUI

struct AudioWaveform: View {
    let color: Color
    @State private var waveformData: [CGFloat] = []
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<40, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(color.opacity(0.3))
                    .frame(width: 2, height: waveformData[safe: index] ?? 12)
            }
        }
        .frame(height: 32)
        .onAppear {
            waveformData = (0..<40).map { _ in
                CGFloat.random(in: 4...32)
            }
        }
    }
}

