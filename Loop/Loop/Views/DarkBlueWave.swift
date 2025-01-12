//
//  DarkBlueWave.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/11/25.
//

import SwiftUI

struct DarkBlueWaveView: View {
    private let waveColor = Color(hex: "1E3D59") // Deep blue
    
    var body: some View {
        ZStack {
            // Background waves with different opacities
            ForEach(0..<3) { index in
                StaticWave(frequency: Double(index + 1) * 0.5)
                    .fill(waveColor)
                    .opacity(0.3 - Double(index) * 0.1)
            }
            
            // Main wave
            StaticWave(frequency: 1.0)
                .fill(waveColor)
        }
        .frame(height: 200)
    }
}

struct StaticWave: Shape {
    var frequency: Double
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath()
        let width = rect.width
        let height = rect.height
        let midHeight = height / 2
        let amplitude: CGFloat = 30 // Wave height
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        var x: CGFloat = 0
        while x <= width {
            let relativeX = x / width
            let normalizedX = relativeX * .pi * 2 * frequency
            let y = midHeight + sin(normalizedX) * amplitude + amplitude // Adding amplitude pushes wave down
            path.addLine(to: CGPoint(x: x, y: y))
            x += 1
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.close()
        
        return Path(path.cgPath)
    }
}

#Preview {
    DarkBlueWaveView()
        .frame(maxWidth: .infinity)
        .background(Color.white)
}
