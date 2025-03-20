//
//  SettingsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/9/24.
//


import SwiftUI
import Foundation
import Darwin
struct SettingsView: View {
    @ObservedObject private var notificationManager = NotificationManager.shared
    @ObservedObject var premiumManager = PremiumManager.shared
    
    @AppStorage("iCloudBackupEnabled") private var isCloudBackupEnabled = false
    @State private var showingLogoutAlert = false
    @State private var showingContactView = false
    @State private var showingReviewPrompt = false
    @State private var selectedWebView: WebViewData?
    @State private var reminderTime: Date
    @State private var morningReminderTime: Date
    @State private var showTimeSelector = false
    @State private var showMorningTimeSelector = false
    @State private var showNameEditor = false
    @State private var userName: String
    @State private var animateContent = false
    @State private var timePickerType: TimePickerType = .evening
    
    @State private var showingPremiumUpgrade = false
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    enum TimePickerType {
        case morning
        case evening
    }
    
    @Environment(\.dismiss) var dismiss
    
    init() {
        let savedName = UserDefaults.standard.string(forKey: "userName") ?? "Set your name"
        _userName = State(initialValue: savedName)
        
        let savedTime = UserDefaults.standard.object(forKey: "reminderTime") as? Date
        let defaultTime = Calendar.current.date(from: DateComponents(hour: 21, minute: 0)) ?? Date()
        _reminderTime = State(initialValue: savedTime ?? defaultTime)
        
        let savedMorningTime = UserDefaults.standard.object(forKey: "morningReminderTime") as? Date
        let defaultMorningTime = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
        _morningReminderTime = State(initialValue: savedMorningTime ?? defaultMorningTime)
    }
    
    var body: some View {
        ZStack {
            Color(hex: "F5F5F5")
                .ignoresSafeArea(.all)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 40) {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(textColor)
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 16) {
                        header
                        
                        if !premiumManager.isUserPremium() {
                            premiumWidget
                        }
                    }
                
                    preferencesSection
                    
                    socialSection
                    
                    supportSection
                    
                    Spacer(minLength: 60)
                }
                .padding(.horizontal, 24)
            }
        }
        .sheet(isPresented: $showTimeSelector) {
            TimePickerSheet(
                selectedTime: $reminderTime,
                onSave: { newTime in
                    UserDefaults.standard.set(newTime, forKey: "reminderTime")
                    NotificationManager.shared.saveAndScheduleReminder(at: newTime)
                },
                pickerTitle: "daily reminder",
                timePickerType: .evening
            )
            .presentationDetents([.fraction(0.7)])
        }
        .sheet(isPresented: $showMorningTimeSelector) {
            TimePickerSheet(
                selectedTime: $morningReminderTime,
                onSave: { newTime in
                    UserDefaults.standard.set(newTime, forKey: "morningReminderTime")
                    NotificationManager.shared.saveAndScheduleMorningReminder(at: newTime)
                },
                pickerTitle: "morning reflection",
                timePickerType: .morning
            )
            .presentationDetents([.fraction(0.7)])
        }
        .sheet(isPresented: $showingContactView) { ContactView() }
        .sheet(item: $selectedWebView) { webViewData in
            webView(for: webViewData)
        }
        .sheet(isPresented: $showNameEditor) { nameEditorView }
        .sheet(isPresented: $showingPremiumUpgrade) {
            PremiumUpgradeView(onIntroCompletion: {
                showingPremiumUpgrade = false
            })
        }
        .alert("Leave a Review", isPresented: $showingReviewPrompt) {
            Button("Not Now", role: .cancel) { }
            Button("Review on App Store") {
                if let writeReviewURL = URL(string: "https://apps.apple.com/us/app/loop-daily-reflections/id6738974660?action=write-review") {
                    UIApplication.shared.open(writeReviewURL)
                }
            }
        }
    }
    
    
    private var header: some View {
        HStack {
            Text("Profile")
                .font(.custom("PPNeueMontreal-Medium", size: 36))
                .foregroundColor(textColor)
            Spacer()
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateContent = true
            }
        }
    }
    
    private var premiumWidget: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                Text("Unlimited entry length, custom prompts, and more")
                    .font(.custom("PPNeueMontreal-Medium", size: 20))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                
                Text("try loop premium.")
                    .font(.system(size: 17))
                    .foregroundColor(textColor.opacity(0.6))
                    .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.top, 48)
            
            HStack {
                Spacer()
                
                Button(action: {
                    showPremiumUpgrade()
                }, label: {
                    Text("Subscribe")
                        .foregroundColor(textColor)
                        .padding()
                        .padding(.horizontal, 12)
                        .background(
                            Capsule()
                                .stroke(style: StrokeStyle(lineWidth: 1))
                                .foregroundColor(textColor.opacity(0.7))
                        )
                        .padding(.top, 12)
                })
                .padding(.bottom, 24)
                
                Spacer()
            }
        }
        .background(ZStack{
            Color.white
            
            VStack {
                Spacer()
                
                Image(systemName: "quote.opening")
                    .font(.system(size: 200))
                    .foregroundColor(Color(hex: "E9ECEF"))
                    .offset(x: 0, y: -50)
                    .scaleEffect(y: -1)
                    .opacity(0.6)
            }
        })
        .cornerRadius(10)
    }
    
    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Button(action: { showNameEditor = true }) {
                HStack(spacing: 20) {
                    Circle()
                        .fill(accentColor.opacity(0.1))
                        .frame(width: 64, height: 64)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 24))
                                .foregroundColor(accentColor)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(userName)
                            .font(.custom("PPNeueMontreal-Medium", size: 22))
                            .foregroundColor(textColor)
                        
                        Text("tap to edit")
                            .font(.system(size: 15))
                            .foregroundColor(textColor.opacity(0.5))
                    }
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.white)
        )
    }
    
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Preferences")
            
            VStack(spacing: 32) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Daily Reminders")
                                .font(.custom("PPNeueMontreal-Medium", size: 17))
                                .foregroundColor(textColor)
                        }
                        
                        Spacer()
                        
                        MinimalToggle(isOn: Binding(
                            get: { notificationManager.isNotificationsEnabled },
                            set: { _ in
                                notificationManager.toggleNotifications(enabled: !notificationManager.isNotificationsEnabled)
                            }
                        ))
                    }
                    
                    if notificationManager.isNotificationsEnabled {
                        Button(action: { showTimeSelector = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "moon.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(accentColor)
                                
                                Text("Evening Reflection - \(NotificationManager.shared.formatReminderTime(reminderTime))")
                                    .font(.system(size: 15))
                                    .foregroundColor(textColor.opacity(0.5))
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(textColor.opacity(0.3))
                            }
                        }
                        
                        Button(action: { showMorningTimeSelector = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "sun.max.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(accentColor)
                                
                                Text("Morning Reflection - \(NotificationManager.shared.formatReminderTime(morningReminderTime))")
                                    .font(.system(size: 15))
                                    .foregroundColor(textColor.opacity(0.5))
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(textColor.opacity(0.3))
                            }
                        }
                    }
                }

                iCloudBackupSection
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.white)
            )
        }
    }
    
    var iCloudBackupSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("iCloud Backup")
                    .font(.custom("PPNeueMontreal-Medium", size: 17))
                    .foregroundColor(textColor)
                
                if premiumManager.isUserPremium() {
                    Text("Sync your journal across devices")
                        .font(.system(size: 15))
                        .foregroundColor(textColor.opacity(0.5))
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 12))
                            .foregroundColor(accentColor)
                        
                        Text("Premium feature")
                            .font(.system(size: 15))
                            .foregroundColor(accentColor)
                    }
                }
            }
            
            Spacer()

            if premiumManager.isUserPremium() {
                MinimalToggle(isOn: $isCloudBackupEnabled)
            } else {
                Button(action: {
                    initiateUpgradeToPremium()
                }) {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                }
            }
        }
    }

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Support")
            
            VStack(spacing: 32) {
                supportLink("Contact Us", icon: "envelope.fill") {
                    showingContactView = true
                }
                
                
                
                supportLink("Privacy Policy", icon: "lock.fill") {
                    selectedWebView = WebViewData(
                        title: "Privacy Policy",
                        url: URL(string: "https://loopapp.com/privacy")!
                    )
                }
                
                supportLink("Terms of Service", icon: "doc.text.fill") {
                    selectedWebView = WebViewData(
                        title: "Terms of Service",
                        url: URL(string: "https://loopapp.com/terms")!
                    )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.white)
            )
        }
    }
    
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(spacing: 24) {
                Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")")
                    .font(.system(size: 15))
                    .foregroundColor(textColor.opacity(0.5))
                
                Button(action: { showingLogoutAlert = true }) {
                    Text("Log Out")
                        .font(.custom("PPNeueMontreal-Medium", size: 17))
                        .foregroundColor(.red.opacity(0.8))
                }
                .alert("Log Out", isPresented: $showingLogoutAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Log Out", role: .destructive) {
                        print("logging out")
                        FirstLaunchManager.shared.isFirstLaunch = true
                    }
                }
            }
        }
    }
    
    
    private var socialSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Social")
            
            VStack(spacing: 32) {
                Button(action: {
                    showingReviewPrompt = true
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 16))
                            .foregroundColor(accentColor)
                        
                        Text("Leave a Review")
                            .font(.custom("PPNeueMontreal-Medium", size: 17))
                            .foregroundColor(textColor)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(textColor.opacity(0.3))
                    }
                }
                
                socialLink("Follow us on Instagram", icon: "insta") {
                    if let url = URL(string: "https://www.instagram.com/joinloop.app/") {
                        UIApplication.shared.open(url)
                    }
                }
                
                socialLink("Follow us on TikTok", icon: "tiktok") {
                    if let url = URL(string: "https://tiktok.com/@loopapp") {
                        UIApplication.shared.open(url)
                    }
                }
                
                socialLink("Visit our Website", icon: "link") {
                    if let url = URL(string: "https://seeloop.app") {
                        UIApplication.shared.open(url)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.white)
            )
            .navigationBarBackButtonHidden()
        }
    }
    
    private func socialLink(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(icon)
                    .resizable()
                    .frame(width: 16, height: 16)
                    .font(.system(size: 16))
                    .foregroundColor(accentColor)
                
                Text(title)
                    .font(.custom("PPNeueMontreal-Medium", size: 17))
                    .foregroundColor(textColor)
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14))
                    .foregroundColor(textColor.opacity(0.3))
            }
        }
    }
    
    private func sectionTitle(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(textColor.opacity(0.5))
            .tracking(1.5)
    }
    
    private func supportLink(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(accentColor)
                
                Text(title)
                    .font(.custom("PPNeueMontreal-Medium", size: 17))
                    .foregroundColor(textColor)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(textColor.opacity(0.3))
            }
        }
    }
    
    private func initiateUpgradeToPremium() {
        showPremiumUpgrade()
    }
    
    private func showPremiumUpgrade() {
        showingPremiumUpgrade = true
    }

}

struct MinimalToggle: View {
    @Binding var isOn: Bool
    
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        Button(action: { isOn.toggle() }) {
            Circle()
                .stroke(isOn ? accentColor : Color.gray.opacity(0.3), lineWidth: 1.5)
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .fill(isOn ? accentColor : Color.clear)
                        .frame(width: 16, height: 16)
                )
        }
    }
}

extension SettingsView {
    var reminderPicker: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                    
                VStack(spacing: 32) {
                    DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        
                    Button(action: {
                        UserDefaults.standard.set(reminderTime, forKey: "reminderTime")
                        NotificationManager.shared.saveAndScheduleReminder(at: reminderTime)
                        showTimeSelector = false
                    }) {
                        Text("Set Time")
                            .font(.custom("PPNeueMontreal-Medium", size: 17))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(accentColor)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { showTimeSelector = false }
                }
            }
        }
    }
    var nameEditorView: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Text("What should we call you?")
                        .font(.custom("PPNeueMontreal-Medium", size: 22))
                        .foregroundColor(textColor)
                        .padding(.top, 40)
                    
                    TextField("Your Name", text: $userName)
                        .font(.custom("PPNeueMontreal-Medium", size: 34))
                        .foregroundColor(textColor)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(.plain)
                    
                    Spacer()
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showNameEditor = false }) {
                        Text("Cancel")
                            .font(.system(size: 17))
                            .foregroundColor(textColor)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        UserDefaults.standard.set(userName, forKey: "userName")
                        showNameEditor = false
                    }) {
                        Text("Save")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(accentColor)
                    }
                }
            }
        }
    }
    
    func webView(for webViewData: WebViewData) -> some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                WebView(url: webViewData.url)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(webViewData.title)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { selectedWebView = nil }) {
                        Text("Done")
                            .font(.system(size: 17))
                            .foregroundColor(textColor)
                    }
                }
            }
        }
    }
    
    private func timeFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date).lowercased()
    }
}

struct ContactView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    private let contactMethods = [
        ContactMethod(
            title: "Send us an email",
            description: "support@loopapp.com",
            icon: "envelope.fill",
            url: "mailto:loopapp.help@gmail.com"
        ),
        ContactMethod(
            title: "Call us",
            description: "+1 (973) 610-9630",
            icon: "phone.fill",
            url: "tel:+15551234567"
        )
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 40) {
                    Text("How can we help?")
                        .font(.custom("PPNeueMontreal-Medium", size: 28))
                        .foregroundColor(textColor)
                        .padding(.top, 20)
                    
                    VStack(spacing: 32) {
                        ForEach(contactMethods) { method in
                            Button(action: {
                                if let url = URL(string: method.url) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 20) {
                                    Image(systemName: method.icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(accentColor)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(method.title)
                                            .font(.custom("PPNeueMontreal-Medium", size: 17))
                                            .foregroundColor(textColor)
                                        
                                        Text(method.description)
                                            .font(.system(size: 15))
                                            .foregroundColor(textColor.opacity(0.5))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(textColor.opacity(0.3))
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .font(.system(size: 17))
                            .foregroundColor(textColor)
                    }
                }
            }
        }
    }
}

struct TimePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTime: Date
    let onSave: (Date) -> Void
    let pickerTitle: String
    let timePickerType: SettingsView.TimePickerType
    
    @State private var opacity = 0.0
    @State private var sheetOffset: CGFloat = 1000
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 38, height: 4)
                        .padding(.top, 12)
                    
                    Text(pickerTitle)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(textColor.opacity(0.6))
                        .tracking(1.2)
                        .padding(.top, 8)
                    
                    HStack {
                        if timePickerType == .morning {
                            Image(systemName: "sun.max.fill")
                                .foregroundColor(accentColor)
                                .font(.system(size: 32))
                                .padding(.trailing, 8)
                        } else {
                            Image(systemName: "moon.fill")
                                .foregroundColor(accentColor)
                                .font(.system(size: 32))
                                .padding(.trailing, 8)
                        }
                        
                        Text(timeFormatted(selectedTime))
                            .font(.custom("PPNeueMontreal-Medium", size: 58))
                            .foregroundColor(textColor)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .background(
                    RoundedRectangle(cornerRadius: 32)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 20, y: 10)
                )
                .padding(.horizontal, 20)
                
                DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding(.top, 40)
                    .colorMultiply(accentColor.opacity(0.8))

                HStack(spacing: 16) {
                    Button(action: hideSheet) {
                        Text("Cancel")
                            .font(.system(size: 17))
                            .foregroundColor(textColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .cornerRadius(18)
                    }
                    
                    Button(action: {
                        onSave(selectedTime)
                        hideSheet()
                    }) {
                        Text("Set Time")
                            .font(.custom("PPNeueMontreal-Medium", size: 17))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(accentColor)
                            .cornerRadius(18)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color(hex: "FAFBFC"))
            )
        }
    }
    
    private func timeFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date).lowercased()
    }
    
    private func showSheet() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            opacity = 1
            sheetOffset = 280
        }
    }
    
    private func hideSheet() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            opacity = 0
            sheetOffset = 1000
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            dismiss()
        }
    }
}


struct ContactMethod: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let url: String
}


#Preview {
    SettingsView()
}
