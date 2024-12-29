//
//  AllThemesView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/26/24.
//

import SwiftUI

import SwiftUI

struct AllThemesView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var loopManager = LoopManager.shared
    @State private var thematicPrompt: ThematicPrompt?

    let accentColor = Color(hex: "A28497")
    let backgroundColor = Color(hex: "FAFBFC")
    let textColor = Color(hex: "2C3E50")

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ZStack {
//            FlowingBackground(color: accentColor)
//                .opacity(0.2)
//                .ignoresSafeArea()
            Color(hex: "F5F5F5")
                .ignoresSafeArea(.all)
            

            VStack(spacing: 0) {
                ZStack {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(textColor)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    
                    Text("THEMES")
                        .font(.system(size: 15, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(textColor.opacity(0.5))
                }

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Array(loopManager.thematicPrompts.sorted(by: { a, b in
                            a.id > b.id
                        }).enumerated()), id: \.element.id) { index, prompt in
                            ThematicPromptCard(
                                prompt: prompt,
                                accentColor: accentColor,
                                isEven: index % 2 == 0
                            ) {
                                thematicPrompt = prompt
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
            }
        }
        .fullScreenCover(item: $thematicPrompt) { prompt in
            RecordThematicLoopPromptsView(prompt: prompt)
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    AllThemesView()
}
