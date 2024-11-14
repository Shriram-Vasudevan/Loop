////
////  SendLoopOverlay.swift
////  Loop
////
////  Created by Shriram Vasudevan on 11/9/24.
////
//
//import SwiftUI
//import AVKit
//import CloudKit
//
//
//
//struct SendLoopOverlay: View {
//    @ObservedObject var friendsManager = FriendsManager.shared
//    @ObservedObject var loopManager = LoopManager.shared
//    @ObservedObject var audioManager = AudioManager.shared
//    @Environment(\.dismiss) var dismiss
//    
//    let friend: PublicUserRecord
//    
//    @State private var selectedPrompt: String = ""
//    @State private var isAnonymous = false
//    @State private var showPromptSelector = false
//    
//    // Recording states
//    @State private var isRecording = false
//    @State private var isPostRecording = false
//    @State private var timeRemaining: Int = 30
//    @State private var recordingTimer: Timer?
//    @State private var audioURL: URL?
//    
//    // Playback states
//    @State private var audioPlayer: AVAudioPlayer?
//    @State private var isPlaying = false
//    @State private var progress: Double = 0
//    @State private var playbackTimer: Timer?
//    
//    let accentColor = Color(hex: "A28497")
//    let textColor = Color(hex: "2C3E50")
//    
//    var body: some View {
//        ZStack {
//            Color(hex: "FAFBFC").ignoresSafeArea()
//            
//            VStack(spacing: 0) {
//                // Header
//                header
//                
//                ScrollView {
//                    VStack(spacing: 24) {
//                        // Prompt Selection
//                        promptSection
//                        
//                        // Recording/Playback Area
//                        if isPostRecording {
//                            playbackSection
//                        } else {
//                            recordingSection
//                        }
//                        
//                        // Options
//                        optionsSection
//                        
//                        // Send Button
//                        if isPostRecording {
//                            sendButton
//                        }
//                    }
//                    .padding(24)
//                }
//            }
//        }
//        .sheet(isPresented: $showPromptSelector) {
//            promptPicker
//        }
//        .onAppear {
//            setupInitialState()
//        }
//    }
//    
//    private var header: some View {
//        VStack(spacing: 8) {
//            HStack {
//                Button(action: { dismiss() }) {
//                    Image(systemName: "xmark")
//                        .font(.system(size: 24, weight: .light))
//                        .foregroundColor(textColor)
//                }
//                
//                Spacer()
//                
//                Text("New Loop")
//                    .font(.system(size: 18, weight: .medium))
//                    .foregroundColor(textColor)
//                
//                Spacer()
//                
//                Circle()
//                    .fill(.clear)
//                    .frame(width: 24)
//            }
//            .padding(.horizontal, 20)
//            .padding(.top, 16)
//            
//            Text("to " + friend.name)
//                .font(.system(size: 15, weight: .regular))
//                .foregroundColor(textColor.opacity(0.6))
//                .padding(.bottom, 16)
//        }
//    }
//    
//    private var promptSection: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            Text("prompt")
//                .font(.system(size: 15, weight: .medium))
//                .foregroundColor(textColor.opacity(0.8))
//            
//            Button(action: { showPromptSelector = true }) {
//                HStack {
//                    Text(selectedPrompt.isEmpty ? "Choose a prompt" : selectedPrompt)
//                        .font(.system(size: 15, weight: .regular))
//                        .foregroundColor(selectedPrompt.isEmpty ? textColor.opacity(0.5) : textColor)
//                        .multilineTextAlignment(.leading)
//                    
//                    Spacer()
//                    
//                    Image(systemName: "chevron.right")
//                        .font(.system(size: 14, weight: .medium))
//                        .foregroundColor(textColor.opacity(0.3))
//                }
//                .padding(16)
//                .background(
//                    RoundedRectangle(cornerRadius: 16)
//                        .fill(Color.white)
//                        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 4)
//                )
//            }
//        }
//    }
//    
//    private var recordingSection: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            HStack {
//                Text("recording")
//                    .font(.system(size: 15, weight: .medium))
//                    .foregroundColor(textColor.opacity(0.8))
//                
//                Spacer()
//                
//                if isRecording {
//                    HStack(spacing: 8) {
//                        Circle()
//                            .fill(Color.red.opacity(0.8))
//                            .frame(width: 8, height: 8)
//                        
//                        Text("\(timeRemaining)s")
//                            .font(.system(size: 15, weight: .medium))
//                            .foregroundColor(textColor.opacity(0.6))
//                    }
//                }
//            }
//            
//            ZStack {
//                RoundedRectangle(cornerRadius: 16)
//                    .fill(Color.white)
//                    .shadow(color: Color.black.opacity(0.04), radius: 8, y: 4)
//                
//                recordButton
//            }
//            .frame(height: 160)
//        }
//    }
//    
//    private var recordButton: some View {
//        Button(action: toggleRecording) {
//            ZStack {
//                Circle()
//                    .fill(Color.white)
//                    .frame(width: 84)
//                    .shadow(color: accentColor.opacity(0.2), radius: 20, x: 0, y: 8)
//                
//                Circle()
//                    .fill(isRecording ? accentColor : .white)
//                    .frame(width: 76)
//                
//                if isRecording {
//                    RoundedRectangle(cornerRadius: 4)
//                        .fill(Color.white)
//                        .frame(width: 20, height: 20)
//                } else {
//                    Circle()
//                        .fill(accentColor)
//                        .frame(width: 64)
//                }
//            }
//        }
//        .disabled(selectedPrompt.isEmpty)
//        .opacity(selectedPrompt.isEmpty ? 0.5 : 1)
//        .scaleEffect(isRecording ? 1.08 : 1.0)
//        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isRecording)
//    }
//    
//    private var playbackSection: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            Text("preview")
//                .font(.system(size: 15, weight: .medium))
//                .foregroundColor(textColor.opacity(0.8))
//            
//            VStack(spacing: 16) {
//                // Waveform
//                GeometryReader { geometry in
//                    HStack(spacing: 2) {
//                        ForEach(0..<50, id: \.self) { index in
//                            let height = CGFloat.random(in: 0.1...1.0)
//                            let isPlayed = Double(index) / 50.0 <= progress
//                            
//                            RoundedRectangle(cornerRadius: 2)
//                                .fill(isPlayed ? accentColor : Color.gray.opacity(0.3))
//                                .frame(width: 3, height: geometry.size.height * height)
//                        }
//                    }
//                }
//                .frame(height: 60)
//                
//                // Controls
//                HStack {
//                    Text(formatTime(currentTime))
//                        .font(.system(size: 13, weight: .medium))
//                        .foregroundColor(textColor.opacity(0.6))
//                    
//                    Spacer()
//                    
//                    HStack(spacing: 20) {
//                        Button(action: togglePlayback) {
//                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
//                                .font(.system(size: 44))
//                                .foregroundColor(accentColor)
//                        }
//                        
//                        Button(action: retryRecording) {
//                            Image(systemName: "arrow.clockwise.circle.fill")
//                                .font(.system(size: 32))
//                                .foregroundColor(textColor.opacity(0.3))
//                        }
//                    }
//                    
//                    Spacer()
//                    
//                    Text(formatTime(duration))
//                        .font(.system(size: 13, weight: .medium))
//                        .foregroundColor(textColor.opacity(0.6))
//                }
//            }
//            .padding(20)
//            .background(
//                RoundedRectangle(cornerRadius: 16)
//                    .fill(Color.white)
//                    .shadow(color: Color.black.opacity(0.04), radius: 8, y: 4)
//            )
//        }
//    }
//    
//    private var optionsSection: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            Text("options")
//                .font(.system(size: 15, weight: .medium))
//                .foregroundColor(textColor.opacity(0.8))
//            
//            Toggle(isOn: $isAnonymous) {
//                HStack {
//                    Image(systemName: "person.fill.questionmark")
//                        .font(.system(size: 15))
//                        .foregroundColor(textColor.opacity(0.6))
//                    
//                    Text("Send anonymously")
//                        .font(.system(size: 15, weight: .regular))
//                        .foregroundColor(textColor)
//                }
//            }
//            .padding(16)
//            .background(
//                RoundedRectangle(cornerRadius: 16)
//                    .fill(Color.white)
//                    .shadow(color: Color.black.opacity(0.04), radius: 8, y: 4)
//            )
//        }
//    }
//    
//    private var sendButton: some View {
//        Button(action: sendLoop) {
//            HStack {
//                Text("Send Loop")
//                    .font(.system(size: 16, weight: .medium))
//            }
//            .foregroundColor(.white)
//            .frame(maxWidth: .infinity)
//            .frame(height: 54)
//            .background(
//                RoundedRectangle(cornerRadius: 16)
//                    .fill(
//                        LinearGradient(
//                            gradient: Gradient(colors: [accentColor, accentColor.opacity(0.9)]),
//                            startPoint: .topLeading,
//                            endPoint: .bottomTrailing
//                        )
//                    )
//                    .shadow(color: accentColor.opacity(0.2), radius: 10, y: 5)
//            )
//        }
//        .padding(.top, 12)
//    }
//    
//    private var promptPicker: some View {
//        NavigationView {
//            ScrollView {
//                LazyVStack(spacing: 12) {
//                    ForEach(loopManager.availablePrompts, id: \.self) { prompt in
//                        Button(action: {
//                            selectedPrompt = prompt
//                            showPromptSelector = false
//                        }) {
//                            HStack {
//                                Text(prompt)
//                                    .font(.system(size: 15, weight: .regular))
//                                    .foregroundColor(textColor)
//                                    .multilineTextAlignment(.leading)
//                                
//                                Spacer()
//                                
//                                if selectedPrompt == prompt {
//                                    Image(systemName: "checkmark")
//                                        .font(.system(size: 14, weight: .medium))
//                                        .foregroundColor(accentColor)
//                                }
//                            }
//                            .padding(16)
//                            .background(
//                                RoundedRectangle(cornerRadius: 12)
//                                    .fill(Color.white)
//                                    .shadow(color: Color.black.opacity(0.04), radius: 6, y: 3)
//                            )
//                        }
//                    }
//                }
//                .padding(.horizontal, 20)
//                .padding(.vertical, 12)
//            }
//            .background(Color(hex: "FAFBFC"))
//            .navigationTitle("Choose a prompt")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Done") {
//                        showPromptSelector = false
//                    }
//                    .foregroundColor(accentColor)
//                }
//            }
//        }
//    }
//    
//    private func setupInitialState() {
//        selectedPrompt = loopManager.availablePrompts.first ?? ""
//        audioManager.resetRecording()
//        timeRemaining = 30
//        setupAudioSession()
//    }
//    
//    private func formatTime(_ time: TimeInterval) -> String {
//        let minutes = Int(time) / 60
//        let seconds = Int(time) % 60
//        return String(format: "%d:%02d", minutes, seconds)
//    }
//    
//    // MARK: - Audio Session Management
//    private func setupAudioSession() {
//        do {
//            let session = AVAudioSession.sharedInstance()
//            try session.setCategory(.playAndRecord, mode: .default)
//            try session.setActive(true)
//        } catch {
//            print("Failed to set up audio session: \(error)")
//        }
//    }
//    
//    // MARK: - Recording Management
//    private func toggleRecording() {
//        withAnimation(.easeInOut(duration: 0.3)) {
//            isRecording.toggle()
//        }
//        
//        if isRecording {
//            startRecording()
//        } else {
//            stopRecording()
//        }
//    }
//    
//    private func startRecording() {
//        audioManager.startRecording()
//        timeRemaining = 30
//        startTimer()
//    }
//    
//    private func stopRecording() {
//        audioManager.stopRecording()
//        stopTimer()
//        isPostRecording = true
//        audioURL = audioManager.getRecordedAudioFile()
//        setupAudioPlayer()
//    }
//    
//    private func startTimer() {
//        recordingTimer?.invalidate()
//        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
//            if timeRemaining > 0 {
//                timeRemaining -= 1
//            } else {
//                stopRecording()
//            }
//        }
//    }
//    
//    private func stopTimer() {
//        recordingTimer?.invalidate()
//        recordingTimer = nil
//    }
//    
//    // MARK: - Playback Management
//    private func setupAudioPlayer() {
//        guard let url = audioURL else { return }
//        do {
//            audioPlayer = try AVAudioPlayer(contentsOf: url)
//            audioPlayer?.prepareToPlay()
//        } catch {
//            print("Failed to setup audio player: \(error)")
//        }
//    }
//    
//    private func togglePlayback() {
//        if isPlaying {
//            pausePlayback()
//        } else {
//            startPlayback()
//        }
//    }
//    
//    private func startPlayback() {
//        audioPlayer?.play()
//        isPlaying = true
//        startPlaybackTimer()
//    }
//    
//    private func pausePlayback() {
//        audioPlayer?.pause()
//        isPlaying = false
//        playbackTimer?.invalidate()
//    }
//    
//    private func stopPlayback() {
//        audioPlayer?.stop()
//        audioPlayer?.currentTime = 0
//        isPlaying = false
//        progress = 0
//        playbackTimer?.invalidate()
//    }
//    
//    private func startPlaybackTimer() {
//        playbackTimer?.invalidate()
//        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
//            updateProgress()
//        }
//    }
//    
//    private func updateProgress() {
//        guard let player = audioPlayer else { return }
//        progress = player.currentTime / player.duration
//        if !player.isPlaying {
//            stopPlayback()
//        }
//    }
//    
//    private var currentTime: TimeInterval {
//        audioPlayer?.currentTime ?? 0
//    }
//    
//    private var duration: TimeInterval {
//        audioPlayer?.duration ?? 0
//    }
//    
//    private func retryRecording() {
//        stopPlayback()
//        audioManager.resetRecording()
//        isPostRecording = false
//        isRecording = false
//        timeRemaining = 30
//    }
//    
//    private func sendLoop() {
//        guard let audioURL = self.audioURL else { return }
//        
//        UserCloudKitUtility.sendLoopToOtherUser(
//            recipientID: friend.userID,
//            data: CKAsset(fileURL: audioURL),
//            prompt: selectedPrompt,
//            timestamp: Date(),
//            availableAt: Date(),
//            anonymous: isAnonymous
//        ) { result in
//            DispatchQueue.main.async {
//                switch result {
//                case .success:
//                    dismiss()
//                case .failure(let error):
//                    print("Failed to send loop: \(error)")
//                }
//            }
//        }
//    }
//}
//
//#Preview {
//    SendLoopOverlay(friend: PublicUserRecord(userID: "", username: "johndoe", phone: "", name: "John Doe", friends: [""]))
//}
