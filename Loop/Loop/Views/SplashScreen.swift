//
//  SplashScreen.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/7/24.
//

import SwiftUI

struct SplashScreen: View {
    @Binding var showingSplashScreen: Bool
    @Binding var showLoops: Bool
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    @State private var contentOpacity = 0.0
    @State private var titleOffset: CGFloat = 30
    @State private var subtitleOffset: CGFloat = 30
    @State private var iconOpacity = 0.0
    @State private var backgroundOpacity = 0.0
    @State private var iconScale = 0.9
    
    var body: some View {
        ZStack {
            // Base white background
            Color.white
                .ignoresSafeArea()
            
            // Animated background with signature Loop colors
            CustomAnimatedBackground()
                .opacity(backgroundOpacity)
            
            // Main content
            VStack(spacing: 0) {
                Spacer()
//                
//                // Icon container
//                ZStack {
//                    Circle()
//                        .fill(.white)
//                        .frame(width: 120, height: 120)
//                        .shadow(color: accentColor.opacity(0.1), radius: 20)
//                    
//                    Image(systemName: "waveform")
//                        .font(.system(size: 40, weight: .thin))
//                        .foregroundColor(accentColor)
//                }
//                .scaleEffect(iconScale)
//                .opacity(iconOpacity)
//                
                Spacer()
                    .frame(height: 40)
                
                // Text content
                VStack(spacing: 12) {
                    Text("loop")
                        .font(.custom("PPNeueMontreal-Medium", size: 44))
                        .foregroundColor(textColor)
                        .offset(y: titleOffset)
                    
                    Text("daily reflections")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(accentColor)
                        .offset(y: subtitleOffset)
                }
                .opacity(contentOpacity)
                
                Spacer()
            }
            .padding(.bottom, 100)
        }
        .onAppear {
            animateEntrance()
        }
    }
    
    private func animateEntrance() {
        // Fade in background waves
        withAnimation(.easeIn(duration: 1.2)) {
            backgroundOpacity = 1
        }
        
        // Fade in and scale icon
        withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.3)) {
            iconScale = 1
            iconOpacity = 1
        }
        
        // Slide up text elements
        withAnimation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.5)) {
            titleOffset = 0
            subtitleOffset = 0
            contentOpacity = 1
        }
        
        // Transition to main app
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.75) {
            if FirstLaunchManager.shared.isFirstLaunch {
                showLoops = false
            } else {
                showLoops = LaunchManager.shared.isFirstLaunchOfDay()
            }
            
            withAnimation(.easeOut(duration: 0.5)) {
                showingSplashScreen = false
            }
        }
    }
}

struct CustomAnimatedBackground: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            Canvas { context, size in
                let timeOffset = timeline.date.timeIntervalSinceReferenceDate
                
                for i in 0..<3 {
                    let frequency = Double(i + 1) * 0.5
                    let amplitude = 100 - Double(i) * 20
                    let phase = timeOffset.remainder(dividingBy: 8) / 8 * .pi * 2
                    
                    var path = Path()
                    let width = size.width
                    let height = size.height
                    let midHeight = height / 2
                    
                    let steps = Int(width / 4)
                    let dx = width / CGFloat(steps)
                    
                    path.move(to: CGPoint(x: 0, y: height))
                    path.addLine(to: CGPoint(x: 0, y: midHeight))
                    
                    for step in 0...steps {
                        let x = CGFloat(step) * dx
                        let relativeX = x / width
                        let y = sin(relativeX * .pi * frequency * 2 + phase) * amplitude + midHeight
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.closeSubpath()
                    
                    // Using Loop's signature color
                    let gradient = Gradient(colors: [
                        Color(hex: "A28497").opacity(0.03),
                        Color(hex: "A28497").opacity(0.06)
                    ])
                    
                    context.fill(
                        path,
                        with: .linearGradient(
                            gradient,
                            startPoint: CGPoint(x: size.width/2, y: 0),
                            endPoint: CGPoint(x: size.width/2, y: size.height)
                        )
                    )
                }
            }
            .background(Color(hex: "FAFBFC"))
        }
        .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    SplashScreen(
        showingSplashScreen: .constant(true),
        showLoops: .constant(true)
    )
}
