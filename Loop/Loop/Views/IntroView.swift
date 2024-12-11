//
//  IntroView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/1/24.
//

import SwiftUI
import SpriteKit

struct OnboardingView: View {
    let onIntroCompletion: () -> Void
    @ObservedObject var audioManager = AudioManager.shared

    @State private var currentStep = 0
    @State private var fadeInOpacity = 0.0
    @State private var showMockRecording = false
    @State private var recordingProgress: CGFloat = 0
    @State private var showPastLoop = false
    @State private var showInsights = false
    @State private var showStorageInfo = false
    @State private var userName = ""
    @State private var reminderTime = Date()
    @State private var selectedPurposes: Set<String> = []
    @State private var backgroundOpacity = 0.0
    @State private var waveformData: [CGFloat] = Array(repeating: 0, count: 60)
    @State private var showWaveform = false
    @State private var isPlaying = false
    @State private var progress: CGFloat = 0.3
    @State private var showInitialPrompt = true
    @State private var contentOpacity: CGFloat = 0
    
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
                    welcomeView
                        .tag(0)
                    PromptsView {
                           withAnimation {
                               currentStep = 2
                           }
                       }
                       .tag(1)
                        .tag(1)
                    pastLoopView
                        .tag(2)
                    insightsView
                        .tag(3)
                    purposeView
                        .tag(4)
                    storageView
                        .tag(5)
                    setupView
                        .tag(6)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentStep)
                
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
        
        private var recordingDemoView: some View {
            ZStack {
                VStack(spacing: 0) {
                    
                    Spacer()
                    
                    Text("what made you smile today?")
                        .font(.system(size: 32, weight: .light))
                        .multilineTextAlignment(.center)
                        .foregroundColor(textColor)
                        .padding(.horizontal, 32)
                    
                    if isRecording {
                        HStack(spacing: 12) {
                            PulsingDot()
                            Text("\(timeRemaining)s")
                                .font(.system(size: 26, weight: .ultraLight))
                                .foregroundColor(accentColor)
                        }
                        .transition(.opacity)
                    }
                    
                    Spacer()
                    
                    RecordButton(
                        isRecording: isRecording,
                        progress: 0
                    ) { 
                        toggleRecording()
                    }
                    .padding(.bottom, 60)
                }
            }
        }
        
        private var pastLoopView: some View {
            ZStack {
                VStack(spacing: 0) {
                    Text("then loop brings back a previous entry")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(textColor.opacity(0.6))
                        .padding(.top, 32)
                        .padding(.bottom, 40)
                    
                    Text("what made you smile today?")
                        .font(.system(size: 24, weight: .light))
                        .multilineTextAlignment(.center)
                        .foregroundColor(textColor)
                        .padding(.horizontal, 40)
                    
                    Text("September 24, 2024")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(textColor.opacity(0.6))
                        .padding(.bottom, 20)
                    
                    Spacer()
                    
                    WaveformSection(
                        waveformData: waveformData,
                        progress: 0.3,
                        showBars: true,
                        accentColor: accentColor
                    )
                    .safeAreaPadding(.horizontal, 24)
                    
                    Spacer()
                    
                    TimeSlider(progress: $progress,
                              duration: 30 ?? 0,
                              accentColor: accentColor,
                              onEditingChanged: { editing in
                        if !editing {
                            //
                        }
                    })
                    .safeAreaPadding(.horizontal, 24)
                    
                    HStack {
                        Text("0:00")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(textColor.opacity(0.6))
                        
                        Spacer()
                        
                        Circle()
                            .fill(accentColor)
                            .frame(width: 64, height: 64)
                            .shadow(color: accentColor.opacity(0.3), radius: 10, y: 5)
                            .overlay(
                                Image(systemName: "play.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .offset(x: 2)
                            )
                        
                        Spacer()
                        
                        Text("0:30")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(textColor.opacity(0.6))
                    }
                    .allowsHitTesting(false)
                    .safeAreaPadding(.horizontal, 24)
                    
                    OnboardingButton(text: "continue", icon: "arrow.right") {
                        withAnimation {
                            currentStep = 3
                        }
                    }
                    .padding(.vertical, 48)
                }
                .onAppear {
                    generateWaveform()
                }
                
            }
        }
        
        private var insightsView: some View {
            ZStack {
                VStack(spacing: 0) {
                    Text("compare then and now")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(textColor.opacity(0.6))
                        .padding(.top, 32)
                    
                    OnboardingInsightsView()
                    
                    OnboardingButton(text: "continue", icon: "arrow.right") {
                        withAnimation {
                            currentStep = 4
                        }
                    }
                    .padding(.vertical, 32)

                }
            }
        }
        
    private var purposeView: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("why do you want to loop?")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(textColor)
                    .padding(.top, 32)
                
                Text("choose what resonates")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(textColor.opacity(0.6))
            }
            
            // Scrollable purpose buttons
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(Array(purposes), id: \.self) { purpose in
                        PurposeButtonView(
                            purpose: purpose,
                            isSelected: selectedPurposes.contains(purpose)
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                if selectedPurposes.contains(purpose) {
                                    selectedPurposes.remove(purpose)
                                } else {
                                    selectedPurposes.insert(purpose)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 40)
            }
            
            // Continue button
            Button(action: {
                withAnimation {
                    currentStep = 5
                }
            }) {
                HStack(spacing: 12) {
                    Text("continue")
                        .font(.system(size: 18, weight: .light))
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
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
            .disabled(selectedPurposes.isEmpty)
            .opacity(selectedPurposes.isEmpty ? 0.6 : 1)
        }
    }
        
    private var storageView: some View {
        ZStack {
            VStack(spacing: 16) {
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
                        currentStep = 6
                    }
                }
                .padding(.bottom, 48)
            }
        }
    }
    
    private var setupView: some View {
        VStack(spacing: 0) {
            Text("personalize your loop")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(textColor)
                .padding(.top, 32)
            
            // Name Input Section
            VStack(spacing: 40) {
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(accentColor.opacity(0.2))
                            .frame(width: 6, height: 6)
                            .overlay(
                                Circle()
                                    .fill(accentColor)
                                    .frame(width: 3, height: 3)
                            )
                        
                        Text("YOUR NAME")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(accentColor)
                            .tracking(1.2)
                    }
                    
                    ZStack(alignment: .center) {
                        if userName.isEmpty {
                            Text("type your name")
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(textColor.opacity(0.3))
                        }
                        
                        TextField("", text: $userName)
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(textColor)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 8)
                    
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [
                                accentColor.opacity(0.1),
                                accentColor.opacity(0.3),
                                accentColor.opacity(0.1)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(height: 1)
                        .frame(width: 240)
                }
                .padding(.top, 40)
                
                // Time Selection Section
                VStack(spacing: 16) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(accentColor.opacity(0.2))
                            .frame(width: 6, height: 6)
                            .overlay(
                                Circle()
                                    .fill(accentColor)
                                    .frame(width: 3, height: 3)
                            )
                        
                        Text("DAILY REMINDER")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(accentColor)
                            .tracking(1.2)
                    }
                    
                    DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: 320)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                        )
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Start Button
            Button(action: {
                saveUserPreferences()
                onIntroCompletion()
            }) {
                HStack(spacing: 12) {
                    Text("begin your journey")
                        .font(.system(size: 18, weight: .light))
                    
                    Image(systemName: "mic.circle.fill")
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
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
            .disabled(userName.isEmpty)
            .opacity(userName.isEmpty ? 0.6 : 1)
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
                            Text("More secure options coming soon")
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
    
    private func saveUserPreferences() {
        UserDefaults.standard.set(userName, forKey: "userName")
        UserDefaults.standard.set(reminderTime, forKey: "reminderTime")
        
        Task {
            if await NotificationManager.shared.requestNotificationPermissions() {
                    NotificationManager.shared.scheduleDailyReminder(at: reminderTime)
            }
        }
    }

    private func toggleRecording() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isRecording.toggle()
        }
        
        if !isRecording {
            audioManager.stopRecording()
            stopTimer()
            currentStep = 2
        } else {
            startRecordingWithTimer()
        }
    }
    
    private func startRecordingWithTimer() {
        audioManager.prepareForNewRecording()
        audioManager.startRecording()
        timeRemaining = 30
        startTimer()
    }
    
    private func startTimer() {
        recordingTimer?.invalidate()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopTimer()
                audioManager.stopRecording()
                currentStep = 2
            }
        }
    }
    
    private func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
}

struct TrendDirection: RawRepresentable {
    let rawValue: Int
    
    static let up = TrendDirection(rawValue: 1)
    static let down = TrendDirection(rawValue: -1)
    static let neutral = TrendDirection(rawValue: 0)
}

struct InsightTrend: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let icon: String
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

struct LiveWaveformView: View {
    @State private var phase = 0.0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let width = size.width
                let height = size.height
                let centerY = height / 2
                
                for x in stride(from: 0, to: width, by: 3) {
                    let normalizedX = x / width
                    let amplitude = 20.0 * (1 + sin(normalizedX * 8 + phase)) / 2
                    let y = centerY + amplitude * sin(normalizedX * 15 + phase)
                    
                    let path = Path { p in
                        p.move(to: CGPoint(x: x, y: centerY - amplitude))
                        p.addLine(to: CGPoint(x: x, y: centerY + amplitude))
                    }
                    
                    context.stroke(
                        path,
                        with: .color(Color(hex: "A28497").opacity(0.3)),
                        lineWidth: 2
                    )
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

struct RecordButton: View {
    let isRecording: Bool
    let progress: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 88)
                    .shadow(color: Color(hex: "A28497").opacity(0.2), radius: 20)
                
                Circle()
                    .fill(Color(hex: "A28497"))
                    .frame(width: 74)
                
                if isRecording {
                    Circle()
                        .stroke(Color(hex: "A28497").opacity(0.2), lineWidth: 4)
                        .frame(width: 96)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color(hex: "A28497"), lineWidth: 4)
                        .frame(width: 96)
                        .rotationEffect(.degrees(-90))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                }
                
                if isRecording {
                    PulsingRing(color: Color(hex: "A28497"))
                }
            }
        }
    }
}

struct PromptsView: View {
    let onContinue: () -> Void
    
    @State private var currentPromptIndex = 0
    @State private var isTimerVisible = false
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    private let backgroundColor = Color(hex: "FAFBFC")
    
    private let prompt = (category: "growth", prompt: "what made you smile today?")
    
    @State var isRecording: Bool = false
    @State private var timeRemaining: Int = 30
    
    @State private var recordingTimer: Timer?
    
    var body: some View {
        VStack(spacing: 0) {
            // Category pill
            HStack(spacing: 8) {
                Circle()
                    .fill(accentColor.opacity(0.2))
                    .frame(width: 6, height: 6)
                
                Text(prompt.category)
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(accentColor.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(accentColor.opacity(0.1))
            )
            .padding(.top, 16)
            
            // Progress dots
            ProgressIndicator(
                totalSteps: 3,
                currentStep: currentPromptIndex,
                accentColor: accentColor
            )
            .padding(.vertical, 24)
            
            // Description section
            VStack(spacing: 16) {
                Text("record your first loop")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(textColor.opacity(0.6))
            }
            
            Spacer()
            
            // Main prompt
            VStack(spacing: 32) {
                Text(prompt.prompt)
                    .font(.system(size: 44, weight: .ultraLight))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
                    .animation(.easeInOut, value: currentPromptIndex)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 20)
            
            if isRecording {
                HStack(spacing: 12) {
                    PulsingDot()
                    Text("\(timeRemaining)s")
                        .font(.system(size: 26, weight: .ultraLight))
                        .foregroundColor(accentColor)
                }
                .transition(.opacity)
            }
            Spacer()
            
           
            VStack (spacing: 12) {
                recordingButton
                // Continue button
                Button(action: {
                    withAnimation {
                        onContinue()
                    }
                }) {
                    Text("skip")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(.gray)
                        .underline()
                }
            }
            .padding(.bottom, 30)
        }
        .onAppear {
            isTimerVisible = true
        }
    }
    
    private var recordingButton: some View {
        Button(action: {
            withAnimation {
                toggleRecording()
            }
        }) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 96)
                    .shadow(color: accentColor.opacity(0.2), radius: 20, x: 0, y: 8)

                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                isRecording ? accentColor : .white,
                                isRecording ? accentColor.opacity(0.9) : .white
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                
                if isRecording {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white)
                        .frame(width: 26, height: 26)
                } else {
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
                        .frame(width: 74)
                }
            
                if isRecording {
                    PulsingRing(color: accentColor)
                }
            }
            .scaleEffect(isRecording ? 1.08 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isRecording)
        }
    }
    
    private func toggleRecording() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isRecording.toggle()
        }
        
        if !isRecording {
            stopTimer()
        } else {
            startRecordingWithTimer()
        }
    }
    
    private func startRecordingWithTimer() {
        timeRemaining = 30
        startTimer()
    }
    
    private func startTimer() {
        recordingTimer?.invalidate()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopTimer()
            }
        }
    }
    
    private func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }

}

struct OnboardingProgressIndicator: View {
    let totalSteps: Int
    let currentStep: Int
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Circle()
                    .fill(currentStep >= index ? accentColor : accentColor.opacity(0.2))
                    .frame(width: 8, height: 8)
            }
        }
    }
}


struct OnboardingInsightsView: View {
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    private let backgroundColor = Color(hex: "FAFBFC")
    private let surfaceColor = Color(hex: "F8F5F7")
    
    @State private var selectedTimeframe = 0
    private let timeframes = ["Today", "This Week", "This Month"]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Timeframe selector
                HStack(spacing: 12) {
                    ForEach(Array(timeframes.enumerated()), id: \.offset) { index, timeframe in
                        Button(action: {
                            withAnimation { selectedTimeframe = index }
                        }) {
                            Text(timeframe)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(selectedTimeframe == index ? .white : textColor)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(selectedTimeframe == index ? accentColor : Color.white)
                                )
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                        }
                    }
                }
                .padding(.top, 16)
                
                // AI Analysis Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(accentColor.opacity(0.2))
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .fill(accentColor)
                                    .frame(width: 4, height: 4)
                            )
                        
                        Text("AI ANALYSIS")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(accentColor)
                            .tracking(1.2)
                    }
                    
                    Text("Contemplative")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(textColor)
                    
                    Text("Your reflections today show deep introspection and thoughtful consideration of personal experiences, with a focus on emotional awareness.")
                        .font(.system(size: 16))
                        .foregroundColor(textColor.opacity(0.7))
                        .lineSpacing(4)
                }
                .padding(24)
                .background(
                    ZStack {
                        Color.white
                        
                        WavyBackground()
                            .background(surfaceColor)
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                
                // Expression Stats
                HStack(spacing: 16) {
                    // Speaking Pace Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "waveform")
                                .foregroundColor(accentColor)
                            
                            Text("Speaking Pace")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(textColor)
                        }
                        
                        Text("142")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(textColor)
                        
                        Text("words/min")
                            .font(.system(size: 14))
                            .foregroundColor(textColor.opacity(0.6))
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    
                    // Duration Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(accentColor)
                            
                            Text("Duration")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(textColor)
                        }
                        
                        Text("1:45")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(textColor)
                        
                        Text("minutes")
                            .font(.system(size: 14))
                            .foregroundColor(textColor.opacity(0.6))
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                }
                
                // Sentiment Timeline
                VStack(alignment: .leading, spacing: 20) {
                    Text("Emotional Journey")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(textColor)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(["Morning", "Afternoon", "Evening"], id: \.self) { time in
                            HStack(spacing: 12) {
                                Text(time)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(textColor.opacity(0.6))
                                    .frame(width: 80, alignment: .leading)
                                
                                Circle()
                                    .fill(accentColor)
                                    .frame(width: 8, height: 8)
                                
                                Text(getMockSentiment(for: time))
                                    .font(.system(size: 15))
                                    .foregroundColor(textColor)
                            }
                        }
                    }
                }
                .padding(24)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                
                // Common Themes
                VStack(alignment: .leading, spacing: 20) {
                    Text("Recurring Themes")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(textColor)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(mockThemes, id: \.self) { theme in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(accentColor)
                                    .frame(width: 4, height: 4)
                                
                                Text(theme)
                                    .font(.system(size: 15, weight: .medium))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(accentColor.opacity(0.15), lineWidth: 1)
                                    .background(surfaceColor)
                            )
                        }
                    }
                }
                .padding(24)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }
    
    private func getMockSentiment(for time: String) -> String {
        switch time {
        case "Morning": return "Energetic and motivated"
        case "Afternoon": return "Focused and productive"
        case "Evening": return "Peaceful and reflective"
        default: return ""
        }
    }
    
    private let mockThemes = [
        "gratitude",
        "personal growth",
        "relationships",
        "achievement",
        "wellbeing",
        "creativity"
    ]
}

struct PurposeButtonView: View {
    let purpose: String
    let isSelected: Bool
    let action: () -> Void
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(accentColor.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 26, height: 26)
                    
                    if isSelected {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 26, height: 26)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                            )
                    }
                }
                
                // Purpose text
                Text(purpose)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(textColor)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(
                        color: isSelected ? accentColor.opacity(0.1) : Color.black.opacity(0.05),
                        radius: isSelected ? 12 : 8,
                        y: 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? accentColor.opacity(0.2) : Color.clear,
                        lineWidth: 1
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

#Preview {
    OnboardingView {
        print("Onboarding completed")
    }
}
