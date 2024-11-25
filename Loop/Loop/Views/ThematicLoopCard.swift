//
//  ThematicLoopCard.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/22/24.
//

import SwiftUI

struct ThematicPromptCard: View {
    let theme: ThematicPrompt
    let accentColor: Color
    let textColor: Color
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    if theme.isPriority {
                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                            .foregroundColor(accentColor)
                    }
                    
                    Text(theme.name)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(textColor)
                }
                
                Text(theme.description)
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(Color(hex: "2C3E50").opacity(0.6))
                    .lineLimit(2)
                
                Text("\(theme.prompts.count) prompts")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(accentColor)
            }
            .frame(width: 200)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(isSelected ? accentColor : Color.clear, lineWidth: 2)
                    )
                    .shadow(
                        color: Color.black.opacity(0.04),
                        radius: 15,
                        x: 0,
                        y: 8
                    )
            )
        }
    }
}
//#Preview {
//    ThematicLoopCard()
//}
