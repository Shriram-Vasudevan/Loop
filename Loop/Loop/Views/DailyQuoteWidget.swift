//
//  DailyQuoteWidget.swift
//  Loop
//
//  Created by Shriram Vasudevan on 2/7/25.
//

import SwiftUI

struct DailyQuoteWidget: View {
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    private let backgroundColor = Color.white
    
    @StateObject private var quoteManager = QuoteManager.shared
    
    @State var showQuoteReflectionSheet: Bool = false
    
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
                    Text("DAILY WISDOM")
                        .font(.system(size: 13, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(textColor.opacity(0.5))
                    
                    Spacer()
                }
                
                VStack (spacing: 16) {
                    Text("\(quoteManager.currentQuote.text)")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(textColor)
                        .lineSpacing(8)
                        .multilineTextAlignment(.center)
                    
                    HStack {
                        Text("— \(quoteManager.currentQuote.author)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(textColor.opacity(0.5))
                    }
                }
                
                Button(action: {
                    showQuoteReflectionSheet = true
                }, label: {
                    Text("Reflect")
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
        .fullScreenCover(isPresented: $showQuoteReflectionSheet, content: {
            RecordQuoteView(quote: quoteManager.currentQuote)
        })
    }
}

#Preview {
    DailyQuoteWidget()
        .padding()
        .background(Color(hex: "FAFBFC"))
}
