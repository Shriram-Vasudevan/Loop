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
    
    @State private var hasEnoughData: Bool = false

    private func checkDataSufficiency() async {
        let metrics = await trendsManager.getDailyMetrics(for: timeframe)
//        hasEnoughData = trendsManager.hasEnoughDataPoints(metrics, category: selectedCategory)
    }
    
//    // Get current category data
//    private var categoryData: [CategoryEffect] {
//        let correlations = trendsManager.getCorrelations(for: timeframe)
//        switch selectedCategory {
//        case .topics:
//            return correlations.topics?.map { correlation in
//                CategoryEffect(
//                    name: correlation.name,
//                    effect: correlation.effect,
//                    color: correlation.color
//                )
//            } ?? getMockData()
//        case .sleep:
//            return correlations.sleep?.map { correlation in
//                CategoryEffect(
//                    name: correlation.name,
//                    effect: correlation.effect,
//                    color: correlation.color
//                )
//            } ?? getMockData()
//        case .timeOfDay:
//            return correlations.timeOfDay?.map { correlation in
//                CategoryEffect(
//                    name: correlation.name,
//                    effect: correlation.effect,
//                    color: correlation.color
//                )
//            } ?? getMockData()
//        case .dayOfWeek:
//            return correlations.dayOfWeek?.map { correlation in
//                CategoryEffect(
//                    name: correlation.name,
//                    effect: correlation.effect,
//                    color: correlation.color
//                )
//            } ?? getMockData()
//        }
//    }
    
    private func getMockData() -> [CategoryEffect] {
        switch selectedCategory {
            case .topics:
                return [
                    CategoryEffect(name: "Relationships", effect: 2.0, color: Color(hex: "B5D5E2")),
                    CategoryEffect(name: "Work", effect: -1.5, color: Color(hex: "A28497")),
                    CategoryEffect(name: "Learning", effect: 1.0, color: Color(hex: "93A7BB"))
                ]
            case .sleep:
                return [
                    CategoryEffect(name: "Before 10pm", effect: 1.5, color: Color(hex: "B5D5E2")),
                    CategoryEffect(name: "After midnight", effect: -1.0, color: Color(hex: "A28497")),
                    CategoryEffect(name: "8+ hours", effect: 2.0, color: Color(hex: "93A7BB"))
                ]
            case .timeOfDay:
                return [
                    CategoryEffect(name: "Morning", effect: 1.8, color: Color(hex: "B5D5E2")),
                    CategoryEffect(name: "Afternoon", effect: 0.5, color: Color(hex: "A28497")),
                    CategoryEffect(name: "Evening", effect: -0.8, color: Color(hex: "93A7BB"))
                ]
            case .dayOfWeek:
                return [
                    CategoryEffect(name: "Monday", effect: -0.5, color: Color(hex: "B5D5E2")),
                    CategoryEffect(name: "Wednesday", effect: 1.0, color: Color(hex: "A28497")),
                    CategoryEffect(name: "Friday", effect: 1.5, color: Color(hex: "93A7BB"))
                ]
            }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            HStack {
                VStack (alignment: .leading, spacing: 6) {
                    Text("Mood Patterns")
                        .font(.system(size: 20, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(textColor)
                    
                    Text("How different factors affect your mood")
                        .font(.system(size: 13, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(textColor.opacity(0.5))
                }
                
                Spacer()
                
                CategoryPicker(selectedCategory: $selectedCategory)
            }

            VStack(spacing: 24) {
                ZStack {
                    HStack(spacing: 16) {
                        YAxisLabels(bounds: yAxisBounds)
                        
//                        CurvesView(categories: hasEnoughData ? categoryData : getMockData(), bounds: yAxisBounds)
//                            .opacity(hasEnoughData ? 1 : 0.3)
                    }
                    .frame(height: 200)
                    
                    // Show empty state overlay if needed
                    if !hasEnoughData {
                        EmptyGraphStateOverlay()
                    }
                }

                if hasEnoughData {
                    HStack(spacing: 24) {
//                        ForEach(categoryData, id: \.name) { category in
//                            LegendItem(name: category.name,
//                                     color: category.color,
//                                     effect: category.effect)
//                        }
                    }
                }
            }
        }
//        .onChange(of: timeframe) { _ in
//            Task {
//                await trendsManager.fetchAllCorrelations(for: timeframe)
//                await checkDataSufficiency()  // Add this
//            }
//        }
//        .onChange(of: selectedCategory) { _ in
//            Task {
//                await trendsManager.fetchAllCorrelations(for: timeframe)
//                await checkDataSufficiency()  // Add this
//            }
//        }
//        .onAppear {
//            Task {
//                await trendsManager.fetchAllCorrelations(for: timeframe)
//                await checkDataSufficiency()  // Add this
//            }
//        }
    }
    
    private var yAxisBounds: (min: Double, max: Double) {
//        let effects = categoryData.map { $0.effect }
//        let minEffect = (effects.min() ?? -3).rounded(.down)
//        let maxEffect = (effects.max() ?? 3).rounded(.up)
//        return (minEffect, maxEffect)
        return (0.0, 0.0)
    }
}

struct CategoryPicker: View {
    @Binding var selectedCategory: AnalysisCategory
    let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        Menu {
            Picker("Category", selection: $selectedCategory) {
                ForEach(AnalysisCategory.allCases, id: \.self) { category in
                    Text(category.rawValue)
                        .tag(category)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selectedCategory.rawValue)
                    .font(.system(size: 15))
                    .foregroundColor(textColor)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(textColor.opacity(0.6))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(textColor.opacity(0.15), lineWidth: 1)
                    .background(Color.white.cornerRadius(8))
            )
        }
    }
}

struct EmptyGraphStateOverlay: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Not enough data")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "2C3E50"))
            
            Text("Keep reflecting to see relationships")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "2C3E50").opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .padding()
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.4)
        )
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
            lineWidth: 5
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

enum AnalysisCategory: String, CaseIterable {
    case topics = "Entry Topics"
    case sleep = "Sleep Schedule"
    case timeOfDay = "Time of Day"
    case dayOfWeek = "Day of Week"
}

// Preview
struct MoodAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview with mock data
        VStack {
            MoodAnalysisView(timeframe: .constant(.week))
                .padding()
                .previewDisplayName("With Data")
            
            Spacer()
        }
        .background(Color(hex: "F5F5F5"))
    }
}

// Environment key for preview
private struct HasNoDataKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var hasNoData: Bool {
        get { self[HasNoDataKey.self] }
        set { self[HasNoDataKey.self] = newValue }
    }
}
