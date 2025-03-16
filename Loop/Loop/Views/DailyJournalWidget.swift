//
//  DailyJournalWidget.swift
//  Loop
//
//  Created by Shriram Vasudevan on 3/11/25.
//

import SwiftUI

struct DailyJournalWidget: View {
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    private let backgroundColor = Color.white
    
    @ObservedObject private var journalOfTheDayManager = JournalOfTheDayManager.shared
    
    @State var showFreeResponseSheet: Bool = false
    @State var showDreamSheet: Bool = false
    @State var showSuccessSheet: Bool = false
    
    var body: some View {
        ZStack {
//            GeometryReader { geometry in
//                Path { path in
//                    let size = min(geometry.size.width, geometry.size.height) * 0.15
//                    let position = CGPoint(x: 32, y: 32)
//
//                    path.move(to: position)
//                    path.addCurve(
//                        to: CGPoint(x: position.x + size, y: position.y + size),
//                        control1: CGPoint(x: position.x + size * 0.5, y: position.y),
//                        control2: CGPoint(x: position.x + size, y: position.y + size * 0.5)
//                    )
//                }
//                .stroke(accentColor.opacity(0.1), lineWidth: 2)
//            }

            VStack(alignment: .center, spacing: 24) {
                HStack {
                    Text("TODAYS JOURNAL")
                        .font(.system(size: 13, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(textColor.opacity(0.5))
                    
                    Spacer()
                    
//                    Button {
//                        withAnimation {
//                            quoteManager.showDailyQuote = false
//                        }
//                    } label: {
//                        Image(systemName: "xmark")
//                            .font(.system(size: 13, weight: .medium))
//                            .tracking(1.5)
//                            .foregroundColor(textColor)
//                    }

                }
                
                journalContent
                
                Button(action: {
                    switch journalOfTheDayManager.currentJournal {
                    case .freeResponse:
                        showFreeResponseSheet = true
                    case .dream:
                        showDreamSheet = true
                    case .success:
                        showSuccessSheet = showFreeResponseSheet
                    case .none:
                        showFreeResponseSheet = true
                    }
                }, label: {
                    Text("Journal")
                        .foregroundColor(textColor)
                        .padding()
                        .padding(.horizontal, 12)
                        .background(
                            Capsule()
                                .stroke(style: StrokeStyle(lineWidth: 1))
                                .foregroundColor(textColor.opacity(0.7))
                        )
                        .padding(.top, 12)

                })
            }
            .padding(32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        .fullScreenCover(isPresented: $showFreeResponseSheet) {
            RecordFreeResponseView()
        }
        .fullScreenCover(isPresented: $showSuccessSheet) {
            AddSuccessView()
        }
        .fullScreenCover(isPresented: $showDreamSheet) {
            DreamJournalView()
        }
    }
    

    @ViewBuilder
    private var journalContent: some View {
        switch journalOfTheDayManager.currentJournal {
        case .freeResponse:
            VStack(spacing: 8) {
                FreeResponseShape()
                    .padding(.bottom, 4)
                
                Text("Free Entry")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(textColor)

            }
            
        case .dream:
            VStack(spacing: 8) {
                DreamShape()
                    .padding(.bottom, 4)
                
                Text("Dream Journal")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(textColor)

            }
            
        case .success:
            VStack(spacing: 8) {
                SuccessShape()
                    .padding(.bottom, 4)
                
                Text("Success Log")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(textColor)

            }
        case .none:
            FreeResponseShape()
                .padding(.bottom, 4)
            
            Text("Free Entry")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(textColor)
        }
    }
}

struct JournalColors {
    static let accent = Color(hex: "A28497")
    static let moonYellow = Color(hex: "F9D71C")
    static let journalBlue = Color(hex: "5E8B7E")
    static let successGreen = Color(hex: "66A182")
}

struct FreeResponseShape: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5.6)
                .fill(Color.white)
                .frame(width: 45, height: 56)
                .shadow(color: Color.black.opacity(0.1), radius: 2.8, x: 0, y: 1.4)

            VStack(spacing: 8.4) {
                ForEach(0..<4) { _ in
                    Rectangle()
                        .fill(JournalColors.accent.opacity(0.6))
                        .frame(width: 34, height: 1.4)
                }
            }

            Path { path in
                path.move(to: CGPoint(x: 59, y: 8.4))
                path.addLine(to: CGPoint(x: 39, y: 28))
                path.addLine(to: CGPoint(x: 42, y: 31))
                path.addLine(to: CGPoint(x: 62, y: 11))
                path.addLine(to: CGPoint(x: 59, y: 8.4))

                path.move(to: CGPoint(x: 36, y: 31))
                path.addLine(to: CGPoint(x: 42, y: 31))
                path.addLine(to: CGPoint(x: 39, y: 28))
                path.closeSubpath()
            }
            .fill(JournalColors.journalBlue)
        }
        .frame(width: 70, height: 70)
    }
}

struct DreamShape: View {
    var body: some View {
        ZStack {
            Star(corners: 5, smoothness: 0.45)
                .fill(JournalColors.moonYellow.opacity(0.8))
                .frame(width: 14, height: 14)
                .offset(x: -22, y: -17)

            Star(corners: 5, smoothness: 0.45)
                .fill(JournalColors.moonYellow.opacity(0.6))
                .frame(width: 8.4, height: 8.4)
                .offset(x: 17, y: -11)

            ZStack {
                Circle()
                    .fill(JournalColors.moonYellow)
                    .frame(width: 49, height: 49)

                Circle()
                    .fill(Color.black.opacity(0.05))
                    .frame(width: 49, height: 49)
                    .offset(x: 14, y: -2.8)
                    .mask(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 47.6, height: 47.6)
                    )
            }
        }
        .frame(width: 70, height: 70)
    }
}

struct SuccessShape: View {
    var body: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 21, y: 14))
                path.addLine(to: CGPoint(x: 49, y: 14))
                path.addCurve(
                    to: CGPoint(x: 53, y: 21),
                    control1: CGPoint(x: 52, y: 14),
                    control2: CGPoint(x: 53, y: 17)
                )
                path.addCurve(
                    to: CGPoint(x: 49, y: 42),
                    control1: CGPoint(x: 53, y: 28),
                    control2: CGPoint(x: 53, y: 38)
                )
                path.addLine(to: CGPoint(x: 21, y: 42))
                path.addCurve(
                    to: CGPoint(x: 17, y: 21),
                    control1: CGPoint(x: 17, y: 38),
                    control2: CGPoint(x: 17, y: 28)
                )
                path.addCurve(
                    to: CGPoint(x: 21, y: 14),
                    control1: CGPoint(x: 17, y: 17),
                    control2: CGPoint(x: 18, y: 14)
                )
                path.closeSubpath()

                path.move(to: CGPoint(x: 28, y: 42))
                path.addLine(to: CGPoint(x: 42, y: 42))
                path.addLine(to: CGPoint(x: 45, y: 56))
                path.addLine(to: CGPoint(x: 25, y: 56))
                path.addLine(to: CGPoint(x: 28, y: 42))
                path.closeSubpath()
            }
            .fill(JournalColors.successGreen)

            Path { path in
                path.move(to: CGPoint(x: 28, y: 21))
                path.addCurve(
                    to: CGPoint(x: 24, y: 35),
                    control1: CGPoint(x: 22, y: 25),
                    control2: CGPoint(x: 21, y: 31)
                )
            }
            .stroke(Color.white.opacity(0.6), lineWidth: 2.1)
            
            // Sparkle
            SparkleShape()
                .fill(JournalColors.moonYellow)
                .frame(width: 16.8, height: 16.8)
                .offset(x: 17, y: -14)
        }
        .frame(width: 70, height: 70)
    }
}

struct Star: Shape {
    let corners: Int
    let smoothness: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * smoothness
        
        let angleIncrement = .pi * 2 / CGFloat(corners * 2)
        
        var angle = -CGFloat.pi / 2
        
        for i in 0..<corners * 2 {
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let x = center.x + cos(angle) * radius
            let y = center.y + sin(angle) * radius
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
            
            angle += angleIncrement
        }
        
        path.closeSubpath()
        return path
    }
}

struct SparkleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let radius = min(rect.width, rect.height) / 2

        path.move(to: CGPoint(x: center.x, y: center.y - radius))
        path.addLine(to: CGPoint(x: center.x, y: center.y + radius))

        path.move(to: CGPoint(x: center.x - radius, y: center.y))
        path.addLine(to: CGPoint(x: center.x + radius, y: center.y))

        path.move(to: CGPoint(x: center.x - radius * 0.7, y: center.y - radius * 0.7))
        path.addLine(to: CGPoint(x: center.x + radius * 0.7, y: center.y + radius * 0.7))

        path.move(to: CGPoint(x: center.x - radius * 0.7, y: center.y + radius * 0.7))
        path.addLine(to: CGPoint(x: center.x + radius * 0.7, y: center.y - radius * 0.7))
        
        return path
    }
}

struct JournalShapesPreview: View {
    var body: some View {
        HStack(spacing: 40) {
            VStack {
                FreeResponseShape()
                Text("Free Entry")
                    .font(.caption)
            }
            
            VStack {
                DreamShape()
                Text("Dream Journal")
                    .font(.caption)
            }
            
            VStack {
                SuccessShape()
                Text("Success Log")
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(hex: "FAFBFC"))
    }
}

struct JournalShapesPreview_Previews: PreviewProvider {
    static var previews: some View {
        JournalShapesPreview()
    }
}

#Preview {
    DailyJournalWidget()
        .padding()
        .background(Color(hex: "FAFBFC"))
}
