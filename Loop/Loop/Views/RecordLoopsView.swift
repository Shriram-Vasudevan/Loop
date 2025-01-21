//
//  RecordLoopsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/3/24.
//

import SwiftUI
import AVKit

struct RecordLoopsView: View {
    @ObservedObject var loopManager = LoopManager.shared
    @ObservedObject var audioManager = AudioManager.shared
    @ObservedObject var analysisManager = AnalysisManager.shared
    @ObservedObject var reflectionCardManager = ReflectionCardManager.shared
    @ObservedObject var reflectionSessionManager = ReflectionSessionManager.shared
    
    @State private var isRecording = false
    @State private var isPostRecording = false
    @State private var isShowingMemory = false
    @State private var isLoadingMemory = false
    @State private var userDaysThresholdNotMet = false
    @State private var noMemoryFound = false
    @State private var recordingTimer: Timer?
    @State private var timeRemaining: Int = 30
    @State private var showingFirstLaunchScreen = true
    @State private var showingPromptOptions = false
    @State var isFirstLaunch: Bool
    @State private var backgroundOpacity: Double = 0
    @State private var messageOpacity: Double = 0
    
    @State private var allPrompts: [String] = []
    @State private var pastLoop: Loop?
    
    let accentColor = Color(hex: "A28497")
    let secondaryColor = Color(hex: "B7A284")
    let textColor = Color(hex: "2C3E50")
    
        
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject private var checkinManager = DailyCheckinManager.shared
    @State private var dayRating: Double = 5.0
    @State private var showingDayRating: Bool = true
    
    @State private var selectedColorHex: String = "#B5D5E2"
    
    @State private var currentTab = 0
    @State private var recordedTabs: Set<Int> = []
    @State private var recordedAudioURLs: [Int: URL] = [:]
    
    @State private var postRecordingTabs: Set<Int> = []

    @State private var sleepHours: Double = 7.0
    
    var body: some View {
        ZStack {
            if !UserDefaults.standard.hasSetupDailyReflection {
                Color(hex: "F5F5F5")
                    .edgesIgnoringSafeArea(.all)
            } else {
                TransitioningBackground(
                    currentTab: currentTab,
                    prompts: reflectionSessionManager.prompts
                )
            }
            
            if !UserDefaults.standard.hasSetupDailyReflection {
                firstLaunchOrQuietSpaceScreen
                    .padding(.horizontal, 24)
            } else {
                VStack {
                    topBar
                        .padding(.bottom, 40)
                        .padding(.horizontal, 24)
                    
                    TabView(selection: $currentTab) {
                        ForEach(reflectionSessionManager.prompts.indices, id: \.self) { index in
                            ZStack {
                                if reflectionSessionManager.completedPrompts.contains(index) && (reflectionSessionManager.prompts[index].type != .moodCheckIn && reflectionSessionManager.prompts[index].type != .sleepCheckin) {
                                    ReflectionCompletedView()
                                } else if isPostRecording && (reflectionSessionManager.prompts[index].type == .recording || reflectionSessionManager.prompts[index].type == .guided)  {
                                    postRecordingView
                                } else {
                                    VStack(spacing: 0) {
                                        dynamicPromptView(for: reflectionSessionManager.prompts[index], at: index)
                                    }
                                    .padding(.horizontal, 24)
                                }
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .indexViewStyle(.page(backgroundDisplayMode: .never))
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                    .animation(.easeInOut(duration: 0.3), value: currentTab)
                    .onChange(of: currentTab) { index in
                        withAnimation {
                            handleTabChange(to: index)
                        }
                    }
                    
                    
                }
            }
        }
        .onAppear {
            audioManager.cleanup()
        }
    }
    
    func handleTabChange(to index: Int) {
        guard index >= 0 && index < reflectionSessionManager.prompts.count else {
            print("Invalid index for tab change.")
            return
        }
        
        currentTab = index
        let currentPrompt = reflectionSessionManager.prompts[index]

        // Reset recording state when changing tabs
        isRecording = false
        timeRemaining = 30
        
        withAnimation {
            backgroundOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation {
                backgroundOpacity = 1
            }
        }
    }


    
    
    private var topBar: some View {
        VStack(spacing: 24) {
            ZStack {
                Text("DAILY REFLECTION")
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
                totalSteps: reflectionSessionManager.prompts.count,
                currentStep: currentTab,
                accentColor: accentColor
            )
        }
        .padding(.top, 16)
    }
  
    private var initialView: some View {
        VStack(spacing: 24) {
            VStack (spacing: 10) {
                HStack {
                    Text("daily reflection for \(formatDate())")
                        .font(.custom("PPNeueMontreal-Bold", size: 35))
                        .foregroundColor(textColor)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                
                HStack {
                    Text("let's explore your day in a meaningful way")
                        .font(.system(size: 15, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(textColor.opacity(0.5))
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }

            }
            .padding(.bottom, 25)
            
            TodaysReflectionPlanView()
            
//            Spacer()
            
            VStack(spacing: 16) {
                Button(action: {
                    withAnimation (.smooth(duration: 0.4)) {
                        let selectedCards = reflectionCardManager.getOrderedCards()
                        reflectionSessionManager.setupSession(withCards: selectedCards)
                        UserDefaults.standard.hasSetupDailyReflection = true
                        showingFirstLaunchScreen = false
                        currentTab = 0
                    }
                }) {
                    Text("continue")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.white)
                        .frame(height: 56)
                        .frame(maxWidth: .infinity)
                        .background(accentColor)
                        .cornerRadius(28)
                }


            }
            .padding(.top, 10)
        }
        .padding(.top, 45)
        .padding(.bottom, 40)
    }
   
    private func dynamicPromptView(for prompt: ReflectionPrompt, at tabIndex: Int) -> some View {
        switch prompt.type {
        case .sleepCheckin:
            return AnyView(
                ZStack {
                    VStack {
                        MinimalSleepCheckInView(
                            hoursSlept: $sleepHours,
                            isEditable: true
                        ) {
                            reflectionSessionManager.markPromptComplete(at: tabIndex)
                        }
                        
                        Spacer()
                        
                        HStack {
                            Spacer()
                            
                            Button {
                                currentTab += 1
                            } label: {
                                HStack {
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 23, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(24)
                                        .background (
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
        case .moodCheckIn:
            return AnyView(
                ZStack {
                    VStack {
                        MoodCheckInView(
                            dayRating: $dayRating,
                            isEditable: true,
                            isOpenedFromPlus: false
                        ) {
                            reflectionSessionManager.markPromptComplete(at: tabIndex)
                        }
                        
                        Spacer()
                        
                        HStack {
                            Spacer()
                            
                            Button {
                                currentTab += 1
                            } label: {
                                HStack {
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 23, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(24)
                                        .background (
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
                    VStack(spacing: 15) {
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
                        
                        recordingButton(for: prompt) {
                            toggleRecording()
                        }      
                    }
                    .padding(.bottom, 40)
                }
            )
        case .guided:
            return AnyView(
                ZStack {
                    if reflectionSessionManager.needCategorySelection() {
                        CategorySelectionView(
                            reflectionSessionManager: reflectionSessionManager,
                            onCategorySelected: { category, isAI in
                                Task {
                                    if isAI {
                                        DispatchQueue.main.async {
                                            withAnimation {
                                                reflectionSessionManager.isLoadingAIPrompt = true
                                            }
                                        }
                                        if let aiPrompt = await reflectionSessionManager.generateAIPrompt() {
                                            DispatchQueue.main.async {
                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                    let updatedPrompt = ReflectionPrompt(
                                                        text: aiPrompt,
                                                        type: .guided,
                                                        description: nil
                                                    )
                                                    reflectionSessionManager.updateGuidedPrompt(updatedPrompt)
                                                    reflectionSessionManager.isLoadingAIPrompt = false
                                                }
                                            }
                                        } else {
                                            DispatchQueue.main.async {
                                                withAnimation {
                                                    reflectionSessionManager.isLoadingAIPrompt = false
                                                }
                                            }
                                        }
                                    } else {
                                        DispatchQueue.main.async {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                if let category = category {
                                                    if let prompt = reflectionSessionManager.getRandomPrompt(for: category) {
                                                        let updatedPrompt = ReflectionPrompt(
                                                            text: prompt.text,
                                                            type: .guided,
                                                            description: nil
                                                        )
                                                        reflectionSessionManager.updateGuidedPrompt(updatedPrompt)
                                                    }
                                                } else {
                                                    let updatedPrompt = ReflectionPrompt(
                                                        text: "",
                                                        type: .guided,
                                                        description: nil
                                                    )
                                                    reflectionSessionManager.updateGuidedPrompt(updatedPrompt)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        )
                    } else if reflectionSessionManager.isLoadingAIPrompt {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Generating thoughtful question...")
                                .font(.system(size: 14))
                                .foregroundColor(textColor.opacity(0.6))
                        }
                    } else {
                        VStack(spacing: 24) {
                            Spacer()
                            
                            VStack(spacing: 16) {
                                Text(prompt.text)
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundColor(textColor)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .transition(.opacity.combined(with: .scale))
                                    .animation(.easeInOut, value: prompt.text)
                                
                                Button(action: {
                                    reflectionSessionManager.resetGuidedPrompt()
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "arrow.left")
                                        Text("Choose different topic")
                                    }
                                    .font(.system(size: 14))
                                    .foregroundColor(accentColor)
                                }
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
                            
                            recordingButton(for: prompt) {
                                toggleRecording()
                            }
                            .padding(.bottom, 40)
                        }
                    }
                }
            )
        }
    }



    
//    private func promptArea(forTab tab: Int) -> some View {
//        VStack(spacing: isRecording ? 20 : 20) {
//            if tab == 3 && (!loopManager.completedPromptIndices.contains(0) || !loopManager.completedPromptIndices.contains(1)) {
//                VStack(spacing: 24) {
//                    ZStack {
//                        Circle()
//                            .fill(textColor.opacity(0.05))
//                            .frame(width: 64, height: 64)
//                        
//                        Image(systemName: "lock.fill")
//                            .font(.system(size: 24))
//                            .foregroundColor(textColor.opacity(0.5))
//                    }
//                    
//                    VStack(spacing: 8) {
//                        Text("REFLECTION LOCKED")
//                            .font(.system(size: 13, weight: .medium))
//                            .tracking(1.5)
//                            .foregroundColor(textColor.opacity(0.5))
//                        
//                        Text("Complete the first two reflections")
//                            .font(.system(size: 18, weight: .medium))
//                            .foregroundColor(textColor)
//                            .multilineTextAlignment(.center)
//                    }
//                }
//            }
//            else if tab == 3 && loopManager.needsCategorySelection() {
//                CategorySelectionView(
//                    loopManager: loopManager,
//                    onCategorySelected: { category in
//                        Task {
////                            await loopManager.selectCategory(category)
//                        }
//                    },
//                    isDailyPrompt: true,
//                    accentColor: accentColor,
//                    textColor: textColor
//                )
//            } else {
//                VStack(spacing: 20) {
//                    if tab == 3 {
//                        // For dynamic third prompt
//                        VStack(spacing: isRecording ? 20 : 20) {
//                            Text(loopManager.dailyPrompts[tab - 1])
//                                .font(.system(size: 28, weight: .medium))
//                                .foregroundColor(textColor)
//                                .multilineTextAlignment(.center)
//                                .fixedSize(horizontal: false, vertical: true)
//                                .transition(.opacity)
//                                .animation(.easeInOut, value: loopManager.dailyPrompts[tab - 1])
//                            
//                            if isRecording {
//                                HStack(spacing: 12) {
//                                    PulsingDot()
//                                    Text("\(timeRemaining)s")
//                                        .font(.system(size: 26, weight: .ultraLight))
//                                        .foregroundColor(accentColor)
//                                }
//                                .transition(.opacity)
//                            } else if !isPostRecording {
//                                Button(action: {
//                                    withAnimation {
//                                        showingPromptOptions.toggle()
//                                    }
//                                }) {
//                                    HStack(spacing: 8) {
//                                        Image(systemName: "arrow.triangle.2.circlepath")
//                                        Text("try another prompt")
//                                    }
//                                    .font(.system(size: 16, weight: .light))
//                                    .foregroundColor(accentColor)
//                                    .padding(.horizontal, 16)
//                                    .padding(.vertical, 8)
//                                    .background(
//                                        Capsule()
//                                            .stroke(accentColor.opacity(0.3), lineWidth: 1)
//                                    )
//                                }
//                                .opacity(isRecording ? 0 : 1)
//                            }
//                        }
//                        .frame(maxWidth: .infinity)
//                    } else {
//                        // For prompts 1 and 2
//                    
//                    }
//                }
//                .frame(maxWidth: .infinity)
//            }
//        }
//    }
//    
    
    private var promptSwitcherOverlay: some View {
        ZStack {
//            Color.black.opacity(0.5)
//                .edgesIgnoringSafeArea(.all)
//                .onTapGesture {
//                    withAnimation {
//                        showingPromptOptions = false
//                    }
//                }
//            
//            VStack(spacing: 24) {
//                Text("Choose another prompt")
//                    .font(.system(size: 24, weight: .light))
//                    .foregroundColor(.black)
//                
//                VStack(spacing: 16) {
//                    ForEach(loopManager.getAlternativePrompts(), id: \.text) { prompt in
//                        Button(action: {
//                            withAnimation {
//                                loopManager.switchToPrompt(prompt)
//                                showingPromptOptions = false
//                            }
//                        }) {
//                            VStack(alignment: .leading, spacing: 8) {
//                                Text(prompt.category.rawValue)
//                                    .font(.system(size: 14, weight: .medium))
//                                    .foregroundColor(accentColor)
//                                
//                                Text(prompt.text)
//                                    .font(.system(size: 18, weight: .light))
//                                    .foregroundColor(.black)
//                                    .multilineTextAlignment(.leading)
//                            }
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                            .padding()
//                            .background(Color.white.opacity(0.1))
//                            .cornerRadius(12)
//                        }
//                    }
//                }
//            }
//            .padding(32)
//            .background(
//                RoundedRectangle(cornerRadius: 24)
//                    .fill(Color(hex: "FFFFFF").opacity(0.95))
//            )
//            .padding(24)
        }
        .transition(.opacity.combined(with: .scale(scale: 1.1)))
    }
    
    private func recordingButton(for prompt: ReflectionPrompt, onTap: @escaping () -> Void) -> some View {
        let isRecording = self.isRecording
        let primaryColor: Color
        let secondaryColor: Color
        
        // Determine colors based on prompt type
        switch prompt.type {
        case .moodCheckIn:
            primaryColor = Color(hex: "F5F5F5")
            secondaryColor = Color(hex: "B7A284")
        case .recording:
            primaryColor = Color(hex: "A28497")
            secondaryColor = Color(hex: "A28497")
        case .guided:
            primaryColor = Color(hex: "4C5B61")
            secondaryColor = Color(hex: "94A7B7")
        case .sleepCheckin:
            primaryColor = Color(hex: "F5F5F5")
            secondaryColor = Color(hex: "B7A284")
        }
        
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
                        color: isRecording ? primaryColor.opacity(0.2) : secondaryColor.opacity(0.2),
                        radius: 20,
                        x: 0,
                        y: 8
                    )
                
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                isRecording ? primaryColor : .white,
                                isRecording ? primaryColor.opacity(0.9) : secondaryColor.opacity(0.9)
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
                                    primaryColor,
                                    primaryColor.opacity(0.85)
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

    
    private var postRecordingView: some View {
        VStack {
            LoopAudioConfirmationView(
                audioURL: audioManager.getRecordedAudioFile() ?? URL(fileURLWithPath: ""),
                waveformData: generateRandomWaveform(count: 40),
                onComplete: { completeRecording() },
                onRetry: { retryRecording() }, isReadOnly: false
            )
            .transition(.opacity.combined(with: .scale))
            .animation(.easeInOut(duration: 0.3), value: isPostRecording)
        }
    }
        
    private var thankYouScreen: some View {
        VStack(spacing: 12) {
            Spacer()
            
            Text("thank you for looping")
                .font(.system(size: 36, weight: .thin))
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 32, weight: .thin))
                    .foregroundColor(accentColor)
//                
//                Text("see your insights")
//                    .font(.system(size: 24, weight: .thin))
//                    .foregroundColor(Color.gray)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            audioManager.cleanup()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                dismiss()
            }
        }
    }
    
    private var firstLaunchOrQuietSpaceScreen: some View {
        Group {
            initialView
                .transition(.opacity.combined(with: .scale))
        }
        .animation(.easeInOut(duration: 0.5), value: isFirstLaunch)
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
    
    private func completeRecording() {
        guard let audioFileURL = audioManager.getRecordedAudioFile() else {
            print("Audio file not found.")
            return
        }
        
        // Mark the current prompt as completed
        recordedTabs.insert(currentTab)
        recordedAudioURLs[currentTab] = audioFileURL
        
        let currentPromptIndex = currentTab
        guard currentPromptIndex < reflectionSessionManager.prompts.count else {
            print("Invalid prompt index.")
            return
        }
        
        let currentPrompt = reflectionSessionManager.prompts[currentPromptIndex]
        
        // Save the loop data
        Task {
            let loopSaved = await loopManager.addLoop(
                mediaURL: audioFileURL,
                isVideo: false,
                prompt: currentPrompt.text,
                isDailyLoop: true,
                isFollowUp: false,
                isSuccess: false,
                isUnguided: false
            )
            
            if loopSaved != nil {
                reflectionSessionManager.markPromptComplete(at: currentPromptIndex)
                reflectionSessionManager.saveRecordingCache(prompt: currentPrompt.text, transcript: loopSaved.1)
            }
            
            // Handle navigation based on completion state
            if reflectionSessionManager.hasCompletedForToday {
                // All prompts completed
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    isShowingMemory = false
                    audioManager.cleanup()
                    dismiss() // Dismiss view since all prompts are completed
                }
            } else {
                // Move to the next incomplete prompt
                if let nextPromptIndex = reflectionSessionManager.prompts.firstIndex(where: { !reflectionSessionManager.completedPrompts.contains(reflectionSessionManager.prompts.firstIndex(of: $0) ?? -1) }) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        isPostRecording = false
                        currentTab = nextPromptIndex
                    }
                } else {
                    print("No next prompt found.")
                }
            }
        }
    }
    
    private func retryRecording() {
        audioManager.cleanup()
        isPostRecording = false
        isRecording = false
        timeRemaining = 30
    }
    
    private var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy"
        return dateFormatter.string(from: Date())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func generateRandomWaveform(count: Int, minHeight: CGFloat = 12, maxHeight: CGFloat = 64) -> [CGFloat] {
        return (0..<count).map { _ in
            CGFloat.random(in: minHeight...maxHeight)
        }
    }
    
    func formatDate() -> String {
        let dayNumber = Calendar.current.component(.day, from: Date())
        
        let formatString = "MMMM d"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = formatString
        var formattedDate = dateFormatter.string(from: Date())
        
        var suffix: String
        switch dayNumber {
            case 1, 21, 31: suffix = "st"
            case 2, 22: suffix = "nd"
            case 3, 23: suffix = "rd"
            default: suffix = "th"
        }
        
        formattedDate.append(suffix)
        
        return formattedDate
    }
}

//struct PastLoopPlayer: View {
//    let loop: Loop
//    @State private var isPlaying = false
//    @State private var progress: Double = 0
//    @State private var audioPlayer: AVAudioPlayer?
//    @State private var timer: Timer?
//    @State private var waveformData: [CGFloat] = []
//
//    let accentColor = Color(hex: "A28497")
//
//    var body: some View {
//        VStack(spacing: 32) {
//            WaveformView(
//                waveformData: waveformData,
//                color: accentColor
//            )
//
//            // Enhanced playback controls
//            HStack(spacing: 40) {
//                Button(action: togglePlayback) {
//                    Circle()
//                        .fill(Color.white)
//                        .frame(width: 56, height: 56)
//                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
//                        .overlay(
//                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
//                                .font(.system(size: 22))
//                                .foregroundColor(accentColor)
//                                .offset(x: isPlaying ? 0 : 2)
//                        )
//                }
//            }
//
//            // Progress bar
//            GeometryReader { geometry in
//                ZStack(alignment: .leading) {
//                    RoundedRectangle(cornerRadius: 2)
//                        .fill(Color.gray.opacity(0.2))
//                        .frame(height: 4)
//
//                    RoundedRectangle(cornerRadius: 2)
//                        .fill(accentColor)
//                        .frame(width: geometry.size.width * progress, height: 4)
//                }
//            }
//            .frame(height: 4)
//            .padding(.horizontal)
//        }
//        .onAppear {
//            setupAudioPlayer()
//            generateWaveform()
//        }
//        .onDisappear(perform: cleanup)
//    }
//
//    private func generateWaveform() {
//        // Generate random waveform data for visualization
//        waveformData = (0..<50).map { _ in
//            CGFloat.random(in: 10...50)
//        }
//    }
//
//    private func togglePlayback() {
//        if isPlaying {
//            stopPlayback()
//        } else {
//            startPlayback()
//        }
//    }
//
//    private func setupAudioPlayer() {
//        guard let url = loop.data.fileURL else { return }
//
//        do {
//            audioPlayer = try AVAudioPlayer(contentsOf: url)
//            audioPlayer?.prepareToPlay()
//            audioPlayer?.delegate = AudioPlayerDelegate(onComplete: {
//                isPlaying = false
//                progress = 0
//            })
//        } catch {
//            print("Error setting up audio player: \(error)")
//        }
//    }
//
//    private func startPlayback() {
//        audioPlayer?.play()
//        isPlaying = true
//        startProgressTimer()
//    }
//
//    private func stopPlayback() {
//        audioPlayer?.pause()
//        isPlaying = false
//        timer?.invalidate()
//    }
//
//    private func startProgressTimer() {
//        timer?.invalidate()
//        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
//            guard let player = audioPlayer else { return }
//            progress = player.currentTime / player.duration
//        }
//    }
//
//    private func cleanup() {
//        timer?.invalidate()
//        timer = nil
//        audioPlayer?.stop()
//        audioPlayer = nil
//    }
//}





struct FloatingElements: View {
    @State private var offsetY: CGFloat = 0
    
    var body: some View {
        ZStack {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color(hex: "94A7B7").opacity(0.1))
                    .frame(width: 12, height: 12)
                    .offset(
                        x: CGFloat(index * 20 - 20),
                        y: offsetY + CGFloat(index * 15)
                    )
                    .animation(
                        Animation.easeInOut(duration: 2)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.3),
                        value: offsetY
                    )
            }
        }
        .onAppear {
            offsetY = -20
        }
    }
}

struct CategorySelectionView: View {
    @ObservedObject var reflectionSessionManager: ReflectionSessionManager
    let onCategorySelected: (PromptCategory?, Bool) -> Void
    
    let accentColor = Color(hex: "A28497")
    let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 26) {
            HStack {
                Text("Let's go deeper on today's reflection. ")
                    .font(.system(size: 18, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor)
                + Text("Choose a topic.")
                    .font(.system(size: 18, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.5))
                
                Spacer()
            }

            if !reflectionSessionManager.completedPrompts.isEmpty {
                Button(action: {
                    withAnimation {
                        onCategorySelected(nil, true)
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Get AI Suggestion")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Based on your previous reflections")
                                .font(.system(size: 12))
                                .opacity(0.7)
                        }
                        
                        Spacer()
                    }
                    .foregroundColor(reflectionSessionManager.aiPromptAttempted ? textColor.opacity(0.3) : accentColor)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(reflectionSessionManager.aiPromptAttempted ? Color.gray.opacity(0.1) : accentColor.opacity(0.1))
                    )
                }
                .disabled(reflectionSessionManager.aiPromptAttempted)
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "info.circle")
                    Text("Complete previous reflections to get AI suggestions")
                        .font(.system(size: 14))
                    Spacer()
                }
                .foregroundColor(textColor.opacity(0.5))
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
            
            // Categories
            ScrollView(showsIndicators: false) {
                VStack(spacing: 4) {
                    ForEach(reflectionSessionManager.availableCategories.filter { $0 != .freeform && $0 != .extraPrompts }, id: \.self) { category in
                        HStack {
                            Text(category.rawValue)
                                .font(.system(size: 14, weight: .bold))
                                .tracking(1.5)
                                .foregroundColor(textColor)
                            
                            Spacer()
                        }
                        
                        .padding()
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.white)
                        )
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                onCategorySelected(category, false)
                            }
                        }
                        .transition(.opacity.combined(with: .slide))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: category)
                    }
                }
            }
        }
    }
}

struct InitialReflectionVisual: View {
    let index: Int
    private let accentColor = Color(hex: "A28497")
    private let blueColor = Color(hex: "1E3D59")
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            Canvas { context, size in
                // Base gradient background
                let baseColor = index == 0 ? accentColor : blueColor
                let gradientRect = CGRect(origin: .zero, size: size)
                let gradient = Gradient(colors: [
                    baseColor.opacity(0.1),
                    baseColor.opacity(0.05)
                ])
                
                context.fill(
                    RoundedRectangle(cornerRadius: 24).path(in: gradientRect),
                    with: .linearGradient(
                        gradient,
                        startPoint: CGPoint(x: size.width/2, y: 0),
                        endPoint: CGPoint(x: size.width/2, y: size.height)
                    )
                )
                
                let timeOffset = timeline.date.timeIntervalSinceReferenceDate
                // Bound the phase to prevent potential floating-point precision issues
                let boundedTimeOffset = timeOffset.remainder(dividingBy: 2 * .pi)
                let phase = boundedTimeOffset * 0.5
                
                // Wave layers
                for i in 0..<3 {
                    var path = Path()
                    let width = size.width
                    let height = size.height
                    
                    // Pre-calculate some constants outside the inner loop
                    let heightFactor = height * 0.1
                    let baseHeight = height * 0.6
                    let layerPhase = phase + Double(i)
                    
                    // Optimize steps while maintaining visual quality
                    let steps = Int(width / 4)
                    let dx = width / CGFloat(steps)
                    
                    path.move(to: CGPoint(x: 0, y: height))
                    
                    // Pre-calculate step values that don't change in the loop
                    let stepScale = 1.0 / 100.0
                    
                    for step in 0...steps {
                        let x = CGFloat(step) * dx
                        let relativeX = x * stepScale
                        
                        // Combined sine-cosine calculation remains the same for visual identity
                        let sine = sin(relativeX + layerPhase)
                        let cosine = cos(relativeX * 2 + layerPhase)
                        let y = baseHeight + CGFloat(sine * cosine) * heightFactor
                        
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.closeSubpath()
                    
                    context.opacity = 0.2 - Double(i) * 0.05
                    context.fill(
                        path,
                        with: .color(baseColor)
                    )
                }
            }
        }
    }
}

struct TransitioningBackground: View {
    let currentTab: Int
    let prompts: [ReflectionPrompt]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(prompts.indices, id: \.self) { index in
                    let promptType = prompts[index].type
                    Group {
                        switch promptType {
                        case .moodCheckIn:
                            Color(hex: "F5F5F5")
                        case .recording:
                            InitialReflectionVisual(index: 0)
                        case .guided:
                            InitialReflectionVisual(index: 1)
                        case .sleepCheckin:
                            Color(hex: "F5F5F5")
                        }
                    }
                    .opacity(currentTab == index ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5), value: currentTab)
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

extension Color {
    func toHex() -> String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let rgb: Int = (Int)(red * 255) << 16 | (Int)(green * 255) << 8 | (Int)(blue * 255) << 0
        return String(format: "#%06x", rgb)
    }
}


#Preview {
    RecordLoopsView(isFirstLaunch: true)
}
