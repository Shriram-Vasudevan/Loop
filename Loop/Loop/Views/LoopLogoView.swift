import SwiftUI

struct SimpleLoopLogo: View {
    // Define the custom color
    let curveColor = Color(hex: "A28497")
    
    var body: some View {
        ZStack {
            // White background
            Color.white
                .edgesIgnoringSafeArea(.all)
            
            // Background curve with custom color
            Path { path in
                path.move(to: CGPoint(x: 20, y: 30))
                path.addCurve(
                    to: CGPoint(x: 110, y: 30),
                    control1: CGPoint(x: 40, y: -10),
                    control2: CGPoint(x: 90, y: -10)
                )
                path.addCurve(
                    to: CGPoint(x: 20, y: 30),
                    control1: CGPoint(x: 90, y: 70),
                    control2: CGPoint(x: 40, y: 70)
                )
            }
            .stroke(curveColor.opacity(0.3), lineWidth: 1.2)
            
            // Text with period
            Text("loop.")
                .font(.system(size: 32, weight: .light))
                .tracking(-1)
                .foregroundColor(.black)
        }
        .frame(width: 120, height: 60)
    }
}

struct SimpleLoopLogo_Previews: PreviewProvider {
    static var previews: some View {
        SimpleLoopLogo()
    }
}
