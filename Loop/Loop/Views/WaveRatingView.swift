//
//  WaveRatingView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/15/25.
//

import SwiftUI

import SwiftUI

struct GeometricSliderView: View {
    @Binding var rating: Double
    private let baseColor = Color(hex: "1E3D59")
    private let textColor = Color(hex: "2C3E50")
    @State private var isDragging = false
    @State private var phase: Double = 0
    
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 32) {
                // Rating display
                Text(String(format: "%.1f", rating))
                    .font(.system(size: 72, weight: .light))
                    .foregroundColor(textColor)
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: 0.2), value: rating)
                    .opacity(isDragging ? 1 : 0.7)
                
                // Slider track
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    baseColor.opacity(0.08),
                                    baseColor.opacity(0.05)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(baseColor.opacity(0.1), lineWidth: 1)
                        )
                        .frame(height: 24)
                    
                    // Active fill with waves
                    GeometryReader { fillGeometry in
                        ZStack {
                            // Main fill
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            baseColor.opacity(0.3),
                                            baseColor.opacity(0.2)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            // Wave overlays
                            HStack(spacing: 0) {
                                ForEach(0..<3) { i in
                                    GeometricShape(phase: phase + Double(i) * 0.5)
                                        .fill(baseColor.opacity(0.2))
                                        .frame(width: 40)
                                }
                            }
                            .mask(
                                LinearGradient(
                                    colors: [.clear, .black, .black, .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        }
                    }
                    .frame(width: max(0, min(geometry.size.width, CGFloat(rating) / 10 * geometry.size.width)))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: rating)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            isDragging = true
                            let width = geometry.size.width
                            let newRating = 10 * (gesture.location.x / width)
                            rating = min(max(0, newRating), 10)
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
            }
            .onReceive(timer) { _ in
                withAnimation(.linear(duration: 0.05)) {
                    phase += 0.05
                }
            }
        }
    }
}

struct GeometricShape: Shape {
    var phase: Double
    
    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: 0, y: height))
        
        stride(from: 0, through: width, by: 1).forEach { x in
            let relativeX = Double(x) / Double(width)  // Explicit casting to Double
            let y = height/2 + sin(relativeX * .pi * 2 + phase) * 8
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

struct GeometricSliderView_Previews: PreviewProvider {
    static var previews: some View {
        GeometricSliderView(rating: .constant(5.0))
            .padding(.horizontal, 32)
            .frame(height: 200)
            .background(Color.white)
    }
}
