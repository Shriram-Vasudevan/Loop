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
    @State private var slideOffset = CGSize(width: 0, height: 50)
    @State private var showMockRecording = false
    @State private var recordingProgress: CGFloat = 0
    @State private var showInsights = false
    @State private var showStorageInfo = false
    @State private var userName = ""
    @State private var reminderTime = Date()
    @State private var selectedPurposes: Set<String> = []
    @State private var backgroundOpacity = 0.0
    @State private var showPastLoop = false
    @State private var showPastLoopDate = false
    
    let accentColor = Color(hex: "A28497")
    let textColor = Color(hex: "2C3E50")
    
    private let purposes = [
        "capture moments",
        "reflect daily",
        "track growth",
        "build mindfulness",
        "understand myself"
    ]
    
    private let mockInsightWords = [
        "gratitude", "family", "growth", "peaceful",
        "learning", "progress", "gentle", "clarity",
        "present", "mindful", "strength", "journey"
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
                welcomeView.tag(0)
                recordingDemoView.tag(1)
                insightsView.tag(2)
                purposeView.tag(3)
                storageView.tag(4)
                setupView.tag(5)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentStep)
            
            if showStorageInfo {
                storageInfoOverlay
            }
        }
        .preferredColorScheme(.light)
    }
    
    private var welcomeView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 24) {
                Text("welcome to loop")
                    .font(.system(size: 44, weight: .ultraLight))
                    .foregroundColor(textColor)
                    .opacity(fadeInOpacity)
                    .offset(slideOffset)
                
                Text("start micro-journaling")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(textColor.opacity(0.6))
                    .opacity(fadeInOpacity)
                    .offset(slideOffset)
            }
            
            Spacer()
            
            FloatingButton(text: "begin", icon: "arrow.right") {
                withAnimation {
                    currentStep = 1
                }
            }
            .opacity(fadeInOpacity)
            .padding(.bottom, 60)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1)) {
                fadeInOpacity = 1
                slideOffset = .zero
            }
        }
    }
    
    private var recordingDemoView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            if showPastLoop {
                pastLoopPreview
            } else {
                recordingPreview
            }
            
            Spacer()
            
            FloatingButton(
                text: showPastLoop ? "next" : "save recording",
                icon: "arrow.right"
            ) {
                if showPastLoop {
                    withAnimation {
                        currentStep = 2
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        showPastLoop = true
                    }
                }
            }
            .padding(.bottom, 60)
        }
    }
    
    private var recordingPreview: some View {
        VStack(spacing: 32) {
            Text("record your first loop")
                .font(.system(size: 32, weight: .ultraLight))
                .foregroundColor(textColor)
            
            PromptCard(
                prompt: "What made you smile today?",
                isRecording: showMockRecording,
                progress: recordingProgress,
                accentColor: accentColor
            )
            .onAppear {
                startRecordingDemo()
            }
        }
    }
    
    private var pastLoopPreview: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("complete the loop")
                    .font(.system(size: 32, weight: .ultraLight))
                    .foregroundColor(textColor)
                
                HStack(spacing: 4) {
                    Text("from")
                        .font(.system(size: 18, weight: .light))
                    Text("March 24")
                        .font(.system(size: 18, weight: .medium))
                }
                .foregroundColor(accentColor)
                .opacity(showPastLoopDate ? 1 : 0)
                .animation(.easeIn(duration: 0.4).delay(0.2), value: showPastLoopDate)
            }
            
            PromptCard(
                prompt: "What made you smile today?",
                showPlayback: true,
                accentColor: accentColor
            )
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .scale.combined(with: .opacity)
            ))
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    showPastLoopDate = true
                }
            }
        }
    }
    
    private var insightsView: some View {
        VStack(spacing: 40) {
            Text("discover patterns")
                .font(.system(size: 32, weight: .ultraLight))
                .foregroundColor(textColor)
                .padding(.top, 60)
            
            ZStack {
                if showInsights {
                    WordCloudView(words: mockInsightWords)
                        .frame(height: 300)
                }
            }
            
            VStack(spacing: 24) {
                OnboardingInsightCard(
                    icon: "waveform",
                    title: "speaking rhythm",
                    detail: "naturally paced reflection",
                    accentColor: accentColor
                )
                
                OnboardingInsightCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "emotional journey",
                    detail: "growing self-awareness",
                    accentColor: accentColor
                )
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            FloatingButton(text: "explore more", icon: "arrow.right") {
                withAnimation {
                    currentStep = 3
                }
            }
            .padding(.bottom, 60)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                showInsights = true
            }
        }
    }
    
    private var purposeView: some View {
        VStack(spacing: 32) {
            Text("why do you want to loop?")
                .font(.system(size: 32, weight: .ultraLight))
                .foregroundColor(textColor)
                .padding(.top, 60)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(purposes, id: \.self) { purpose in
                        PurposeCard(
                            purpose: purpose,
                            isSelected: selectedPurposes.contains(purpose),
                            accentColor: accentColor
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
                .padding(.horizontal, 32)
                .padding(.vertical, 20)
            }
            
            Spacer()
            
            FloatingButton(text: "continue", icon: "arrow.right") {
                withAnimation {
                    currentStep = 4
                }
            }
            .padding(.bottom, 60)
            .disabled(selectedPurposes.isEmpty)
            .opacity(selectedPurposes.isEmpty ? 0.6 : 1)
        }
    }
    
    private var storageView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("your journal is for you")
                    .font(.system(size: 32, weight: .ultraLight))
                    .foregroundColor(textColor)
                
                Text("secured with iCloud backup")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(textColor.opacity(0.6))
            }
            .padding(.top, 60)
            
            Spacer()
            
            VStack(spacing: 24) {
                Button {
                    withAnimation(.spring(response: 0.4)) {
                        showStorageInfo = true
                    }
                } label: {
                    Text("(but what about storage space?)")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(accentColor)
                }
                
                FloatingButton(text: "finish setup", icon: "arrow.right") {
                    withAnimation {
                        currentStep = 5
                    }
                }
            }
            .padding(.bottom, 60)
        }
    }
    
    private var storageInfoOverlay: some View {
        ZStack {
            Color.black.opacity(0.2)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation(.spring(response: 0.4)) {
                        showStorageInfo = false
                    }
                }
            
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text("Optimized for You")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(textColor)
                    
                    Text("Record hundreds of loops without worrying about storage. We've optimized each recording to take minimal space while maintaining perfect quality.")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(textColor.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    Text("Looking ahead: We're working on additional secure storage options to give you more choices while maintaining the same level of privacy.")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(textColor.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
                
                Button {
                    withAnimation(.spring(response: 0.4)) {
                        showStorageInfo = false
                    }
                } label: {
                    Text("Got it")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(accentColor)
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
    
    private var setupView: some View {
        VStack(spacing: 40) {
            Text("one last step")
                .font(.system(size: 32, weight: .ultraLight))
                .foregroundColor(textColor)
                .padding(.top, 60)
            
            VStack(spacing: 32) {
                CustomTextField(
                    text: $userName,
                    placeholder: "your name",
                    imageName: "person"
                )
                .padding(.horizontal, 48)
                
                VStack(spacing: 16) {
                    Text("when should we remind you to loop?")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(textColor)
                    
                    DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxHeight: 100)
                }
            }
            
            Spacer()
            
            FloatingButton(text: "start looping", icon: "mic.circle.fill") {
                saveUserPreferences()
                onIntroCompletion()
            }
            .padding(.bottom, 60)
            .disabled(userName.isEmpty)
            .opacity(userName.isEmpty ? 0.6 : 1)
        }
    }
    
    private func startRecordingDemo() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                showMockRecording = true
            }
            
            withAnimation(.linear(duration: 3)) {
                recordingProgress = 1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    showMockRecording = false
                    recordingProgress = 0
                }
            }
        }
    }
    
    private func saveUserPreferences() {
        UserDefaults.standard.set(userName, forKey: "userName")
        UserDefaults.standard.set(reminderTime, forKey: "reminderTime")
    }
}


struct PromptCard: View {
    let prompt: String
    var isRecording: Bool = false
    var progress: CGFloat = 0
    var showPlayback: Bool = false
    let accentColor: Color
    
    @State private var waveformOpacity = 0.0
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 20)
            
            VStack(spacing: 24) {
                Text(prompt)
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(Color(hex: "2C3E50"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                if isRecording || showPlayback {
                    LiveWaveform()
                        .frame(height: 60)
                        .padding(.horizontal, 40)
                        .opacity(waveformOpacity)
                }
                
                if showPlayback {
                    PlaybackButton(accentColor: accentColor)
                } else {
                    RecordingButton(
                        isRecording: isRecording,
                        progress: progress,
                        accentColor: accentColor
                    )
                }
            }
            .padding(.vertical, 40)
        }
        .frame(height: 300)
        .padding(.horizontal, 32)
        .onAppear {
            if isRecording || showPlayback {
                withAnimation(.easeIn(duration: 0.4).delay(0.2)) {
                    waveformOpacity = 1
                }
            }
        }
    }
}

struct RecordingButton: View {
    let isRecording: Bool
    let progress: CGFloat
    let accentColor: Color
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 88)
                .shadow(color: accentColor.opacity(0.2), radius: 20)
            
            Circle()
                .fill(accentColor)
                .frame(width: 74)
            
            if isRecording {
                Circle()
                    .stroke(accentColor.opacity(0.2), lineWidth: 4)
                    .frame(width: 96)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(accentColor, lineWidth: 4)
                    .frame(width: 96)
                    .rotationEffect(.degrees(-90))
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
            }
        }
    }
}

struct PlaybackButton: View {
    let accentColor: Color
    @State private var isPlaying = false
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                isPlaying.toggle()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 88)
                    .shadow(color: accentColor.opacity(0.2), radius: 20)
                
                Circle()
                    .fill(accentColor)
                    .frame(width: 74)
                
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                    .offset(x: isPlaying ? 0 : 2)
            }
        }
    }
}

struct LiveWaveform: View {
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

struct WordCloudView: View {
    let words: [String]
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(words.indices, id: \.self) { index in
                WordBubble(
                    word: words[index],
                    index: index,
                    totalCount: words.count,
                    size: geometry.size
                )
            }
        }
    }
}

struct WordBubble: View {
    let word: String
    let index: Int
    let totalCount: Int
    let size: CGSize
    
    @State private var position: CGPoint = .zero
    @State private var scale: CGFloat = 0
    
    var body: some View {
        Text(word)
            .font(.system(size: fontSize, weight: .light))
            .foregroundColor(Color(hex: "A28497").opacity(opacity))
            .position(x: position.x, y: position.y)
            .scaleEffect(scale)
            .onAppear {
                let angle = (2 * .pi * Double(index)) / Double(totalCount)
                let radius = min(size.width, size.height) * 0.35
                position = CGPoint(
                    x: size.width/2 + radius * cos(angle),
                    y: size.height/2 + radius * sin(angle)
                )
                
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(Double(index) * 0.1)) {
                    scale = 1
                }
            }
    }
    
    private var fontSize: CGFloat {
        [24, 20, 18, 22, 19, 21][index % 6]
    }
    
    private var opacity: Double {
        [0.9, 0.7, 0.8, 0.6, 0.85][index % 5]
    }
}

struct FloatingButton: View {
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
            .frame(height: 60)
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
            .cornerRadius(30)
            .shadow(color: Color(hex: "A28497").opacity(0.15), radius: 12, y: 6)
            .padding(.horizontal, 32)
        }
    }
}

struct OnboardingInsightCard: View {
    let icon: String
    let title: String
    let detail: String
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(Color(hex: "2C3E50").opacity(0.6))
                
                Text(detail)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(hex: "2C3E50"))
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
        )
    }
}

struct PurposeCard: View {
    let purpose: String
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(purpose)
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(isSelected ? .white : Color(hex: "2C3E50"))
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 24)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? accentColor : Color.white)
                    .shadow(
                        color: isSelected ? accentColor.opacity(0.3) : Color.black.opacity(0.05),
                        radius: 8,
                        y: 4
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let imageName: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                Image(systemName: imageName)
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(Color(hex: "A28497"))
                
                TextField(placeholder, text: $text)
                    .font(.system(size: 18, weight: .light))
            }
            .padding(.vertical, 16)
            
            Rectangle()
                .fill(Color(hex: "A28497").opacity(0.2))
                .frame(height: 1)
        }
    }
}

#Preview {
    OnboardingView {
        print("Onboarding completed")
    }
}

