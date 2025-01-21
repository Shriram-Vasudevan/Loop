import SwiftUI

struct FloatingEntryMenu: View {
    @Binding var newEntrySelected: Bool
    @Binding var successSelected: Bool
    @Binding var moodCheckIn: Bool
    
    let accentColor = Color(hex: "A28497")
    let moodColor = Color(hex: "4C5B61")
    
    @State private var isAnimated = false
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 16) {
                MenuCard(
                    title: "Record a New Entry",
                    description: "Capture your thoughts and reflections",
                    icon: "square.and.pencil",
                    color: accentColor,
                    delay: 0.2
                ) {
                    newEntrySelected = true
                }
                
                MenuCard(
                    title: "How are you feeling?",
                    description: "Take a moment to check in with yourself",
                    icon: "heart.fill",
                    color: moodColor,
                    delay: 0.1
                ) {
                    moodCheckIn = true
                }
                
                MenuCard(
                    title: "Celebrate Success",
                    description: "Document your achievements",
                    icon: "sparkles",
                    color: accentColor.opacity(0.9),
                    delay: 0.3
                ) {
                    successSelected = true
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 100)
            .offset(y: isAnimated ? 0 : 40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isAnimated = true
            }
        }
    }
}

struct MenuCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let delay: Double
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var opacity: Double = 0
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon Container
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(color)
                }
                
                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(Color(hex: "2C3E50"))
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "2C3E50").opacity(0.6))
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "2C3E50").opacity(0.3))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.06), radius: 15, x: 0, y: 4)
            )
            .scaleEffect(isPressed ? 0.98 : 1)
            .opacity(opacity)
        }
        .buttonStyle(PlainButtonStyle())
        .pressEvents(
            onPress: {
                withAnimation(.easeOut(duration: 0.2)) {
                    isPressed = true
                }
            },
            onRelease: {
                withAnimation(.easeOut(duration: 0.2)) {
                    isPressed = false
                }
            }
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.3).delay(delay)) {
                opacity = 1
            }
        }
    }
}
extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() }
        )
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
