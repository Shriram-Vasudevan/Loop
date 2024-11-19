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
    
    // Design constants
    private let accentColor = Color(hex: "A28497")
    private let backgroundColor = Color(hex: "FAFBFC")
    private let textColor = Color(hex: "2C3E50")
    
    // Animation states
    @State private var logoScale = 0.9
    @State private var logoOpacity = 0.0
    @State private var circleOneScale = 0.0
    @State private var circleTwoScale = 0.0
    @State private var textOneOpacity = 0.0
    @State private var textTwoOpacity = 0.0
    @State private var lineWidth: CGFloat = 0.0
    @State private var rotationAngle = 0.0
    
    // Circle animation positions
    @State private var circleOnePosition: CGPoint = .zero
    @State private var circleTwoPosition: CGPoint = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RadialGradient(
                    gradient: Gradient(colors: [
                        backgroundColor,
                        Color(hex: "F8F5F7")
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: geometry.size.width
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    ZStack {
                        Circle()
                            .strokeBorder(
                                AngularGradient(
                                    gradient: Gradient(colors: [
                                        accentColor.opacity(0.2),
                                        accentColor.opacity(0.1),
                                        accentColor.opacity(0.2)
                                    ]),
                                    center: .center
                                ),
                                lineWidth: lineWidth
                            )
                            .frame(width: 280, height: 280)
                            .rotationEffect(.degrees(rotationAngle))
                        
                        Circle()
                            .fill(accentColor.opacity(0.05))
                            .frame(width: 200, height: 200)
                            .scaleEffect(circleOneScale)
                            .offset(x: circleOnePosition.x, y: circleOnePosition.y)

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
                            .frame(width: 120, height: 120)
                            .scaleEffect(circleTwoScale)
                            .offset(x: circleTwoPosition.x, y: circleTwoPosition.y)
                            .overlay(
                                Image(systemName: "waveform")
                                    .font(.system(size: 40, weight: .ultraLight))
                                    .foregroundColor(.white)
                                    .opacity(logoOpacity)
                            )
                    }
                    .frame(height: 300)

                    VStack(spacing: 12) {
                        Text("loop")
                            .font(.system(size: 44, weight: .ultraLight))
                            .foregroundColor(textColor)
                            .opacity(textOneOpacity)
                        
                        Text("capture your journey")
                            .font(.system(size: 18, weight: .light))
                            .foregroundColor(textColor.opacity(0.6))
                            .opacity(textTwoOpacity)
                    }
                    .padding(.top, 40)
                    
                    Spacer()
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 1.2)) {
                    lineWidth = 1.0
                }
                
                withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
                    circleOneScale = 1.0
                    circleTwoScale = 1.0
                }
                
                withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                    textOneOpacity = 1.0
                }
                
                withAnimation(.easeOut(duration: 0.8).delay(0.5)) {
                    textTwoOpacity = 1.0
                    logoOpacity = 1.0
                }

                withAnimation(
                    .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
                ) {
                    circleOnePosition = CGPoint(x: 0, y: -5)
                    circleTwoPosition = CGPoint(x: 0, y: 5)
                }

                withAnimation(
                    .linear(duration: 20)
                    .repeatForever(autoreverses: false)
                ) {
                    rotationAngle = 360
                }

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
