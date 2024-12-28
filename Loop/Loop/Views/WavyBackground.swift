//
//  WavyBackground.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/6/24.
//

import SwiftUI

struct WavyBackground: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            Canvas { context, size in
                let timeOffset = timeline.date.timeIntervalSinceReferenceDate
                
                // Create gradient from white to a very light shade of A28497
                let backgroundGradient = Gradient(colors: [.white, Color(hex: "A28497").opacity(0.05)])
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .linearGradient(
                        backgroundGradient,
                        startPoint: CGPoint(x: size.width/2, y: 0),
                        endPoint: CGPoint(x: size.width/2, y: size.height)
                    )
                )
       
                let waveConfigs: [(amplitude: Double, frequency: Double, opacity: Double)] = [
                    (20, 1.5, 0.6),
                    (40, 1.2, 0.4),
                    (10, 2.0, 0.3)
                ]
                
                for (index, config) in waveConfigs.enumerated() {
                    let phase = timeOffset.remainder(dividingBy: 10) / 10 * .pi * 2
                    let phaseOffset = Double(index) * 20
                    
                    var path = Path()
                    let width = size.width
                    let height = size.height
                    let midHeight = height / 2
                    
                    let steps = Int(width / 4)
                    let dx = width / CGFloat(steps)
                    
                    path.move(to: CGPoint(x: 0, y: height))
                    path.addLine(to: CGPoint(x: 0, y: midHeight))
                    
                    for step in 0...steps {
                        let x = CGFloat(step) * dx
                        let relativeX = x / width
                        let y = sin(relativeX * .pi * config.frequency + phase + phaseOffset/30) * config.amplitude + midHeight
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.closeSubpath()

                    context.opacity = config.opacity
                    // Use progressively darker shades of A28497 for each wave
                    context.fill(
                        path,
                        with: .color(Color(hex: "A28497").opacity(0.8 - Double(index) * 0.2))
                    )
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
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

struct Particle: Identifiable {
    let id: Int
    var isActive = false

    var size: CGFloat {
        CGFloat.random(in: 4...8)
    }
    
    func xPosition(in size: CGSize) -> CGFloat {
        CGFloat.random(in: 0...size.width)
    }
    
    func yPosition(in size: CGSize) -> CGFloat {
        CGFloat.random(in: 0...size.height)
    }
}
#Preview {
    WavyBackground()
}
