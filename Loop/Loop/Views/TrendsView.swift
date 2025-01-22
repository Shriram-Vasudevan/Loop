//
//  TrendsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/28/24.
//



import SwiftUI

import SwiftUI

struct MoodTrendsSection: View {
    let sadColor = Color(hex: "1E3D59")
    let neutralColor = Color(hex: "94A7B7")
    let happyColor = Color(hex: "B784A7")
    let textColor = Color(hex: "2C3E50")
    
    // Mock data for preview
    let averageMood: Double = 7.8
    let moodLabel: String = "optimistic"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            // Title area
            VStack(alignment: .leading, spacing: 8) {
                Text("YOUR HEADSPACE")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.5))
                
                Text("Weekly Overview")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(textColor)
            }
            
            // Main mood visualization
            HStack(alignment: .bottom, spacing: 24) {
                // Large mood indicator
                VStack(alignment: .leading, spacing: 12) {
                    Text(moodLabel)
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(getMoodColor())
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", averageMood))
                            .font(.system(size: 48, weight: .light))
                        Text("/ 10")
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(textColor.opacity(0.5))
                    }
                }
                
                Spacer()
                
                // Vertical mood scale with current position
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        // Scale lines
                        ForEach((1...10).reversed(), id: \.self) { value in
                            HStack(spacing: 8) {
                                // Scale line
                                Rectangle()
                                    .fill(getScaleColor(for: Double(value)))
                                    .frame(width: value == Int(averageMood.rounded()) ? 24 : 16, height: 2)
                                
                                // Value label for every other number
                                if value % 2 == 0 {
                                    Text("\(value)")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(textColor.opacity(0.5))
                                }
                            }
                            .frame(height: geometry.size.height / 10)
                        }
                    }
                }
                .frame(width: 60)
            }
            .padding(24)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.white)
                    
                    // Decorative pattern
                    MoodPattern(currentMood: averageMood)
                        .fill(getMoodColor().opacity(0.05))
                }
            )
            
            // Additional mood insights
            HStack(spacing: 16) {
                MoodInsightTile(
                    title: "BEST TIME",
                    value: "8 PM",
                    description: "avg. rating"
                )
                
                MoodInsightTile(
                    title: "SLEEP IMPACT",
                    value: "+24%",
                    description: "mood increase"
                )
            }
        }
        .padding(24)
    }
    
    private func getMoodColor() -> Color {
        if averageMood <= 4 {
            return sadColor
        } else if averageMood <= 7 {
            return neutralColor
        } else {
            return happyColor
        }
    }
    
    private func getScaleColor(for value: Double) -> Color {
        if value <= 4 {
            return sadColor.opacity(value == averageMood.rounded() ? 1 : 0.3)
        } else if value <= 7 {
            return neutralColor.opacity(value == averageMood.rounded() ? 1 : 0.3)
        } else {
            return happyColor.opacity(value == averageMood.rounded() ? 1 : 0.3)
        }
    }
}

struct MoodPattern: Shape {
    let currentMood: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        // Create a pattern that changes based on mood
        // Higher mood = more upward waves, lower mood = more downward waves
        let waveHeight = height * 0.1
        let frequency = currentMood > 5 ? 6 : 4
        
        path.move(to: CGPoint(x: 0, y: height))
        
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = CGFloat(x) / width
            let angle = relativeX * .pi * CGFloat(frequency)
            let multiplier: CGFloat = currentMood > 5 ? 1 : -1
            let y = height - (sin(angle) * waveHeight * multiplier)
            
            if x == 0 {
                path.move(to: CGPoint(x: CGFloat(x), y: y))
            } else {
                path.addLine(to: CGPoint(x: CGFloat(x), y: y))
            }
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

struct MoodInsightTile: View {
    let title: String
    let value: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .tracking(1.5)
                .foregroundColor(Color(hex: "2C3E50").opacity(0.5))
            
            Text(value)
                .font(.system(size: 24, weight: .light))
                .foregroundColor(Color(hex: "2C3E50"))
            
            Text(description)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "2C3E50").opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
        )
    }
}

// Preview
struct MoodTrendsSection_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(hex: "F5F5F5").ignoresSafeArea()
            
            MoodTrendsSection()
        }
    }
}
