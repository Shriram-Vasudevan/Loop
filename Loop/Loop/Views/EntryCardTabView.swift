import SwiftUI

struct EntryCardTabView: View {
    private let accentColor = Color(hex: "A28497")
    
    @State private var selectedTab = 0
    
    @Binding var newEntrySelected: Bool
    @Binding var successSelected: Bool
    @Binding var moodCheckIn: Bool
    
    var body: some View {
        TabView(selection: $selectedTab) {
            EntryCard(
                title: "New Entry",
                subtitle: "Record your thoughts and feelings",
                content: AnyView(
                    WavePattern()
                        .fill(accentColor.opacity(0.7))
                        .frame(height: 100)
                )
            )
            .tag(0)
            .onTapGesture {
                newEntrySelected = true
            }
            
            EntryCard(
                title: "Success",
                subtitle: "Celebrate your achievements",
                content: AnyView(
                    DarkBlueWaveView()
                        .frame(height: 100)
                )
            )
            .tag(1)
            .onTapGesture {
                successSelected = true
            }
            
            EntryCard(
                title: "Mood Check-in",
                subtitle: "Track how you're feeling",
                content: AnyView(
                    MoodPatternView()
                )
            )
            .tag(2)
            .onTapGesture {
                moodCheckIn = true
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        .frame(height: 400)
    }
}

struct EntryCard: View {
    let title: String
    let subtitle: String
    let content: AnyView
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack (spacing: 10) {
                HStack {
                    Text(title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    Spacer()
                }
                
                HStack {
                    Text(subtitle)
                        .font(.system(size: 17))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            
            content
                .padding(.vertical, 20)
            
            Spacer()
        }
        .padding(25)
        .frame(width: 320, height: 380)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
        )
    }
}

struct NewDarkBlueWaveView: View {
    private let waveColor = Color.blue.opacity(0.8)
    
    var body: some View {
        ZStack {
            ForEach(0..<3) { index in
                SineWave(frequency: Double(index + 1) * 1.5, phase: .random(in: 0...2 * .pi))
                    .fill(waveColor)
                    .opacity(0.3 - Double(index) * 0.1)
            }
        }
        .frame(height: 100)
    }
}

struct SineWave: Shape {
    var frequency: Double
    var phase: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height / 2
        let amplitude = height * 0.25
        
        path.move(to: CGPoint(x: 0, y: height))
        
        stride(from: 0, through: width, by: 1).forEach { x in
            let relativeX = x / width
            // Fixed operator precedence by adding parentheses
            let normalizedX = ((relativeX * .pi) * 2.0 * frequency) + phase
            let y = midHeight + sin(normalizedX) * amplitude
            
            if x == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

struct MoodPatternView: View {
    private let waveColor = Color(hex: "84A297")
    
    var body: some View {
        ZStack {
            // Three gentle filled waves
            ForEach(0..<3) { index in
                MoodCurve(yOffset: CGFloat(index) * 20)
                    .fill(waveColor)
                    .opacity(0.3 - Double(index) * 0.1)
            }
        }
        .frame(height: 100)
    }
}

struct MoodCurve: Shape {
    var yOffset: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height / 2
        
        path.move(to: CGPoint(x: 0, y: height))
        
        // Draw the curve
        stride(from: 0, through: width, by: 1).forEach { x in
            let relativeX = x / width
            let y = midHeight + sin(relativeX * .pi) * 20 + yOffset
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        // Complete the path to fill
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

#Preview {
    EntryCardTabView(newEntrySelected: .constant(false), successSelected: .constant(false), moodCheckIn: .constant(false))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.1))
}
