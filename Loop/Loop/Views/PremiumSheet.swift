//
//  PremiumSheet.swift
//  Loop
//
//  Created by Shriram Vasudevan on 2/21/25.
//

import SwiftUI

struct PremiumUpgradeView: View {
    let onIntroCompletion: () -> Void
    @ObservedObject private var premiumManager = PremiumManager.shared
    @State private var appearAnimation: [Bool] = Array(repeating: false, count: 5)
    @State private var selectedSubscription: SubscriptionType = .monthly
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
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
                .padding(.top, 64)
                
                VStack(spacing: 32) {
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
                            FeatureRow(emoji: "✦", title: "Improved Transcription")
                            FeatureRow(emoji: "✦", title: "Entries that return to you")
                            FeatureRow(emoji: "✦", title: "More Journals")
                            FeatureRow(emoji: "✦", title: "Deeper Insights")
                            FeatureRow(emoji: "✦", title: "iCloud Backup")
                        }
                        .opacity(appearAnimation[3] ? 1 : 0)
                        
                        VStack(spacing: 16) {
                            subscriptionOptions
                                .padding(.top, 12)
                        }
                        .padding(.top, 30)
                        .opacity(appearAnimation[3] ? 1 : 0)
                    }
                    .padding(.top, 12)
                }
                
                Spacer()

                HStack(spacing: 16) {
                    Button {
                        onIntroCompletion()
                    } label: {
                        Text("skip for now")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(textColor.opacity(0.6))
                            .frame(height: 60)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(textColor.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .disabled(isPurchasing || isRestoring)
                    .opacity(appearAnimation[4] ? 1 : 0)
                    
                    Button {
                        purchasePremium()
                    } label: {
                        HStack(spacing: 12) {
                            if isPurchasing || isRestoring {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("upgrade")
                                    .font(.system(size: 18, weight: .medium))
                                Text("✨")
                                    .font(.system(size: 16, weight: .medium))
                            }
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
                    .disabled(isPurchasing || isRestoring)
                    .opacity(appearAnimation[4] ? 1 : 0)
                }

                Button {
                    restorePurchases()
                } label: {
                    Text("restore purchase")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(textColor.opacity(0.6))
                }
                .disabled(isPurchasing || isRestoring)
                .padding(.top, 16)
                .opacity(appearAnimation[4] ? 1 : 0)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .onAppear {
            Task {
                await premiumManager.loadProducts()
            }
            animateEntrance()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Premium"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private var subscriptionOptions: some View {
        VStack(spacing: 12) {
            Button {
                selectedSubscription = .monthly
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Monthly")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(textColor)
                        
                        Text(premiumManager.getFormattedPrice(for: .monthly))
                            .font(.system(size: 15))
                            .foregroundColor(textColor.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .stroke(selectedSubscription == .monthly ? accentColor : Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 24, height: 24)
                        
                        if selectedSubscription == .monthly {
                            Circle()
                                .fill(accentColor)
                                .frame(width: 16, height: 16)
                        }
                    }
                }
                .padding(16)
                .background(selectedSubscription == .monthly ? accentColor.opacity(0.1) : Color.gray.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selectedSubscription == .monthly ? accentColor : Color.clear, lineWidth: 1)
                )
            }
            
            Button {
                selectedSubscription = .yearly
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Yearly")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(textColor)
                        
                        Text(premiumManager.getFormattedPrice(for: .yearly))
                            .font(.system(size: 15))
                            .foregroundColor(textColor.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .stroke(selectedSubscription == .yearly ? accentColor : Color.gray.opacity(0.3), lineWidth: 2)
                            .frame(width: 24, height: 24)
                        
                        if selectedSubscription == .yearly {
                            Circle()
                                .fill(accentColor)
                                .frame(width: 16, height: 16)
                        }
                    }
                }
                .padding(16)
                .background(selectedSubscription == .yearly ? accentColor.opacity(0.1) : Color.gray.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selectedSubscription == .yearly ? accentColor : Color.clear, lineWidth: 1)
                )
            }

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
    
    private func purchasePremium() {
        isPurchasing = true
        
        Task {
            do {
                let success = try await premiumManager.purchasePremium(subscriptionType: selectedSubscription)
                
                await MainActor.run {
                    isPurchasing = false
                    
                    if success {
                        alertMessage = "Thank you for upgrading to Premium!"
                        showAlert = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            onIntroCompletion()
                        }
                    } else {
                        alertMessage = "Purchase could not be completed."
                        showAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    alertMessage = "Purchase failed: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    
    private func restorePurchases() {
        isRestoring = true
        
        Task {
            await premiumManager.restorePurchases()
            
            await MainActor.run {
                isRestoring = false
                
                if premiumManager.isUserPremium() {
                    alertMessage = "Your premium subscription has been restored!"
                    showAlert = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        onIntroCompletion()
                    }
                } else {
                    alertMessage = "No premium subscription found to restore."
                    showAlert = true
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
    PremiumUpgradeView(onIntroCompletion: {})
}
