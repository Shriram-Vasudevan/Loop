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
    @State private var backgroundOpacity = 0.0
    @State private var contentOpacity: CGFloat = 0
    
    // User selections and state
    @State private var selectedPurposes: Set<String> = []
    @State private var selectedReflectionStyles: Set<String> = []
    @State private var selectedEmotionalChallenges: Set<String> = []
    @State private var userName = ""
    
    let accentColor = Color(hex: "A28497")
    let textColor = Color(hex: "2C3E50")
    
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
                ReflectionStyleView(currentTab: $currentStep, selectedStyles: $selectedReflectionStyles)
                    .edgesIgnoringSafeArea(.all)
                    .tag(2)
                EmotionalIntelligenceView(currentTab: $currentStep, selectedChallenges: $selectedEmotionalChallenges)
                    .edgesIgnoringSafeArea(.all)
                    .tag(3)
                PatternRecognitionView(currentTab: $currentStep)
                    .edgesIgnoringSafeArea(.all)
                    .tag(4)
                PrivacyStorageView(currentTab: $currentStep, onIntroCompletion: {
                    FirstLaunchManager.shared.showTutorial = true
                    saveUserPreferences()
                })
                    .tag(5)
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
        // Save all user selections
        UserDefaults.standard.set(Array(selectedPurposes), forKey: "selectedPurposes")
        UserDefaults.standard.set(Array(selectedReflectionStyles), forKey: "selectedReflectionStyles")
        UserDefaults.standard.set(Array(selectedEmotionalChallenges), forKey: "selectedEmotionalChallenges")
        
        DispatchQueue.main.async {
            onIntroCompletion()
        }
    }
}

// Modified to focus on growth intentions
struct WhyLoopView: View {
    @Binding var currentTab: Int
    @State private var selectedPurposes: Set<String> = []
    @State private var appearAnimation: [Bool] = Array(repeating: false, count: 9)
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    private let purposes = [
        (icon: "sun.max", text: "greater self-awareness"),
        (icon: "brain", text: "better decision-making"),
        (icon: "sparkles", text: "recognizing behavior patterns"),
        (icon: "sparkle", text: "clarity in personal values"),
        (icon: "leaf", text: "track my growth"),
        (icon: "ellipsis", text: "other")
    ]
    
    var body: some View {
        ZStack {
            VStack(spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("set your growth intentions")
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
                    .opacity(appearAnimation[8] ? 1 : 0)
                    .offset(y: appearAnimation[8] ? 0 : 20)
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

// New View: Reflection Style Assessment
struct ReflectionStyleView: View {
    @Binding var currentTab: Int
    @Binding var selectedStyles: Set<String>
    @State private var appearAnimation: [Bool] = Array(repeating: false, count: 8)
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    private let reflectionStyles = [
        (icon: "mouth", text: "I process verbally - speaking helps me think"),
        (icon: "list.bullet", text: "I'm detail-oriented and remember specifics"),
        (icon: "heart", text: "I focus on emotions and how experiences make me feel"),
        (icon: "rectangle.3.group", text: "I connect dots between different experiences"),
        (icon: "ellipsis", text: "other")
    ]
    
    var body: some View {
        ZStack {
            VStack(spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("discover your reflection style")
                            .font(.system(size: 26, weight: .medium))
                            .foregroundColor(textColor)
                            .opacity(appearAnimation[0] ? 1 : 0)
                            .offset(y: appearAnimation[0] ? 0 : 20)
                        
                        Spacer()
                    }
                    
                    Text("how do you naturally process your thoughts?")
                        .font(.system(size: 16, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(textColor.opacity(0.6))
                        .opacity(appearAnimation[1] ? 1 : 0)
                }
                .padding(.top, 64)

                VStack(spacing: 8) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            ForEach(Array(reflectionStyles.enumerated()), id: \.element.text) { index, style in
                                EnhancedPurposeCard(
                                    icon: style.icon,
                                    text: style.text,
                                    isSelected: selectedStyles.contains(style.text),
                                    onTap: {
                                        withAnimation(.spring(response: 0.3)) {
                                            if selectedStyles.contains(style.text) {
                                                selectedStyles.remove(style.text)
                                            } else {
                                                selectedStyles.insert(style.text)
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
                    .opacity(selectedStyles.isEmpty ? 0.6 : 1)
                    .disabled(selectedStyles.isEmpty)
                    .opacity(appearAnimation[7] ? 1 : 0)
                    .offset(y: appearAnimation[7] ? 0 : 20)
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

// New View: Emotional Intelligence Check
struct EmotionalIntelligenceView: View {
    @Binding var currentTab: Int
    @Binding var selectedChallenges: Set<String>
    @State private var appearAnimation: [Bool] = Array(repeating: false, count: 7)
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    private let emotionalChallenges = [
        (icon: "questionmark.circle", text: "Identifying what I'm actually feeling"),
        (icon: "link", text: "Connecting emotions to specific triggers"),
        (icon: "chart.xyaxis.line", text: "Finding patterns in my emotional responses"),
        (icon: "rectangle.and.text.magnifyingglass", text: "Separating emotions from thoughts"),
        (icon: "ellipsis", text: "other")
    ]
    
    var body: some View {
        ZStack {
            VStack(spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("understand your emotional landscape")
                            .font(.system(size: 26, weight: .medium))
                            .foregroundColor(textColor)
                            .opacity(appearAnimation[0] ? 1 : 0)
                            .offset(y: appearAnimation[0] ? 0 : 20)
                        
                        Spacer()
                    }
                    
                    Text("when reflecting, what do you find challenging?")
                        .font(.system(size: 16, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(textColor.opacity(0.6))
                        .opacity(appearAnimation[1] ? 1 : 0)
                }
                .padding(.top, 64)

                VStack(spacing: 8) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            ForEach(Array(emotionalChallenges.enumerated()), id: \.element.text) { index, challenge in
                                EnhancedPurposeCard(
                                    icon: challenge.icon,
                                    text: challenge.text,
                                    isSelected: selectedChallenges.contains(challenge.text),
                                    onTap: {
                                        withAnimation(.spring(response: 0.3)) {
                                            if selectedChallenges.contains(challenge.text) {
                                                selectedChallenges.remove(challenge.text)
                                            } else {
                                                selectedChallenges.insert(challenge.text)
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
                    .opacity(selectedChallenges.isEmpty ? 0.6 : 1)
                    .disabled(selectedChallenges.isEmpty)
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

// New View: Pattern Recognition Demo
struct PatternRecognitionView: View {
    @Binding var currentTab: Int
    @State private var appearAnimation: [Bool] = Array(repeating: false, count: 10)
    @State private var wordBubbles: [WordBubble] = []
    @State private var showInsights = false
    @State private var insightOpacity: [Double] = [0, 0, 0]
    @State private var pulsateCircle = false
    @State private var expandLines = false
    @State private var showConnections = false
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    // Sample reflection data
    private let sampleReflections = [
        "Today I felt anxious about my presentation at work but was relieved when it was over",
        "Meeting with Sarah made me feel supported. I'm grateful for friends like her",
        "Frustrated with the traffic today. It always puts me in a bad mood",
        "Started the day feeling motivated but ended exhausted. Need to manage energy better",
        "Family dinner was wonderful. Feeling connected and loved"
    ]
    
    // Sample insights
    private let insights = [
        "Work presentations consistently trigger anxiety followed by relief",
        "Social connections with specific people (Sarah, family) correlate with positive emotions",
        "External factors (traffic) regularly impact your mood - consider countermeasures"
    ]
    
    private var bubblesData: [WordBubble] {
        var bubbles: [WordBubble] = []
        
        let baseX = UIScreen.main.bounds.width / 2
        let baseY = UIScreen.main.bounds.height / 2 - 80
        
        // Create pattern of bubbles
        bubbles.append(WordBubble(id: 0, text: "anxiety", x: baseX - 120, y: baseY - 80, delay: 0.2, size: 70, color: Color(hex: "FF7675").opacity(0.8)))
        bubbles.append(WordBubble(id: 1, text: "relief", x: baseX - 50, y: baseY - 50, delay: 0.3, size: 60, color: Color(hex: "74B9FF").opacity(0.8)))
        bubbles.append(WordBubble(id: 2, text: "work", x: baseX + 40, y: baseY - 90, delay: 0.4, size: 80, color: Color(hex: "A29BFE").opacity(0.8)))
        bubbles.append(WordBubble(id: 3, text: "support", x: baseX + 100, y: baseY, delay: 0.5, size: 75, color: Color(hex: "55EFC4").opacity(0.8)))
        bubbles.append(WordBubble(id: 4, text: "friends", x: baseX + 70, y: baseY + 70, delay: 0.6, size: 65, color: Color(hex: "FDCB6E").opacity(0.8)))
        bubbles.append(WordBubble(id: 5, text: "family", x: baseX - 80, y: baseY + 50, delay: 0.7, size: 70, color: Color(hex: "FF9FF3").opacity(0.8)))
        bubbles.append(WordBubble(id: 6, text: "traffic", x: baseX - 30, y: baseY + 100, delay: 0.8, size: 55, color: Color(hex: "FF7675").opacity(0.8)))
        
        return bubbles
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("discover patterns you never noticed")
                            .font(.system(size: 26, weight: .medium))
                            .foregroundColor(textColor)
                            .opacity(appearAnimation[0] ? 1 : 0)
                        
                        Spacer()
                    }
                    
                    Text("loop reveals hidden connections in your reflections")
                        .font(.system(size: 16, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(textColor.opacity(0.6))
                        .opacity(appearAnimation[1] ? 1 : 0)
                }
                .padding(.top, 64)
                .padding(.horizontal, 24)

                ZStack {
                    ForEach(bubblesData) { bubble in
                        BubbleView(wordBubble: bubble, isVisible: appearAnimation[2])
                    }
                }
                .frame(height: 300)
                .opacity(appearAnimation[2] ? 1 : 0)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Insights generated from your patterns:")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(textColor)
                        .padding(.horizontal, 24)
                        .opacity(insightOpacity[0])
                    
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(0..<insights.count, id: \.self) { index in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(accentColor)
                                
                                Text(insights[index])
                                    .font(.system(size: 16))
                                    .foregroundColor(textColor.opacity(0.8))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.horizontal, 24)
                            .opacity(insightOpacity[min(index + 1, insightOpacity.count - 1)])
                        }
                    }
                }
                .padding(.top, 16)

                
                Spacer()
                
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
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .opacity(appearAnimation[9] ? 1 : 0)
                .offset(y: appearAnimation[9] ? 0 : 20)
            }
        }
        .onAppear {
            animateEntrance()
            
            // Run the demo animation sequence
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 1.0)) {
                    pulsateCircle = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.spring(response: 0.8)) {
                        showConnections = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeInOut(duration: 1.2)) {
                            expandLines = true
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(.easeInOut(duration: 0.8)) {
                                showInsights = true
                                
                                // Animate each insight appearance
                                for i in 0..<insightOpacity.count {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.7) {
                                        withAnimation(.easeInOut(duration: 0.7)) {
                                            insightOpacity[i] = 1.0
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func animateEntrance() {
        for index in 0..<appearAnimation.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.15) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    appearAnimation[index] = true
                }
            }
        }
    }
}

// Word Bubble Model
struct WordBubble: Identifiable {
    let id: Int
    let text: String
    let x: CGFloat
    let y: CGFloat
    let delay: Double
    let size: CGFloat
    let color: Color
}

// Bubble View for Pattern Recognition
struct BubbleView: View {
    let wordBubble: WordBubble
    let isVisible: Bool
    @State private var appear = false
    
    var body: some View {
        Text(wordBubble.text)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(wordBubble.color)
            )
            .scaleEffect(appear ? 1.0 : 0.5)
            .opacity(appear ? 1.0 : 0)
            .position(x: wordBubble.x, y: wordBubble.y)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + wordBubble.delay) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        appear = isVisible
                    }
                }
            }
            .onChange(of: isVisible) { newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + wordBubble.delay) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                            appear = true
                        }
                    }
                } else {
                    withAnimation(.spring(response: 0.4)) {
                        appear = false
                    }
                }
            }
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

// Feature Row for Premium Card
struct IntroFeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "A28497"))
            
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "2C3E50"))
        }
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
