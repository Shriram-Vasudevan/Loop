import SwiftUI


struct CurvedReflectionSheet: View {
    @Binding var isOpen: Bool
    @Binding var newEntrySelected: Bool
    @Binding var successSelected: Bool
    @Binding var moodCheckIn: Bool
    @Binding var sleepCheckIn: Bool
    @Binding var dreamJournal: Bool
    
    // State for animations
    @State private var sheetOffset: CGFloat = 1000
    @State private var cardsOpacity: Double = 0
    @State private var cardsScale: CGFloat = 0.8
    
    private let backgroundColor = Color(hex: "FAFBFC")
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dimmed background
                Color.black
                    .opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismiss()
                    }
                    .animation(.easeInOut, value: isOpen)
                
                // Main curved sheet
                VStack(spacing: 0) {
                    Spacer()
                    
                    CurveShape()
                        .fill(Color.white)
                        .frame(height: 24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 36, height: 4)
                                .padding(.top, 8)
                        )
                    
                    // Content container
                    VStack(spacing: 32) {
                        // Top row
                        HStack(spacing: 60) {
                            CircleReflectionButton(type: .dreamJournal, action: { selectReflection(.dreamJournal) })
                            CircleReflectionButton(type: .success, action: { selectReflection(.success) })
                        }
                        .padding(.top, 20)
                        
                        HStack {
                            Spacer()
                            
                            CircleReflectionButton(type: .newEntry, action: { selectReflection(.dreamJournal) })
                            
                            Spacer()
                        }
                        
                        // Bottom row
                        HStack(spacing: 60) {
                            CircleReflectionButton(type: .moodCheckIn, action: { selectReflection(.moodCheckIn) })
                            CircleReflectionButton(type: .sleepCheckIn, action: { selectReflection(.sleepCheckIn) })
                        }
                        .padding(.bottom, 30)
                    }
                    .opacity(cardsOpacity)
                    .scaleEffect(cardsScale)
                    .background(Color.white)
                }
                .offset(y: sheetOffset)
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            if value.translation.height > 100 {
                                dismiss()
                            }
                        }
                )
            }
        }
        .onAppear {
            animateEntry()
        }
    }
    
    private func animateEntry() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            sheetOffset = 0
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
            cardsScale = 1
            cardsOpacity = 1
        }
    }
    
    private func dismiss() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            sheetOffset = 1000
            cardsScale = 0.8
            cardsOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isOpen = false
        }
    }
    
    private func selectReflection(_ type: ReflectionType) {
        switch type {
            case .dreamJournal:
                dreamJournal = true
            case .newEntry:
                newEntrySelected = true
            case .moodCheckIn:
                moodCheckIn = true
            case .sleepCheckIn:
                sleepCheckIn = true
            case .success:
                successSelected = true
        }
        dismiss()
    }
}

struct CurveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: 0, y: 24))
        
        let center = rect.width / 2
        
        path.addCurve(
            to: CGPoint(x: rect.width, y: 24),
            control1: CGPoint(x: center - 80, y: 0),
            control2: CGPoint(x: center + 80, y: 0)
        )
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}

struct CircleReflectionButton: View {
    let type: ReflectionType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: type.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: type.iconName)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                    )
                    .shadow(color: type.gradientColors[0].opacity(0.3), radius: 8, x: 0, y: 4)
                
                Text(type.rawValue)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "2C3E50"))
            }
        }
        .buttonStyle(SpringyButton())
    }
}

struct MainReflectionCard: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: ReflectionType.newEntry.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: ReflectionType.newEntry.iconName)
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white)
                    )
                    .shadow(color: ReflectionType.newEntry.gradientColors[0].opacity(0.3), radius: 12, x: 0, y: 6)
                
                VStack(spacing: 4) {
                    Text("New Entry")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "2C3E50"))
                    
                    Text("Share what's on your mind")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "2C3E50").opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 8)
            )
        }
        .buttonStyle(SpringyButton())
    }
}

struct SpringyButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

//#Preview {
//    CurvedReflectionSheet(isPresented: .constant(true), selectedReflection: .constant(nil))
//}

// Add these properties to your EntryType enum
extension ReflectionType {
    var iconName: String {
        switch self {
        case .newEntry: return "square.and.pencil"
        case .moodCheckIn: return "heart"
        case .dreamJournal: return "moon.stars"
        case .sleepCheckIn: return "bed.double"
        case .success: return "star"
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .newEntry:
            return [Color(hex: "A28497"), Color(hex: "B784A7")]
        case .moodCheckIn:
            return [Color(hex: "B784A7"), Color(hex: "A28497")]
        case .dreamJournal:
            return [Color(hex: "1E3D59"), Color(hex: "4C5B61")]
        case .sleepCheckIn:
            return [Color(hex: "94A7B7"), Color(hex: "4C5B61")]
        case .success:
            return [Color(hex: "B784A7"), Color(hex: "94A7B7")]
        }
    }
}

struct EntryTypeGrid: View {
    @Binding var isOpen: Bool
    @Binding var newEntrySelected: Bool
    @Binding var successSelected: Bool
    @Binding var moodCheckIn: Bool
    @Binding var sleepCheckIn: Bool
    @Binding var dreamJournal: Bool
    
    private let cardWidth: CGFloat = 160
    private let cardHeight: CGFloat = 200  // Slightly shorter for grid layout
    private let spacing: CGFloat = 16
    
    let backgroundColor = Color(hex: "FAFBFC")
    
    var body: some View {
        ZStack {
            // Overlay background
            if isOpen {
                Color.black
                    .opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isOpen = false
                        }
                    }
            }

            VStack(spacing: 24) {
//                // Close button
//                HStack {
//                    Spacer()
//                    Button {
//                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
//                            isOpen = false
//                        }
//                    } label: {
//                        Image(systemName: "xmark")
//                            .font(.system(size: 17, weight: .semibold))
//                            .foregroundColor(Color(hex: "2C3E50"))
//                            .frame(width: 32, height: 32)
//                    }
//                }
//                .padding(.horizontal, 24)
            
                VStack(spacing: spacing) {
                    HStack(spacing: spacing) {
                        CarouselReflectionCard(type: .newEntry)
                            .frame(width: cardWidth, height: cardHeight)
                            .onTapGesture { newEntrySelected = true }
                        
                        CarouselReflectionCard(type: .dreamJournal)
                            .frame(width: cardWidth, height: cardHeight)
                            .onTapGesture { dreamJournal = true }
                    }
                    

                    HStack(spacing: spacing) {
                        CarouselReflectionCard(type: .moodCheckIn)
                            .frame(width: cardWidth, height: cardHeight)
                            .onTapGesture { moodCheckIn = true }
                        
                        CarouselReflectionCard(type: .sleepCheckIn)
                            .frame(width: cardWidth, height: cardHeight)
                            .onTapGesture { sleepCheckIn = true }
                    }
                    
                    CarouselReflectionCard(type: .success)
                        .frame(width: cardWidth, height: cardHeight)
                        .onTapGesture { successSelected = true }
                }
                .padding(.horizontal, 24)
            }
            .padding(.vertical, 24)
            .opacity(isOpen ? 1 : 0)
            .scaleEffect(isOpen ? 1 : 0.9)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isOpen)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct BackgroundEffect: View {
    @Binding var isMenuOpened: Bool
    
    var body: some View {
        ZStack {
            Color.white
                .opacity(0.98)
                .blur(radius: 3)
            
            GeometryReader { geometry in
                ZStack {
                    Circle()
                        .fill(Color(hex: "A28497").opacity(0.1))
                        .frame(width: geometry.size.width * 0.8)
                        .blur(radius: 50)
                        .offset(y: -geometry.size.height * 0.2)
                    
                    Circle()
                        .fill(Color(hex: "B7A284").opacity(0.1))
                        .frame(width: geometry.size.width * 0.8)
                        .blur(radius: 50)
                        .offset(y: geometry.size.height * 0.2)
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onTapGesture {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isMenuOpened = false
            }
        }
    }
}

struct CardWrapper: View {
    let type: ReflectionType
    @Binding var isSelected: Bool
    let isAnimating: Bool
    let index: Int
    
    var body: some View {
        CarouselReflectionCard(type: type)
            .frame(width: UIScreen.main.bounds.width * 0.85, height: 230)
            .scaleEffect(isAnimating ? 1 : 0.8)
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 50)
            .animation(
                .spring(response: 0.6, dampingFraction: 0.8)
                .delay(Double(index) * 0.1),
                value: isAnimating
            )
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isSelected = true
                }
            }
    }
}

#Preview {
    CurvedReflectionSheet(
        isOpen: .constant(true),
        newEntrySelected: .constant(false),
        successSelected: .constant(false),
        moodCheckIn: .constant(false),
        sleepCheckIn: .constant(false),
        dreamJournal: .constant(false)
    )
}


enum ReflectionType: String, CaseIterable, Hashable {
    case newEntry = "New Entry"
    case moodCheckIn = "Mood Check-in"
    case dreamJournal = "Dream Journal"
    case sleepCheckIn = "Sleep Check-in"
    case success = "Add Success"
    
    var description: String {
        switch self {
        case .moodCheckIn:
            return "Track emotions and identify patterns"
        case .sleepCheckIn:
            return "Monitor your sleep quality"
        case .newEntry:
            return "Share what's on your mind"
        case .dreamJournal:
            return "Record and reflect on your dreams"
        case .success:
            return "Celebrate your achievements"
        }
    }
}

struct CarouselReflectionCard: View {
    let type: ReflectionType
    
    var body: some View {
        VStack(spacing: 0) {
            CardHeader(type: type)
                .frame(height: 120)

            VStack(alignment: .leading, spacing: 8) {
                Text(type.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "2C3E50"))
                    .lineLimit(1)
                
                Text(type.description)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "2C3E50").opacity(0.6))
                    .lineSpacing(2)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.white)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 4)
    }
}


struct CardHeader: View {
    let type: ReflectionType
    
    var body: some View {
        ZStack {
            switch type {
            case .newEntry:
                NewEntryHeader()
            case .moodCheckIn:
                MoodCheckInHeader()
            case .sleepCheckIn:
                SleepCheckInHeader()
            case .dreamJournal:
                DreamJournalHeader()
            case .success:
                SuccessHeader()
            }
        }
    }
}

struct NewEntryHeader: View {
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [accentColor, accentColor.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Smaller floating paper shapes
            ForEach(0..<3) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 40, height: 50)
                    .rotationEffect(.degrees(Double(index * 15) - 15))
                    .offset(x: CGFloat(index * 10) - 10,
                           y: CGFloat(index * 10) - 10)
                    .padding(.bottom, 30)
            }
            
        }
    }
}

struct MoodCheckInHeader: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "A28497"), Color(hex: "B784A7")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Smaller circles
            ForEach(0..<3) { index in
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    .frame(width: 60 + CGFloat(index * 20),
                           height: 60 + CGFloat(index * 20))
            }
            
            // Adjusted wave
            WaveShape()
                .fill(Color.white.opacity(0.1))
                .frame(height: 50)
                .offset(y: 20)
        }
    }
}

struct SleepCheckInHeader: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "94A7B7"), Color(hex: "4C5B61")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Smaller moon
            Circle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 40, height: 40)
                .offset(x: 15, y: -10)
                .blur(radius: 5)
            
            // Fewer, smaller stars
            ForEach(0..<12) { _ in
                Circle()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 1, height: 1)
                    .offset(x: .random(in: -50...50),
                           y: .random(in: -40...30))
                    .blur(radius: 0.3)
            }
            
            // Adjusted wave
            WaveShape()
                .fill(Color.white.opacity(0.1))
                .frame(height: 30)
                .offset(y: 40)
        }
    }
}

struct DreamJournalHeader: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "1E3D59"), Color(hex: "4C5B61")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Fewer, smaller stars
            ForEach(0..<15) { _ in
                Circle()
                    .fill(Color.white.opacity(Double.random(in: 0.2...0.4)))
                    .frame(width: Double.random(in: 1...2),
                           height: Double.random(in: 1...2))
                    .offset(x: .random(in: -50...50),
                           y: .random(in: -40...40))
                    .blur(radius: 0.3)
            }
            
            // Smaller clouds
            ForEach(0..<3) { index in
                CloudShape()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 50 + CGFloat(index * 15),
                           height: 30)
                    .offset(x: CGFloat(index * 20) - 30,
                           y: CGFloat(index * 10) - 10)
                    .blur(radius: 3)
            }
        }
    }
}

struct SuccessHeader: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "B784A7"), Color(hex: "94A7B7")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Smaller sun glow
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 30, height: 30)
                .offset(y: -10)
                .blur(radius: 8)
            
            // Adjusted mountain range
            MountainRange()
                .fill(Color.white.opacity(0.15))
                .frame(height: 60)
                .offset(y: 20)
        }
    }
}

// Helper Shapes
struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: 0, y: height))
        
        var x: CGFloat = 0
        let wavelength = width / 2
        
        while x <= width {
            let relativeX = x / wavelength
            path.addLine(to: CGPoint(
                x: x,
                y: height/2 + sin(relativeX * .pi * 2) * height/4
            ))
            x += 1
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()
        return path
    }
}

struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: CGRect(x: rect.width * 0.2,
                                  y: rect.height * 0.2,
                                  width: rect.width * 0.3,
                                  height: rect.height * 0.3))
        path.addEllipse(in: CGRect(x: rect.width * 0.4,
                                  y: rect.height * 0.3,
                                  width: rect.width * 0.4,
                                  height: rect.height * 0.4))
        return path
    }
}

struct MountainRange: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height))
        
        path.addLine(to: CGPoint(x: rect.width * 0.4, y: rect.height * 0.2))
        path.addLine(to: CGPoint(x: rect.width * 0.6, y: 0))
        path.addLine(to: CGPoint(x: rect.width * 0.8, y: rect.height * 0.3))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        
        path.closeSubpath()
        return path
    }
}

//#Preview {
//    EntryTypeCarousel()
//        .padding()
//}
