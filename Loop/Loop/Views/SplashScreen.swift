//
//  SplashScreen.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/7/24.
//

import SwiftUI

import SwiftUI

struct SplashScreen: View {
    @Binding var showingSplashScreen: Bool
    @Binding var showLoops: Bool
    
    // Animation states
    @State private var circleScale = 0.0
    @State private var textOpacity = 0.0
    @State private var waveOffset = 0.0
    @State private var rotationAngle = 0.0
    
    private let accentColor = Color(hex: "A28497")
    private let backgroundColor = Color(hex: "FAFBFC")
    private let textColor = Color(hex: "2C3E50")
    
    @State private var backgroundOpacity: Double = 0
    
    var body: some View {
        ZStack {
            AnimatedBackground()
                .opacity(backgroundOpacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.2)) {
                        backgroundOpacity = 1
                    }
                }
            
            RadialGradient(
                gradient: Gradient(colors: [
                    backgroundColor,
                    Color(hex: "F8F5F7")
                ]),
                center: .center,
                startRadius: 100,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            VStack {
                VStack(spacing: 8) {
                    Text("loop")
                        .font(.system(size: 44, weight: .ultraLight))
                        .foregroundColor(textColor)
                    
                    Text("daily reflections")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(textColor.opacity(0.6))
                }
                .opacity(textOpacity)
                .padding(.bottom, 60)
                
                ZStack {
                    Circle()
                        .fill(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    accentColor.opacity(0.1),
                                    accentColor.opacity(0.05),
                                    accentColor.opacity(0.1)
                                ]),
                                center: .center
                            )
                        )
                        .frame(width: 300, height: 300)
                        .rotationEffect(.degrees(rotationAngle))

                    Circle()
                        .fill(accentColor.opacity(0.1))
                        .frame(width: 200, height: 200)
                        .scaleEffect(circleScale)

                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    accentColor,
                                    accentColor.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "waveform.circle.fill")
                                .font(.system(size: 40, weight: .light))
                                .foregroundColor(.white)
                        )
                        .scaleEffect(circleScale)
                }
            }
        }
        .onAppear {
            animateSplashScreen()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.75) {
                if FirstLaunchManager.shared.isFirstLaunch {
                    showLoops = false
                } else {
                    showLoops = LaunchManager.shared.isFirstLaunchOfDay()
                }
                
                withAnimation(.easeOut(duration: 0.3)) {
                    showingSplashScreen = false
                }
            }
        }
    }
    
    private func animateSplashScreen() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            circleScale = 1.0
        }

        withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
            textOpacity = 1.0
        }

        withAnimation(
            .linear(duration: 20)
            .repeatForever(autoreverses: false)
        ) {
            rotationAngle = 360
        }
        
        withAnimation(
            .linear(duration: 2.0)
            .repeatForever(autoreverses: false)
        ) {
            waveOffset = 1.0
        }
    }
}

struct WaveGroup: Shape {
    var waveOffset: Double
    
    var animatableData: Double {
        get { waveOffset }
        set { waveOffset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: 0, y: height * 0.5))
        
        for x in stride(from: 0, to: width, by: 1) {
            let relativeX = x / width
            let sine = sin(relativeX * .pi * 4 + waveOffset * .pi * 2)
            let y = height * 0.5 + sine * 20
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        // Complete the path
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

#Preview {
    SplashScreen(
        showingSplashScreen: .constant(true),
        showLoops: .constant(true)
    )
}

//#Preview {
//    SplashScreen()
//}
