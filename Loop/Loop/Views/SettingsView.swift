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
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    private let version = "1.0.0"
    private let build = "42"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    Text("settings")
                        .font(.system(size: 40, weight: .ultraLight))
                        .foregroundColor(textColor)
                    Spacer()
                }
                .padding(.top, 16)
                
                SettingsSection(
                    title: "account",
                    rows: [
                        SettingsRowContent(icon: "person.circle", title: "John Appleseed", subtitle: "Premium Member"),
                        SettingsRowContent(icon: "envelope", title: "john@email.com")
                    ]
                )
                
                SettingsSection(
                    title: "preferences",
                    rows: [
                        SettingsRowContent(icon: "bell", title: "notifications", isToggle: true, toggleValue: notificationsEnabled),
                        SettingsRowContent(icon: "clock", title: "reminder time", subtitle: "9:00 PM"),
                        SettingsRowContent(icon: "square.stack", title: "data storage", subtitle: "42.8 MB")
                    ]
                )
                
                SettingsSection(
                    title: "support",
                    rows: [
                        SettingsRowContent(icon: "questionmark.circle", title: "help center"),
                        SettingsRowContent(icon: "envelope.badge", title: "contact us"),
                        SettingsRowContent(icon: "doc.text", title: "privacy policy"),
                        SettingsRowContent(icon: "doc", title: "terms of service")
                    ]
                )
                
                SettingsSection(
                    title: "app info",
                    rows: [
                        SettingsRowContent(icon: "info.circle", title: "version", subtitle: "\(version) (\(build))")
                    ]
                )
                
                Button(action: { showingLogoutAlert = true }) {
                    Text("log out")
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
                .padding(.top, 8)
                .alert("Log Out", isPresented: $showingLogoutAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Log Out", role: .destructive) { }
                } message: {
                    Text("Are you sure you want to log out?")
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color(hex: "FAFBFC"))
    }
}

struct SettingsRowContent {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var isToggle: Bool = false
    var toggleValue: Bool = false
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
                ForEach(rows.indices, id: \.self) { index in
                    SettingsRow(content: rows[index])
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
    @State private var toggleState: Bool
    
    init(content: SettingsRowContent) {
        self.content = content
        _toggleState = State(initialValue: content.toggleValue)
    }
    
    var body: some View {
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
                Toggle("", isOn: $toggleState)
                    .tint(Color(hex: "A28497"))
            } else if content.subtitle == nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "2C3E50").opacity(0.3))
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(Color.white)
    }
}

#Preview {
    SettingsView()
}
