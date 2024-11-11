//
//  PagesHolderView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/7/24.
//

import SwiftUI

struct PagesHolderView: View {
    @State var pageType: PageType
    let accentColor = Color(hex: "A28497")
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // Main content
                    switch pageType {
                    case .home:
                        HomeView()
                    case .journal:
                        LoopsView()
                    case .settings:
                        SettingsView()
                    case .insights:
                        InsightsView()
                    }
                    
                    // Custom tab bar
                    HStack(spacing: 0) {
                        // Home tab
                        TabBarButton(
                            icon: "house",
                            label: "home",
                            isSelected: pageType == .home,
                            accentColor: accentColor
                        ) {
                            pageType = .home
                        }
                        
                        // Journal tab
                        TabBarButton(
                            icon: "book",
                            label: "journal",
                            isSelected: pageType == .journal,
                            accentColor: accentColor
                        ) {
                            pageType = .journal
                        }
                        
                        // Center Record Button
                        RecordButton(accentColor: accentColor) {
                            // Handle record action
                        }
                        

                        TabBarButton(
                            icon: "chart.bar",
                            label: "insights",
                            isSelected: pageType == .insights,
                            accentColor: accentColor
                        ) {
                            pageType = .insights
                        }
                        
                        // Settings tab
                        TabBarButton(
                            icon: "gearshape",
                            label: "settings",
                            isSelected: pageType == .settings,
                            accentColor: accentColor
                        ) {
                            pageType = .settings
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                    .background(
                        Color.white
                            .shadow(color: Color.black.opacity(0.05), radius: 20, y: -5)
                    )
                }
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }
}

struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? accentColor : .gray.opacity(0.8))
                
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? accentColor : .gray.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct RecordButton: View {
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [accentColor, accentColor.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: accentColor.opacity(0.3), radius: 10)
                
                Image(systemName: "waveform")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    PagesHolderView(pageType: .home)
}
