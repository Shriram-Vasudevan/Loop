//
//  TodaysReflectionPlanView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/16/25.
//

import SwiftUI

struct TodaysReflectionPlanView: View {
    @StateObject private var reflectionManager = ReflectionCardManager.shared
    @State private var showingEditView = false
    
    private let accentColor = Color(hex: "A28497")    // Main mauve accent
    private let textColor = Color(hex: "2C3E50")
    private let lightMauve = Color(hex: "D5C5CC")     // Lighter variant
    private let midMauve = Color(hex: "BBA4AD")       // Medium variant
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text("TODAY'S REFLECTION")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.5))
                
                Spacer()
                
                Button(action: {
                    showingEditView = true
                }) {
                    Text("EDIT")
                        .font(.system(size: 13, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(accentColor)
                }
            }
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(reflectionManager.getOrderedCards(), id: \.self) { card in
                        ReflectionCard(card: card)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .fullScreenCover(isPresented: $showingEditView) {
            EditPlanView()
        }
    }
}

struct ReflectionCard: View {
    let card: ReflectionCardManager.ReflectionCardType
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    private let lightMauve = Color(hex: "D5C5CC")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Content Section
            VStack(alignment: .center, spacing: 6) {
                Text(card.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(textColor)
                
                Text(card.shortDescription)
                    .font(.system(size: 13))
                    .foregroundColor(textColor.opacity(0.6))
                    .lineLimit(1)
            }
        }
        .frame(width: 140, height: 100)
        .padding(16)
        .background(
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        lightMauve.opacity(0.3),
                        Color.white.opacity(0.9)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Geometric pattern
                cardPattern
                    .opacity(0.2)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor.opacity(0.1), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var cardPattern: some View {
        switch card {
        case .sleepCheckin:
            GeometricMountains()
                .fill(accentColor)
                .frame(height: 60)
                .offset(y: 40)
        case .moodCheckin:
            GeometricMountains()
                .fill(accentColor)
                .frame(height: 60)
                .offset(y: 40)
        case .daySummary:
            WavyPattern()
                .fill(accentColor)
                .frame(height: 40)
                .offset(y: 50)
        case .standOut:
            StarPattern()
                .fill(accentColor)
                .frame(height: 40)
                .offset(y: 50)
        case .aiGenerated:
            SparklePattern()
                .fill(accentColor)
                .frame(height: 40)
                .offset(y: 50)
        case .freeform:
            PencilPattern()
                .fill(accentColor)
                .frame(height: 40)
                .offset(y: 50)
        }
    }
}

// Geometric Patterns
struct WavyPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: 0, y: height * 0.5))
        
        // Create a gentle wave pattern
        for x in stride(from: 0, to: width, by: width/4) {
            path.addCurve(
                to: CGPoint(x: x + width/4, y: height * 0.5),
                control1: CGPoint(x: x + width/8, y: height * 0.3),
                control2: CGPoint(x: x + width/8, y: height * 0.7)
            )
        }
        
        return path
    }
}

struct StarPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let centerX = rect.width * 0.7
        let centerY = rect.height * 0.7
        let size: CGFloat = 20
        
        // Create a simple star
        let points = 5
        let angleStep = Double.pi * 2 / Double(points)
        
        for i in 0..<points {
            let angle = Double(i) * angleStep - Double.pi / 2
            let point = CGPoint(
                x: centerX + CGFloat(Foundation.cos(angle)) * size,
                y: centerY + CGFloat(Foundation.sin(angle)) * size
            )
            
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        
        path.closeSubpath()
        return path
    }
}

struct SparklePattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Create a sparkle pattern
        let sparkleSize: CGFloat = 15
        let points = [(rect.width * 0.7, rect.height * 0.5),
                     (rect.width * 0.8, rect.height * 0.3),
                     (rect.width * 0.6, rect.height * 0.7)]
        
        for point in points {
            path.move(to: CGPoint(x: point.0 - sparkleSize/2, y: point.1))
            path.addLine(to: CGPoint(x: point.0 + sparkleSize/2, y: point.1))
            path.move(to: CGPoint(x: point.0, y: point.1 - sparkleSize/2))
            path.addLine(to: CGPoint(x: point.0, y: point.1 + sparkleSize/2))
        }
        
        return path
    }
}

struct PencilPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Simple pencil strokes
        let lines = 3
        let spacing = rect.height / CGFloat(lines + 1)
        
        for i in 1...lines {
            let y = spacing * CGFloat(i)
            path.move(to: CGPoint(x: rect.width * 0.5, y: y))
            path.addLine(to: CGPoint(x: rect.width * 0.8, y: y))
        }
        
        return path
    }
}

extension ReflectionCardManager.ReflectionCardType {
    var shortDescription: String {
        switch self {
        case .sleepCheckin: return "Sleep tracker"
        case .moodCheckin: return "Quick check-in"
        case .daySummary: return "Reflect on today"
        case .standOut: return "Key moment"
        case .aiGenerated: return "Today's prompt"
        case .freeform: return "Open thoughts"
        }
    }
}

struct GeometricPattern: Shape {
    let index: Int
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        switch index % 3 {
        case 0: // Circles pattern
            let circleCount = 3
            let circleSize = rect.width / CGFloat(circleCount) * 0.8
            
            for row in 0..<circleCount {
                for col in 0..<circleCount {
                    let x = rect.width * CGFloat(col) / CGFloat(circleCount - 1)
                    let y = rect.width * CGFloat(row) / CGFloat(circleCount - 1)
                    path.addEllipse(in: CGRect(x: x - circleSize/2, y: y - circleSize/2,
                                             width: circleSize, height: circleSize))
                }
            }
            
        case 1: // Diagonal lines pattern
            let lineCount = 8
            let spacing = rect.width / CGFloat(lineCount)
            
            for i in 0...lineCount {
                path.move(to: CGPoint(x: CGFloat(i) * spacing, y: 0))
                path.addLine(to: CGPoint(x: CGFloat(i) * spacing + rect.height, y: rect.height))
            }
            
        case 2: // Grid pattern
            let gridCount = 4
            let spacing = rect.width / CGFloat(gridCount)
            
            // Vertical lines
            for i in 0...gridCount {
                path.move(to: CGPoint(x: CGFloat(i) * spacing, y: 0))
                path.addLine(to: CGPoint(x: CGFloat(i) * spacing, y: rect.height))
            }
            
            // Horizontal lines
            for i in 0...gridCount {
                path.move(to: CGPoint(x: 0, y: CGFloat(i) * spacing))
                path.addLine(to: CGPoint(x: rect.width, y: CGFloat(i) * spacing))
            }
            
        default:
            break
        }
        
        return path
    }
}
struct EditPlanView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var reflectionManager = ReflectionCardManager.shared
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    // Grid layout
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(ReflectionCardManager.ReflectionCardType.allCases, id: \.self) { card in
                        EditableCard(
                            card: card,
                            isSelected: reflectionManager.currentTemplate.selectedCards.contains(card),
                            onTap: {
                                reflectionManager.toggleCard(card)
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }
            .background(Color(hex: "F5F5F5"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Edit Plan")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(textColor)
                }
            }
        }
    }
}

struct EditableCard: View {
    let card: ReflectionCardManager.ReflectionCardType
    let isSelected: Bool
    let onTap: () -> Void
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .center, spacing: 8) {
                Text(card.title)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(textColor)
                
                Text(card.description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(textColor.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .padding()
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? textColor : Color.clear, lineWidth: 1)
            )
            .overlay(
                Group {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(accentColor)
                            .padding(12)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    }
                }
            )
            .cornerRadius(12)
        }
    }
}
#Preview {
    TodaysReflectionPlanView()
}
