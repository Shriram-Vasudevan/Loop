//
//  InsightsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/7/24.
//

import SwiftUI
import Charts

struct InsightsView: View {
    @ObservedObject var analysisManager = AnalysisManager.shared
    
    @State private var selectedTab = "today"
    
    private let accentColor = Color(hex: "A28497")
    private let backgroundColor = Color(hex: "FAFBFC")
    private let textColor = Color(hex: "2C3E50")
    private let surfaceColor = Color(hex: "F8F5F7")
    
    @State var timeFrame: Timeframe = .week
    
    var body: some View {
        ZStack {
            Color(hex: "F5F5F5")
                .ignoresSafeArea()
            VStack(spacing: 0) {
                tabView
                    .padding(.top, 24)
                
                contentView
                    .padding(.top, selectedTab == "today" ? 32 : 0)
            }
        }
    }
    
    private var tabView: some View {
        Menu {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = "today"
                }
            } label: {
                HStack {
                    Text("Today")
                        .font(.system(size: 14, weight: .medium))
                        .tracking(1.5)
                }
            }
            
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = "trends"
                }
            } label: {
                HStack {
                    Text("Trends")
                        .font(.system(size: 14, weight: .medium))
                        .tracking(1.5)
                }
            }
        } label: {
            ZStack {
                VStack(alignment: .center, spacing: 4) {
                    Text(selectedTab == "today" ? "TODAY" : "TRENDS")
                        .font(.system(size: 13, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(textColor.opacity(0.6))
                    
                    Text(selectedTab == "today"
                        ? formattedTodayDate()
                        : {
                            switch timeFrame {
                            case .week:
                                return formattedWeekDateRange()
                            case .month:
                                return currentMonth()
                            case .year:
                                return currentYear()
                            }
                        }()
                    )
                    .font(.system(size: 12))
                    .foregroundColor(textColor.opacity(0.6))
                }
                
                HStack {
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(textColor.opacity(0.6))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.white)
            )
        }
        .padding(.horizontal, 24)
    }
    
    private func formattedWeekDateRange() -> String {
        let calendar = Calendar.current
        let today = Date()
        
        let weekday = calendar.component(.weekday, from: today)
        let daysToSubtract = weekday - 1
        guard let weekStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: today),
              let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            return ""
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        
        return "\(dateFormatter.string(from: weekStart)) - \(dateFormatter.string(from: weekEnd))"
    }
    

    private func formattedTodayDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: Date())
    }
    
    private func currentMonth() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }
    
    private func currentYear() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY"
        return formatter.string(from: Date())
    }
    
    @ViewBuilder
    private var contentView: some View {
        if selectedTab == "today" {
            TodaysInsightsView(analysisManager: analysisManager)
        } else {
            TrendsView(selectedTimeframe: $timeFrame, previewData: nil)
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, frame) in result.frames {
            let position = CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY)
            subviews[index].place(at: position, proposal: ProposedViewSize(frame.size))
        }
    }
    
    struct FlowResult {
        var size: CGSize
        var frames: [Int: CGRect]
        
        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var height: CGFloat = 0
            var maxWidth: CGFloat = 0
            var x: CGFloat = 0
            var y: CGFloat = 0
            var row: CGFloat = 0
            var frames = [Int: CGRect]()
            
            for (index, subview) in subviews.enumerated() {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > width {
                    x = 0
                    y += row + spacing
                    row = 0
                }
                
                frames[index] = CGRect(x: x, y: y, width: size.width, height: size.height)
                row = max(row, size.height)
                x += size.width + spacing
                maxWidth = max(maxWidth, x)
                height = max(height, y + row)
            }
            
            self.size = CGSize(width: maxWidth, height: height)
            self.frames = frames
        }
    }
}
    
struct ErrorView: View {
    let error: AnalysisError
    let textColor: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("Error Occurred")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(textColor)
                
                Text(getRawErrorMessage())
                    .font(.system(size: 14))
                    .foregroundColor(textColor.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func getRawErrorMessage() -> String {
        switch error {
        case .transcriptionFailed(let message):
            return "Transcription Error: \(message)"
        case .analysisFailure(let underlyingError):
            return String(describing: underlyingError)
        case .aiAnalysisFailed(let apiError):
            return "API Error: \(apiError)"
        case .invalidData(let details):
            return "Data Error: \(details)"
        case .missingFields(let fields):
            return "Missing fields: \(fields.joined(separator: ", "))"
        }
    }
}

#if DEBUG
struct InsightsView_Previews: PreviewProvider {
    static var previews: some View {
        InsightsView(analysisManager: .preview)
    }
}
#endif
