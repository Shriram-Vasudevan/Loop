//
//  RecordQuoteView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 2/7/25.
//

import SwiftUI

struct RecordQuoteView: View {
    var quote: Quote
    
    @ObservedObject var loopManager = LoopManager.shared
    @ObservedObject var audioManager = AudioManager.shared
    
    @State private var isRecording = false
    @State private var isPostRecording = false
    @State private var showingThankYouScreen = false
    @State private var recordingTimer: Timer?
    
    @State private var timeRemaining: Int = 60
    @State private var retryAttempts = 100
    @Environment(\.dismiss) var dismiss
    
    let accentColor = Color(hex: "A28497")
    let secondaryColor = Color(hex: "B7A284")
    let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        ZStack {
            InitialReflectionVisual(index: 0)
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 0) {
                if showingThankYouScreen {
                    thankYouView
                } else if isPostRecording {
                    VStack {
                        headerSection
                        
                        postRecordingView
                            .padding(.top, 50)
                    }
                } else {
                    VStack {
                        headerSection
                        mainRecordingView
                    }
                }
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
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.gray)
                }
            }
            .padding(.top, 16)
            
            Text("Quote Reflection")
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(textColor)
            
            Text("What thoughts does this spark?")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.gray)
                .padding(.bottom, 8)
            
            Divider()
        }
        .padding(.horizontal, 32)
    }
    
    private var mainRecordingView: some View {
        VStack(spacing: 40) {

            VStack (spacing: 16) {
                Text("\(quote.text)")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(textColor)
                    .lineSpacing(8)
                    .multilineTextAlignment(.center)
                
                HStack {
                    Text("— \(quote.author)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(textColor.opacity(0.5))
                }
            }
            .padding(.top, 60)
            
            if isRecording {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        PulsingDot()
                        Text("\(timeRemaining)s")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(accentColor)
                    }
                    
                    Text("Recording your thoughts...")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.gray)
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
                    prompt: quote.text,
                    isDailyLoop: true,
                    isFollowUp: false, isSuccess: false, isUnguided: false, isDream: false, isMorningJournal: false
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
    

}

#Preview {
    RecordQuoteView(quote: Quote(text: "In today's rush, we all think too much, seek too much, want too much, and forget about the joy of just being.", author: "Eckhart Tolle"))
}
