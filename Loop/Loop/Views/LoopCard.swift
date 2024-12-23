//
//  LoopCard.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/23/24.
//

import SwiftUI
import CloudKit

struct LoopCard: View {
    let loop: Loop
    let action: () -> Void
    @State private var showDeleteConfirmation = false
    @State private var isPressed = false
    
    // Colors
    private let accentColor = Color(hex: "A28497")
    private let thematicColor = Color(hex: "84A297")
    private let followUpColor = Color(hex: "8497A2")
    private let textColor = Color(hex: "2C3E50")
    
    private var cardAccentColor: Color {
        if !loop.isDailyLoop && !loop.isFollowUp {
            return thematicColor
        } else if loop.isFollowUp {
            return followUpColor
        }
        return accentColor
    }
    
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
            VStack(spacing: 0) {
                // Top section with time and type
                HStack(alignment: .center) {
                    timeSection
                    Spacer()
                    menuSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                cardAccentColor.opacity(0.1),
                                cardAccentColor.opacity(0.05),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                
                promptSection
                    .padding(.horizontal, 20)
                
                HStack {
                    waveformSection
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 20)
                    
                    Spacer()
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .shadow(
                        color: cardAccentColor.opacity(0.08),
                        radius: 15,
                        x: 0,
                        y: 8
                    )
                    .shadow(
                        color: cardAccentColor.opacity(0.05),
                        radius: 3,
                        x: 0,
                        y: 2
                    )
            )
        }
        .buttonStyle(CardButtonStyle(isPressed: isPressed))
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
    
    // MARK: - Component Sections
    
    private var timeSection: some View {
        HStack(spacing: 12) {
            Text(formatTime())
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(cardAccentColor)
            
            if !loop.isDailyLoop && !loop.isFollowUp {
                RefinedBadge(text: "thematic", color: thematicColor)
            } else if loop.isFollowUp {
                RefinedBadge(text: "follow up", color: followUpColor)
            }
        }
    }
    
    private var menuSection: some View {
        HStack(spacing: 16) {
            Menu {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(textColor.opacity(0.6))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(MenuButtonStyle())
            
            WaveformIndicator(color: cardAccentColor)
                .frame(width: 24)
        }
    }
    
    private var promptSection: some View {
        Text(loop.promptText)
            .font(.system(size: 17, weight: .regular))
            .foregroundColor(textColor)
            .lineSpacing(4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var waveformSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recording")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(cardAccentColor.opacity(0.6))
                .padding(.leading, 2)
            
            EnhancedAudioWaveform(color: cardAccentColor)
        }
    }
    
    private func formatTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: loop.timestamp)
    }
}

// MARK: - Supporting Views

struct RefinedBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(color.opacity(0.12))
                    .overlay(
                        Capsule()
                            .strokeBorder(color.opacity(0.2), lineWidth: 1)
                    )
            )
    }
}

struct EnhancedAudioWaveform: View {
    let color: Color
    @State private var waveformData: [CGFloat] = []
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<35, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.7),
                                color.opacity(0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 3, height: waveformData[safe: index] ?? 12)
            }
        }
        .frame(height: 40)
        .onAppear {
            waveformData = (0..<35).map { _ in
                CGFloat.random(in: 4...40)
            }
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
