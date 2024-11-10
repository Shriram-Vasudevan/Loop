//
//  IntroView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/1/24.
//

import SwiftUI
import AVKit

struct IntroView: View {
    @State private var currentPage = 0
    @State private var backgroundOpacity: Double = 0

    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var reminderEnabled = true
    @State private var reminderTime = Date()
    
    private let accentColor = Color(hex: "A28497")
    private let secondaryColor = Color(hex: "B7A284")
    private let backgroundColor = Color(hex: "FAFBFC")
    private let textColor = Color(hex: "2C3E50")
    
    private let totalPages = 2
    var onIntroCompletion: () -> Void
    
    var body: some View {
        ZStack {
            AnimatedBackground()
                .opacity(backgroundOpacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.2)) {
                        backgroundOpacity = 1
                    }
                }
            
            TabView(selection: $currentPage) {
                welcomeView
                    .tag(0)
                
                finalSetupView
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
        }
        .preferredColorScheme(.light)
    }
    
    private var welcomeView: some View {
        VStack(spacing: 0) {
            Text("welcome to loop")
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundColor(textColor)
                .padding(.bottom, 12)
            
            Text("your daily micro-journaling companion")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(textColor.opacity(0.6))
                .padding(.bottom, 60)
 
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 20)
                
                VStack(spacing: 24) {
                    Text("what made you smile today?")
                        .font(.system(size: 24, weight: .ultraLight))
                        .foregroundColor(textColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 88)
                            .shadow(color: accentColor.opacity(0.2), radius: 20)
                        
                        Circle()
                            .fill(accentColor)
                            .frame(width: 74)
                    }
                    .padding(.bottom, 20)
                }
                .padding(.vertical, 40)
            }
            .frame(height: 240)
            .padding(.horizontal, 32)
            .padding(.bottom, 20)
            
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 15)
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "quote.opening")
                            .font(.system(size: 24, weight: .ultraLight))
                            .foregroundColor(accentColor)
                        Spacer()
                    }
                    
                    Text("watching the sunset with my family")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(textColor)
                    
                    HStack {
                        Image(systemName: "calendar")
                            .font(.system(size: 14, weight: .light))
                        Text("nov 8")
                            .font(.system(size: 14, weight: .light))
                    }
                    .foregroundColor(textColor.opacity(0.6))
                }
                .padding(20)
            }
            .frame(height: 140)
            .padding(.horizontal, 32)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    currentPage = 1
                }
            }) {
                HStack(spacing: 12) {
                    Text("begin your journey")
                        .font(.system(size: 18, weight: .light))
                }
                .frame(height: 60)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [accentColor, accentColor.opacity(0.9)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(30)
                .shadow(color: accentColor.opacity(0.15), radius: 12, y: 6)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .padding(.top, 30)
    }
    
    private var finalSetupView: some View {
        VStack(spacing: 0) {
            Text("personalize your loop")
                .font(.system(size: 32, weight: .ultraLight))
                .foregroundColor(textColor)
                .padding(.bottom, 40)
            
            VStack(spacing: 32) {
                VStack(spacing: 24) {
                    CustomTextField(
                        text: $name,
                        placeholder: "your name",
                        imageName: "person"
                    )
                    
                    CustomTextField(
                        text: $phoneNumber,
                        placeholder: "phone number",
                        imageName: "phone",
                        keyboardType: .phonePad
                    )
                }
                .padding(.horizontal, 48)
                
                VStack(spacing: 20) {
                    Button(action: {
                        reminderEnabled.toggle()
                    }) {
                        HStack {
                            Text("daily loop reminders")
                                .font(.system(size: 18, weight: .light))
                                .foregroundColor(textColor)
                            
                            Spacer()
                            
                            Toggle("", isOn: $reminderEnabled)
                                .tint(accentColor)
                                .labelsHidden()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 48)
                    
                    DatePicker("Reminder Time",
                             selection: $reminderTime,
                             displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxHeight: 120)
                        .padding(.top, 8)
                        .disabled(!reminderEnabled)
                        .opacity(reminderEnabled ? 1 : 0.5)
                }
            }
            
            Spacer()
            
            Button(action: {
                saveUserPreferences()
                createUserRecord()
                onIntroCompletion()
            }) {
                HStack(spacing: 12) {
                    Text("begin looping")
                        .font(.system(size: 18, weight: .light))
                }
                .frame(height: 60)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [accentColor, accentColor.opacity(0.9)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(30)
                .shadow(color: accentColor.opacity(0.15), radius: 12, y: 6)
            }
            .disabled(!isFormValid)
            .opacity(isFormValid ? 1 : 0.6)
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .padding(.top, 30)
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && (!reminderEnabled || (reminderEnabled && !phoneNumber.isEmpty))
    }
    
    private func saveUserPreferences() {
        UserDefaults.standard.set(name, forKey: "userName")
        UserDefaults.standard.set(phoneNumber, forKey: "userPhone")
        UserDefaults.standard.set(reminderEnabled, forKey: "reminderEnabled")
        if reminderEnabled {
            UserDefaults.standard.set(reminderTime, forKey: "reminderTime")
            ReminderManager.shared.requestNotificationPermissions { success in
                if success {
                    ReminderManager.shared.saveReminderTime(reminderTime)
                }
            }
        }
    }
    
    private func createUserRecord() {
        UserCloudKitUtility.createUser(username: "", phoneNumber: phoneNumber, name: name) { result in
            if case .failure(let error) = result {
                print("Error creating user: \(error)")
            }
        }
    }
}

struct CustomTextField: View {
    @Binding var text: String
    var placeholder: String
    var imageName: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: imageName)
                    .foregroundColor(Color.gray)
                
                TextField(placeholder, text: $text)
                    .font(.system(size: 18, weight: .light))
                    .keyboardType(keyboardType)
            }
            .padding(.vertical, 12)
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.3))
        }
    }
}


#Preview {
    IntroView {
        print("Intro completed")
    }
}
#Preview {
    IntroView {
        print("Intro completed")
    }
}
