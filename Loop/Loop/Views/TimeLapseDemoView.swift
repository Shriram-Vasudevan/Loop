//
//  TimeLapseDemoView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/31/24.
//

import SwiftUI

struct TimeLapseDemoView: View {
    let accentColor = Color(hex: "A28497")
    let textColor = Color(hex: "2C3E50")
    let onComplete: () -> Void
    
    @State private var phase = 0.0
    @State private var currentStage = 0
    @State private var textOpacity = 0.0
    @State private var patternOpacity = 0.0
    @State private var yearOffset: CGFloat = 0
    @State private var nextYearOffset: CGFloat = UIScreen.main.bounds.height
    @State private var yearOpacity = 0.0
    
    // Get current year dynamically
    @State private var currentYear: Int = {
        let calendar = Calendar.current
        return calendar.component(.year, from: Date())
    }()
    
    let stages = [
        "AS TIME PASSES...",
        "YOUR COLLECTION GROWS",
        "UNTIL ONE DAY, LOOP BRINGS YOUR ENTRY BACK"
    ]
    
    var body: some View {
        ZStack {
            // Year transitions in background
            ZStack {
                Text(String(format: "%.0f", Double(currentYear)))
                    .font(.system(size: 130, weight: .bold))
                    .foregroundColor(textColor.opacity(0.05))
                    .offset(y: yearOffset)

                // Next year
                Text(String(format: "%.0f", Double(currentYear + 1)))
                    .font(.system(size: 130, weight: .bold))
                    .foregroundColor(textColor.opacity(0.05))
                    .offset(y: nextYearOffset)
            }
            .opacity(yearOpacity)
            
            // Text overlay
            Text(stages[currentStage])
                .font(.system(size: 14, weight: .medium))
                .tracking(1.5)
                .foregroundColor(textColor.opacity(0.6))
                .multilineTextAlignment(.center)
                .opacity(textOpacity)
                .padding(.horizontal)
//                .padding(.bottom, 100)
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Initial fade in
        withAnimation(.easeIn(duration: 1)) {
            textOpacity = 1
            yearOpacity = 1
        }
        
        // Year transitions
        let yearTransitionTiming = 5.7 // When to start year transition
        
        DispatchQueue.main.asyncAfter(deadline: .now() + yearTransitionTiming) {
            withAnimation(.easeInOut(duration: 2.0)) {
                yearOffset = -UIScreen.main.bounds.height
                nextYearOffset = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                currentYear += 1
                yearOffset = 0
                nextYearOffset = UIScreen.main.bounds.height
            }
        }
        
        // Text transitions
        for i in 0..<stages.count {
            let fadeOutDelay = Double(i) * 3.0 + 3.0
            let fadeInDelay = fadeOutDelay + 0.5
            
            // Fade out current text
            DispatchQueue.main.asyncAfter(deadline: .now() + fadeOutDelay) {
                withAnimation(.easeOut(duration: 0.5)) {
                    if !(i == stages.count - 1) {
                        textOpacity = 0
                    }
                }
            }
            
            // Fade in next text
            DispatchQueue.main.asyncAfter(deadline: .now() + fadeInDelay) {
                if i < stages.count - 1 {
                    currentStage += 1
                    withAnimation(.easeIn(duration: 0.5)) {
                        textOpacity = 1
                    }
                }
            }
        }
        
        // Calculate total animation duration
        let totalDuration = 10.0
        
        // Final fadeout and completion
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            withAnimation(.easeOut(duration: 0.5)) {
                textOpacity = 0
                yearOpacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onComplete()
            }
        }
    }
}
#Preview {
    TimeLapseDemoView(onComplete: {})
}
