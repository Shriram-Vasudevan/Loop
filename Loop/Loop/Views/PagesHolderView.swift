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
    let secondaryColor = Color(hex: "B7A284")
    let backgroundColor = Color(hex: "FAFBFC")
    
    @State var showFreeResponseButton: Bool = false
    var body: some View {
        NavigationStack {
            ZStack {
                TabBarBackground()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Main content
                    switch pageType {
                    case .home:
                        HomeView(pageType: $pageType)
                    case .journal:
                        LoopsView()
                    case .schedule:
                        ScheduleView()
                    case .insights:
                       InsightsView()
                    }
                    
                    ZStack(alignment: .top) {
                        // Regular tab bar
                        HStack(spacing: 0) {
                            // First two items
                            ForEach([
                                (icon: "house", label: "Home", type: PageType.home),
                                (icon: "book", label: "Journal", type: PageType.journal),
                            ], id: \.label) { item in
                                BottomTabButton(
                                    icon: item.icon,
                                    label: item.label,
                                    isSelected: pageType == item.type,
                                    accentColor: accentColor
                                ) {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        pageType = item.type
                                    }
                                }
                            }
                            
                            Spacer()
                                .frame(maxWidth: .infinity)
                        
                            
                            ForEach([
                                (icon: "chart.bar", label: "Insights", type: PageType.insights),
                                (icon: "calendar", label: "Calendar", type: PageType.schedule)
                            ], id: \.label) { item in
                                BottomTabButton(
                                    icon: item.icon,
                                    label: item.label,
                                    isSelected: pageType == item.type,
                                    accentColor: accentColor
                                ) {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        pageType = item.type
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                        Button {
                            showFreeResponseButton = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 62, height: 62)
                                .background(
                                    Circle()
                                        .fill(accentColor)
                                        .shadow(color: accentColor.opacity(0.25), radius: 8, x: 0, y: 4)
                                )
                        }
                        .offset(y: -8)
                    }
                    .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 16) }
                    .background(
                        backgroundColor.opacity(0.95)
                            .ignoresSafeArea(edges: .bottom)
                    )
                    
                }
            }
            .edgesIgnoringSafeArea(.bottom)
            .persistentSystemOverlays(.hidden)
            .fullScreenCover(isPresented: $showFreeResponseButton) {
                RecordFreeResponseView(prompt: "Share Absolutely Anything")
            }
        }
    }
}

struct TabBarBackground: View {
    let accentColor = Color(hex: "A28497")
    let secondaryColor = Color(hex: "B7A284")
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color(hex: "FAFBFC")
            
            GeometryReader { geometry in
                ZStack {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(
                                [accentColor, secondaryColor][index % 2]
                                    .opacity(0.04)
                            )
                            .frame(width: CGFloat(30 + index * 15))
                            .offset(
                                x: geometry.size.width * (0.3 + CGFloat(index) * 0.2),
                                y: geometry.size.height - CGFloat(100 + index * 20)
                            )
                            .blur(radius: 15)
                            .opacity(isAnimating ? 0.8 : 0.4)
                            .animation(
                                Animation.easeInOut(duration: 3)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.5),
                                value: isAnimating
                            )
                    }
                }
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct BottomTabButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: isSelected ? .medium : .light))
                    .foregroundColor(isSelected ? accentColor : .gray.opacity(0.5))
                    .frame(height: 18)
                
                Text(label)
                    .font(.system(size: 10, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? accentColor : .gray.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(TabButtonStyle())
    }
}

struct TabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    PagesHolderView(pageType: .home)
}
