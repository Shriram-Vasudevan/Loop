//
//  PastLoopCard.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/7/24.
//

import SwiftUI

struct PastLoopCard: View {
    let loop: Loop
    let accentColor: Color
    
    var onClicked: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "waveform")
                    .foregroundColor(accentColor)
                Spacer()
                Text(formattedDate(loop.timestamp))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(loop.promptText)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.black)
                .lineLimit(2)
            
            if let mood = loop.mood {
                HStack {
                    Text("Mood:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(mood)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(accentColor)
                }
            }
            
            Button(action: {
                onClicked()
            }) {
                Text("Listen")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

//#Preview {
//    PastLoopCard()
//}
