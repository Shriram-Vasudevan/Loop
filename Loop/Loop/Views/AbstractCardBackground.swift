//
//  AbstractCardBackground.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/30/24.
//

import SwiftUI

struct AbstractCardBackground: View {
    let accentColor: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let waveHeight = height * 0.15
                let numberOfWaves = 3
                
                path.move(to: CGPoint(x: 0, y: height))
                
                // Draw multiple waves
                for waveIndex in 0..<numberOfWaves {
                    let yOffset = height - (CGFloat(waveIndex) * (height * 0.2))
                    
                    // First curve
                    path.addCurve(
                        to: CGPoint(x: width * 0.33, y: yOffset - waveHeight),
                        control1: CGPoint(x: width * 0.1, y: yOffset),
                        control2: CGPoint(x: width * 0.2, y: yOffset - waveHeight)
                    )
                    
                    // Second curve
                    path.addCurve(
                        to: CGPoint(x: width * 0.66, y: yOffset + waveHeight),
                        control1: CGPoint(x: width * 0.46, y: yOffset - waveHeight),
                        control2: CGPoint(x: width * 0.53, y: yOffset + waveHeight)
                    )
                    
                    // Third curve
                    path.addCurve(
                        to: CGPoint(x: width, y: yOffset),
                        control1: CGPoint(x: width * 0.8, y: yOffset + waveHeight),
                        control2: CGPoint(x: width * 0.9, y: yOffset)
                    )
                }
                
                // Complete the path
                path.addLine(to: CGPoint(x: width, y: height))
                path.closeSubpath()
            }
            .fill(accentColor)
            .opacity(0.05)
        }
    }
}

//#Preview {
//    AbstractCardBackground()
//}
