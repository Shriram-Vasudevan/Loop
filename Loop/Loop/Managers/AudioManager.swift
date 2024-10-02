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
    @Published var isRecording: Bool = false
    @Published var elapsedTime: Int = 0
    
    private var audioFilename: URL? {
        let directory = FileManager.default.temporaryDirectory
        let filePath = directory.appendingPathComponent("loopRecording.m4a")
        return filePath
    }
    
    private override init() {
        super.init()
    }

    func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to configure audio session:", error.localizedDescription)
        }
    }

    func startRecording() {
        configureAudioSession()
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            guard let audioFilename = audioFilename else {
                print("Failed to create file path for recording.")
                return
            }
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            isRecording = true
        } catch {
            print("Failed to start recording:", error.localizedDescription)
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
    }

    func getRecordedAudioFile() -> URL? {
        return audioFilename
    }

    func resetRecording() {
        audioRecorder = nil
        isRecording = false
    }
}

extension AudioManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            print("Recording finished successfully.")
        } else {
            print("Recording failed to finish.")
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("Recording error occurred: \(error.localizedDescription)")
        }
    }
}
