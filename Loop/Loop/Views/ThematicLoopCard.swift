//
//  ThematicLoopCard.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/22/24.
//

import SwiftUI

struct ThematicLoopCard: View {
    let theme: ThematicLoop
    let accentColor: Color
    
    var body: some View {
        Button(action: {}) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.1))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: theme.icon)
                            .font(.system(size: 20))
                            .foregroundColor(accentColor)
                    }
                    
                    Spacer()
                    
                    Text("\(theme.prompts.count) prompts")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(accentColor)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(theme.title)
                        .font(.system(size: 22, weight: .light))
                        .foregroundColor(Color(hex: "2C3E50"))
                    
                    Text(theme.description)
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(Color(hex: "2C3E50").opacity(0.6))
                }
            }
            .frame(width: 220)
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
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
