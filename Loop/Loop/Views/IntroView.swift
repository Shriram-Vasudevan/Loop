//
//  IntroView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/1/24.
//

import SwiftUI
import SpriteKit
import Speech
import Combine

struct OnboardingView: View {
    let onIntroCompletion: () -> Void

    @State private var currentStep = 0
    @State private var fadeInOpacity = 0.0
    @State private var showMockRecording = false
    @State private var recordingProgress: CGFloat = 0
    @State private var showPastLoop = false
    @State private var showInsights = false
    @State private var showStorageInfo = false
    @State private var showFinalNote = false
    @State private var userName = ""
    @State private var selectedPurposes: Set<String> = []
    @State private var backgroundOpacity = 0.0
    @State private var waveformData: [CGFloat] = Array(repeating: 0, count: 60)
    @State private var showWaveform = false
    @State private var progress: CGFloat = 0.3
    @State private var showInitialPrompt = true
    @State private var contentOpacity: CGFloat = 0
    
    @State private var reminderTime: Date = {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 20
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()

    
    @State private var recordingTimer: Timer?
    @State private var timeRemaining: Int = 30
    @State private var isRecording = false
    
    let accentColor = Color(hex: "A28497")
    let textColor = Color(hex: "2C3E50")
    
    private let purposes = [
        "capture growth",
        "reflect daily",
        "understand patterns",
        "build awareness",
        "track journey"
    ]
        
    var body: some View {
        ZStack {
            InitialReflectionVisual(index: 0)
                .edgesIgnoringSafeArea(.all)
                .animation(.easeInOut, value: currentStep)
            
            TabView(selection: $currentStep) {
                welcomeView
                    .tag(0)
                WhyLoopView(currentTab: $currentStep)
                    .edgesIgnoringSafeArea(.all)
                    .tag(1)
                PrivacyStorageView(currentTab: $currentStep, onIntroCompletion: {
                    FirstLaunchManager.shared.showTutorial = true
                    saveUserPreferences()
                })
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

        }
        .preferredColorScheme(.light)
    }
    
    private var welcomeView: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("welcome to loop")
                        .font(.system(size: 42, weight: .medium))
                        .foregroundColor(textColor)
                    
                    Text("your audio journal for\n thoughtful reflection")
                        .font(.system(size: 28, weight: .regular))
                        .foregroundColor(textColor.opacity(0.8))
                        .lineSpacing(8)
                }
                .opacity(fadeInOpacity)
                .padding(.horizontal, 32)
                .padding(.top, 130)

                Text("express your thoughts with guided prompts and discover patterns in your journey")
                    .font(.system(size: 17))
                    .foregroundColor(textColor.opacity(0.6))
                    .opacity(fadeInOpacity)
                    .padding(.horizontal, 32)
                Spacer()
                
                OnboardingButton(text: "begin", icon: "arrow.right") {
                    withAnimation {
                        currentStep = 1
                    }
                }
                .padding(.bottom, 48)
                .opacity(fadeInOpacity)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 2)) {
                    fadeInOpacity = 1
                }
            }
        }
    }
    
    private func saveUserPreferences() {
        UserDefaults.standard.set(userName, forKey: "userName")
//        UserDefaults.standard.set(reminderTime, forKey: "reminderTime")
//        
//        NotificationManager.shared.saveAndScheduleReminder(at: reminderTime)
//        
        DispatchQueue.main.async {
            onIntroCompletion()
        }
    }
    
    private func waveHeight(for index: Int) -> CGFloat {
           let heights: [CGFloat] = [15, 20, 25, 30, 25, 20, 15, 20, 25, 30, 25, 20, 15, 20, 25, 30, 25, 20, 15, 20]
           return heights[index]
       }

}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

struct OnboardingButton: View {
    let text: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(text)
                    .font(.system(size: 18, weight: .light))
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .light))
            }
            .frame(height: 56)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "A28497"),
                        Color(hex: "A28497").opacity(0.9)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(28)
            .shadow(color: Color(hex: "A28497").opacity(0.15), radius: 12, y: 6)
            .padding(.horizontal, 32)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct WhyLoopView: View {
    @Binding var currentTab: Int
    @State private var selectedPurposes: Set<String> = []
    @State private var appearAnimation: [Bool] = Array(repeating: false, count: 7)
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    private let purposes = [
        (icon: "sun.max", text: "process my day"),
        (icon: "leaf", text: "track my growth"),
        (icon: "heart", text: "understand my emotions"),
        (icon: "brain", text: "build self-awareness"),
        (icon: "sparkles", text: "find clarity"),
        (icon: "ellipsis", text: "other")
    ]
    
    var body: some View {
        ZStack {
//            Color(hex: "F5F5F5").edgesIgnoringSafeArea(.all)
//            
            VStack(spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("why do you want to loop?")
                            .font(.system(size: 26, weight: .medium))
                            .foregroundColor(textColor)
                            .opacity(appearAnimation[0] ? 1 : 0)
                            .offset(y: appearAnimation[0] ? 0 : 20)
                        
                        Spacer()
                    }
                    
                    Text("select all that resonate")
                        .font(.system(size: 16, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(textColor.opacity(0.6))
                        .opacity(appearAnimation[1] ? 1 : 0)
                }
                .padding(.top, 64)

                VStack(spacing: 8) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            ForEach(Array(purposes.enumerated()), id: \.element.text) { index, purpose in
                                EnhancedPurposeCard(
                                    icon: purpose.icon,
                                    text: purpose.text,
                                    isSelected: selectedPurposes.contains(purpose.text),
                                    onTap: {
                                        withAnimation(.spring(response: 0.3)) {
                                            if selectedPurposes.contains(purpose.text) {
                                                selectedPurposes.remove(purpose.text)
                                            } else {
                                                selectedPurposes.insert(purpose.text)
                                            }
                                        }
                                    }
                                )
                                .opacity(appearAnimation[min(index + 2, appearAnimation.count - 1)] ? 1 : 0)
                                .offset(y: appearAnimation[min(index + 2, appearAnimation.count - 1)] ? 0 : 20)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.6)) {
                            currentTab += 1
                        }
                    }) {
                        HStack(spacing: 12) {
                            Text("continue")
                                .font(.system(size: 18, weight: .medium))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .frame(height: 60)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    accentColor,
                                    accentColor.opacity(0.85)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(30)
                        .shadow(color: accentColor.opacity(0.25), radius: 15, y: 8)
                    }
                    .opacity(selectedPurposes.isEmpty ? 0.6 : 1)
                    .disabled(selectedPurposes.isEmpty)
                    .opacity(appearAnimation[6] ? 1 : 0)
                    .offset(y: appearAnimation[6] ? 0 : 20)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .onAppear {
            animateEntrance()
        }
    }
    
    private func animateEntrance() {
        for index in 0..<appearAnimation.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    appearAnimation[index] = true
                }
            }
        }
    }
}

struct EnhancedPurposeCard: View {
    let icon: String
    let text: String
    let isSelected: Bool
    let onTap: () -> Void
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
//                Image(systemName: icon)
//                    .font(.system(size: 20, weight: .medium))
//                    .foregroundColor(isSelected ? .white : accentColor)
//                    .frame(width: 32)
//
                Text(text)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(isSelected ? .white : textColor)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? accentColor : Color.white)
                    .shadow(color: Color.black.opacity(isSelected ? 0.1 : 0.05),
                           radius: isSelected ? 12 : 8,
                           y: isSelected ? 6 : 4)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct PrivacyStorageView: View {
    @Binding var currentTab: Int
    let onIntroCompletion: () -> Void
    
    @State private var appearAnimation: [Bool] = Array(repeating: false, count: 5)
    @State private var waveOffset: CGFloat = 0
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        ZStack {
//            Color(hex: "F5F5F5").edgesIgnoringSafeArea(.all)
//            
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("your journal is for you")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(textColor)
                        
                        Spacer()
                    }

                    Text("we take privacy seriously")
                        .font(.system(size: 16, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(textColor.opacity(0.6))
                        .opacity(appearAnimation[1] ? 1 : 0)
                }
                .padding(.top, 64)
                
                VStack(spacing: 32) {
                    ZStack {
                        ForEach(0..<3) { index in
                            AltWavePattern()
                                .fill(accentColor.opacity(0.2 + Double(index) * 0.2))
                                .frame(height: 90)
                                .offset(x: -10 + CGFloat(index * 50))
                        }
                    }
                    .frame(height: 90)
                    .mask(Rectangle().frame(height: 90))
                    .opacity(appearAnimation[2] ? 1 : 0)
                    .padding(.top, -32)
                    
                    VStack(spacing: 24) {
                        Text("Your journal stays on your device by default. We strongly believe in privacy, which is why your reflections are stored locally or backed up to your own iCloud if you choose. Only you can access your data.")
                            .font(.system(size: 17, weight: .medium))
                            .tracking(1.5)
                            .foregroundColor(textColor.opacity(0.5))
                            .multilineTextAlignment(.leading)
                            .opacity(appearAnimation[3] ? 1 : 0)

                        HStack(spacing: 8) {
                            Text("We will never deal with third parties.")
                                .opacity(appearAnimation[4] ? 1 : 0)
                            
                            Spacer()
                        }
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(textColor)
                    }
                    .padding(.top, 12)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.6)) {
                        onIntroCompletion()
                    }
                }) {
                    HStack(spacing: 12) {
                        Text("start looping")
                            .font(.system(size: 18, weight: .medium))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .frame(height: 60)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                accentColor,
                                accentColor.opacity(0.85)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(30)
                    .shadow(color: accentColor.opacity(0.25), radius: 15, y: 8)
                }
                .opacity(appearAnimation[3] ? 1 : 0)
                .offset(y: appearAnimation[3] ? 0 : 20)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .onAppear {
            animateEntrance()
            animateWave()
        }
    }
    
    private func animateEntrance() {
        for index in 0..<appearAnimation.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.2) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    appearAnimation[index] = true
                }
            }
        }
    }
    
    private func animateWave() {
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            waveOffset = -200
        }
    }
}

struct AltWavePattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: 0, y: height))
        
        let waveSegmentWidth: CGFloat = width / 4
        let amplitude: CGFloat = height * 0.3
        
        let c1 = CGPoint(x: waveSegmentWidth * 0.25, y: height - amplitude)
        let c2 = CGPoint(x: waveSegmentWidth * 0.75, y: height - amplitude)
        
        let p1 = CGPoint(x: waveSegmentWidth, y: height)

        let c3 = CGPoint(x: waveSegmentWidth * 1.25, y: height + amplitude)
        let c4 = CGPoint(x: waveSegmentWidth * 1.75, y: height + amplitude)

        let p2 = CGPoint(x: waveSegmentWidth * 2, y: height)

        path.addCurve(to: p1, control1: c1, control2: c2)
        path.addCurve(to: p2, control1: c3, control2: c4)

        path.addCurve(to: CGPoint(x: waveSegmentWidth * 3, y: height),
                     control1: CGPoint(x: waveSegmentWidth * 2.25, y: height - amplitude),
                     control2: CGPoint(x: waveSegmentWidth * 2.75, y: height - amplitude))
        path.addCurve(to: CGPoint(x: waveSegmentWidth * 4, y: height),
                     control1: CGPoint(x: waveSegmentWidth * 3.25, y: height + amplitude),
                     control2: CGPoint(x: waveSegmentWidth * 3.75, y: height + amplitude))

        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

struct PrivacyFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
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
                    .frame(width: 48, height: 48)
                    .shadow(color: accentColor.opacity(0.15), radius: 8, y: 4)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            
        }
    }
}
struct GeometricShapes: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Create abstract geometric shapes
        let size = min(rect.width, rect.height)
        let centerX = rect.midX
        let bottomY = rect.maxY
        
        // Simple mountain-like shapes
        path.move(to: CGPoint(x: centerX - size/2, y: bottomY))
        path.addLine(to: CGPoint(x: centerX - size/4, y: bottomY - size/3))
        path.addLine(to: CGPoint(x: centerX, y: bottomY - size/2))
        path.addLine(to: CGPoint(x: centerX + size/4, y: bottomY - size/4))
        path.addLine(to: CGPoint(x: centerX + size/2, y: bottomY))
        
        return path
    }
}

#Preview {
    OnboardingView {
        print("Onboarding completed")
    }
}
