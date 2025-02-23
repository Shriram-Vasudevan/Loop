//
//  NotificationRequestView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 2/19/25.
//

import SwiftUI


struct NotificationPermissionSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var dontAskAgain = false
    @State private var appearAnimation: [Bool] = Array(repeating: false, count: 5)
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        ZStack {
//            InitialReflectionVisual(index: 0)
//                .edgesIgnoringSafeArea(.all)
//                .animation(.easeInOut, value: 0)
//            
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(textColor.opacity(0.6))
                        }
                        
                        Spacer()
                        
                    }
                    
                    HStack {
                        Text("notifications help you loop")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(textColor)
                        
                        Spacer()
                        
                        
                    }
                    .opacity(appearAnimation[0] ? 1 : 0)

                    Text("build a consistent practice")
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
                        Text("Get gentle reminders to reflect at your preferred time. We'll help you maintain your journaling practice without being intrusive.")
                            .font(.system(size: 17, weight: .medium))
                            .tracking(1.5)
                            .foregroundColor(textColor.opacity(0.5))
                            .multilineTextAlignment(.leading)
                            .opacity(appearAnimation[3] ? 1 : 0)

                        Toggle("Don't show this again", isOn: $dontAskAgain)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(textColor)
                            .opacity(appearAnimation[3] ? 1 : 0)
                    }
                    .padding(.top, 12)
                }
                
                Spacer()
                
                Button {
                    Task {
                        let granted = await NotificationManager.shared.requestNotificationPermissions()
                        if granted {
                            guard let time = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) else {
                                dismiss()
                                return
                            }
                            
                            NotificationManager.shared.saveAndScheduleReminder(at: time)
                            dismiss()
                        }
                    }
                } label: {
                    HStack(spacing: 12) {
                        Text("enable notifications")
                            .font(.system(size: 18, weight: .medium))
                        Image(systemName: "bell.fill")
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
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .onAppear {
            animateEntrance()
        }
        .onDisappear {
            if dontAskAgain {
                UserDefaults.standard.set(true, forKey: "dontShowNotificationPrompt")
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
}

// Preview
#Preview {
    NotificationPermissionSheet()
}
