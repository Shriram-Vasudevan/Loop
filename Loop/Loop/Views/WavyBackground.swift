//
//  WavyBackground.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/6/24.
//

import SwiftUI

struct WavyBackground: View {
    @State private var waveOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.white, Color(white: 0.98)]),
                               startPoint: .top,
                               endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)

                OptimizedWaveLayer(phase: waveOffset, amplitude: 20, frequency: 1.5, color: Color(white: 0.9).opacity(0.6), size: geometry.size)
                OptimizedWaveLayer(phase: waveOffset + 20, amplitude: 40, frequency: 1.2, color: Color(white: 0.85).opacity(0.4), size: geometry.size)
                OptimizedWaveLayer(phase: waveOffset + 60, amplitude: 10, frequency: 2.0, color: Color(white: 0.8).opacity(0.3), size: geometry.size)
            }
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                    waveOffset = 30
                }
            }
            .drawingGroup()
            
        }
    }
}

struct OptimizedWaveLayer: View {
    let phase: CGFloat
    let amplitude: CGFloat
    let frequency: CGFloat
    let color: Color
    let size: CGSize

    var body: some View {
        Path { path in
            let midHeight = size.height * 0.5
            let width = size.width

            let stepSize: CGFloat = 5.0
            path.move(to: CGPoint(x: 0, y: midHeight))

            for x in stride(from: 0, to: width, by: stepSize) {
                let relativeX = x / width
                let y = midHeight + amplitude * sin(relativeX * frequency * 2 * .pi + phase)
                path.addLine(to: CGPoint(x: x, y: y))
            }

            path.addLine(to: CGPoint(x: width, y: size.height))
            path.addLine(to: CGPoint(x: 0, y: size.height))
            path.closeSubpath()
        }
        .fill(color)
        .offset(y: phase)
    }
}




// A simple Identifiable particle model
struct Particle: Identifiable {
    let id: Int
    var isActive = false
    
    // Generate random size for the particle
    var size: CGFloat {
        CGFloat.random(in: 4...8)
    }
    
    // Randomize x position within the screen
    func xPosition(in size: CGSize) -> CGFloat {
        CGFloat.random(in: 0...size.width)
    }
    
    // Randomize y position within the screen
    func yPosition(in size: CGSize) -> CGFloat {
        CGFloat.random(in: 0...size.height)
    }
}
#Preview {
    WavyBackground()
}
