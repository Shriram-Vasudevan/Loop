//
//  PulsingView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/20/24.
//

import SwiftUI

struct PulsingDot: View {
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(Color.red.opacity(0.8))
            .frame(width: 8, height: 8)
            .scaleEffect(isAnimating ? 1.5 : 1)
            .opacity(isAnimating ? 0.5 : 1)
            .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

struct PulsingRing: View {
    let color: Color
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.6
    
    var body: some View {
        Circle()
            .stroke(color.opacity(opacity), lineWidth: 2)
            .frame(width: 100, height: 100)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                    scale = 1.3
                    opacity = 0
                }
            }
    }
}
