//
//  SettingsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/9/24.
//

import SwiftUI



struct SettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @State private var showingLogoutAlert = false
    @State private var showingTimePicker = false
    @State private var showingContactView = false
    @State private var selectedWebView: WebViewData?
    @State private var reminderTime: Date
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    private let version = "1.0.0"
    private let build = "42"
    
    init() {
        let defaultTime = Calendar.current.date(from: DateComponents(hour: 21, minute: 0)) ?? Date()
        _reminderTime = State(initialValue: NotificationManager.shared.loadReminderTime() ?? defaultTime)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    SettingsSection(
                        title: "account",
                        rows: [
                            SettingsRowContent(icon: "person.circle", title: "John Appleseed", subtitle: "Premium Member"),
                            SettingsRowContent(icon: "envelope", title: "john@email.com")
                        ]
                    )
                    
                    SettingsSection(
                        title: "notifications",
                        rows: [
                            SettingsRowContent(
                                icon: "bell",
                                title: "Enable Notifications",
                                isToggle: true,
                                toggleValue: notificationsEnabled,
                                action: { toggleNotifications() }
                            ),
                            SettingsRowContent(
                                icon: "clock",
                                title: "Reminder Time",
                                subtitle: NotificationManager.shared.formatReminderTime(reminderTime),
                                action: { showingTimePicker = true }
                            )
                        ]
                    )
                    
                    SettingsSection(
                        title: "support",
                        rows: [
                            SettingsRowContent(
                                icon: "envelope.badge",
                                title: "Contact Us",
                                action: { showingContactView = true }
                            ),
                            SettingsRowContent(
                                icon: "doc.text",
                                title: "Privacy Policy",
                                action: { openPrivacyPolicy() }
                            ),
                            SettingsRowContent(
                                icon: "doc",
                                title: "Terms of Service",
                                action: { openTermsOfService() }
                            )
                        ]
                    )
                    
                    SettingsSection(
                        title: "app info",
                        rows: [
                            SettingsRowContent(
                                icon: "info.circle",
                                title: "Version",
                                subtitle: "\(version) (\(build))"
                            )
                        ]
                    )
                    
                    Button(action: { showingLogoutAlert = true }) {
                        Text("Log Out")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.red.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.04), radius: 10)
                            )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .background(Color(hex: "FAFBFC"))
            .navigationTitle("Settings")
            .sheet(isPresented: $showingTimePicker) {
                NotificationTimePicker(selectedTime: $reminderTime)
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
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    selectedWebView = nil
                                }
                            }
                        }
                }
            }
            .alert("Log Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) { }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
    }
    
    private func toggleNotifications() {
//        if notificationsEnabled {
//            NotificationManager.shared.requestNotificationPermissions { granted in
//                if !granted {
//                    notificationsEnabled = false
//                }
//            }
//        } else {
//            NotificationManager.shared.disableReminder()
//        }
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


struct SettingsSection: View {
    let title: String
    let rows: [SettingsRowContent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 16, weight: .ultraLight))
                .foregroundColor(Color(hex: "2C3E50"))
                .textCase(.lowercase)
            
            VStack(spacing: 1) {
                ForEach(rows) { row in
                    SettingsRow(content: row)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 10)
            )
        }
    }
}

struct SettingsRow: View {
    let content: SettingsRowContent
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    
    var body: some View {
        Button(action: { content.action?() }) {
            HStack(spacing: 16) {
                Image(systemName: content.icon)
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(Color(hex: "A28497"))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(content.title)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color(hex: "2C3E50"))
                    
                    if let subtitle = content.subtitle {
                        Text(subtitle)
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(Color(hex: "2C3E50").opacity(0.6))
                    }
                }
                
                Spacer()
                
                if content.isToggle {
                    Toggle("", isOn: $notificationsEnabled)
                        .tint(Color(hex: "A28497"))
                } else if content.action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "2C3E50").opacity(0.3))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(Color.white)
    }
}

struct NotificationTimePicker: View {
    @Binding var selectedTime: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker("Select Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding()
                
                Button("Set Time") {
                    NotificationManager.shared.saveAndScheduleReminder(at: selectedTime)
                    dismiss()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "A28497"))
                .cornerRadius(12)
                .padding()
            }
            .navigationTitle("Reminder Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct ContactView: View {
    let contacts: [ContactMethod] = [
        .email("support@loopapp.com"),
        .phone("+1 (555) 123-4567")
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Contact Us")
                .font(.system(size: 28, weight: .light))
                .padding(.top)
            
            VStack(spacing: 16) {
                ForEach(contacts) { contact in
                    HStack(spacing: 16) {
                        Image(systemName: contact.icon)
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "A28497"))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(contact.title)
                                .font(.system(size: 14, weight: .medium))
                            Text(contact.value)
                                .font(.system(size: 16))
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.04), radius: 8)
                    )
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .background(Color(hex: "FAFBFC"))
    }
}
