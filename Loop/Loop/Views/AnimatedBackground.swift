//
//  AnimatedBackground.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/20/24.
//

import SwiftUI

struct AnimatedBackground: View {
    // Using TimelineView for smooth animations
    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            Canvas { context, size in
                let timeOffset = timeline.date.timeIntervalSinceReferenceDate
                
                // Draw three waves with different properties
                for i in 0..<3 {
                    let frequency = Double(i + 1) * 0.5
                    let amplitude = 100 - Double(i) * 20
                    let phase = timeOffset.remainder(dividingBy: 8) / 8 * .pi * 2
                    
                    var path = Path()
                    let width = size.width
                    let height = size.height
                    let midHeight = height / 2
                    
                    // Optimize point calculation by reducing sample points
                    let steps = Int(width / 4) // Reduce number of points
                    let dx = width / CGFloat(steps)
                    
                    path.move(to: CGPoint(x: 0, y: height))
                    path.addLine(to: CGPoint(x: 0, y: midHeight))
                    
                    for step in 0...steps {
                        let x = CGFloat(step) * dx
                        let relativeX = x / width
                        let y = sin(relativeX * .pi * frequency * 2 + phase) * amplitude + midHeight
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.closeSubpath()
                    
                    // Create gradient for each wave
                    let gradient = Gradient(colors: [
                        Color(hex: "94A7B7").opacity(0.03),
                        Color(hex: "94A7B7").opacity(0.06)
                    ])
                    
                    let gradientRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                    context.fill(
                        path,
                        with: .linearGradient(
                            gradient,
                            startPoint: CGPoint(x: size.width/2, y: 0),
                            endPoint: CGPoint(x: size.width/2, y: size.height)
                        )
                    )
                }
            }
            .background(Color(hex: "FAFBFC"))
        }
        .edgesIgnoringSafeArea(.all)
    }
}
