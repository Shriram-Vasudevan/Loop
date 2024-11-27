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
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < currentStep ? accentColor : accentColor.opacity(0.2))
                    .frame(height: 4)
            }
        }
    }
}
