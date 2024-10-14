//
//  VideoManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/14/24.
//


import AVFoundation
import SwiftUI

class VideoManager: NSObject, ObservableObject {
    @Published var videoOutput = AVCaptureMovieFileOutput()
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?

    @Published var isRecording: Bool = false
    @Published var videoFileURL: URL?
    
    
    override init() {
        super.init()
    }

    func startRecording() {
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let directoryURL = temporaryDirectoryURL.appendingPathComponent(UUID().uuidString, isDirectory: true)
        
        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        } catch {
            print(error.localizedDescription)
        }
        
        let fileURL = directoryURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
        self.videoFileURL = fileURL
        
        videoOutput.startRecording(to: fileURL, recordingDelegate: self)
    }
    
    func stopRecording() {
        videoOutput.stopRecording()
    }

    // MARK: - Reset Recording State
    func resetRecording() {
        videoFileURL = nil
        isRecording = false
    }
}

extension VideoManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("An error occurred: \(error)")
        } else {
            print("Successfully wrote to file at \(outputFileURL)")
        }
    }

}
