//
//  TodaysReflectionWidget.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/16/25.
//

import SwiftUI

struct SunsetReflectionView: View {
    private let accentColor = Color(hex: "A28497")    // Main mauve accent
    private let textColor = Color(hex: "2C3E50")
    
    // Mauve color variants
    private let lightMauve = Color(hex: "D5C5CC")     // Lighter variant
    private let midMauve = Color(hex: "BBA4AD")       // Medium variant
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    lightMauve.opacity(0.3),
                    Color.white.opacity(0.9)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            GeometricMountains()
                .fill(midMauve)
                .opacity(0.2)
                .frame(height: 120)
                .offset(y: 40)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("TODAY'S REFLECTION")
                        .font(.system(size: 13, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(textColor.opacity(0.5))
                    
                    Spacer()
                }
                
                HStack {
                    Text("Take time to look back on your day")
                        .font(.system(size: 23, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(textColor)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                
                Spacer()
            }
            .padding(32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}


struct GeometricMountains: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // First mountain
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.width * 0.3, y: rect.height * 0.2))
        path.addLine(to: CGPoint(x: rect.width * 0.5, y: rect.maxY))
        
        // Second mountain
        path.move(to: CGPoint(x: rect.width * 0.3, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.width * 0.7, y: rect.height * 0.3))
        path.addLine(to: CGPoint(x: rect.width, y: rect.maxY))
        
        return path
    }
}

#Preview {
    SunsetReflectionView()
        .padding()
        .background(Color.white)
}

//struct HorizonReflectionView: View {
//    private let horizonBlue = Color(hex: "1E3D59")
//    
//    var body: some View {
//        ZStack {
//            // Base layer with horizontal lines
//            VStack(spacing: 0) {
//                ForEach(0..<8) { index in
//                    Rectangle()
//                        .fill(horizonBlue)
//                        .opacity(0.1 - Double(index) * 0.01)
//                        .frame(height: 25)
//                }
//            }
//            
//            // Content overlay
//            VStack(alignment: .leading, spacing: 8) {
//                Text("TODAY'S REFLECTION")
//                    .font(.system(size: 13, weight: .medium))
//                    .tracking(1.5)
//                    .foregroundColor(horizonBlue.opacity(0.7))
//                
//                Text("Take time to look back on your day")
//                    .font(.system(size: 23, weight: .medium))
//                    .tracking(1.5)
//                    .foregroundColor(horizonBlue)
//            }
//            .padding(32)
//            .frame(maxWidth: .infinity, alignment: .leading)
//        }
//        .frame(height: 200)
//        .clipShape(RoundedRectangle(cornerRadius: 12))
//    }
//}
//
//struct MinimalStarfieldView: View {
//    private let nightBlue = Color(hex: "1E3D59")
//    
//    var body: some View {
//        ZStack {
//            // Background
//            Color(hex: "F5F6F8")
//            
//            // Geometric star pattern
//            GeometricStars()
//                .stroke(nightBlue.opacity(0.2), lineWidth: 1)
//            
//            // Content overlay
//            VStack(alignment: .leading, spacing: 8) {
//                Text("TODAY'S REFLECTION")
//                    .font(.system(size: 13, weight: .medium))
//                    .tracking(1.5)
//                    .foregroundColor(nightBlue.opacity(0.7))
//                
//                Text("Take time to look back on your day")
//                    .font(.system(size: 23, weight: .medium))
//                    .tracking(1.5)
//                    .foregroundColor(nightBlue)
//            }
//            .padding(32)
//            .frame(maxWidth: .infinity, alignment: .leading)
//        }
//        .frame(height: 200)
//        .clipShape(RoundedRectangle(cornerRadius: 12))
//    }
//}
//
//struct GeometricStars: Shape {
//    func path(in rect: CGRect) -> Path {
//        var path = Path()
//        let gridSize = 6
//        let spacing = rect.width / CGFloat(gridSize)
//        
//        for row in 0..<gridSize {
//            for col in 0..<gridSize {
//                let x = CGFloat(col) * spacing + spacing/2
//                let y = CGFloat(row) * spacing + spacing/2
//                
//                if (row + col) % 2 == 0 {
//                    // Draw small geometric star
//                    let size = spacing * 0.2
//                    path.move(to: CGPoint(x: x, y: y - size))
//                    path.addLine(to: CGPoint(x: x + size, y: y))
//                    path.addLine(to: CGPoint(x: x, y: y + size))
//                    path.addLine(to: CGPoint(x: x - size, y: y))
//                    path.addLine(to: CGPoint(x: x, y: y - size))
//                }
//            }
//        }
//        
//        return path
//    }
//}
//
//struct ContentView: View {
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 20) {
//                SunsetReflectionView()
//                    .shadow(color: Color.black.opacity(0.05), radius: 10)
//                
////                HorizonReflectionView()
////                    .shadow(color: Color.black.opacity(0.05), radius: 10)
////                
////                MinimalStarfieldView()
////                    .shadow(color: Color.black.opacity(0.05), radius: 10)
//            }
//            .padding()
//        }
//    }
//}
//
//#Preview {
//    ContentView()
//}
