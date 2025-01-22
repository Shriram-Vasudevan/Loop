//
//  TrendsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/28/24.
//



import SwiftUI

import SwiftUI

struct TrendsView: View {
    @State private var timeframe: Timeframe = .week
    @ObservedObject var trendsManager = TrendsManager.shared
    
    // Colors from Loop
    let accentColor = Color(hex: "A28497")
    let textColor = Color(hex: "2C3E50")
    let sadColor = Color(hex: "1E3D59")
    let neutralColor = Color(hex: "94A7B7")
    let happyColor = Color(hex: "B784A7")
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header and timeframe selector
                VStack(spacing: 16) {
                    HStack {
                        Text("insights")
                            .font(.system(size: 28, weight: .light))
                            .foregroundColor(textColor)
                        Spacer()
                    }
                    
                    TimeframeSelector(selection: $timeframe)
                }
                .padding(.horizontal, 24)
                
                // Mood section
                VStack(spacing: 16) {
                    HStack {
                        Text("MOOD TRENDS")
                            .font(.system(size: 13, weight: .medium))
                            .tracking(1.5)
                            .foregroundColor(textColor.opacity(0.5))
                        Spacer()
                    }
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("feeling good")
                                .font(.system(size: 24, weight: .light))
                                .foregroundColor(getColor(for: 7.8))
                            
                            Text("your average mood")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(textColor.opacity(0.5))
                        }
                        
                        Spacer()
                        
                        // Simple circular indicator
                        Circle()
                            .trim(from: 0, to: 0.78)
                            .stroke(getColor(for: 7.8), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 50, height: 50)
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white)
                    )
                }
                .padding(.horizontal, 24)
                
                // Other insights section
                VStack(alignment: .leading, spacing: 16) {
                    Text("THIS WEEK")
                        .font(.system(size: 13, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(textColor.opacity(0.5))
                    
                    // Example insight cards
                    InsightCard(text: "Your reflections tend to be more positive around 8pm", backgroundColor: accentColor)
                    InsightCard(text: "You write about work most often", backgroundColor: neutralColor)
                    InsightCard(text: "You complete 40% more entries on good days", backgroundColor: happyColor)
                }
                .padding(.horizontal, 24)
            }
            .padding(.vertical, 32)
        }
        .background(Color(hex: "F5F5F5"))
    }
    
    private func getColor(for rating: Double) -> Color {
        if rating <= 5 {
            let t = (rating - 1) / 4
            return interpolateColor(from: sadColor, to: neutralColor, with: t)
        } else {
            let t = (rating - 5) / 5
            return interpolateColor(from: neutralColor, to: happyColor, with: t)
        }
    }
    
    private func interpolateColor(from: Color, to: Color, with percentage: Double) -> Color {
        let fromUIColor = UIColor(from)
        let toUIColor = UIColor(to)
        
        var fromR: CGFloat = 0
        var fromG: CGFloat = 0
        var fromB: CGFloat = 0
        var fromA: CGFloat = 0
        fromUIColor.getRed(&fromR, green: &fromG, blue: &fromB, alpha: &fromA)
        
        var toR: CGFloat = 0
        var toG: CGFloat = 0
        var toB: CGFloat = 0
        var toA: CGFloat = 0
        toUIColor.getRed(&toR, green: &toG, blue: &toB, alpha: &toA)
        
        let r = fromR + (toR - fromR) * CGFloat(percentage)
        let g = fromG + (toG - fromG) * CGFloat(percentage)
        let b = fromB + (toB - fromB) * CGFloat(percentage)
        let a = fromA + (toA - fromA) * CGFloat(percentage)
        
        return Color(UIColor(red: r, green: g, blue: b, alpha: a))
    }
}

struct TimeframeSelector: View {
    @Binding var selection: Timeframe
    let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        HStack {
            ForEach([Timeframe.week, .month, .year], id: \.self) { timeframe in
                Button(action: {
                    withAnimation {
                        selection = timeframe
                    }
                }) {
                    Text(timeframe.displayText)
                        .font(.system(size: 13, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(selection == timeframe ? textColor : textColor.opacity(0.5))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selection == timeframe ? Color.white : Color.clear)
                        )
                }
            }
            Spacer()
        }
    }
}

struct InsightCard: View {
    let text: String
    let backgroundColor: Color
    
    var body: some View {
        HStack {
            Text(text)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(Color(hex: "2C3E50"))
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white)
        )
    }
}

// Preview
struct TrendsView_Previews: PreviewProvider {
    static var previews: some View {
        TrendsView()
    }
}
