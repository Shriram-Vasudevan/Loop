//
//  TrendsLoadingView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/28/24.
//

import SwiftUI

struct TrendsLoadingView: View {
    private let accentColor = Color(hex: "A28497")
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 24) {
            EmptySineWave()
                .stroke(accentColor.opacity(0.1), lineWidth: 2)
                .frame(height: 200)
                .offset(x: isAnimating ? 20 : -20)
                .animation(
                    Animation.easeInOut(duration: 2)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            Text("Loading insights...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(accentColor)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct EmptySineWave: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height / 2
        let amplitude = height / 4
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        var x: CGFloat = 0
        while x <= width {
            let relativeX = x / width
            let y = midHeight + sin(relativeX * .pi * 2) * amplitude
            if x == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
            x += 1
        }
        
        return path
    }
}
