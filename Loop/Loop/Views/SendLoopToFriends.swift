//
//  SendLoopToFriends.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/4/24.
//

import SwiftUI
import AVKit
import CloudKit

struct SendLoopToFriends: View {
    @ObservedObject var friendsManager = FriendsManager.shared
    @ObservedObject var loopManager = LoopManager.shared
    @ObservedObject var audioManager = AudioManager.shared
    
    @State var userID: String
    @State var username: String
    @State var name: String
    
    @State private var selectedPrompt: String = ""
    @State private var isAnonymous = false
    @State private var availabilityDate = Date()
    @State private var showConfirmation = false
    @Environment(\.dismiss) var dismiss
    
    let accentColor = Color(hex: "A28497")
    let complementaryColor = Color(hex: "84A297")
    let backgroundColor = Color(hex: "F5F5F5")
    let strokeColor = Color(hex: "6B7280")
    
    @State private var retryAttempts = 1
    @State private var recordingTimer: Timer?
    @State private var timeRemaining: Int = 30
    
    @State private var isRecording = false
    @State private var isPostRecording = false
    @State private var audioURL: URL? = nil
    
    
    //for playback
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var progress: CGFloat = 0
    @State private var timer: Timer?
    var body: some View {
        ZStack {
            WaveBackground()
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                HStack {
                    Text("Send Loop to \(name)")
                        .font(.system(size: 36, weight: .thin))
                        .foregroundColor(.black)
                        .padding(.top, 20)
                        .padding(.horizontal)
                    
                    Spacer()
                }
                
                promptSelection
                    .padding(.horizontal)
                
                anonymityToggle
                    .padding(.horizontal)
                
                
                if !isPostRecording {
                    preRecordingWidget
                        .padding(.horizontal)
                } else {
                    postRecordingWidget
                        .padding(.horizontal)
                }
                
                HStack {
                    availabilityPicker
                        .padding(.horizontal)
                    
                    Spacer()
                }
                
                sendButton
                    .padding(.horizontal)
                    .disabled(audioURL == nil)
                
                Spacer()
            }
            .onAppear {
                selectedPrompt = loopManager.availablePrompts.first ?? ""
            }
            .alert(isPresented: $showConfirmation) {
                Alert(
                    title: Text("Loop Sent!"),
                    message: Text("Your loop has been sent to \(name)."),
                    dismissButton: .default(Text("OK")) {
                        dismiss()
                    }
                )
            }
        }
    }
    
    // MARK: - Pre-Recording Widget (Rectangular)
    private var preRecordingWidget: some View {
        VStack(spacing: 20) {
            ZStack {
                VStack(spacing: 10) {
                    Text("Ready to Record")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(accentColor)
                    
                    Button(action: toggleRecording) {
                        HStack {
                            Spacer()
                            Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(isRecording ? .red : accentColor)
                            Spacer()
                        }
                    }
                    
                    if isRecording {
                        Text("Recording... \(timeRemaining)s")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                    } else {
                        Text("Tap to start recording")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                }
            }

        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .frame(width: .infinity)
                .shadow(color: accentColor.opacity(0.3), radius: 8, x: 0, y: 8)
        )
        .onAppear {
            timeRemaining = 30
        }
    }

    
    private var postRecordingWidget: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                
                Text("Recorded Audio")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(accentColor)
                
                Spacer()
            }
            
            Text(formattedProgress)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "333333"))
            
            ZStack {
                HStack(spacing: 40) {
                    Button(action: togglePlayback) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 44, height: 44)
                            .foregroundColor(accentColor)
                    }
                    
                    Button(action: retryRecording) {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(complementaryColor)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: accentColor.opacity(0.3), radius: 8, x: 0, y: 8)
        )
    }
    
    // MARK: - Prompt Selection
    private var promptSelection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select Prompt")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(accentColor)
            
            Menu {
                ForEach(loopManager.availablePrompts, id: \.self) { prompt in
                    Button(action: {
                        selectedPrompt = prompt
                    }) {
                        Text(prompt)
                            .font(.system(size: 18))
                            .foregroundColor(.black)
                    }
                }
            } label: {
                HStack {
                    Text(selectedPrompt.isEmpty ? "Choose a prompt" : selectedPrompt)
                        .font(.system(size: 18))
                        .foregroundColor(selectedPrompt.isEmpty ? .gray : .black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 20))
                        .foregroundColor(accentColor)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(accentColor, lineWidth: 2)
                )
            }
        }
    }
    
    // MARK: - Anonymity Toggle
    private var anonymityToggle: some View {
        HStack {
            Toggle("Send as Anonymous", isOn: $isAnonymous)
                .font(.system(size: 18))
                .foregroundColor(accentColor)
                .toggleStyle(SwitchToggleStyle(tint: accentColor))
                .padding()
        }
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(accentColor, lineWidth: 2)
        )
    }
    
    // MARK: - Availability Date Picker
    private var availabilityPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Set Availability Date")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(accentColor)
            
            DatePicker(
                "Available from",
                selection: $availabilityDate,
                in: Date()...,
                displayedComponents: .date
            )
            .datePickerStyle(CompactDatePickerStyle())
            .labelsHidden()
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(accentColor, lineWidth: 2)
            )
        }
    }
    
    // MARK: - Actions
    private func toggleRecording() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isRecording.toggle()
        }
        
        if !isRecording {
            audioManager.stopRecording()
            stopTimer()
            isPostRecording = true
            audioURL = audioManager.getRecordedAudioFile()
            
            setupAudioPlayer()
        } else {
            startRecordingWithTimer()
        }
    }
    
    private func startRecordingWithTimer() {
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
                audioURL = audioManager.getRecordedAudioFile()
            }
        }
    }
    
    private func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    private func retryRecording() {
        audioManager.resetRecording()
        isPostRecording = false
        isRecording = false
        audioURL = nil
        timeRemaining = 30
    }
    
    private func togglePlayback() {
        if isPlaying {
            audioPlayer?.pause()
            timer?.invalidate()
        } else {
            audioPlayer?.play()
            startUpdatingProgress()
        }
        isPlaying.toggle()
    }
    
    private func stopPlayback() {
        audioPlayer?.stop()
        isPlaying = false
        progress = 0
    }
    
    private func startUpdatingProgress() {
        guard let player = audioPlayer else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if player.isPlaying {
                self.progress = CGFloat(player.currentTime / player.duration)
            } else {
                timer.invalidate()
                self.isPlaying = false
            }
        }
    }
    
    private var formattedProgress: String {
        let duration = audioPlayer?.duration ?? 0
        let currentTime = duration * Double(progress)
        return String(format: "%.2f / %.2f", currentTime, duration)
    }
    
    private func setupAudioPlayer() {
        do {
            guard let audioURL = self.audioURL else { return }
            audioPlayer = try? AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.prepareToPlay()
        } catch {
            print("Error setting up audio player: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Send Button
    private var sendButton: some View {
        Button(action: sendLoop) {
            HStack {
                Spacer()
                Text("Send Loop")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding()
            .background(audioURL == nil ? Color.gray : accentColor)
            .cornerRadius(15)
            .shadow(color: accentColor.opacity(0.4), radius: 10, x: 0, y: 10)
        }
    }
    
    private func sendLoop() {
        guard let audioURl = self.audioURL else { return }
        
        UserCloudKitUtility.sendLoopToOtherUser(
            recipientID: userID,
            data: CKAsset(fileURL: audioURl),
            prompt: selectedPrompt,
            timestamp: Date(),
            availableAt: availabilityDate,
            anonymous: isAnonymous
        ) { result in
            switch result {
            case .success:
                showConfirmation = true
            case .failure(let error):
                print("Error sending loop: \(error)")
            }
        }
    }
}
#Preview {
    SendLoopToFriends(userID: "", username: "", name: "Shriram")
}
