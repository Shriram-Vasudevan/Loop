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
            if currentStep == 0 {
                InitialReflectionVisual(index: 0)
                    .edgesIgnoringSafeArea(.all)
                    .animation(.easeInOut, value: currentStep)
            }
            else {
                Color(hex: "F5F5F5").edgesIgnoringSafeArea(.all)
            }
            
            TabView(selection: $currentStep) {
                welcomeView  // Keep existing welcome view
                    .tag(0)
                WhyLoopView(currentTab: $currentStep)
                    .edgesIgnoringSafeArea(.all)
                    .tag(1)
//                JournalShowcaseView(currentTab: $currentStep)
//                    .tag(2)
                PrivacyStorageView(currentTab: $currentStep, onIntroCompletion: {
                    onIntroCompletion()
                })
                    .tag(2)
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
                // Context
                Text("express your thoughts with guided prompts and discover patterns in your journey")
                    .font(.system(size: 17))
                    .foregroundColor(textColor.opacity(0.6))
                    .opacity(fadeInOpacity)
                    .padding(.horizontal, 32)
                Spacer()
                
                OnboardingButton(text: "begin", icon: "arrow.right") {
                    withAnimation {
                        currentStep = 1
                        showFinalNote = true
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

struct PrivacyStorageView: View {
    @Binding var currentTab: Int
    @State var onIntroCompletion: () -> Void
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(spacing: 40) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("your journal is for you")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(textColor)
                    
                    Spacer()
                }
                
                Text("we take privacy seriously")
                    .font(.system(size: 14, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.5))
            }
            .padding(.top, 32)
            
            VStack(spacing: 32) {
                WavePattern()
                    .fill(accentColor.opacity(0.7))
                    .frame(height: 90)
                
                Text("Your journal stays on your device by default. We strongly believe in privacy, which is why your reflections are stored locally and can only be accessed by you.\n\nFor added flexibility, you can enable iCloud backup to sync across your devices – but that's entirely up to you.")
                    .font(.system(size: 17, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.5))
                    .multilineTextAlignment(.center)
                
                // Extra assurance
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text("We will never deal with third parties")
                }
                .font(.system(size: 14))
                .foregroundColor(accentColor)
            }
            
            Spacer()
            
            // Start Button
            Button(action: {
                withAnimation {
                    onIntroCompletion()
                }
            }) {
                HStack(spacing: 12) {
                    Text("start looping")
                        .font(.system(size: 18, weight: .regular))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .light))
                }
                .frame(height: 56)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            accentColor,
                            accentColor.opacity(0.9)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(28)
                .shadow(color: accentColor.opacity(0.15), radius: 12, y: 6)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 48)
        .background(Color(hex: "F5F5F5"))
    }
}

struct JournalShowcaseView: View {
    @Binding var currentTab: Int
   @State private var currentJournal = 0
   @State private var isAnimating = false
   @State private var timer: Timer.TimerPublisher = Timer.publish(every: 2.5, on: .main, in: .common)
   @State private var timerCancellable: AnyCancellable?
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    private let journals = [
        (title: "daily reflection", description: "guided prompts for each day", background: AnyView(InitialReflectionVisual(index: 0))),
        (title: "dream journal", description: "capture dreams before they fade", background: AnyView(DreamBackground())),
        (title: "success journal", description: "celebrate your achievements", background: AnyView(SuccessBackground()))
    ]
    
    var body: some View {
        VStack(spacing: 32) {

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("find what interests you")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(textColor)
                    
                    Spacer()
                }
                    
                Text("reflect in different ways")
                    .font(.system(size: 14, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.5))
            }
            .padding(.top, 32)

            ZStack {
                ForEach(0..<journals.count, id: \.self) { index in
                    journals[index].background
                        .opacity(currentJournal == index ? 1 : 0)
                }
                
                VStack {
                    Spacer()
                    
                    // Title and description
                    VStack(alignment: .leading, spacing: 8) {
                        Text(journals[currentJournal].title)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                            .transition(.opacity)
                        
                        Text(journals[currentJournal].description)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                            .transition(.opacity)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: [.black.opacity(0.3), .clear],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.top, -16)

            Button(action: {
                withAnimation {
                    currentTab += 1
                }
            }) {
                HStack(spacing: 12) {
                    Text("continue")
                        .font(.system(size: 18, weight: .regular))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .light))
                }
                .frame(height: 56)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            accentColor,
                            accentColor.opacity(0.9)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(28)
                .shadow(color: accentColor.opacity(0.15), radius: 12, y: 6)
                .padding(.bottom, 48)
            }
        }
        .padding(.horizontal, 24)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func startTimer() {
        timer = Timer.publish(every: 2.5, on: .main, in: .common)
        timerCancellable = timer.autoconnect().sink { _ in
            withAnimation(.easeInOut(duration: 0.7)) {
                currentJournal = (currentJournal + 1) % journals.count
            }
        }
    }
    
    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
}

#Preview("Journal Showcase") {
    JournalShowcaseView(currentTab: .constant(0))
        .background(Color(hex: "F5F5F5"))
}

struct WhyLoopView: View {
    @Binding var currentTab: Int
    @State private var selectedPurposes: Set<String> = []
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    private let purposes = [
        "process my day",
        "track my growth",
        "understand my emotions",
        "build self-awareness",
        "find clarity",
        "other"
    ]
    
    var body: some View {
        ZStack {
            VStack(spacing: 32) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("why do you want to loop?")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(textColor)
                        
                        Spacer()
                    }
                    
                    Text("select all that resonate")
                        .font(.system(size: 14, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(textColor.opacity(0.5))
                }
                .padding(.top, 32)
                
                // Selection cards
                VStack(spacing: 12) {
                    ForEach(purposes, id: \.self) { purpose in
                        PurposeCard(
                            text: purpose,
                            isSelected: selectedPurposes.contains(purpose),
                            onTap: {
                                withAnimation(.spring(response: 0.3)) {
                                    if selectedPurposes.contains(purpose) {
                                        selectedPurposes.remove(purpose)
                                    } else {
                                        selectedPurposes.insert(purpose)
                                    }
                                }
                            }
                        )
                    }
                }
                
                Spacer()
                
                // Continue Button
                Button(action: {
                    withAnimation {
                        currentTab += 1
                    }
                }) {
                    HStack(spacing: 12) {
                        Text("continue")
                            .font(.system(size: 18, weight: .regular))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .light))
                    }
                    .frame(height: 56)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                accentColor,
                                accentColor.opacity(0.9)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(28)
                    .shadow(color: accentColor.opacity(0.15), radius: 12, y: 6)
                }
                .opacity(selectedPurposes.isEmpty ? 0.6 : 1)
                .disabled(selectedPurposes.isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }
}

struct PurposeCard: View {
    let text: String
    let isSelected: Bool
    let onTap: () -> Void
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(text)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .white : textColor)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? accentColor : Color.white)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    WhyLoopView(currentTab: .constant(0))
}


struct StorageFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 44, height: 44)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(textColor)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(textColor)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(textColor.opacity(0.6))
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
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
