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
    @State private var insightTrends: [InsightTrend] = []
    
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
                .opacity(backgroundOpacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.2)) {
                        backgroundOpacity = 1
                    }
                }
            
            TabView(selection: $currentStep) {
                welcomeView
                    .tag(0)
                recordingDemoView
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
        VStack {
            Spacer()
            
            VStack(spacing: 8) {
                Text("welcome to loop")
                    .font(.system(size: 38, weight: .ultraLight))
                    .foregroundColor(textColor)
                    .opacity(fadeInOpacity)
                
                Text("start micro-journaling")
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
            withAnimation(.easeOut(duration: 1)) {
                fadeInOpacity = 1
            }
        }
    }

        private var recordingDemoView: some View {
            VStack(spacing: 0) {
                topBar
                    .padding(.top, 16)
                
                Spacer()
                
                Text("What made you smile today?")
                    .font(.system(size: 32, weight: .light))
                    .multilineTextAlignment(.center)
                    .foregroundColor(textColor)
                    .padding(.horizontal, 32)
                    .opacity(showMockRecording ? 0.6 : 1)
                
                if showMockRecording {
                    LiveWaveformView()
                        .frame(height: 80)
                        .padding(.top, 40)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                
                RecordButton(
                    isRecording: showMockRecording,
                    progress: recordingProgress
                ) {
                    withAnimation(.spring(response: 0.6)) {
                        showMockRecording = true
                        startRecordingDemo()
                    }
                }
                .padding(.bottom, 60)
            }
        }
        
        private var pastLoopView: some View {
            VStack(spacing: 0) {
                HStack {
                    Button {
                        withAnimation {
                            currentStep -= 1
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(textColor.opacity(0.6))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                VStack(spacing: 8) {
                    Text("from your past")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(textColor.opacity(0.6))
                    
                    Text("September 24")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(accentColor)
                }
                .padding(.top, 32)
                
                Spacer()
                
                VStack(spacing: 24) {
                    Text("What made you smile today?")
                        .font(.system(size: 32, weight: .light))
                        .multilineTextAlignment(.center)
                        .foregroundColor(textColor)
                        .padding(.horizontal, 32)
                    
                    if showWaveform {
                        WaveformView(waveformData: waveformData, color: accentColor)
//                        .frame(height: 80)
                        .padding(.horizontal, 32)
                    }
                }
                
                Spacer()
                
                OnboardingButton(text: "see your growth", icon: "arrow.right") {
                    withAnimation {
                        currentStep = 3
                    }
                }
                .padding(.bottom, 48)
            }
            .onAppear {
                generateWaveformData()
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
                    }
                }
            }
        }
        
        private var topBar: some View {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("record your first loop")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(accentColor)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        
        private func startRecordingDemo() {
            withAnimation(.linear(duration: 3)) {
                recordingProgress = 1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    currentStep = 2
                }
            }
        }
        
        private func generateWaveformData() {
            waveformData = (0..<60).map { _ in
                CGFloat.random(in: 12...64)
            }
            withAnimation(.easeOut(duration: 0.4)) {
                showWaveform = true
            }
        }

        private var insightsView: some View {
            ZStack {
                FloatingInsights()
                
                VStack(spacing: 0) {
                    HStack {
                        Text("trends in your growth")
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(textColor)
                            .padding(.top, 32)
                    }
                    .padding(.horizontal, 24)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 32) {
                            GrowthComparison()
                                .padding(.top, 40)
                            
                            InsightsTrends()
                                .padding(.horizontal, 24)
                            
                            OnboardingButton(text: "continue", icon: "arrow.right") {
                                withAnimation {
                                    currentStep = 4
                                }
                            }
                            .padding(.vertical, 32)
                        }
                    }
                }
            }
        }
        
        struct FloatingInsights: View {
            let insights = [
                "gratitude", "family", "progress",
                "mindful", "growth", "peaceful"
            ]
            
            var body: some View {
                ZStack {
                    ForEach(insights.indices, id: \.self) { index in
                        FloatingWord(
                            word: insights[index],
                            initialOffset: randomOffset(),
                            delay: Double(index) * 0.2
                        )
                    }
                }
                .opacity(0.15)
            }
            
            private func randomOffset() -> CGSize {
                CGSize(
                    width: CGFloat.random(in: -100...100),
                    height: CGFloat.random(in: -100...100)
                )
            }
        }
        
        struct FloatingWord: View {
            let word: String
            let initialOffset: CGSize
            let delay: Double
            
            @State private var opacity = 0.0
            @State private var offset: CGSize
            
            init(word: String, initialOffset: CGSize, delay: Double) {
                self.word = word
                self.initialOffset = initialOffset
                self.delay = delay
                _offset = State(initialValue: initialOffset)
            }
            
            var body: some View {
                Text(word)
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(Color(hex: "A28497"))
                    .offset(offset)
                    .opacity(opacity)
                    .onAppear {
                        withAnimation(.easeOut(duration: 1).delay(delay)) {
                            opacity = 1
                            offset = CGSize(
                                width: initialOffset.width * 0.5,
                                height: initialOffset.height * 0.5
                            )
                        }
                        
                        withAnimation(
                            .easeInOut(duration: 4)
                            .repeatForever(autoreverses: true)
                            .delay(delay)
                        ) {
                            offset = CGSize(
                                width: initialOffset.width * -0.3,
                                height: initialOffset.height * -0.3
                            )
                        }
                    }
            }
        }
        
        struct GrowthComparison: View {
            var body: some View {
                VStack(spacing: 24) {
                    HStack(alignment: .top, spacing: 32) {
                        TrendColumn(
                            title: "Then",
                            date: "September",
                            content: "Finding joy in morning coffee",
                            trend: .neutral
                        )
                        
                        TrendColumn(
                            title: "Now",
                            date: "November",
                            content: "Grateful for family breakfast conversations",
                            trend: .up
                        )
                    }
                    .padding(.horizontal, 32)
                    
                    GrowthIndicator()
                }
            }
        }
        
        struct TrendColumn: View {
            let title: String
            let date: String
            let content: String
            let trend: TrendDirection
            
            var body: some View {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "2C3E50").opacity(0.6))
                        
                        if trend != .neutral {
                            Image(systemName: trend == .up ? "arrow.up" : "arrow.down")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(trend == .up ? Color(hex: "6FCF97") : Color(hex: "EB5757"))
                        }
                    }
                    
                    Text(date)
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(Color(hex: "2C3E50").opacity(0.4))
                    
                    Text(content)
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(Color(hex: "2C3E50"))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        
        struct GrowthIndicator: View {
            var body: some View {
                HStack(spacing: 4) {
                    ForEach(0..<5) { index in
                        Circle()
                            .fill(Color(hex: "6FCF97").opacity(Double(index + 1) / 5))
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
        
        struct InsightsTrends: View {
            let trends = [
                InsightTrend(
                    title: "More reflective",
                    detail: "Your loops are getting deeper",
                    icon: "arrow.up.right"
                ),
                InsightTrend(
                    title: "Future focused",
                    detail: "Growing optimism in your words",
                    icon: "sun.max"
                ),
                InsightTrend(
                    title: "Family connection",
                    detail: "Frequent theme in your loops",
                    icon: "heart"
                )
            ]
            
            var body: some View {
                VStack(spacing: 16) {
                    ForEach(trends) { trend in
                        TrendRow(trend: trend)
                    }
                }
            }
        }
        
        struct TrendRow: View {
            let trend: InsightTrend
            
            var body: some View {
                HStack(spacing: 16) {
                    Image(systemName: trend.icon)
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "A28497"))
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(trend.title)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color(hex: "2C3E50"))
                        
                        Text(trend.detail)
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(Color(hex: "2C3E50").opacity(0.6))
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 12)
            }
        }

        private var purposeView: some View {
            VStack(spacing: 0) {
                Text("why do you want to loop?")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(textColor)
                    .padding(.top, 32)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        ForEach(purposes, id: \.self) { purpose in
                            PurposeButton(
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
                
                OnboardingButton(text: "next", icon: "arrow.right") {
                    withAnimation {
                        currentStep = 5
                    }
                }
                .padding(.bottom, 48)
                .disabled(selectedPurposes.isEmpty)
                .opacity(selectedPurposes.isEmpty ? 0.6 : 1)
            }
        }
        
        private var storageView: some View {
            ZStack {
                VStack(spacing: 24) {
                    Spacer()
                    
                    CloudAnimation()
                        .frame(height: 120)
                    
                    VStack(spacing: 8) {
                        Text("your journal is for you")
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(textColor)
                        
                        Text("secured with iCloud backup")
                            .font(.system(size: 18, weight: .light))
                            .foregroundColor(textColor.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.spring(response: 0.4)) {
                            showStorageInfo = true
                        }
                    } label: {
                        Label("what about storage space?", systemImage: "questionmark.circle")
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
        
        struct PurposeButton: View {
            let purpose: String
            let isSelected: Bool
            let action: () -> Void
            
            var body: some View {
                Button(action: action) {
                    HStack(spacing: 16) {
                        Circle()
                            .stroke(Color(hex: "A28497"), lineWidth: 2)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .fill(Color(hex: "A28497"))
                                    .frame(width: 16, height: 16)
                                    .opacity(isSelected ? 1 : 0)
                            )
                        
                        Text(purpose)
                            .font(.system(size: 18, weight: .light))
                            .foregroundColor(Color(hex: "2C3E50"))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 64)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(
                                color: isSelected ? Color(hex: "A28497").opacity(0.2) : Color.black.opacity(0.05),
                                radius: isSelected ? 12 : 8,
                                y: 4
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "A28497").opacity(isSelected ? 0.3 : 0))
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        
        struct CloudAnimation: View {
            @State private var isAnimating = false
            
            var body: some View {
                ZStack {
                    Image(systemName: "icloud")
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
                            
                            Text("Each 30-second loop is perfectly optimized, letting you record hundreds of moments without storage concerns.")
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

        private var setupView: some View {
            VStack(spacing: 0) {
                Text("personalize your loop")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(textColor)
                    .padding(.top, 32)
                
                VStack(spacing: 40) {
                    VStack(spacing: 8) {
                        ZStack {
                            if userName.isEmpty {
                                Text("your name")
                                    .font(.system(size: 32, weight: .light))
                                    .foregroundColor(textColor.opacity(0.3))
                            }
                            
                            TextField("", text: $userName)
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(textColor)
                                .multilineTextAlignment(.center)
                        }
                        
                        Rectangle()
                            .fill(accentColor.opacity(0.2))
                            .frame(height: 1)
                            .frame(width: 200)
                    }
                    .padding(.top, 40)
                    
                    VStack(spacing: 16) {
                        Text("when do you want to loop?")
                            .font(.system(size: 18, weight: .light))
                            .foregroundColor(textColor)
                        
                        TimeSelectionWheel(selectedTime: $reminderTime)
                    }
                }
                
                Spacer()
                
                OnboardingButton(text: "start looping", icon: "mic.circle.fill") {
                    saveUserPreferences()
                    onIntroCompletion()
                }
                .padding(.bottom, 48)
                .disabled(userName.isEmpty)
                .opacity(userName.isEmpty ? 0.6 : 1)
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
            ReminderManager.shared.requestNotificationPermissions { success in
                if success {
                    ReminderManager.shared.scheduleDailyReminder(at: reminderTime)
                }
            }
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

    #Preview {
        OnboardingView {
            print("Onboarding completed")
        }
    }
