//
//  PremiumSheet.swift
//  Loop
//
//  Created by Shriram Vasudevan on 2/21/25.
//

import SwiftUI

import SwiftUI

struct PremiumUpgradeView: View {
    @Environment(\.dismiss) var dismiss
    @State private var appearAnimation: [Bool] = Array(repeating: false, count: 5)
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Text("✕")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(textColor.opacity(0.6))
                        }
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("unlock premium")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(textColor)
                        
                        Spacer()
                    }
                    .opacity(appearAnimation[0] ? 1 : 0)

                    Text("enhance your experience")
                        .font(.system(size: 16, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(textColor.opacity(0.6))
                        .opacity(appearAnimation[1] ? 1 : 0)
                }
                .padding(.top, 36)
                
                VStack(spacing: 32) {
                    // Wave Animation
                    ZStack {
                        ForEach(0..<3) { index in
                            AltWavePattern()
                                .fill(accentColor.opacity(0.2 + Double(index) * 0.2))
                                .frame(height: 90)
                                .offset(x: -10 + CGFloat(index * 50))
                        }
                    }
                    .frame(height: 90)
                    .mask(Rectangle().frame(height: 90))
                    .opacity(appearAnimation[2] ? 1 : 0)
                    .padding(.top, -32)
                    
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 20) {
                            FeatureRow(emoji: "✦", title: "Unlimited Entry Length")
                            FeatureRow(emoji: "✦", title: "Talk to your Journal")
                            FeatureRow(emoji: "✦", title: "Customizable Prompts")
                            FeatureRow(emoji: "✦", title: "Deeper Insights")
                            FeatureRow(emoji: "✦", title: "Themes & Customization")
                        }
                        .opacity(appearAnimation[3] ? 1 : 0)
                        
                        VStack(spacing: 16) {
                            Text("$39.99/year")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(textColor)
                            
                            Text("or $4.99/month")
                                .font(.system(size: 16))
                                .foregroundColor(textColor.opacity(0.6))
                        }
                        .padding(.top, 30)
                        .opacity(appearAnimation[3] ? 1 : 0)
                    }
                    .padding(.top, 12)
                }
                
                Spacer()
                
                Button {
                    // Handle upgrade
                } label: {
                    HStack(spacing: 12) {
                        Text("upgrade now")
                            .font(.system(size: 18, weight: .medium))
                        Text("✨")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .frame(height: 60)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                accentColor,
                                accentColor.opacity(0.85)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(30)
                    .shadow(color: accentColor.opacity(0.25), radius: 15, y: 8)
                }
                .opacity(appearAnimation[4] ? 1 : 0)
                .offset(y: appearAnimation[4] ? 0 : 20)
                
                Button {
                    // Handle restore
                } label: {
                    Text("restore purchase")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(textColor.opacity(0.6))
                }
                .padding(.top, 16)
                .opacity(appearAnimation[4] ? 1 : 0)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .onAppear {
            animateEntrance()
        }
    }
    
    private func animateEntrance() {
        for index in 0..<appearAnimation.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.2) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    appearAnimation[index] = true
                }
            }
        }
    }
}

struct FeatureRow: View {
    let emoji: String
    let title: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 20))
            
            Text(title)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(Color(hex: "2C3E50"))
            
            Spacer()
        }
    }
}

#Preview {
    PremiumUpgradeView()
}
