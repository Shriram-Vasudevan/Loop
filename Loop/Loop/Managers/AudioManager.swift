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
    
    func prepareForNewRecording() {
        // Clean up previous recording
        audioRecorder?.stop()
        audioRecorder = nil
        
        // Configure new session
        configureAudioSession()
        
        // Prepare new filename
        let directory = FileManager.default.temporaryDirectory
        audioFilename = directory.appendingPathComponent(UUID().uuidString + ".m4a")
    }
        
    func startRecording() {
        guard let filePath = audioFilename else { return }
        
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
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }

    func resetRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        audioFilename = nil
        isRecording = false
    }


    // Return the URL of the recorded audio file
    func getRecordedAudioFile() -> URL? {
        return audioFilename
    }
}

