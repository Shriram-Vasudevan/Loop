//
//  TabButton.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/30/24.
//

import SwiftUI

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(isSelected ? .white : accentColor)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? accentColor : accentColor.opacity(0.1))
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
