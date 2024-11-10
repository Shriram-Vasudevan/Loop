//
//  FluidParticleBackground.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/9/24.
//

import SwiftUI
import AVKit
import CloudKit

struct FloatingParticle: View {
    let initialPosition: CGPoint
    let size: CGFloat
    
    @State private var offset: CGPoint = .zero
    @State private var opacity: Double = 0
    
    var body: some View {
        Circle()
            .fill(Color(hex: "A28497"))
            .frame(width: size, height: size)
            .opacity(opacity)
            .offset(x: initialPosition.x + offset.x, y: initialPosition.y + offset.y)
            .onAppear {
                let randomDuration = Double.random(in: 8...12)
                let randomDelay = Double.random(in: 0...4)
                
                withAnimation(
                    Animation
                        .easeInOut(duration: randomDuration)
                        .repeatForever(autoreverses: true)
                        .delay(randomDelay)
                ) {
                    offset = CGPoint(
                        x: CGFloat.random(in: -20...20),
                        y: CGFloat.random(in: -20...20)
                    )
                    opacity = Double.random(in: 0.03...0.08)
                }
            }
    }
}

struct ParticleBackground: View {
    let particleCount = 20
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<particleCount, id: \.self) { index in
                    FloatingParticle(
                        initialPosition: CGPoint(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        ),
                        size: CGFloat.random(in: 4...12)
                    )
                }
            }
        }
    }
}
