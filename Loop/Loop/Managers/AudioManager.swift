//
//  AudioManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/1/24.
//

import Foundation
import AVKit

class AudioManager: NSObject, ObservableObject {
    static let shared = AudioManager()
    
    private var audioRecorder: AVAudioRecorder?
    private var audioFilename: URL?
    @Published var isRecording: Bool = false

    override init() {
        super.init()
        configureAudioSession()
    }

    // Configure audio session for recording
    func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try session.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    // Start recording a new audio file
    func startRecording() {
        let directory = FileManager.default.temporaryDirectory
        let filePath = directory.appendingPathComponent(UUID().uuidString + ".m4a")
        audioFilename = filePath
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: filePath, settings: settings)
            audioRecorder?.record()
            isRecording = true
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }
    
    // Stop recording
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
    }

    // Reset recording (remove any existing audio)
    func resetRecording() {
        audioRecorder = nil
        audioFilename = nil
        isRecording = false
    }

    // Return the URL of the recorded audio file
    func getRecordedAudioFile() -> URL? {
        return audioFilename
    }
}

