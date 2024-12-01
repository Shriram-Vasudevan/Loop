//
//  ArtisticBackground.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/30/24.
//

import SwiftUI

struct ArtisticBackground: View {
    let baseColor: Color
    @State private var phase = 0.0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                
                // Create gradient backgrounds
                let gradient1 = Gradient(colors: [
                    baseColor.opacity(0.6),
                    baseColor.adjustedHue(by: 30).opacity(0.4)
                ])
                
                let gradient2 = Gradient(colors: [
                    baseColor.adjustedHue(by: -30).opacity(0.3),
                    baseColor.adjustedHue(by: 15).opacity(0.5)
                ])
                
                // Draw flowing curves
                for i in 0..<3 {
                    let animation = time * 0.5 + Double(i) * .pi / 3
                    
                    // Main flowing curve
                    var path1 = Path()
                    let points1 = generateCurvePoints(size: size, phase: animation, amplitude: 40)
                    path1.addLines(points1)
                    path1.closeSubpath()
                    
                    context.fill(
                        path1,
                        with: .linearGradient(
                            gradient1,
                            startPoint: CGPoint(x: 0, y: size.height / 2),
                            endPoint: CGPoint(x: size.width, y: size.height / 2 + 100)
                        )
                    )
                    
                    // Secondary interweaving curve
                    var path2 = Path()
                    let points2 = generateCurvePoints(size: size, phase: -animation * 1.5, amplitude: 30)
                    path2.addLines(points2)
                    path2.closeSubpath()
                    
                    context.fill(
                        path2,
                        with: .linearGradient(
                            gradient2,
                            startPoint: CGPoint(x: size.width, y: size.height / 2),
                            endPoint: CGPoint(x: 0, y: size.height / 2 - 100)
                        )
                    )
                }
                
//                // Add circular patterns
//                for i in 0..<5 {
//                    let circleSize = 100.0 + Double(i) * 20
//                    let xOffset = sin(time * 0.5 + Double(i)) * 30
//                    let yOffset = cos(time * 0.7 + Double(i)) * 20
//
//                    var circlePath = Path()
//                    circlePath.addEllipse(in: CGRect(
//                        x: size.width/2 - circleSize/2 + xOffset,
//                        y: size.height/2 - circleSize/2 + yOffset,
//                        width: circleSize,
//                        height: circleSize
//                    ))
//
//                    context.stroke(
//                        circlePath,
//                        with: .color(baseColor.opacity(0.1)),
//                        lineWidth: 1
//                    )
//                }
//
                // Add subtle noise texture
                context.addFilter(.blur(radius: 30))
            }
        }
    }
    
    private func generateCurvePoints(size: CGSize, phase: Double, amplitude: Double) -> [CGPoint] {
        var points: [CGPoint] = []
        let step = size.width / 40
        
        points.append(CGPoint(x: 0, y: size.height))
        
        for x in stride(from: 0, through: size.width, by: step) {
            let normalizedX = x / size.width
            let wave1 = sin(normalizedX * 4 * .pi + phase)
            let wave2 = cos(normalizedX * 2 * .pi + phase * 1.5)
            let wave3 = sin(normalizedX * 6 * .pi - phase * 0.5)
            
            let combinedWave = (wave1 + wave2 + wave3) * 0.33
            let y = size.height * 0.5 + combinedWave * amplitude
            
            points.append(CGPoint(x: x, y: y))
        }
        
        points.append(CGPoint(x: size.width, y: size.height))
        return points
    }
}
