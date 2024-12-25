//
//  EmptyStateView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/17/24.
//

import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 36))
                .foregroundColor(accentColor)
            
            Text(title)
                .font(.custom("PPNeueMontreal-Medium", size: 24))
                .foregroundColor(textColor)
            
            Text(message)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(textColor.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
