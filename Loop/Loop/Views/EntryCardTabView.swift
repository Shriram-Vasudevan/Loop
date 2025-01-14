import SwiftUI

import SwiftUI

struct FloatingEntryMenu: View {
    @Binding var newEntrySelected: Bool
    @Binding var successSelected: Bool
    @Binding var moodCheckIn: Bool
    @State private var isMenuOpen = true
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        ZStack {
            // Background overlay
            if isMenuOpen {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            isMenuOpen = false
                        }
                    }
            }
            
            // Menu items
            VStack(spacing: 0) {
                Spacer()
                
                // Entry buttons container
                VStack(spacing: 24) {
                    // New Entry
                    EntryButton(
                        title: "New Entry",
                        subtitle: "Record your thoughts and feelings",
                        icon: "square.and.pencil",
                        accentColor: accentColor,
                        textColor: textColor
                    ) {
                        newEntrySelected = true
                    }
                    
                    // Success
                    EntryButton(
                        title: "Success",
                        subtitle: "Celebrate your achievements",
                        icon: "checkmark",
                        accentColor: accentColor,
                        textColor: textColor
                    ) {
                        successSelected = true
                    }
                    
                    // Mood Check-in
                    EntryButton(
                        title: "Mood Check-in",
                        subtitle: "Track how you're feeling",
                        icon: "heart.fill",
                        accentColor: accentColor,
                        textColor: textColor
                    ) {
                        moodCheckIn = true
                    }
                }
                .offset(y: isMenuOpen ? 0 : 200)
                .opacity(isMenuOpen ? 1 : 0)
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isMenuOpen)
                
                Spacer()
                    .frame(height: 100)
                
                // Toggle button
                Button {
                    withAnimation {
                        isMenuOpen.toggle()
                    }
                } label: {
                    Image(systemName: isMenuOpen ? "xmark" : "plus")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 62, height: 62)
                        .background(
                            Circle()
                                .fill(accentColor)
                                .shadow(color: accentColor.opacity(0.25), radius: 8, x: 0, y: 4)
                        )
                        .rotationEffect(isMenuOpen ? Angle.degrees(135) : .zero)
                }
                .padding(.bottom, 32)
            }
        }
    }
}

struct EntryButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    let textColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Circle()
                    .fill(.white)
                    .frame(width: 48, height: 48)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 20))
                            .foregroundColor(accentColor)
                    )
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(textColor)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(textColor.opacity(0.6))
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(textColor.opacity(0.3))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal, 24)
    }
}


#Preview {
    FloatingEntryMenu(
        newEntrySelected: .constant(false),
        successSelected: .constant(false),
        moodCheckIn: .constant(false)
    )
    .preferredColorScheme(.light)
}
