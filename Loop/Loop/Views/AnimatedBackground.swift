//
//  AnimatedBackground.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/20/24.
//

import SwiftUI

struct AnimatedBackground: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Color(hex: "FAFBFC").edgesIgnoringSafeArea(.all)
            
            ForEach(0..<3) { index in
                WaveShape(frequency: Double(index + 1) * 0.5,
                         amplitude: 100 - Double(index) * 20,
                         phase: animate ? .pi * 2 : 0)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "94A7B7").opacity(0.03),
                                Color(hex: "94A7B7").opacity(0.06)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .offset(y: CGFloat(index) * 50)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                animate = true
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct WaveShape: Shape {
    let frequency: Double
    let amplitude: Double
    var phase: Double
    
    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height / 2
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let y = sin(relativeX * .pi * frequency * 2 + phase) * amplitude + midHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}
