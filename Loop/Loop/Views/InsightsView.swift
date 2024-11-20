//
//  InsightsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/7/24.
//
import SwiftUI

struct InsightsView: View {
    @ObservedObject var analysisManager = AnalysisManager.shared
    @State private var selectedInsightType: String?
    @State private var animateIn = false
    
    let accentColor = Color(hex: "A28497")
    let backgroundColor = Color(hex: "FAFBFC")
    let surfaceColor = Color(hex: "F8F5F7")
    let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        ZStack {
            backgroundColor.edgesIgnoringSafeArea(.all)
            
            if let analysis = analysisManager.currentDailyAnalysis {
                if analysis.isComplete {
                    completedAnalysisView(analysis)
                } else {
                    processingView(analysis)
                }
            } else {
                noAnalysisView
            }
        }
    }
    
    private func completedAnalysisView(_ analysis: DailyAnalysis) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                header
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : -20)
                
                // Main Stats
                statsOverview(analysis)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)
                
                // Response Summary
                responseSummary(analysis)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 20)
                
                // Topics & Keywords
                if !analysis.keywords.isEmpty {
                    keywordsView(analysis)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                }
                
                // People Mentioned
                if !analysis.names.isEmpty {
                    connectionsView(analysis)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateIn = true
            }
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Reflections")
                .font(.system(size: 32, weight: .ultraLight))
                .foregroundColor(textColor)
            
            Text("Based on your responses")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(textColor.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func statsOverview(_ analysis: DailyAnalysis) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            InsightCard(
                title: "Speaking Pace",
                value: String(format: "%.0f", analysis.averageSpeakingPace),
                unit: "WPM",
                icon: "waveform",
                color: accentColor
            )
            
            InsightCard(
                title: "Total Words",
                value: "\(analysis.totalWordCount)",
                unit: "words",
                icon: "text.bubble",
                color: accentColor
            )
            
            InsightCard(
                title: "Self References",
                value: String(format: "%.0f", analysis.selfReferencePercentage * 100),
                unit: "%",
                icon: "person",
                color: accentColor
            )
            
            InsightCard(
                title: "Duration",
                value: String(format: "%.0f", analysis.totalDuration),
                unit: "sec",
                icon: "clock",
                color: accentColor
            )
        }
    }
    
    private func responseSummary(_ analysis: DailyAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Response Patterns")
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(textColor)
            
            VStack(spacing: 12) {
                PatternRow(
                    icon: "arrow.left.arrow.right",
                    title: "Time Focus",
                    detail: getTensePattern(analysis),
                    color: accentColor
                )
                
                Divider()
                    .background(surfaceColor)
                
                PatternRow(
                    icon: "hand.point.up",
                    title: "Self Expression",
                    detail: getSelfExpressionPattern(analysis),
                    color: accentColor
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 10)
            )
        }
    }
    
    private func keywordsView(_ analysis: DailyAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Themes")
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(textColor)
            
            FlowLayout(spacing: 8) {
                ForEach(analysis.keywords, id: \.self) { keyword in
                    Text(keyword)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(accentColor.opacity(0.1))
                        )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 10)
            )
        }
    }
    
    private func connectionsView(_ analysis: DailyAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("People Mentioned")
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(textColor)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(analysis.names, id: \.self) { name in
                        PersonBubble(name: name, color: accentColor)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 10)
            )
        }
    }
    
    private func processingView(_ analysis: DailyAnalysis) -> some View {
        VStack(spacing: 24) {
            ProgressCircle(
                progress: Double(analysis.completedLoopCount) / 3.0,
                color: accentColor
            )
            .frame(width: 80, height: 80)
            
            Text("Analyzing Your Reflections")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(textColor)
            
            Text("\(analysis.completedLoopCount) of 3 loops processed")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(textColor.opacity(0.7))
        }
    }
    
    private var noAnalysisView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(accentColor)
            
            Text("No Reflections Yet")
                .font(.system(size: 24, weight: .light))
                .foregroundColor(textColor)
            
            Text("Record your loops to see insights")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(textColor.opacity(0.7))
        }
    }
    
    private func getTensePattern(_ analysis: DailyAnalysis) -> String {
        if analysis.pastTensePercentage > analysis.futureTensePercentage {
            return "You focused more on past experiences"
        } else {
            return "You focused more on future possibilities"
        }
    }
    
    private func getSelfExpressionPattern(_ analysis: DailyAnalysis) -> String {
        let percentage = analysis.selfReferencePercentage * 100
        if percentage > 70 {
            return "Your responses were very personally focused"
        } else if percentage > 40 {
            return "You maintained a balanced perspective"
        } else {
            return "You focused more on external observations"
        }
    }
}

struct InsightCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(hex: "2C3E50").opacity(0.7))
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Color(hex: "2C3E50"))
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(hex: "2C3E50").opacity(0.7))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: color.opacity(0.1), radius: 10)
        )
    }
}

struct PatternRow: View {
    let icon: String
    let title: String
    let detail: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .light))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(hex: "2C3E50").opacity(0.7))
                
                Text(detail)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color(hex: "2C3E50"))
            }
        }
    }
}

struct PersonBubble: View {
    let name: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Text(String(name.prefix(1)))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Circle().fill(color))
            
            Text(name)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(Color(hex: "2C3E50"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(color.opacity(0.1))
        )
    }
}

struct ProgressCircle: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        Circle()
            .stroke(color.opacity(0.2), lineWidth: 8)
            .overlay(
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(color, lineWidth: 8)
                    .rotationEffect(.degrees(-90))
            )
    }
}

struct FlowLayout: Layout {
    let spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        
        for (index, position) in result.positions.enumerated() {
            let point = CGPoint(x: position.x + bounds.minX, y: position.y + bounds.minY)
            subviews[index].place(at: point, proposal: .unspecified)
        }
    }
    
    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        guard !subviews.isEmpty else { return ([], .zero) }
        
        let maxWidth = proposal.width ?? .infinity
        var currentPosition = CGPoint.zero
        var positions: [CGPoint] = []
        var rowMaxY: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentPosition.x + size.width > maxWidth && currentPosition.x > 0 {
                currentPosition.x = 0
                currentPosition.y = rowMaxY + spacing
            }
            
            positions.append(currentPosition)
            rowMaxY = max(rowMaxY, currentPosition.y + size.height)
            currentPosition.x += size.width + spacing
        }
        
        return (positions, CGSize(width: maxWidth, height: rowMaxY))
    }
}

// MARK: - Preview
#Preview {
    InsightsView()
}
