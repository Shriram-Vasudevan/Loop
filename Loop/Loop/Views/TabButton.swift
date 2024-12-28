//
//  TabButton.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/30/24.
//

import SwiftUI

struct InsightsTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .tracking(1.5)
                .foregroundColor(isSelected ? textColor : textColor.opacity(0.5))
                .padding(.bottom, 12)
        }
    }
}
