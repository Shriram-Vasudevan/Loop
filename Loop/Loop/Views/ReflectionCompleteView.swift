//
//  ReflectionCompleteView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/16/25.
//

import SwiftUI

import SwiftUI

struct ReflectionCompletedView: View {
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 24) {
            VStack (spacing: 8) {
                Text("REFLECTION COMPLETE")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.5))
                
                Text("you can edit it later")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(textColor.opacity(0.7))
                
            }
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(accentColor)
                    )
                
                DiamondPattern()
                    .stroke(accentColor.opacity(0.2), lineWidth: 1)
                    .frame(width: 120, height: 30)
            }
            
            Spacer()
        }

    }
}

struct DiamondPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let diamondWidth = rect.width / 5
        let diamondHeight = rect.height
        
        // Create a row of connected diamonds
        for i in 0..<5 {
            let centerX = CGFloat(i) * diamondWidth + diamondWidth/2
            let centerY = rect.height/2
            
            // Draw diamond
            path.move(to: CGPoint(x: centerX, y: centerY - diamondHeight/2))
            path.addLine(to: CGPoint(x: centerX + diamondWidth/2, y: centerY))
            path.addLine(to: CGPoint(x: centerX, y: centerY + diamondHeight/2))
            path.addLine(to: CGPoint(x: centerX - diamondWidth/2, y: centerY))
            path.closeSubpath()
            
            // Add connecting lines between diamonds
            if i < 4 {
                path.move(to: CGPoint(x: centerX + diamondWidth/2, y: centerY))
                path.addLine(to: CGPoint(x: centerX + diamondWidth, y: centerY))
            }
        }
        
        return path
    }
}

#Preview {
    ZStack {
        Color.white
        ReflectionCompletedView()
            .padding()
    }
}
