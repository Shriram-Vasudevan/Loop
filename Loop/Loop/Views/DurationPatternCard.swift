//
//  DurationPatternCard.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/30/24.
//

import Foundation
import SwiftUI

struct DurationPatternCard: View {
    let highlight: SpeakingHighlight
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        ZStack {
            Color(hex:"F5F5F5").ignoresSafeArea(.all)
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("REFLECTION LENGTH")
                        .font(.system(size: 13, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(textColor.opacity(0.5))
                    
                    Spacer()
                }
                
                // Main Content
                VStack(alignment: .leading, spacing: 27) {
                    // Duration Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your longest reflection was")
                            .font(.system(size: 16))
                            .foregroundColor(textColor.opacity(0.7))
                        
                        HStack(spacing: 4) {
                            Text(highlight.dayName)
                                .font(.system(size: 20, weight: .medium))
                            Text("at")
                                .font(.system(size: 20))
                                .foregroundColor(textColor.opacity(0.7))
                            Text(highlight.timeString)
                                .font(.system(size: 20, weight: .medium))
                        }
                        .foregroundColor(textColor)
                    }
                    
                    HStack {
                        Spacer()
                        // Emotion Section
                        VStack(alignment: .trailing, spacing: 8) {
                            Text("loop said")
                                .font(.system(size: 16))
                                .foregroundColor(textColor.opacity(0.7))
                            
                            Text(highlight.emotion.uppercased())
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(accentColor)
                        }
                    }
                }
            }
            .padding(24)
            .background(
                ZStack {
                    Color.white
                    AbstractCardBackground(accentColor: accentColor)
                }
            )
            .cornerRadius(10)
        }
    }
}
