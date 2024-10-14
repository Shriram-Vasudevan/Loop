//
//  VideoRecordButton.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/14/24.
//

import SwiftUI

struct VideoRecordButton: View {
    @ObservedObject var videoManager: VideoManager
    @Binding var isRecording: Bool
    let onRecordingComplete: () -> Void

    var body: some View {
        Button(action: {
            if videoManager.isRecording {
                videoManager.stopRecording()
                isRecording = false
                onRecordingComplete()
            } else {
                videoManager.startRecording()
                isRecording = true
            }
        }) {
            ZStack {
                Circle()
                    .stroke(videoManager.isRecording ? Color.red : Color(hex: "4A4A4A").opacity(0.8), lineWidth: 6)
                    .frame(width: 90, height: 90)

                if videoManager.isRecording {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.red)
                        .frame(width: 31, height: 31)
                } else {
                    Circle()
                        .fill(Color(hex: "4A4A4A"))
                        .frame(width: 72, height: 72)
                        .opacity(0.8)
                }
            }
        }
    }
}

