//
//  LiveTranscriptionManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 3/8/25.
//

import Foundation
import Speech
import AVFoundation
import Combine

class LiveTranscriptionManager: ObservableObject {
    static let shared = LiveTranscriptionManager()
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    
    @Published var transcribedText: String = ""
    @Published var isTranscribing: Bool = false
    @Published var isAuthorized: Bool = false
    
    private init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        checkSpeechRecognitionAuthorization()
    }
    
    func checkSpeechRecognitionAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                self.isAuthorized = status == .authorized
            }
        }
    }
    
    func startTranscription() {
        guard !isTranscribing else { return }
        
        // Reset transcript when starting new
        transcribedText = ""
        
        // Check authorization
        guard isAuthorized else {
            checkSpeechRecognitionAuthorization()
            return
        }
        
        // Set up audio engine if it doesn't exist
        if audioEngine == nil {
            audioEngine = AVAudioEngine()
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest,
              let speechRecognizer = speechRecognizer,
              speechRecognizer.isAvailable else {
            print("Speech recognition not available")
            return
        }
        
        // Configure request to return partial results
        recognitionRequest.shouldReportPartialResults = true
        
        // Set up audio session
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session setup failed: \(error)")
            return
        }
        
        // Set up audio engine input and tap
        let inputNode = audioEngine?.inputNode
        
        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                DispatchQueue.main.async {
                    self.transcribedText = result.bestTranscription.formattedString
                }
            }
            
            if error != nil || (result?.isFinal ?? false) {
                self.stopTranscription()
                
                // Restart if error occurred but we're still supposed to be transcribing
                if error != nil && self.isTranscribing {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.startTranscription()
                    }
                }
            }
        }
        
        // Install tap on input node
        let recordingFormat = inputNode?.outputFormat(forBus: 0)
        inputNode?.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat!) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        // Start audio engine
        do {
            try audioEngine?.start()
            isTranscribing = true
        } catch {
            print("Audio engine start failed: \(error)")
            stopTranscription()
        }
    }
    
    func stopTranscription() {
        // Stop audio engine and remove tap
        if audioEngine?.isRunning ?? false {
            audioEngine?.stop()
            audioEngine?.inputNode.removeTap(onBus: 0)
        }
        
        // End recognition request
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        // Cancel recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Update state
        isTranscribing = false
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    func resetTranscription() {
        stopTranscription()
        transcribedText = ""
    }
}
