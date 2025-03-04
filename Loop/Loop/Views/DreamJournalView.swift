//
//  DreamJournalView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/27/25.
//

import SwiftUI

struct DreamJournalView: View {
    @ObservedObject var loopManager = LoopManager.shared
    @ObservedObject var audioManager = AudioManager.shared
    
    @State private var isRecording = false
    @State private var isPostRecording = false
    @State private var showingThankYouScreen = false
    @State private var recordingTimer: Timer?
    @State private var timeRemaining: Int = 60
    
    @Environment(\.dismiss) var dismiss
    
    private let deepBlue = Color(hex: "1E3D59")
    private let lightBlue = Color(hex: "94A7B7")
    private let textColor = Color(hex: "2C3E50")
    
    @State private var retryAttempts = 100
    
    let accentColor = Color(hex: "A28497")
    let secondaryColor = Color(hex: "B7A284")

    
    var body: some View {
        ZStack {
            DreamBackground()
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                if showingThankYouScreen {
                    thankYouView
                } else if isPostRecording {
                    postRecordingView
                        .padding(.top, 50)
                } else {
                    mainRecordingView
                }
            }
            
            VStack {
                headerSection
                Spacer()
            }
        }
        .background(Color.white)
        .onAppear {
            audioManager.cleanup()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(formattedDate())
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(lightBlue)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(lightBlue)
                }
            }
            .padding(.top, 16)
            
            Text("Dream Journal")
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(.white)
            
            Text("Keep track of your dreams from last night. Speak the details, emotions, and moments you remember before they slip away.")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(lightBlue)
                .padding(.bottom, 8)
            
            Divider()
                .foregroundColor(.white)
        }
        .padding(.horizontal, 32)
    }
    
    private var mainRecordingView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            if isRecording {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        PulsingDot()
                        Text("\(timeRemaining)s")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(.white)
                    }
                    
                    Text("Recording your dream...")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(lightBlue)
                }
            }
            
            Spacer()
            
            recordingButton
                .padding(.bottom, 30)
        }
        .padding(.horizontal, 32)
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
                    .shadow(color: deepBlue.opacity(0.2), radius: 20, x: 0, y: 8)
                
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                isRecording ? deepBlue : .white,
                                isRecording ? deepBlue.opacity(0.9) : .white
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
                                    deepBlue,
                                    deepBlue.opacity(0.85)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 74)
                }
                
                if isRecording {
                    PulsingRing(color: deepBlue)
                }
            }
            .scaleEffect(isRecording ? 1.08 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isRecording)
        }
    }
    
    private var postRecordingView: some View {
        FreeResponseAudioConfirmationView(
            audioURL: audioManager.getRecordedAudioFile() ?? URL(fileURLWithPath: ""),
            waveformData: generateRandomWaveform(count: 60),
            onComplete: {
                withAnimation {
                    isPostRecording = false
                    showingThankYouScreen = true
                    completeRecording()
                }
            },
            onRetry: { retryRecording() },
            retryAttempts: retryAttempts,
            accentColor: accentColor,
            textColor: textColor
        )
    }
    
    private var thankYouView: some View {
        VStack(spacing: 8) {
            Spacer()
            
            Text("Entry Saved")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(textColor)
            
            Text("Thank you for sharing your thoughts")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.gray)
            
            Spacer()
        }
        .onAppear {
            audioManager.cleanup()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                dismiss()
            }
        }
    }
    
    // Helper functions remain largely the same
    private func toggleRecording() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isRecording.toggle()
        }
        
        if !isRecording {
            audioManager.stopRecording()
            stopTimer()
            isPostRecording = true
        } else {
            startRecordingWithTimer()
        }
    }
    
    private func startRecordingWithTimer() {
        try? audioManager.prepareForNewRecording()
        audioManager.startRecording()
        timeRemaining = 60
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
        if let audioFileURL = audioManager.getRecordedAudioFile() {
            Task {
                let loop = await loopManager.addLoop(
                    mediaURL: audioFileURL,
                    isVideo: false,
                    prompt: formattedDate(),
                    isDailyLoop: true,
                    isFollowUp: false, isSuccess: false, isUnguided: true, isDream: true, isMorningJournal: false
                )
                
                AnalysisManager.shared.performAnalysisForUnguidedEntry(transcript: loop.1)
            }
        }
    }
    
    private func retryRecording() {
        if retryAttempts > 0 {
            audioManager.cleanup()
            isPostRecording = false
            isRecording = false
            timeRemaining = 30
        }
    }
    
    private func generateRandomWaveform(count: Int) -> [CGFloat] {
        (0..<count).map { _ in CGFloat.random(in: 12...64) }
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: Date())
    }
    
    func getGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
            case 0...11:
                return "Good Morning"
            case 12...16:
                return "Good Afternoon"
        case 17...23:
            return "Good Evening"
        default:
            return "Hey there"
        }
    }
}

struct DreamBackground: View {
    @State private var starOpacity: Double = 0
    @State private var starScale: CGSize = CGSize(width: 1.0, height: 1.0)
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "1E3D59"),
                    Color(hex: "4C5B61")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            ForEach(0..<50) { _ in
                Circle()
                    .fill(Color.white)
                    .frame(width: CGFloat.random(in: 1...3))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .scaleEffect(starScale)
            }
            

            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 100, height: 100)
                .blur(radius: 30)
                .offset(x: UIScreen.main.bounds.width * 0.3, y: -UIScreen.main.bounds.height * 0.2)
            
            ForEach(0..<3) { i in
                CloudShape()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 200, height: 100)
                    .offset(
                        x: CGFloat.random(in: -200...200),
                        y: CGFloat.random(in: 100...500)
                    )
                    .blur(radius: 10)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 6.0, repeats: true) { _ in
                withAnimation(
                    Animation.easeInOut(duration: 1.5)
                ) {
                    starScale = CGSize(width: Double.random(in: 0.8...1.2), height: Double.random(in: 0.8...1.2))
                }
            }

        }
    }
}



#Preview {
    DreamJournalView()
}
