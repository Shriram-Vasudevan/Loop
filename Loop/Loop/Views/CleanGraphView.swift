//
//  CleanGraphView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/16/24.
//

import SwiftUI

struct CleanGraphView: View {
    let data: GraphData
    @State private var selectedPoint: TimelinePoint?
    @State private var showingTooltip = false
    @State private var tooltipPosition: CGPoint = .zero
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    // Calculate appropriate max Y value
    private var yAxisMaxValue: Double {
        let maxValue = data.points.compactMap { $0.value }.max() ?? 0
        // Round up to next appropriate number based on scale
        if maxValue <= 10 { return 10 }
        let magnitude = pow(10, floor(log10(maxValue)))
        return ceil(maxValue / magnitude) * magnitude
    }
    
    // Generate Y-axis labels
    private var yAxisLabels: [Double] {
        let maxY = yAxisMaxValue
        return [0, maxY * 0.25, maxY * 0.5, maxY * 0.75, maxY]
    }
    
    private var timelinePoints: [TimelinePoint] {
        var basePoints = data.period.allPoints
        
        // Fill in values for points where we have data
        for point in data.points {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.weekday, .weekOfMonth, .month], from: point.date)
            
            let index: Int
            switch data.period {
            case .week:
                index = (components.weekday ?? 1) - 1
            case .month:
                index = (components.weekOfMonth ?? 1) - 1
            case .year:
                index = (components.month ?? 1) - 1
            }
            
            if index >= 0 && index < basePoints.count {
                basePoints[index].value = point.value
                basePoints[index].date = point.date
            }
        }
        
        return basePoints
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Y-axis
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(yAxisLabels.reversed(), id: \.self) { value in
                        Text(formatValue(value, for: data.metric))
                            .font(.system(size: 10))
                            .foregroundColor(textColor.opacity(0.6))
                            .frame(height: geometry.size.height / CGFloat(yAxisLabels.count))
                    }
                }
                .frame(width: 50)
                .padding(.trailing, 8)
                
                // Main graph content
                ZStack(alignment: .leading) {
                    // Grid lines
                    VStack(spacing: 0) {
                        ForEach(yAxisLabels, id: \.self) { _ in
                            Spacer()
                            Rectangle()
                                .fill(textColor.opacity(0.1))
                                .frame(height: 1)
                        }
                    }
                    
                    // Graph content
                    let points = timelinePoints
                    
                    // Area fill beneath line
                    Path { path in
                        var lastValidY: CGFloat?
                        
                        path.move(to: CGPoint(x: 0, y: geometry.size.height))
                        
                        for (index, point) in points.enumerated() {
                            let x = getX(for: index, width: geometry.size.width, totalPoints: points.count)
                            
                            if let value = point.value {
                                let y = getY(for: value, height: geometry.size.height, maxValue: yAxisMaxValue)
                                
                                if lastValidY == nil {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                                lastValidY = y
                            }
                        }
                        
                        if let lastY = lastValidY {
                            path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                            path.addLine(to: CGPoint(x: 0, y: geometry.size.height))
                            path.closeSubpath()
                        }
                    }
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [
                            accentColor.opacity(0.2),
                            accentColor.opacity(0.05)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    
                    // Main line
                    Path { path in
                        var lastValidPoint: (x: CGFloat, y: CGFloat)?
                        
                        for (index, point) in points.enumerated() {
                            let x = getX(for: index, width: geometry.size.width, totalPoints: points.count)
                            
                            if let value = point.value {
                                let y = getY(for: value, height: geometry.size.height, maxValue: yAxisMaxValue)
                                
                                if let last = lastValidPoint {
                                    path.move(to: CGPoint(x: last.x, y: last.y))
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                                lastValidPoint = (x, y)
                            }
                        }
                    }
                    .stroke(accentColor, style: StrokeStyle(
                        lineWidth: 2,
                        lineCap: .round,
                        lineJoin: .round
                    ))
                    
                    // Data points
                    ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                        if let value = point.value {
                            Circle()
                                .fill(accentColor)
                                .frame(width: 6, height: 6)
                                .background(
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 12, height: 12)
                                        .opacity(selectedPoint?.index == point.index ? 1 : 0)
                                )
                                .position(
                                    x: getX(for: index, width: geometry.size.width, totalPoints: points.count),
                                    y: getY(for: value, height: geometry.size.height, maxValue: yAxisMaxValue)
                                )
                                .gesture(
                                    TapGesture()
                                        .onEnded { _ in
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                if selectedPoint?.index == point.index {
                                                    selectedPoint = nil
                                                    showingTooltip = false
                                                } else {
                                                    selectedPoint = point
                                                    tooltipPosition = CGPoint(
                                                        x: getX(for: index, width: geometry.size.width, totalPoints: points.count),
                                                        y: getY(for: value, height: geometry.size.height, maxValue: yAxisMaxValue)
                                                    )
                                                    showingTooltip = true
                                                }
                                            }
                                        }
                                )
                        }
                    }
                    
                    // X-axis labels
                    VStack {
                        Spacer()
                        HStack(spacing: 0) {
                            ForEach(points, id: \.index) { point in
                                Text(point.label)
                                    .font(.system(size: 12))
                                    .foregroundColor(textColor.opacity(0.6))
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                
                // Value tooltip
                if showingTooltip, let point = selectedPoint, let value = point.value {
                    VStack(alignment: .center, spacing: 4) {
                        Text(formatValue(value, for: data.metric))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(textColor)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .position(x: tooltipPosition.x, y: tooltipPosition.y - 30)
                    .transition(.opacity.combined(with: .scale))
                }
            }
        }
        .padding(.vertical)
    }
    
    private func getX(for index: Int, width: CGFloat, totalPoints: Int) -> CGFloat {
        let spacing = width / CGFloat(max(1, totalPoints - 1))
        return spacing * CGFloat(index)
    }
    
    private func getY(for value: Double, height: CGFloat, maxValue: Double) -> CGFloat {
        guard maxValue > 0 else { return height / 2 }
        let normalized = value / maxValue
        return height - (normalized * (height - 40)) - 20 // Padding for top and bottom
    }
    
    private func formatValue(_ value: Double, for metric: GraphData.MetricType) -> String {
        switch metric {
        case .wpm:
            return String(format: "%.0f", value)
        case .duration:
            let minutes = Int(value) / 60
            let seconds = Int(value) % 60
            return seconds == 0 ? "\(minutes)m" : "\(minutes)m \(seconds)s"
        case .wordCount, .uniqueWords, .selfReferences:
            return String(format: "%.0f", value)
        case .vocabularyDiversity:
            return String(format: "%.1f%%", value * 100)
        }
    }
}
