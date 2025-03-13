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
            VStack(spacing: 16) {
                FreeResponseShape()
                    .padding(.bottom, 4)
                
                Text("Free Entry")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(textColor)
                    
//                Text("Express your thoughts freely")
//                    .font(.system(size: 14))
//                    .foregroundColor(textColor.opacity(0.7))
//                    .multilineTextAlignment(.center)
            }
            
        case .dream:
            VStack(spacing: 16) {
                DreamShape()
                    .padding(.bottom, 4)
                
                Text("Dream Journal")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(textColor)
//                    
//                Text("Record and reflect on your dreams")
//                    .font(.system(size: 14))
//                    .foregroundColor(textColor.opacity(0.7))
//                    .multilineTextAlignment(.center)
            }
            
        case .success:
            VStack(spacing: 16) {
                SuccessShape()
                    .padding(.bottom, 4)
                
                Text("Success Log")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(textColor)
//                    
//                Text("Document your achievements")
//                    .font(.system(size: 14))
//                    .foregroundColor(textColor.opacity(0.7))
//                    .multilineTextAlignment(.center)
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

struct FreeResponseShape: View {
    var body: some View {
        Canvas { context, size in
            let lineWidth: CGFloat = 1.5
            let width = size.width * 0.7
            let yPositions: [CGFloat] = [
                size.height * 0.35,
                size.height * 0.5,
                size.height * 0.65
            ]
            
            for (index, y) in yPositions.enumerated() {
                let lineLength = index == 2 ? width * 0.75 : width
                let path = Path { path in
                    path.move(to: CGPoint(x: (size.width - lineLength) / 2, y: y))
                    path.addLine(to: CGPoint(x: (size.width - lineLength) / 2 + lineLength, y: y))
                }
                context.stroke(path, with: .color(.black), lineWidth: lineWidth)
            }
        }
        .frame(width: 40, height: 40)
    }
}

// Dream - Elegant moon shape
struct DreamShape: View {
    var body: some View {
        Canvas { context, size in
            context.withCGContext { ctx in
                ctx.setFillColor(UIColor.black.cgColor)
                
                // Create a more refined crescent shape
                let center = CGPoint(x: size.width/2, y: size.height/2)
                let radius = min(size.width, size.height) * 0.4
                
                // Outer arc
                ctx.addArc(center: center, radius: radius,
                          startAngle: -.pi/4, endAngle: .pi * 5/4,
                          clockwise: false)
                
                // Inner arc (smaller and offset)
                let innerCenter = CGPoint(x: center.x + radius * 0.3,
                                        y: center.y - radius * 0.1)
                ctx.addArc(center: innerCenter, radius: radius * 0.75,
                          startAngle: .pi * 5/4, endAngle: -.pi/4,
                          clockwise: true)
                ctx.closePath()
                ctx.fillPath()
            }
        }
        .frame(width: 40, height: 40)
    }
}

// Success - Minimalist upward trend or achievement symbol
struct SuccessShape: View {
    var body: some View {
        Canvas { context, size in
            // Clean upward trend line
            let lineWidth: CGFloat = 2
            let path = Path { path in
                path.move(to: CGPoint(x: size.width * 0.25, y: size.height * 0.65))
                path.addLine(to: CGPoint(x: size.width * 0.5, y: size.height * 0.4))
                path.addLine(to: CGPoint(x: size.width * 0.75, y: size.height * 0.25))
            }
            context.stroke(path, with: .color(.black), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            
            // Small dot at the end
            let dotPath = Path(ellipseIn: CGRect(x: size.width * 0.75 - 2.5,
                                               y: size.height * 0.25 - 2.5,
                                               width: 5, height: 5))
            context.fill(dotPath, with: .color(.black))
        }
        .frame(width: 40, height: 40)
    }
}

#Preview {
    DailyJournalWidget()
        .padding()
        .background(Color(hex: "FAFBFC"))
}
