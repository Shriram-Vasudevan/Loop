//
//  LoadingWaveform.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/22/24.
//

import SwiftUI

struct LoadingWaveform: View {
    let accentColor: Color
    @State private var phase: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<30) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(accentColor.opacity(0.3))
                    .frame(width: 3, height: 20 + sin(phase + Double(index) / 3) * 20)
            }
        }
        .frame(height: 70)
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

//#Preview {
//    LoadingWaveform()
//}
