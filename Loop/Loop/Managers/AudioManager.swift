//
//  AudioManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/1/24.
//

import Foundation
import AVFoundation

enum AudioManagerError: Error {
    case sessionSetupFailed
    case recordingSetupFailed
    case playbackSetupFailed
    case fileAccessError
    case invalidFileFormat
}

class AudioManager: NSObject, ObservableObject, AVAudioRecorderDelegate {
    static let shared = AudioManager()
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var audioFilename: URL?
    private var isSessionActive = false
    
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var currentProgress: Double = 0.0
    @Published var recordingDuration: TimeInterval = 0.0
    
    private var progressTimer: Timer?
    private var recordingTimer: Timer?
    
    // MARK: - Initialization
    override private init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Audio Session Management
    private func activateAudioSession(category: AVAudioSession.Category, mode: AVAudioSession.Mode = .default) {
        guard !isSessionActive else { return }
        
        let session = AVAudioSession.sharedInstance()
        
        // First, make sure any existing session is properly deactivated
        if session.isOtherAudioPlaying {
            try? session.setActive(false, options: .notifyOthersOnDeactivation)
        }
        
        // Reset the audio session to ensure clean state
        try? session.setActive(false, options: [])
        
        do {
            // Configure the session
            try session.setCategory(category, mode: mode, options: [.defaultToSpeaker, .allowBluetooth])
            
            // Activate with proper options
            try session.setActive(true, options: [.notifyOthersOnDeactivation])
            isSessionActive = true
        } catch {
            print("Failed to activate audio session: \(error)")
            // Reset state even if activation fails
            isSessionActive = false
        }
    }
    
    private func deactivateAudioSession() {
        guard isSessionActive else { return }
        
        let session = AVAudioSession.sharedInstance()
        
        // Stop all audio activity first
        audioPlayer?.stop()
        audioRecorder?.stop()
        
        // Clean up timers
        progressTimer?.invalidate()
        recordingTimer?.invalidate()
        
        // Attempt deactivation multiple times if needed
        for attempt in 1...3 {
            do {
                // Use proper deactivation options
                try session.setActive(false, options: [.notifyOthersOnDeactivation])
                isSessionActive = false
                break
            } catch {
                print("Deactivation attempt \(attempt) failed: \(error)")
                // Add a small delay before retrying
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
        
        // If still active after attempts, force reset
        if isSessionActive {
            try? session.setActive(false, options: [.notifyOthersOnDeactivation])
            isSessionActive = false
        }
    }
    
    // MARK: - Recording Methods
    func prepareForNewRecording() throws {
        stopPlayback() // Ensure any playback is stopped
        audioRecorder?.stop()
        audioRecorder = nil
        
        let directory = FileManager.default.temporaryDirectory
        audioFilename = directory.appendingPathComponent("\(UUID().uuidString).m4a")
        
        guard let fileURL = audioFilename else {
            throw AudioManagerError.fileAccessError
        }
        
        activateAudioSession(category: .record)
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.prepareToRecord()
        } catch {
            throw AudioManagerError.recordingSetupFailed
        }
    }
    
    func startRecording() {
        do {
            try prepareForNewRecording()
            audioRecorder?.record()
            isRecording = true
            startRecordingTimer()
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    func stopRecording() {
        guard audioRecorder?.isRecording == true else { return }
        
        audioRecorder?.stop()
        isRecording = false
        stopRecordingTimer()
        
        deactivateAudioSession()
    }
    
    // MARK: - Playback Methods
    func startPlayback(fromURL url: URL) throws {
        stopRecording() // Ensure any recording is stopped
        stopPlayback() // Stop any existing playback
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw AudioManagerError.fileAccessError
        }
        
        activateAudioSession(category: .playback)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
            startProgressTimer()
        } catch {
            throw AudioManagerError.playbackSetupFailed
        }
    }
    
    func pausePlayback() {
        audioPlayer?.pause()
        isPlaying = false
        stopProgressTimer()
    }
    
    func resumePlayback() {
        guard let player = audioPlayer, !player.isPlaying else { return }
        
        activateAudioSession(category: .playback)
        player.play()
        isPlaying = true
        startProgressTimer()
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentProgress = 0
        stopProgressTimer()
    }
    
    func seekToProgress(_ progress: Double) {
        guard let duration = audioPlayer?.duration else { return }
        audioPlayer?.currentTime = duration * progress
        currentProgress = progress
    }
    
    // MARK: - Timer Management
    private func startProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            self.currentProgress = player.currentTime / player.duration
        }
    }
    
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    private func startRecordingTimer() {
        recordingTimer?.invalidate()
        recordingDuration = 0
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.recordingDuration += 1
        }
    }
    
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    // MARK: - Interruption Handling
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // Stop all audio activity
            stopPlayback()
            stopRecording()
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            
            if options.contains(.shouldResume) {
                // Only resume if we were previously active
                if !isSessionActive {
                    activateAudioSession(category: .playAndRecord)
                }
            }
        @unknown default:
            break
        }
    }
    
    // MARK: - Route Change Handling
    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .oldDeviceUnavailable:
            // Handle disconnection by stopping playback/recording
            stopPlayback()
            stopRecording()
        case .newDeviceAvailable:
            // Reactivate session if needed
            if !isSessionActive {
                activateAudioSession(category: .playAndRecord)
            }
        default:
            break
        }
    }
    
    // MARK: - Cleanup
    func cleanup() {
        stopRecording()
        stopPlayback()
        deactivateAudioSession()
    }
    
    // MARK: - File Management
    func getRecordedAudioFile() -> URL? {
        return audioFilename
    }
    
    func deleteRecordedAudioFile() {
        guard let url = audioFilename else { return }
        
        do {
            try FileManager.default.removeItem(at: url)
            audioFilename = nil
        } catch {
            print("Failed to delete audio file: \(error)")
        }
    }
    
    // MARK: - AVAudioRecorderDelegate
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        isRecording = false
        stopRecordingTimer()
        
        if !flag {
            print("Recording finished unsuccessfully")
            deleteRecordedAudioFile()
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("Recording encode error: \(error)")
        }
        stopRecording()
        deleteRecordedAudioFile()
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentProgress = 0
        stopProgressTimer()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            print("Playback decode error: \(error)")
        }
        stopPlayback()
    }
}
