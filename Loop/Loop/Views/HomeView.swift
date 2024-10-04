//
//  HomeView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/1/24.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var loopManager = LoopManager.shared
    @State private var showingRecordLoopsView = false
    
    var body: some View {
        NavigationView {
            VStack {
                topBar
                
                Spacer()
                
                promptDisplay
                
                Spacer()
                
                startRecordingButton
                
                Spacer()
            }
            .background(Color.white)
            .navigationBarHidden(true)
            .onAppear {
                // Make sure prompts are selected
                loopManager.selectRandomPrompts()
            }
            .fullScreenCover(isPresented: $showingRecordLoopsView) {
                RecordLoopsView()
            }
        }
    }
    
    // Top Bar with title and X button
    private var topBar: some View {
        HStack {
            Text("LOOP")
                .font(.system(size: 24, weight: .bold, design: .default))
                .foregroundColor(.black)
            Spacer()
            Button(action: {
                // When X is pressed, save the current progress and dismiss
                showingRecordLoopsView = false
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.black)
                    .font(.system(size: 20))
            }
        }
        .padding([.horizontal, .top])
    }
    
    // Display the current prompt or "Nothing to record for now"
    private var promptDisplay: some View {
        Text(loopManager.getCurrentPrompt())
            .font(.system(size: 24, weight: .thin))
            .foregroundColor(Color.gray)
            .multilineTextAlignment(.center)
            .padding()
    }
    
    // Start Recording Button
    private var startRecordingButton: some View {
        Button(action: {
            showingRecordLoopsView = true
        }) {
            Text("Start Recording")
                .font(.system(size: 18, weight: .bold))
                .frame(width: 200, height: 50)
                .background(loopManager.areAllPromptsDone() ? Color.gray : Color.black)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .disabled(loopManager.areAllPromptsDone())
    }
}

#Preview {
    HomeView()
}

