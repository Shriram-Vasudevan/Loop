//
//  IntroView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/1/24.
//

import SwiftUI

struct IntroView: View {
    @State private var currentStep: Int = 0
    @State private var showPermissionsScreen: Bool = false
    @State private var showUserInfoScreen: Bool = false
    @State private var showReminderScreen: Bool = false
    @State private var showiCloudPrompt: Bool = false
    @State private var permissionsGranted: Bool = false
    @State private var reminderTime: Date = Date()
    @State private var username: String = ""
    @State private var name: String = ""
    @State private var phoneNumber: String = ""
    private let totalSteps = 4
    var onIntroCompletion: () -> Void
    
    private let accentColor = Color(hex: "A28497")
    private let backgroundColor = Color.white
    private let groupBackgroundColor = Color(hex: "F8F5F7")
    
    var body: some View {
        ZStack {
            WaveBackground()
            
            VStack {
                if showReminderScreen {
                    reminderScreen
                } else if showUserInfoScreen {
                    userInfoScreen
                } else if showPermissionsScreen {
                    permissionsScreen
                } else if showiCloudPrompt {
                    iCloudPromptScreen
                } else {
                    contentView
                }
            }
            .padding(.horizontal, 24)
            .onAppear {
                if currentStep == totalSteps - 1 {
                    FirstLaunchManager.shared.checkiCloudAccountStatus { status in
                        if status == .noAccount {
                            showiCloudPrompt = true
                        }
                    }
                }
            }
        }
    }

    // MARK: - Onboarding Content View
    private var contentView: some View {
        VStack(spacing: 30) {
            VStack(spacing: 10) {
                Text(getTitle(for: currentStep))
                    .font(.system(size: 40, weight: .thin, design: .rounded))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.top)
                
                Text(getDescription(for: currentStep))
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.vertical, 30)
            
            Spacer()

            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 300, height: 300)
                
                Image("feature\(currentStep + 1)")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
            }
            .padding(.bottom, 40)
            
            Spacer()

            VStack(spacing: 20) {
                progressDots
                
                Button(action: {
                    withAnimation(.spring()) {
                        if currentStep < totalSteps - 1 {
                            currentStep += 1
                        } else {
                            showPermissionsScreen = true
                        }
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 70, height: 70)
                            .shadow(color: accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }

    // MARK: - Permissions Screen
    private var permissionsScreen: some View {
        VStack(spacing: 30) {
            VStack (spacing: 10) {
                Text("Loop needs permission to access your camera and microphone")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.vertical, 30)
            
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 200, height: 200)
                
                Image(systemName: "video.fill.badge.plus")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(accentColor)
            }
            
            Spacer()
            
            Button(action: {
                FirstLaunchManager.shared.requestVideoAndAudioPermissions { granted in
                    DispatchQueue.main.async {
                        permissionsGranted = granted
                        if granted {
                            showUserInfoScreen = true
                        }
                    }
                }
            }) {
                Text("Allow Access")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: 250, height: 60)
                    .background(accentColor)
                    .cornerRadius(30)
                    .shadow(color: accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .padding(.bottom, 25)
        }
        .padding(.horizontal)
    }
    
    // MARK: - User Information Screen
    private var userInfoScreen: some View {
        VStack(spacing: 30) {
            VStack (spacing: 10) {
                Text("Create Your Profile")
                    .font(.system(size: 36, weight: .thin, design: .rounded))
                    .foregroundColor(.black)
                
                Text("Let's set up your Loop account")
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.vertical, 30)
            
            VStack(spacing: 25) {
                CustomTextField(text: $username, placeholder: "Username", imageName: "person")
                CustomTextField(text: $name, placeholder: "Name", imageName: "person")
                CustomTextField(text: $phoneNumber, placeholder: "Phone Number", imageName: "phone")
            }
            .padding(.top, 30)
            
            Spacer()
            
            Button(action: {
                createUserRecord()
                showReminderScreen = true
            }) {
                Text("Continue")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: 250, height: 60)
                    .background(accentColor)
                    .cornerRadius(30)
                    .shadow(color: accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .padding(.bottom, 25)
            .disabled(username.isEmpty || phoneNumber.isEmpty)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Reminder Screen
    private var reminderScreen: some View {
        VStack(spacing: 30) {
            VStack (spacing: 10) {
                Text("Set your Loop Reminder")
                    .font(.system(size: 36, weight: .thin, design: .rounded))
                    .foregroundColor(.black)
                
                Text("Pick a time to be reminded daily to capture your thoughts")
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.vertical, 30)
            
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 300, height: 300)
                
                DatePicker("Select Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(WheelDatePickerStyle())
                    .frame(width: 250, height: 250)
                    .accentColor(accentColor)
            }
            .padding(.vertical, 20)
            
            Spacer()
            
            Button(action: {
                saveReminderTime()
                onIntroCompletion()
            }) {
                Text("Set Reminder")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: 250, height: 60)
                    .background(accentColor)
                    .cornerRadius(30)
                    .shadow(color: accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .padding(.bottom, 25)
        }
    }
    
    private var iCloudPromptScreen: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Please sign in to iCloud to save your loops")
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 200, height: 200)
                
                Image(systemName: "icloud.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(accentColor)
            }
            
            Spacer()
            
            Button(action: {
                // iCloud sign-in logic
            }) {
                Text("Sign in to iCloud")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: 250, height: 60)
                    .background(accentColor)
                    .cornerRadius(30)
                    .shadow(color: accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Progress Dots
    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps) { index in
                Circle()
                    .fill(currentStep == index ? accentColor : Color.gray.opacity(0.3))
                    .frame(width: 10, height: 10)
            }
        }
    }

    // MARK: - Helper Functions
    func getTitle(for step: Int) -> String {
        switch step {
        case 0: return "Welcome to Loop"
        case 1: return "Journaling Reimagined"
        case 2: return "Record Audio or Video"
        case 3: return "Sync Loops Securely"
        default: return ""
        }
    }
    
    func getDescription(for step: Int) -> String {
        switch step {
        case 0: return "Your personal space for mindful journaling."
        case 1: return "Easily capture your thoughts in audio or video form."
        case 2: return "Switch between audio or video recording for your journaling experience."
        case 3: return "Sync and store your loops securely via iCloud."
        default: return ""
        }
    }
    
    func saveReminderTime() {
        ReminderManager.shared.saveReminderTime(reminderTime)
    }
    
    private func createUserRecord() {
        UserCloudKitUtility.createUser(username: username, phoneNumber: phoneNumber, name: name) { result in
            if case .failure(let error) = result {
                print("Error creating user: \(error.localizedDescription)")
            }
        }
    }
}

struct CustomTextField: View {
    @Binding var text: String
    var placeholder: String
    var imageName: String
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: imageName)
                    .foregroundColor(Color.gray)
                TextField(placeholder,text: $text)
                    .font(.system(size: 18, weight: .regular, design: .rounded))
            }
            .padding(.vertical, 10)
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.5))
        }
        .padding(.horizontal)
    }
}

//struct WaveBackground: View {
//    @State private var waveOffset: CGFloat = 0
//    
//    var body: some View {
//        GeometryReader { geometry in
//            ZStack {
//                LinearGradient(gradient: Gradient(colors: [Color.white, Color(hex: "F8F5F7")]),
//                               startPoint: .topLeading, endPoint: .bottomTrailing)
//                    .edgesIgnoringSafeArea(.all)
//                
//                WaveLayer(phase: waveOffset, amplitude: 20, frequency: 1.5, color: Color(hex: "A28497").opacity(0.2), size: geometry.size)
//            }
//            .onAppear {
//                withAnimation(Animation.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
//                    waveOffset = 30
//                }
//            }
//        }
//    }
//}
//
//struct WaveLayer: View {
//    let phase: CGFloat
//    let amplitude: CGFloat
//    let frequency: CGFloat
//    let color: Color
//    let size: CGSize
//
//    var body: some View {
//        Path { path in
//            let midHeight = size.height * 0.5
//            let width = size.width
//
//            let stepSize: CGFloat = 5.0
//
//            path.move(to: CGPoint(x: 0, y: midHeight))
//
//            for x in stride(from: 0, to: width, by: stepSize) {
//                let relativeX = x / width
//                let y = midHeight + amplitude * sin(relativeX * frequency * 2 * .pi + phase)
//                path.addLine(to: CGPoint(x: x, y: y))
//            }
//
//            path.addLine(to: CGPoint(x: width, y: size.height))
//            path.addLine(to: CGPoint(x: 0, y: size.height))
//            path.closeSubpath()
//        }
//        .fill(color)
//        .offset(y: phase)
//    }
//}

#Preview {
    IntroView(onIntroCompletion: {
        print("Intro completed")
    })
}
