//
//  TopicMoodGraph.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/23/25.
//

import SwiftUI

struct MoodAnalysisView: View {
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    @State private var selectedCategory = AnalysisCategory.topics
    @StateObject private var trendsManager = TrendsManager.shared
    @Binding var timeframe: Timeframe
    
    enum AnalysisCategory: String, CaseIterable {
        case topics = "Topics"
        case sleep = "Sleep"
        case wordCount = "Length"
        case timeOfDay = "Time"
    }
    
    private var hasEnoughData: Bool {
        let correlations = trendsManager.getCorrelations(for: timeframe)
        switch selectedCategory {
        case .topics:
            return correlations.topics?.isEmpty == false
        case .sleep:
            return correlations.sleep?.isEmpty == false
        case .timeOfDay:
            return correlations.timeOfDay?.isEmpty == false
        case .wordCount:
            return correlations.wordCount?.isEmpty == false
        }
    }
    
    // Get current category data
    private var categoryData: [CategoryEffect] {
        let correlations = trendsManager.getCorrelations(for: timeframe)
        switch selectedCategory {
        case .topics:
            return correlations.topics?.map { correlation in
                CategoryEffect(
                    name: correlation.name,
                    effect: correlation.effect,
                    color: correlation.color
                )
            } ?? getMockData()
        case .sleep:
            return correlations.sleep?.map { correlation in
                CategoryEffect(
                    name: correlation.name,
                    effect: correlation.effect,
                    color: correlation.color
                )
            } ?? getMockData()
        case .timeOfDay:
            return correlations.timeOfDay?.map { correlation in
                CategoryEffect(
                    name: correlation.name,
                    effect: correlation.effect,
                    color: correlation.color
                )
            } ?? getMockData()
        case .wordCount:
            return correlations.wordCount?.map { correlation in
                CategoryEffect(
                    name: correlation.name,
                    effect: correlation.effect,
                    color: correlation.color
                )
            } ?? getMockData()
        }
    }
    
    private func getMockData() -> [CategoryEffect] {
        [
            CategoryEffect(name: "Sample 1", effect: -2.0, color: Color(hex: "B5D5E2")),
            CategoryEffect(name: "Sample 2", effect: 0.0, color: Color(hex: "A28497")),
            CategoryEffect(name: "Sample 3", effect: 2.0, color: Color(hex: "93A7BB"))
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            HStack {
                Text("EFFECT ON MOOD")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.5))
                
                Spacer()
                
                Picker("Category", selection: $selectedCategory) {
                    ForEach(AnalysisCategory.allCases, id: \.self) { category in
                        Text(category.rawValue)
                            .tag(category)
                    }
                }
                .pickerStyle(.menu)
                .tint(accentColor)
            }

            VStack(spacing: 24) {
                ZStack {
                    HStack(spacing: 16) {
                        YAxisLabels(bounds: yAxisBounds)
                        
                        CurvesView(categories: categoryData, bounds: yAxisBounds)
                    }
                    .frame(height: 200)
                    
                    // Show empty state overlay if needed
                    if !hasEnoughData {
                        EmptyGraphStateOverlay()
                    }
                }

                HStack(spacing: 24) {
                    ForEach(categoryData, id: \.name) { category in
                        LegendItem(name: category.name,
                                 color: category.color,
                                 effect: category.effect)
                    }
                }
            }
        }
        .onChange(of: timeframe) { _ in
            trendsManager.fetchAllCorrelations(for: timeframe)
        }
        .onChange(of: selectedCategory) { _ in
            // Fetch data if needed when category changes
            trendsManager.fetchAllCorrelations(for: timeframe)
        }
        .onAppear {
            trendsManager.fetchAllCorrelations(for: timeframe)
        }
    }
    
    private var yAxisBounds: (min: Double, max: Double) {
        let effects = categoryData.map { $0.effect }
        let minEffect = (effects.min() ?? -3).rounded(.down)
        let maxEffect = (effects.max() ?? 3).rounded(.up)
        return (minEffect, maxEffect)
    }
}

struct EmptyGraphStateOverlay: View {
    var body: some View {
        ZStack {
            Color.white.opacity(0.7)
                .background(.ultraThinMaterial)
                .blur(radius: 5)
            
            VStack(spacing: 8) {
                Text("Not enough data")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: "2C3E50"))
                
                Text("Keep reflecting to see patterns")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "2C3E50").opacity(0.7))
            }
        }
    }
}

struct CategoryEffect {
    let name: String
    let effect: Double
    let color: Color
}

struct YAxisLabels: View {
    let bounds: (min: Double, max: Double)
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text(String(format: "%.1f", bounds.max))
            Spacer()
            Text("0")
            Spacer()
            Text(String(format: "%.1f", bounds.min))
        }
        .font(.system(size: 12))
        .foregroundColor(Color(hex: "2C3E50").opacity(0.5))
        .frame(width: 35)
    }
}

struct CurvesView: View {
    let categories: [CategoryEffect]
    let bounds: (min: Double, max: Double)
    
    var body: some View {
        Canvas { context, size in
            // Draw curves
            for category in categories {
                drawCurve(for: category, context: &context, size: size)
            }
        }
    }
    
    private func drawCurve(for category: CategoryEffect, context: inout GraphicsContext, size: CGSize) {
        let range = bounds.max - bounds.min
        let normalizedEffect = (category.effect - bounds.min) / range
        
        var path = Path()
        path.move(to: CGPoint(x: 0, y: size.height * 0.5))
        
        // Create smooth curve
        path.addCurve(
            to: CGPoint(x: size.width,
                       y: size.height * (1 - normalizedEffect)),
            control1: CGPoint(x: size.width * 0.5,
                            y: size.height * 0.5),
            control2: CGPoint(x: size.width * 0.7,
                            y: size.height * (1 - normalizedEffect))
        )
        
        context.stroke(
            path,
            with: .color(category.color),
            lineWidth: 3
        )
    }
}

struct LegendItem: View {
    let name: String
    let color: Color
    let effect: Double
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(name)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "2C3E50"))
                .fixedSize(horizontal: true, vertical: false)
//            
//            Text(String(format: "%.1f", effect))
//                .font(.system(size: 13, weight: .medium))
//                .foregroundColor(color)
//                .lineLimit(1)
        }
    }
}

// Preview
struct MoodAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        MoodAnalysisView(timeframe: .constant(.week))
            .padding()
    }
}
