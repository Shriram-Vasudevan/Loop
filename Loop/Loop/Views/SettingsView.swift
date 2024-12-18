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
    @StateObject private var notificationManager = NotificationManager.shared
    @AppStorage("iCloudBackupEnabled") private var isCloudBackupEnabled = false
    @State private var showingLogoutAlert = false
    @State private var showingContactView = false
    @State private var selectedWebView: WebViewData?
    @State private var reminderTime: Date
    @State private var showTimeSelector = false
    @State private var showNameEditor = false
    @State private var userName: String
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    private let backgroundColor = Color(hex: "FAFBFC")
    private let surfaceColor = Color(hex: "F8F5F7")
    private let version = "1.0.0"
    private let build = "42"
    
    init() {
        // Load name from UserDefaults
        let savedName = UserDefaults.standard.string(forKey: "userName") ?? "Set your name"
        _userName = State(initialValue: savedName)
        
        // Load reminder time from UserDefaults
        let savedTime = UserDefaults.standard.object(forKey: "reminderTime") as? Date
        let defaultTime = Calendar.current.date(from: DateComponents(hour: 21, minute: 0)) ?? Date()
        _reminderTime = State(initialValue: savedTime ?? defaultTime)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        profileCard
                        preferencesCard
                        supportCard
                        aboutCard
                        logoutButton
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showTimeSelector) {
                reminderPicker
            }
            .sheet(isPresented: $showingContactView) {
                ContactView()
            }
            .sheet(item: $selectedWebView) { webViewData in
                NavigationView {
                    WebView(url: webViewData.url)
                        .navigationTitle(webViewData.title)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            Button("Done") { selectedWebView = nil }
                        }
                }
            }
            .sheet(isPresented: $showNameEditor) {
                nameEditorView
            }
        }
    }
    
    private var profileCard: some View {
        Button(action: { showNameEditor = true }) {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 16) {
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
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(textColor)
                        
                        Text("Edit Profile")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(accentColor)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(textColor.opacity(0.3))
                }
            }
            .padding(20)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        }
    }
    
    private var nameEditorView: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    TextField("Your Name", text: $userName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(size: 17))
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    
                    Button(action: {
                        UserDefaults.standard.set(userName, forKey: "userName")
                        showNameEditor = false
                    }) {
                        Text("Save")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationTitle("Edit Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showNameEditor = false
                    }
                }
            }
        }
    }
    
    private var preferencesCard: some View {
        VStack(spacing: 1) {
            settingRow(title: "Notifications", icon: "bell.fill", hasToggle: true, isOn: notificationManager.isNotificationsEnabled) {
                notificationManager.toggleNotifications(enabled: !notificationManager.isNotificationsEnabled)
            }
            
            if notificationManager.isNotificationsEnabled {
                settingRow(title: "Reminder Time", icon: "clock.fill", subtitle: NotificationManager.shared.formatReminderTime(reminderTime)) {
                    showTimeSelector = true
                }
            }
            
            settingRow(title: "iCloud Backup", icon: "icloud.fill", hasToggle: true, isOn: isCloudBackupEnabled) {
                isCloudBackupEnabled.toggle()
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    private var supportCard: some View {
        VStack(spacing: 1) {
            settingRow(title: "Contact Support", icon: "envelope.fill") {
                showingContactView = true
            }
            
            settingRow(title: "Privacy Policy", icon: "lock.fill") {
                selectedWebView = WebViewData(
                    title: "Privacy Policy",
                    url: URL(string: "https://loopapp.com/privacy")!
                )
            }
            
            settingRow(title: "Terms of Service", icon: "doc.text.fill") {
                selectedWebView = WebViewData(
                    title: "Terms of Service",
                    url: URL(string: "https://loopapp.com/terms")!
                )
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    private var aboutCard: some View {
        VStack(spacing: 1) {
            settingRow(title: "Version", icon: "info.circle.fill", subtitle: "\(version) (\(build))")
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    private var logoutButton: some View {
        Button(action: { showingLogoutAlert = true }) {
            HStack {
                Spacer()
                Text("Log Out")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.red.opacity(0.8))
                Spacer()
            }
            .padding(.vertical, 16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        }
        .alert("Log Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) { }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }
    
    private var reminderPicker: some View {
        NavigationView {
            VStack {
                DatePicker("Select Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding()
                
                Button(action: {
                    UserDefaults.standard.set(reminderTime, forKey: "reminderTime")
                    NotificationManager.shared.saveAndScheduleReminder(at: reminderTime)
                    showTimeSelector = false
                }) {
                    Text("Set Reminder")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
            .navigationTitle("Set Daily Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showTimeSelector = false
                    }
                }
            }
        }
    }
    
    private func settingRow(
        title: String,
        icon: String,
        subtitle: String? = nil,
        hasToggle: Bool = false,
        isOn: Bool = false,
        action: (() -> Void)? = nil
    ) -> some View {
        Button(action: { action?() }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(accentColor)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(textColor)
                
                Spacer()
                
                if hasToggle {
                    Toggle("", isOn: Binding(
                        get: { isOn },
                        set: { _ in action?() }
                    ))
                    .tint(accentColor)
                } else if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 16))
                        .foregroundColor(textColor.opacity(0.6))
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(textColor.opacity(0.3))
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(Color.white)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ContactView: View {
    @Environment(\.dismiss) private var dismiss
    
    let contactMethods = [
        (title: "Email", value: "support@loopapp.com", icon: "envelope.fill", url: "mailto:support@loopapp.com"),
        (title: "Phone", value: "+1 (555) 123-4567", icon: "phone.fill", url: "tel:+15551234567")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "FAFBFC").ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ForEach(contactMethods, id: \.title) { method in
                        Button(action: {
                            if let url = URL(string: method.url) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: method.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(hex: "A28497"))
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(method.title)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(hex: "2C3E50"))
                                    Text(method.value)
                                        .font(.system(size: 16))
                                        .foregroundColor(Color(hex: "2C3E50"))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.forward")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "A28497"))
                            }
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                        }
                    }
                    
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Contact Us")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
