import SwiftUI

struct PromptPromo: Identifiable {
    let id = UUID()
    let text: String
    let category: String
}

struct AppPromo: View {
    @State private var phase = AnimationPhase.initial
    @State private var isRecording = false
    @State private var currentPromptIndex = 0
    @State private var opacity = 0.0
    @State private var promptOpacity = 1.0
    @State private var finalTextOpacity = 0.0
    @State private var timeRemaining = 30
    @State private var timer: Timer?
    @State private var showingInitialUI = false
    
    let accentColor = Color(hex: "A28497")
    
    
    private let prompts = [
        PromptPromo(text: "What made you smile today?", category: "Emotional Wellbeing"),
        PromptPromo(text: "How do you push yourself forward?", category: "Growth"),
        PromptPromo(text: "Who showed up for you recently?", category: "Connections"),
        PromptPromo(text: "What brought you peace today?", category: "Emotional Wellbeing"),
        PromptPromo(text: "What made you think deeply?", category: "Curiosity"),
        PromptPromo(text: "Who inspired you this week?", category: "Connections"),
        PromptPromo(text: "What moved your heart today?", category: "Emotional Wellbeing"),
        PromptPromo(text: "What awakened your spirit?", category: "Growth"),
        PromptPromo(text: "What's one fear you faced?", category: "Challenges"),
        PromptPromo(text: "Who stood out to you?", category: "Emotional Wellbeing"),
        PromptPromo(text: "What changed your perspective?", category: "Growth"),
        PromptPromo(text: "What challenged you to grow?", category: "Challenges"),
        PromptPromo(text: "What's one boundary you set?", category: "Challenges"),
        PromptPromo(text: "What surprised your mind?", category: "Curiosity"),
        PromptPromo(text: "What truth set you free?", category: "Growth"),
        PromptPromo(text: "What dream guided you?", category: "Emotional Wellbeing"),
        PromptPromo(text: "Who changed your path?", category: "Connections")
    ]
    
    enum AnimationPhase {
        case initial
        case recording
        case carousel
        case final
    }
    
    var body: some View {
        ZStack {
            AnimatedBackground()
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                if showingInitialUI && phase != .final {
                    topContent
                        .opacity(opacity)
                }
                
                Spacer()
                
                if phase == .final {
                    finalContent
                } else {
                    VStack(spacing: 0) {
                        promptContainer
                            .frame(height: 160)
                            .opacity(showingInitialUI ? 1 : 0)
                        
                        if isRecording {
                            timerView
                                .padding(.top, 0)
                        }
                    }
                }
                
                Spacer()
                
                if phase != .final {
                    recordButton
                        .padding(.bottom, 60)
                }
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            startAnimationSequence()
        }
    }
    
    private var topContent: some View {
        VStack(spacing: 24) {
            if currentPromptIndex < prompts.count {
                Text(prompts[currentPromptIndex].category)
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(accentColor.opacity(0.8))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(accentColor.opacity(0.1))
                    )
            }
        }
        .padding(.top, 16)
        .animation(.easeInOut(duration: 0.4), value: currentPromptIndex)
    }
    
    private var promptContainer: some View {
        VStack {
            if currentPromptIndex < prompts.count {
                Text(prompts[currentPromptIndex].text)
                    .font(.system(size: 44, weight: .ultraLight))
                    .foregroundColor(.init(hex: "2C3E50"))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(promptOpacity)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var timerView: some View {
        HStack(spacing: 12) {
            PulsingDot()
            Text("\(timeRemaining)s")
                .font(.system(size: 26, weight: .ultraLight))
                .foregroundColor(accentColor)
        }
        .opacity(opacity)
    }
    
    private var finalContent: some View {
        VStack(spacing: 8) {
            Spacer()
            
            Text("loop")
                .font(.system(size: 64, weight: .ultraLight))
                .foregroundColor(.init(hex: "2C3E50"))
            
            Text("capture your reflections")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(accentColor)
            
            Spacer()
            
            Text("coming december 30th")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(.init(hex: "2C3E50"))
                .padding(.bottom, 40)
        }
        .opacity(finalTextOpacity)
    }
    
    private var recordButton: some View {
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
    }
    
    private func getAnimationDuration(for index: Int) -> Double {
        switch index {
        case 0: return 2.5   // Start slower
        case 1: return 2.2   // Gradual increase in speed
        case 2: return 1.8   // More noticeable but still gentle
        case 3: return 1.5   // Continuing smooth progression
        case 4: return 1.3   // Slightly quicker
        case 5: return 1.1   // Maintaining a gentle pace
        case 6: return 0.9   // Picking up subtly
        case 7: return 0.7   // Approaching final prompts
        default: return 0.5  // Last prompts move a bit more quickly
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            }
        }
    }
    
    private func startAnimationSequence() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                isRecording = true
                phase = .recording
            }
            
            withAnimation(.easeIn(duration: 1.2)) {
                   opacity = 1
                   showingInitialUI = true
               }
            
            startTimer()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                startPromptSequence()
            }
        }
    }
    
    private func startPromptSequence() {
        var accumulatedDelay = 0.0
        
        for index in 0..<prompts.count {
            let duration = getAnimationDuration(for: index)
            
            if index != 0 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + accumulatedDelay) {
                            withAnimation(.easeInOut(duration: 0.4)) {  // Softer, longer fade
                                promptOpacity = 0
                            }
                        }
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + accumulatedDelay + 0.4) {
                        currentPromptIndex = index
                        withAnimation(.easeInOut(duration: 0.4)) {  // Matching soft fade-in
                            promptOpacity = 1
                        }
                    }
            
            accumulatedDelay += duration
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + accumulatedDelay + 0.3) {
            withAnimation(.easeOut(duration: 0.3)) {
                opacity = 0
                promptOpacity = 0
                phase = .final
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeIn(duration: 0.5)) {
                    finalTextOpacity = 1
                }
            }
        }
    }
}

#Preview {
    AppPromo()
}
