//
//  LoopLogoView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/10/24.
//
import SwiftUI

struct LoopLogoView: View {
    let accentColor = Color(hex: "A28497")
    let size: CGFloat = 100 // Adjust size as needed
    @State private var drawingStroke: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Background color for preview
            Color(hex: "FAFBFC")
                .ignoresSafeArea()
            
            // Logo container
            VStack {
                ZStack {
                    // Background rounded rectangle
                    RoundedRectangle(cornerRadius: size * 0.24)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    accentColor,
                                    accentColor.opacity(0.85)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: size, height: size)
                        .shadow(color: accentColor.opacity(0.15), radius: 12)
                    
                    // Main loop spiral
                    Circle()
                        .trim(from: 0.1, to: 0.8)
                        .stroke(
                            Color.white.opacity(0.95),
                            style: StrokeStyle(
                                lineWidth: size * 0.055,
                                lineCap: .round
                            )
                        )
                        .frame(width: size * 0.55)
                        .rotationEffect(.degrees(45))
                    
                    // Inner loop spiral
                    Circle()
                        .trim(from: 0.15, to: 0.75)
                        .stroke(
                            Color.white.opacity(0.7),
                            style: StrokeStyle(
                                lineWidth: size * 0.035,
                                lineCap: .round
                            )
                        )
                        .frame(width: size * 0.35)
                        .rotationEffect(.degrees(45))
                    
                    // Accent dots
                    ForEach([0.8, 0.1], id: \.self) { position in
                        Circle()
                            .fill(Color.white.opacity(position == 0.8 ? 0.95 : 0.7))
                            .frame(width: position == 0.8 ? size * 0.08 : size * 0.06)
                            .offset(
                                x: position == 0.8 ? size * 0.2 : -size * 0.12,
                                y: position == 0.8 ? size * 0.2 : -size * 0.12
                            )
                    }
                }
            }
        }
    }
}

// Helper shape for more complex paths if needed
struct FlowingPath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Create flowing spiral path
        let centerX = rect.midX
        let centerY = rect.midY
        let startRadius: CGFloat = rect.width * 0.2
        let endRadius: CGFloat = rect.width * 0.4
        
        // Use CGFloat versions of π and trig functions
        let π = CGFloat.pi
        let startAngle: CGFloat = 0
        let endAngle: CGFloat = π * 1.5
        
        let point = CGPoint(
            x: centerX + startRadius * CGFloat(cos(startAngle)),
            y: centerY + startRadius * CGFloat(sin(startAngle))
        )
        path.move(to: point)
        
        stride(from: startAngle, to: endAngle, by: 0.1).forEach { angle in
            let radius = startRadius + (endRadius - startRadius) * (angle / endAngle)
            let x = centerX + radius * CGFloat(cos(angle))
            let y = centerY + radius * CGFloat(sin(angle))
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        return path
    }
}


#Preview {
    LoopLogoView()
}
