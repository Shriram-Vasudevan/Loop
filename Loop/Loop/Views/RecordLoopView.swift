////
////  RecordLoopView.swift
////  Loop
////
////  Created by Shriram Vasudevan on 10/1/24.
////
//
//import SwiftUI
//import AVKit
//
//struct RecordLoopView: View {
//    @Environment(\.dismiss) var dismiss
//    @StateObject private var audioManager = AudioManager.shared
//    @State private var remainingAttempts: Int = 2
//    @State private var showDoneButton: Bool = false
//    
//    let prompt: String
//    
//    var body: some View {
//        ZStack {
//            Color.white.edgesIgnoringSafeArea(.all)
//            
//            VStack(spacing: 10) {
//                headerView
//                promptView
//                
//                Spacer()
//                
//                recordingIndicator
//                
//                Spacer()
//                
//                recordButton
//                attemptsRemainingView
//                
//                if showDoneButton {
//                    doneButton
//                }
//            }
//            .padding([.horizontal])
//        }
//        .onAppear {
//            audioManager.configureAudioSession()
//        }
//    }
//    
//    private var headerView: some View {
//        HStack {
//            Button(action: { dismiss() }) {
//                Image(systemName: "xmark")
//                    .foregroundColor(.black)
//
//            }
//            Spacer()
//            Text("Record your Loop")
//                .font(.headline)
//                .foregroundColor(.black)
//            Spacer()
//            Color.clear
//                .frame(width: 20, height: 20)
//        }
//    }
//    
//    private var promptView: some View {
//        Text(prompt)
//            .font(.system(size: 24, weight: .medium))
//            .foregroundColor(.gray)
//            .multilineTextAlignment(.center)
//            .padding(.horizontal)
//    }
//    
//    private var recordingIndicator: some View {
//        VStack(spacing: 10) {
//            if audioManager.isRecording {
//                Text(timeString(from: audioManager.elapsedTime))
//                    .font(.system(size: 48, weight: .bold))
//                    .foregroundColor(.black)
//                
//                Text("Recording")
//                    .font(.subheadline)
//                    .foregroundColor(.gray)
//            }
//        }
//        .frame(height: 100)
//    }
//    
//    private var recordButton: some View {
//        Button(action: toggleRecording) {
//            ZStack {
//                Circle()
//                    .fill(audioManager.isRecording ? Color.red : Color.blue)
//                    .frame(width: 80, height: 80)
//                
//                if audioManager.isRecording {
//                    RoundedRectangle(cornerRadius: 4)
//                        .fill(Color.white)
//                        .frame(width: 30, height: 30)
//                } else {
//                    Circle()
//                        .fill(Color.white)
//                        .frame(width: 70, height: 70)
//                }
//            }
//        }
//        .disabled(remainingAttempts == 0)
//    }
//    
//    private var attemptsRemainingView: some View {
//        Text("Attempts remaining: \(remainingAttempts)")
//            .foregroundColor(.gray)
//            .font(.system(size: 14, weight: .regular))
//    }
//    
//    private var doneButton: some View {
//        Button(action: handleRecordingDone) {
//            Text("Done")
//                .font(.system(size: 18, weight: .bold))
//                .frame(width: 200, height: 50)
//                .background(Color.black)
//                .foregroundColor(.white)
//                .cornerRadius(10)
//        }
//        .opacity(showDoneButton ? 1 : 0)
//        .animation(.easeInOut, value: showDoneButton)
//    }
//    
//    private func toggleRecording() {
//        if audioManager.isRecording {
//            audioManager.stopRecording()
//            showDoneButton = true
//            remainingAttempts -= 1
//        } else if remainingAttempts > 0 {
//            audioManager.startRecording()
//            showDoneButton = false
//        }
//    }
//    
//    private func handleRecordingDone() {
//        if let recordedFileURL = audioManager.getRecordedAudioFile() {
//            print("Recorded audio file: \(recordedFileURL)")
//            
//            LoopManager.shared.addLoop(audioURL: recordedFileURL, prompt: prompt)
//            
//            dismiss()
//        }
//    }
//    
//    private func timeString(from seconds: Int) -> String {
//        let minutes = seconds / 60
//        let remainingSeconds = seconds % 60
//        return String(format: "%02d:%02d", minutes, remainingSeconds)
//    }
//}
//
//#Preview {
//    RecordLoopView(prompt: "How are you feeling today?")
//}
