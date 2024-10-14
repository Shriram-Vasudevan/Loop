//
//  VideoRecordingView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/14/24.
//

import SwiftUI
import AVFoundation

struct VideoRecordingView: UIViewRepresentable {
    @ObservedObject var videoManager: VideoManager

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        let captureSession = AVCaptureSession()
        captureSession.beginConfiguration()
         
        guard let videoInputDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let videoInput = try? AVCaptureDeviceInput(device: videoInputDevice),
              let audioInputDevice = AVCaptureDevice.default(.builtInMicrophone, for: .audio, position: .unspecified),
              let audioInput = try? AVCaptureDeviceInput(device: audioInputDevice),
              captureSession.canAddInput(videoInput),
              captureSession.canAddInput(audioInput),
              captureSession.canAddOutput(videoManager.videoOutput) else { return view }
        
        captureSession.addInput(videoInput)
        captureSession.addInput(audioInput)
        captureSession.addOutput(videoManager.videoOutput)
        captureSession.sessionPreset = AVCaptureSession.Preset.high
        captureSession.commitConfiguration()
        captureSession.startRunning()
        
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.frame = view.frame
        videoPreviewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(videoPreviewLayer)
        
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
       
    }
}
