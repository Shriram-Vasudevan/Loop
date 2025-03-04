//
//  MorningReflectionView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 2/25/25.
//

import SwiftUI
import AVKit

struct MorningReflectionView: View {
    @ObservedObject var morningManager = MorningReflectionManager.shared
    @ObservedObject var audioManager = AudioManager.shared
    
    @State private var isRecording = false
    @State private var isPostRecording = false
    @State private var recordingTimer: Timer?
    @State private var timeRemaining: Int = 30
    @State private var sleepHours: Double = 7.0
    @State private var currentTab = 0
    @State private var isSaving = false
    @State private var backgroundOpacity: Double = 0
    @State private var breathingStepIndex = 0
    @State private var breathingTimerRunning = false
    @State private var breathingTimeRemaining = 4
    @State private var breathingTimer: Timer?
    @State private var showBreathingComplete = false
    
    let accentColor = Color(hex: "94A7B7")
    let secondaryColor = Color(hex: "B7A284")
    let textColor = Color(hex: "2C3E50")
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.white
                .edgesIgnoringSafeArea(.all)

            if currentTab > 0 {
                InitialReflectionVisual(index: 1)
                    .edgesIgnoringSafeArea(.all)
                    .opacity(backgroundOpacity)
            }
            
            VStack {
                topBar
                    .padding(.bottom, 20)
                    .padding(.horizontal, 24)
                
                TabView(selection: $currentTab) {
                    ForEach(morningManager.prompts.indices, id: \.self) { index in
                        ZStack {
                            if morningManager.isPromptComplete(at: index) && morningManager.prompts[index].type != .sleepCheckin {
                                VStack {
                                    MorningCompletedView().padding(.horizontal, 24)
                                    
                                    Spacer()
                                }
                            } else if isPostRecording && (morningManager.prompts[index].type == .recording || morningManager.prompts[index].type == .affirmation) && currentTab == index  {
                                postRecordingView
                            } else {
                                VStack(spacing: 0) {
                                    dynamicPromptView(for: morningManager.prompts[index], at: index)
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .indexViewStyle(.page(backgroundDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentTab)
                .onChange(of: currentTab) { index in
                    withAnimation {
                        handleTabChange(to: index)
                    }
                }
            }
        }
        .onAppear {
            audioManager.cleanup()
            withAnimation {
                backgroundOpacity = 1
            }
        }
    }

    private var topBar: some View {
        VStack(spacing: 24) {
            ZStack {
                Text("MORNING REFLECTION")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.5))
                
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(accentColor.opacity(0.8))
                    }
                    
                    Spacer()
                }
            }
            
            ProgressIndicator(
                totalSteps: morningManager.prompts.count,
                currentStep: currentTab,
                accentColor: accentColor
            )
        }
        .padding(.top, 16)
    }
    
    private func dynamicPromptView(for prompt: MorningPrompt, at tabIndex: Int) -> some View {
        switch prompt.type {
        case .sleepCheckin:
            return AnyView(
                ZStack {
                    VStack {
                        MinimalSleepCheckInView(
                            hoursSlept: $sleepHours,
                            isEditable: true,
                            isOpenedFromPlus: false
                        ) {
                            morningManager.markPromptComplete(at: tabIndex)
                        }
                        .padding(.top, 50)
                        
                        Spacer()
                        
                        HStack {
                            Spacer()
                            
                            Button {
                                withAnimation {
                                    SleepCheckinManager.shared.saveDailyCheckin(hours: sleepHours)
                                    morningManager.markPromptComplete(at: tabIndex)
                                    currentTab += 1
                                }
                            } label: {
                                HStack {
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 23, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(24)
                                        .background(
                                            Circle()
                                                .fill(accentColor)
                                        )
                                        .padding()
                                }
                            }
                        }
                        .padding(.bottom, 5)
                    }
                }
            )
        case .recording:
            return AnyView(
                ZStack {
                    VStack(spacing: 8) {
                        HStack {
                            Text(prompt.text)
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(textColor)
                                .multilineTextAlignment(.leading)
                                .transition(.opacity.combined(with: .scale))
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Spacer()
                        }
                        
                        if let description = prompt.description {
                            HStack {
                                Text(description)
                                    .font(.system(size: 14, weight: .medium))
                                    .tracking(1.5)
                                    .foregroundColor(textColor.opacity(0.5))
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                            }
                            .padding(.bottom, 12)
                        }
                        
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
                        
                        ZStack {
                            HStack {
                                
                                recordingButton {
                                    toggleRecording()
                                }
                            }
                            
                            HStack {
                                Spacer()
                                
                                Button {
                                    withAnimation {
                                        skipCurrentPrompt()
                                    }
                                } label: {
                                    Text("Skip")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(textColor.opacity(0.8))
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 24)
                                        .background(
                                            Capsule()
                                                .stroke(textColor.opacity(0.3), lineWidth: 1)
                                        )
                                }
                                .opacity(isRecording ? 0 : 1)
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            )
        case .affirmation:
            return AnyView(
                ZStack {
                    VStack(spacing: 24) {
                        VStack (spacing: 8) {
                            HStack {
                                Text(prompt.text)
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundColor(textColor)
                                    .multilineTextAlignment(.leading)
                                    .transition(.opacity.combined(with: .scale))
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Spacer()
                            }
                            
                            if let description = prompt.description {
                                HStack {
                                    Text(description)
                                        .font(.system(size: 14, weight: .medium))
                                        .tracking(1.5)
                                        .foregroundColor(textColor.opacity(0.5))
                                        .multilineTextAlignment(.leading)
                                    
                                    Spacer()
                                }
                            }
                        }
                        
                        VStack(spacing: 20) {
                            Text(morningManager.currentAffirmation)
                                .font(.system(size: 24, weight: .light))
                                .foregroundColor(textColor)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 30)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.4))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(accentColor.opacity(0.2), lineWidth: 1)
                                )
                            
                            Button {
                                morningManager.selectRandomAffirmation()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                    Text("Try another affirmation")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(accentColor)
                            }
                        }
                        .padding(.top, 20)
                        
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
                        
                        ZStack {
                            HStack {
                                
                                recordingButton {
                                    toggleRecording()
                                }
                            }
                            
                            HStack {
                                Spacer()
                                
                                Button {
                                    withAnimation {
                                        skipCurrentPrompt()
                                    }
                                } label: {
                                    Text("Skip")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(textColor.opacity(0.8))
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 24)
                                        .background(
                                            Capsule()
                                                .stroke(textColor.opacity(0.3), lineWidth: 1)
                                        )
                                }
                                .opacity(isRecording ? 0 : 1)
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            )
        case .breathing:
            return AnyView(
                ZStack {
                    VStack(spacing: 24) {
                        HStack {
                            Text(prompt.text)
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(textColor)
                                .multilineTextAlignment(.leading)
                                .transition(.opacity.combined(with: .scale))
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Spacer()
                        }
                        
                        if let description = prompt.description {
                            HStack {
                                Text(description)
                                    .font(.system(size: 14, weight: .medium))
                                    .tracking(1.5)
                                    .foregroundColor(textColor.opacity(0.5))
                                
                                Spacer()
                            }
                        }
                        
                        Spacer()
                        
                        if breathingTimerRunning {
                            breathingExerciseView
                        } else if showBreathingComplete {
                            VStack(spacing: 24) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 56))
                                    .foregroundColor(accentColor)
                                
                                Text("Breathing exercise complete")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(textColor)
                                
                                Button {
                                    withAnimation {
                                        morningManager.markPromptComplete(at: tabIndex)
                                        currentTab += 1
                                    }
                                } label: {
                                    Text("Continue")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.vertical, 14)
                                        .padding(.horizontal, 32)
                                        .background(
                                            Capsule()
                                                .fill(accentColor)
                                        )
                                }
                            }
                        } else {
                            VStack(spacing: 20) {
                                Text("Box Breathing (4-4-4-4)")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(textColor)
                                
                                Text("Inhale 4 sec, Hold 4 sec, Exhale 4 sec, Hold 4 sec")
                                    .font(.system(size: 16))
                                    .foregroundColor(textColor.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                
                                Button {
                                    startBreathingExercise()
                                } label: {
                                    Text("Start Breathing Exercise")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.vertical, 14)
                                        .padding(.horizontal, 32)
                                        .background(
                                            Capsule()
                                                .fill(accentColor)
                                        )
                                }
                                .padding(.top, 10)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 30)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.4))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(accentColor.opacity(0.2), lineWidth: 1)
                            )
                        }
                        
                        Spacer()
                        
                        if !breathingTimerRunning && !showBreathingComplete {
                            HStack {
                                Button {
                                    withAnimation {
                                        skipCurrentPrompt()
                                    }
                                } label: {
                                    Text("Skip")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(accentColor.opacity(0.8))
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 24)
                                        .background(
                                            Capsule()
                                                .stroke(accentColor.opacity(0.3), lineWidth: 1)
                                        )
                                }
                                
                                Spacer()
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
            )
        }
    }
    
    private var breathingExerciseView: some View {
        let steps = morningManager.getBreathingInstructions()
        let currentStep = steps[breathingStepIndex]
        
        return VStack(spacing: 30) {
            ZStack {
                Circle()
                    .stroke(accentColor.opacity(0.2), lineWidth: 15)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0, to: 1 - (CGFloat(breathingTimeRemaining) / CGFloat(currentStep.duration)))
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: breathingTimeRemaining)
            }
            
            VStack(spacing: 10) {
                Text(currentStep.instruction)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(textColor)
                
                Text("\(breathingTimeRemaining)")
                    .font(.system(size: 36, weight: .thin))
                    .foregroundColor(accentColor)
            }
        }
    }
    
    private var postRecordingView: some View {
        VStack {
            LoopAudioConfirmationView(
                audioURL: audioManager.getRecordedAudioFile() ?? URL(fileURLWithPath: ""),
                waveformData: generateRandomWaveform(count: 40),
                onComplete: { completeRecording() },
                onRetry: { retryRecording() },
                isReadOnly: false
            )
            .transition(.opacity.combined(with: .scale))
            .animation(.easeInOut(duration: 0.3), value: isPostRecording)
        }
    }
    
    private func recordingButton(onTap: @escaping () -> Void) -> some View {
        let isRecording = self.isRecording
        
        return Button(action: {
            withAnimation {
                onTap()
            }
        }) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 96)
                    .shadow(
                        color: isRecording ? accentColor.opacity(0.2) : secondaryColor.opacity(0.2),
                        radius: 20,
                        x: 0,
                        y: 8
                    )
                
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                isRecording ? accentColor : .white,
                                isRecording ? accentColor.opacity(0.9) : secondaryColor.opacity(0.9)
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
                    PulsingRing(color: secondaryColor)
                }
            }
            .scaleEffect(isRecording ? 1.08 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isRecording)
        }
    }
    

    func handleTabChange(to index: Int) {
        guard index >= 0 && index < morningManager.prompts.count else {
            print("Invalid index for tab change.")
            return
        }
        
        withAnimation(.easeInOut(duration: 0.5)) {
           backgroundOpacity = index > 0 ? 1.0 : 0.0
       }
        
        currentTab = index

        isRecording = false
        timeRemaining = 30
        
        breathingTimerRunning = false
        breathingStepIndex = 0
        breathingTimeRemaining = 4
        showBreathingComplete = false
    }
    
    private func toggleRecording() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isRecording.toggle()
            
            if !isRecording {
                audioManager.stopRecording()
                stopTimer()
                withAnimation(.easeInOut(duration: 0.3)) {
                    isPostRecording = true
                }
            } else {
                startRecordingWithTimer()
            }
        }
    }
    
    private func startRecordingWithTimer() {
        try? audioManager.prepareForNewRecording()
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
                isPostRecording = true
            }
        }
    }
    
    private func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    private func skipCurrentPrompt() {
        let currentPromptIndex = currentTab

        if currentPromptIndex + 1 < morningManager.prompts.count {
            currentTab += 1
        } else {
            dismiss()
        }
    }
    
    private func completeRecording() {
        guard !isSaving else { return }
        isSaving = true
        morningManager.isSavingLoop = true
        
        guard let audioFileURL = audioManager.getRecordedAudioFile() else {
            print("Audio file not found.")
            isSaving = false
            morningManager.isSavingLoop = false
            return
        }
        
        let currentPromptIndex = currentTab
        let currentPrompt = morningManager.prompts[currentPromptIndex]
        
        let hasNextPrompt = (currentPromptIndex + 1..<morningManager.prompts.count).contains { index in
            return !morningManager.isPromptComplete(at: index)
        }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            isPostRecording = false
            morningManager.markPromptComplete(at: currentPromptIndex)
            
            if hasNextPrompt {
                currentTab += 1
            } else {
                audioManager.cleanup()
                dismiss()
            }
        }
        
        Task {
            defer {
                isSaving = false
                morningManager.isSavingLoop = false
            }
            
            do {
                let (loop, transcript) = try await LoopManager.shared.addLoop(
                    mediaURL: audioFileURL,
                    isVideo: false,
                    prompt: currentPrompt.text,
                    isDailyLoop: true,
                    isFollowUp: false,
                    isSuccess: false,
                    isUnguided: false,
                    isDream: false, isMorningJournal: true
                )
            } catch {
                print("Error saving morning recording: \(error)")
            }
        }
    }
    
    private func retryRecording() {
        audioManager.cleanup()
        isPostRecording = false
        isRecording = false
        timeRemaining = 30
    }
    
    private func startBreathingExercise() {
        breathingStepIndex = 0
        breathingTimeRemaining = 4
        breathingTimerRunning = true
        
        startBreathingTimer()
    }
    
    private func startBreathingTimer() {
        breathingTimer?.invalidate()
        
        breathingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] timer in
            if breathingTimeRemaining > 1 {
                breathingTimeRemaining -= 1
            } else {

                let steps = morningManager.getBreathingInstructions()
                
                if breathingStepIndex < steps.count - 1 {
                    breathingStepIndex += 1
                    breathingTimeRemaining = steps[breathingStepIndex].duration
                } else {
                    if breathingStepIndex == steps.count - 1 {
                        breathingStepIndex = 0
                        breathingTimeRemaining = steps[0].duration

                        if breathingTimerRunning && breathingStepIndex % 12 == 0 {
                            stopBreathingTimer()
                            withAnimation {
                                showBreathingComplete = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func stopBreathingTimer() {
        breathingTimer?.invalidate()
        breathingTimer = nil
        breathingTimerRunning = false
    }
    
    private func generateRandomWaveform(count: Int, minHeight: CGFloat = 12, maxHeight: CGFloat = 64) -> [CGFloat] {
        return (0..<count).map { _ in
            CGFloat.random(in: minHeight...maxHeight)
        }
    }
}

struct MorningCompletedView: View {
    let accentColor = Color(hex: "94A7B7")
    let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("All done.")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(textColor)
                
                Spacer()
            }
            
            HStack {
                Text("You've completed this part of your morning reflection.")
                    .font(.system(size: 16))
                    .foregroundColor(textColor.opacity(0.7))
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            
        }
    }
}


#Preview {
    MorningReflectionView()
}
