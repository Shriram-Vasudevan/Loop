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
    
    let accentColor = Color(hex: "A28497")
    let backgroundColor = Color.white
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                topBar
                loopsWidget

            }
            .padding(.horizontal)
        }
        .background(backgroundColor.edgesIgnoringSafeArea(.all))
        .onAppear {
            loopManager.selectRandomPrompts()
        }
        .fullScreenCover(isPresented: $showingRecordLoopsView) {
            RecordLoopsView()
        }
    }
    
    private var topBar: some View {
        HStack {
            Text("LOOP")
                .font(.system(size: 24, weight: .bold, design: .default))
               .foregroundColor(.black)
            Spacer()
        }
    }
    
    private var loopsWidget: some View {
        VStack(alignment: .leading, spacing: 30) {
            progressView
            promptView
            recordButton
        }
    }
    
    private var progressView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Loops Completed")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.gray)
            
            HStack(spacing: 8) {
                ForEach(0..<loopManager.prompts.count, id: \.self) { index in
                    Capsule()
                        .fill(index <= loopManager.currentPromptIndex ? accentColor : Color(hex: "EEEEEE"))
                        .frame(height: 4)
                }
            }
            
            Text("\(loopManager.currentPromptIndex + 1) / \(loopManager.prompts.count)")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(accentColor)
        }
    }
    
    private var promptView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(loopManager.areAllPromptsDone() ? "Loops Complete!" : "Today's Prompts")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.gray)
            
            Text(loopManager.getCurrentPrompt())
                .font(.system(size: 24, weight: .light))
                .foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var recordButton: some View {
        Button(action: {
            showingRecordLoopsView = true
        }) {
            HStack {
                Text("Start Recording")
                    .font(.system(size: 18, weight: .medium))
                Spacer()
                Image(systemName: "mic")
            }
            .foregroundColor(loopManager.areAllPromptsDone() ? .gray : accentColor)
            .padding(.vertical, 15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(loopManager.areAllPromptsDone() ? Color.gray : accentColor, lineWidth: 1)
            )
        }
        .disabled(loopManager.areAllPromptsDone())
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

#Preview {
    HomeView()
}

