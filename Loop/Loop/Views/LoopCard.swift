//
//  LoopCard.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/23/24.
//

import SwiftUI
import CloudKit

import SwiftUI

struct LoopCard: View {
    let loop: Loop
    let action: () -> Void
    
    @State private var showDeleteConfirmation = false
    @State private var isPressed = false
    
    private let accentColor = Color(hex: "A28497")
    private let backgroundColor = Color(hex: "FAFBFC")
    private let textColor = Color(hex: "2C3E50")
    private let surfaceColor = Color(hex: "F8F5F7")
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                    action()
                }
            }
        }) {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatTime())
                            .font(.custom("PPNeueMontreal-Medium", size: 14))
                            .foregroundColor(textColor.opacity(0.6))
                        
                        Text(loop.promptText)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(textColor)
                            .lineSpacing(4)
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(textColor.opacity(0.5))
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .highPriorityGesture(TapGesture())
                }
                
                if let transcript = loop.transcript {
                    Text(transcript)
                        .font(.system(size: 13, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(textColor.opacity(0.5))
                        .lineLimit(2)
                }
                
                HStack(spacing: 16) {
                    LoopTypeIndicator(loop: loop)
                    
                    Spacer()
                    
                    WaveformPreview(color: accentColor)
                }
            }
            .padding(20)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                    
                    DecorativeBackground()
                        .cornerRadius(10)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(accentColor.opacity(0.08), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .alert("Delete Loop", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await LoopManager.shared.deleteLoop(withID: loop.id)
                }
            }
        } message: {
            Text("Are you sure you want to delete this loop? This action cannot be undone.")
        }
    }
    
    private func formatTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: loop.timestamp).lowercased()
    }
}

struct LoopTypeIndicator: View {
    let loop: Loop
    
    private let accentColor = Color(hex: "A28497")
    private let thematicColor = Color(hex: "84A297")
    private let followUpColor = Color(hex: "8497A2")
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(indicatorColor)
                .frame(width: 6, height: 6)
            
            Text(typeText)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(indicatorColor)
        }
    }
    
    private var typeText: String {
        if !loop.isDailyLoop && !loop.isFollowUp {
            return "thematic"
        } else if loop.isFollowUp {
            return "follow up"
        }
        return "daily"
    }
    
    private var indicatorColor: Color {
        if !loop.isDailyLoop && !loop.isFollowUp {
            return thematicColor
        } else if loop.isFollowUp {
            return followUpColor
        }
        return accentColor
    }
}

struct WaveformPreview: View {
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<8) { index in
                RoundedRectangle(cornerRadius: 0.5)
                    .fill(color.opacity(0.6))
                    .frame(width: 1, height: CGFloat([12, 16, 20, 24, 20, 16, 12, 8][index]))
            }
        }
    }
}


struct DecorativeBackground: View {
    var body: some View {
        Canvas { context, size in
            let width = size.width * 0.3
            let height = size.height * 0.5
            
            var path = Path(roundedRect: CGRect(
                x: size.width - width - 20,
                y: size.height - height,
                width: width,
                height: height
            ), cornerRadius: 20)
            context.fill(path, with: .color(Color(hex: "A28497").opacity(0.07)))
            
            path = Path(roundedRect: CGRect(
                x: size.width - width + 20,
                y: size.height - height - 20,
                width: width,
                height: height
            ), cornerRadius: 20)
            context.fill(path, with: .color(Color(hex: "A28497").opacity(0.07)))
            

            path = Path(roundedRect: CGRect(
                x: size.width - width/2,
                y: size.height - height/2,
                width: width/2,
                height: height/2
            ), cornerRadius: 15)
            context.fill(path, with: .color(Color(hex: "A28497").opacity(0.04)))
        }
    }
}

#Preview {
    VStack {
        LoopCard(
            loop: Loop(id: "vvevwevwe", data: CKAsset(fileURL: URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("sampleFile.dat")), timestamp: Calendar.current.date(from: DateComponents(year: 2024, month: 9, day: 27))!, promptText: "What's a goal you're working towards?", category: "", transcript: "The transcript button uses the same accent color as the rest of the UI, and the transcript view maintains the app's clean, minimalist aesthetic while providing good readability for the transcript text.", freeResponse: false, isVideo: false, isDailyLoop: false, isFollowUp: false)
        ) {
            print("Card tapped")
        }
        .padding()
        
        LoopCard(
            loop: Loop(id: "vvevwevwe", data: CKAsset(fileURL: URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("sampleFile.dat")), timestamp: Calendar.current.date(from: DateComponents(year: 2024, month: 9, day: 27))!, promptText: "What's a goal you're working towards?", category: "", transcript: "The transcript button uses the same accent color as the rest of the UI, and the transcript view maintains the app's clean, minimalist aesthetic while providing good readability for the transcript text.", freeResponse: false, isVideo: false, isDailyLoop: false, isFollowUp: false)
        ) {
            print("Card tapped")
        }
        .padding()
    }
}
