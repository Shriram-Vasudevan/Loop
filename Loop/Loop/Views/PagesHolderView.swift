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
                    
                    // Modern tab bar
                    HStack(spacing: 0) {
                        ForEach([
                            (icon: "house", label: "Home", type: PageType.home),
                            (icon: "book", label: "Journal", type: PageType.journal),
                            (icon: "chart.bar", label: "Insights", type: PageType.insights),
                            (icon: "gearshape", label: "Settings", type: PageType.settings)
                        ], id: \.label) { item in
                            TabBarButton(
                                icon: item.icon,
                                label: item.label,
                                isSelected: pageType == item.type,
                                accentColor: accentColor
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    pageType = item.type
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                    .background(
                        Color.white
                            .shadow(color: Color.black.opacity(0.07), radius: 15, y: -3)
                            .mask(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .padding(.top, -20)
                            )
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
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? accentColor : .gray.opacity(0.7))
                    .frame(height: 24)
                
                Text(label)
                    .font(.system(size: 12, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? accentColor : .gray.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(TabBarButtonStyle())
    }
}

struct TabBarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}


#Preview {
    PagesHolderView(pageType: .home)
}
