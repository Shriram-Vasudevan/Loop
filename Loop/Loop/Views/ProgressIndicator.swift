//
//  ProgressIndicator.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/24/24.
//

import SwiftUI

struct ProgressIndicator: View {
    let totalSteps: Int
    let currentStep: Int
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index == currentStep ? accentColor : Color(hex: "E8ECF1"))
                    .frame(width: 24, height: 2)
                    .animation(.easeInOut, value: currentStep)
            }
        }
    }
}

