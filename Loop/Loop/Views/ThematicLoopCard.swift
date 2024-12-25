////
////  ThematicLoopCard.swift
////  Loop
////
////  Created by Shriram Vasudevan on 11/22/24.
////
//
//import SwiftUI
//
//struct ThematicPromptCard: View {
//    let theme: ThematicPrompt
//    let accentColor: Color
//    let textColor: Color
//    let isSelected: Bool
//    let onTap: () -> Void
//    
//    var body: some View {
//        Button(action: onTap) {
//            VStack(alignment: .leading, spacing: 12) {
//                HStack(spacing: 8) {
//                    if theme.isPriority {
//                        Image(systemName: "star.fill")
//                            .font(.system(size: 14))
//                            .foregroundColor(accentColor)
//                            .transition(.scale.combined(with: .opacity))
//                    }
//                    
//                    Text(theme.name)
//                        .font(.system(size: 18, weight: .semibold))
//                        .foregroundColor(textColor)
//                }
//                
//                ScrollView {
//                    Text(theme.description)
//                        .font(.system(size: 14, weight: .regular))
//                        .foregroundColor(textColor.opacity(0.6))
//                        .multilineTextAlignment(.leading)
//                }
//                
//                HStack {
//                    Text("\(theme.prompts.count) prompts")
//                        .font(.system(size: 13, weight: .medium))
//                        .foregroundColor(accentColor)
//                    
//                    Spacer()
//                    
//                    if isSelected {
//                        Image(systemName: "checkmark.circle.fill")
//                            .font(.system(size: 16, weight: .semibold))
//                            .foregroundColor(accentColor)
//                    }
//                }
//            }
//            .frame(width: 200, height: 100)
//            .padding(20)
//            .background(
//                ZStack {
//                    RoundedRectangle(cornerRadius: 24)
//                        .fill(Color.white)
//                    
//                    if isSelected {
//                        RoundedRectangle(cornerRadius: 24)
//                            .stroke(accentColor, lineWidth: 2)
//                    }
//                    
//                    RoundedRectangle(cornerRadius: 24)
//                        .fill(
//                            LinearGradient(
//                                colors: [
//                                    accentColor.opacity(isSelected ? 0.1 : 0.05),
//                                    Color.white.opacity(0.5)
//                                ],
//                                startPoint: .topLeading,
//                                endPoint: .bottomTrailing
//                            )
//                        )
//                }
//            )
//            .scaleEffect(isSelected ? 1.02 : 1.0)
//            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
//        }
//    }
//}
//
//#Preview {
//    ThematicPromptCard(
//        theme: ThematicPrompt(
//            id: "1",
//            name: "Morning Reflection",
//            description: "Start your day with mindful reflection and intention setting",
//            isPriority: true, prompts: ["Prompt 1", "Prompt 2", "Prompt 3"], createdAt: Date()
//        ),
//        accentColor: Color(hex: "A28497"),
//        textColor: Color(hex: "2C3E50"),
//        isSelected: false,
//        onTap: {}
//    )
//}
