//
//  PurposeCard.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/24/24.
//

import SwiftUI

struct PurposeCard: View {
    let purpose: String
    let isSelected: Bool
    let accentColor: Color
    let textColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(purpose)
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(isSelected ? .white : textColor)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 24)
            .frame(height: 70)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? accentColor : Color.white)
                    .shadow(
                        color: isSelected ? accentColor.opacity(0.3) : Color.black.opacity(0.05),
                        radius: isSelected ? 12 : 8,
                        y: 4
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

//#Preview {
//    PurposeCard()
//}
