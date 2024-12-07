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
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    private let backgroundColor = Color(hex: "FAFBFC")
    private let version = "1.0.0"
    private let build = "42"
    
    init() {
        let defaultTime = Calendar.current.date(from: DateComponents(hour: 21, minute: 0)) ?? Date()
        _reminderTime = State(initialValue: NotificationManager.shared.loadReminderTime() ?? defaultTime)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        accountSection
                        notificationSection
                        backupSection
                        supportSection
                        appInfoSection
                        logoutButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 32)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showTimeSelector) {
                TimePickerView(selectedTime: $reminderTime) {
                    NotificationManager.shared.saveAndScheduleReminder(at: reminderTime)
                }
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
        }
    }
    
    private var accountSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Image("profile_picture")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(accentColor.opacity(0.2), lineWidth: 2))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("John Appleseed")
                        .font(.title3)
                        .fontWeight(.medium)
                    Text("Premium Member")
                        .font(.subheadline)
                        .foregroundColor(accentColor)
                }
                Spacer()
            }
            .padding(20)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
        }
    }
    
    private var notificationSection: some View {
        VStack(spacing: 2) {
            settingsToggle(
                title: "Notifications",
                icon: "bell.fill",
                isOn: notificationManager.isNotificationsEnabled,
                action: { toggleNotifications() }
            )
            
            if notificationManager.isNotificationsEnabled {
                Button(action: { showTimeSelector = true }) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(accentColor)
                            .frame(width: 24)
                        
                        Text("Daily Reminder")
                            .foregroundColor(textColor)
                        
                        Spacer()
                        
                        Text(NotificationManager.shared.formatReminderTime(reminderTime))
                            .foregroundColor(textColor.opacity(0.6))
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(Color.white)
                }
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
    }
    
    private var backupSection: some View {
        settingsToggle(
            title: "iCloud Backup",
            icon: "icloud.fill",
            isOn: isCloudBackupEnabled,
            action: { isCloudBackupEnabled.toggle() }
        )
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
    }
    
    private var supportSection: some View {
        VStack(spacing: 2) {
            settingsButton(title: "Contact Us", icon: "envelope.fill") {
                showingContactView = true
            }
            settingsButton(title: "Privacy Policy", icon: "lock.fill") {
                openPrivacyPolicy()
            }
            settingsButton(title: "Terms of Service", icon: "doc.fill") {
                openTermsOfService()
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
    }
    
    private var appInfoSection: some View {
        HStack {
            Image(systemName: "info.circle.fill")
                .foregroundColor(accentColor)
                .frame(width: 24)
            
            Text("Version")
                .foregroundColor(textColor)
            
            Spacer()
            
            Text("\(version) (\(build))")
                .foregroundColor(textColor.opacity(0.6))
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
    }
    
    private var logoutButton: some View {
        Button(action: { showingLogoutAlert = true }) {
            Text("Log Out")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.red.opacity(0.8))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
        }
        .alert("Log Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) { }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }
    
    private func settingsToggle(title: String, icon: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(accentColor)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(textColor)
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { isOn },
                set: { _ in action() }
            ))
            .tint(accentColor)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
    }
    
    private func settingsButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(accentColor)
                    .frame(width: 24)
                
                Text(title)
                    .foregroundColor(textColor)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(textColor.opacity(0.3))
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
        }
    }
    
    private func toggleNotifications() {
        notificationManager.toggleNotifications(enabled: !notificationManager.isNotificationsEnabled)
    }
    
    private func openPrivacyPolicy() {
        selectedWebView = WebViewData(
            title: "Privacy Policy",
            url: URL(string: "https://loopapp.com/privacy")!
        )
    }
    
    private func openTermsOfService() {
        selectedWebView = WebViewData(
            title: "Terms of Service",
            url: URL(string: "https://loopapp.com/terms")!
        )
    }
}

struct TimePickerView: View {
    @Binding var selectedTime: Date
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "FAFBFC").ignoresSafeArea()
                
                VStack(spacing: 24) {
                    CircularTimePicker(selectedTime: $selectedTime)
                        .padding(.top, 32)
                    
                    Button(action: {
                        onSave()
                        dismiss()
                    }) {
                        Text("Set Reminder")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "A28497"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Daily Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct CircularTimePicker: View {
    @Binding var selectedTime: Date
    private let calendar = Calendar.current
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1)) { _ in
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2 - 40
                
                let components = calendar.dateComponents([.hour, .minute], from: selectedTime)
                let hour = Double(components.hour ?? 0)
                let minute = Double(components.minute ?? 0)
                
                let hourAngle = (hour + minute / 60) * .pi / 6 - .pi / 2
                let minuteAngle = minute * .pi / 30 - .pi / 2
                
                for i in 0..<12 {
                    let angle = Double(i) * .pi / 6
                    let point = CGPoint(
                        x: center.x + Darwin.cos(angle) * radius,
                        y: center.y + Darwin.sin(angle) * radius
                    )
                    
                    context.draw(Text("\(i == 0 ? 12 : i)"), at: point)
                }
                
                context.stroke(
                    Path { path in
                        path.addArc(
                            center: center,
                            radius: radius,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360),
                            clockwise: false
                        )
                    },
                    with: .color(Color(hex: "A28497").opacity(0.2)),
                    lineWidth: 2
                )
                
                context.stroke(
                    Path { path in
                        path.move(to: center)
                        path.addLine(to: CGPoint(
                            x: center.x + cos(hourAngle) * radius * 0.6,
                            y: center.y + sin(hourAngle) * radius * 0.6
                        ))
                    },
                    with: .color(Color(hex: "A28497")),
                    lineWidth: 3
                )
                
                context.stroke(
                    Path { path in
                        path.move(to: center)
                        path.addLine(to: CGPoint(
                            x: center.x + cos(minuteAngle) * radius * 0.8,
                            y: center.y + sin(minuteAngle) * radius * 0.8
                        ))
                    },
                    with: .color(Color(hex: "A28497")),
                    lineWidth: 2
                )
            }
            .frame(width: 300, height: 300)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let center = CGPoint(x: 150, y: 150)
                        let angle = atan2(value.location.y - center.y, value.location.x - center.x)
                        let minutes = Int((angle + .pi / 2) * 30 / .pi)
                        let normalizedMinutes = (minutes + 60) % 60
                        
                        var components = calendar.dateComponents([.hour, .minute], from: selectedTime)
                        components.minute = normalizedMinutes
                        
                        if let newTime = calendar.date(from: components) {
                            selectedTime = newTime
                        }
                    }
            )
        }
    }
}

struct ContactView: View {
    @Environment(\.dismiss) private var dismiss
    
    let contacts: [ContactMethod] = [
        .email("support@loopapp.com"),
        .phone("+1 (555) 123-4567")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "FAFBFC").ignoresSafeArea()
                
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        ForEach(contacts) { contact in
                            Button(action: {
                                handleContact(contact)
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: contact.icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(Color(hex: "A28497"))
                                        .frame(width: 24)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(contact.title)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Color(hex: "2C3E50"))
                                        Text(contact.value)
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
                                .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
                .padding(.top, 20)
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
    
    private func handleContact(_ contact: ContactMethod) {
        switch contact {
        case .email(let email):
            if let url = URL(string: "mailto:\(email)") {
                UIApplication.shared.open(url)
            }
        case .phone(let phone):
            if let url = URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))") {
                UIApplication.shared.open(url)
            }
        }
    }
}
