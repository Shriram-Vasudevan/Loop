//
//  IntroView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/1/24.
//

import SwiftUI
import SpriteKit
import Speech

struct OnboardingView: View {
    let onIntroCompletion: () -> Void

    @State private var currentStep = 0
    @State private var fadeInOpacity = 0.0
    @State private var showMockRecording = false
    @State private var recordingProgress: CGFloat = 0
    @State private var showPastLoop = false
    @State private var showInsights = false
    @State private var showStorageInfo = false
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
        components.hour = 21
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
            AnimatedBackground()
                .ignoresSafeArea(.all)
            
            TabView(selection: $currentStep) {
                welcomeView  // Keep existing welcome view
                    .tag(0)
                storageView
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
//            if currentStep > 0 {
//                VStack {
//                    HStack {
//                        Spacer()
//                        Button(action: {
//                            saveUserPreferences()
//                            onIntroCompletion()
//                        }) {
//                            Text("Skip")
//                                .font(.system(size: 16, weight: .medium))
//                                .foregroundColor(textColor.opacity(0.5))
//                        }
//                        .padding(.horizontal, 24)
//                        .padding(.top, 16)
//                    }
//                    Spacer()
//                }
//            }
            
            if showStorageInfo {
                StorageInfoOverlay(isShowing: $showStorageInfo)
            }
        }
        .preferredColorScheme(.light)
    }
        
    private var welcomeView: some View {
        ZStack {
            VStack {
                Spacer()
                
                VStack(spacing: 5) {
                    Text("welcome to loop")
                        .font(.system(size: 38, weight: .ultraLight))
                        .foregroundColor(textColor)
                        .opacity(fadeInOpacity)
                    
                    Text("start micro-journaling today")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(textColor.opacity(0.6))
                        .opacity(fadeInOpacity)
                }
                
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
                withAnimation(.easeOut(duration: 3)) {
                    fadeInOpacity = 1
                }
            }
        }
    }
    
    private var storageView: some View {
        ZStack {
            VStack(spacing: 16) {
                
                Text("PRIVACY")
                    .font(.system(size: 14, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.6))
                    .padding(.top, 32)
                
                Spacer()
                
                CloudAnimation()
                    .frame(height: 120)
                
                VStack(spacing: 8) {
                    Text("your journal is for you")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(textColor)
                    
                    Text("only you can access your loops")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(textColor.opacity(0.6))
                }
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.4)) {
                        showStorageInfo = true
                    }
                } label: {
                    Label("where are my entries stored?", systemImage: "questionmark.circle")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(accentColor)
                }
                
                OnboardingButton(text: "continue", icon: "arrow.right") {
                    withAnimation {
                        saveUserPreferences()
                        onIntroCompletion()
                    }
                }
                .padding(.bottom, 48)
            }
        }
    }


    private func generateWaveform() {
        waveformData = (0..<60).map { _ in
            CGFloat.random(in: 12...64)
        }
    }
    
    struct CloudAnimation: View {
        @State private var isAnimating = false
        
        var body: some View {
            ZStack {
                Image(systemName: "lock.fill")
                    .font(.system(size: 64, weight: .light))
                    .foregroundColor(Color(hex: "A28497"))
                
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color(hex: "A28497").opacity(0.1))
                        .frame(width: 12, height: 12)
                        .offset(y: isAnimating ? -40 : 0)
                        .opacity(isAnimating ? 0 : 1)
                        .animation(
                            Animation
                                .easeInOut(duration: 2)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.3),
                            value: isAnimating
                        )
                }
            }
            .onAppear {
                isAnimating = true
            }
        }
    }
    
    struct StorageInfoOverlay: View {
        @Binding var isShowing: Bool
        
        var body: some View {
            ZStack {
                Color.black.opacity(0.2)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            isShowing = false
                        }
                    }
                
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Image(systemName: "arrow.up.doc.on.clipboard")
                            .font(.system(size: 32))
                            .foregroundColor(Color(hex: "A28497"))
                        
                        Text("Optimized for You")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color(hex: "2C3E50"))
                        
                        Text("Your loops are stored on your phone by default, but iCloud backup is available if you'd like to use loop across devices.")
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(Color(hex: "2C3E50").opacity(0.8))
                            .multilineTextAlignment(.center)
                        
                        HStack {
                            Image(systemName: "sparkles")
                            Text("We are strongly against third-party storage")
                                .multilineTextAlignment(.center)
                        }
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(Color(hex: "A28497"))
                        .padding(.top, 8)
                    }
                    
                    Button {
                        withAnimation {
                            isShowing = false
                        }
                    } label: {
                        Text("Got it")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "A28497"))
                            .frame(width: 100, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(Color(hex: "A28497").opacity(0.1))
                            )
                    }
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 20)
                )
                .padding(24)
            }
            .transition(.opacity.combined(with: .scale(scale: 1.1)))
        }
    }

    
    struct TimeSelectionWheel: View {
        @Binding var selectedTime: Date
        
        var body: some View {
            DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxHeight: 180)
                .accentColor(Color(hex: "A28497"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: "A28497").opacity(0.05))
                        .frame(height: 44)
                        .blendMode(.overlay)
                )
                .padding(.horizontal, 32)
        }
    }
    
    private func saveUserPreferences() {
        UserDefaults.standard.set(userName, forKey: "userName")
        UserDefaults.standard.set(reminderTime, forKey: "reminderTime")
        Task {
            let speechStatus = await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status)
                }
            }
            
            if speechStatus == .authorized {
                if await NotificationManager.shared.requestNotificationPermissions() {
                    NotificationManager.shared.scheduleDailyReminder(at: reminderTime)
                }
            }

            DispatchQueue.main.async {
                onIntroCompletion()
            }
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


#Preview {
    OnboardingView {
        print("Onboarding completed")
    }
}
