//
//  InsightsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/7/24.
//

import SwiftUI
import Charts

struct InsightsView: View {
    @Binding var pageType: PageType
    
    @State private var selectedTimeframe: Timeframe = .week
    
    @ObservedObject var analysisManager = AnalysisManager.shared
    @ObservedObject var tabManager = TabManager.shared
    
    private let accentColor = Color(hex: "A28497")
    private let backgroundColor = Color(hex: "FAFBFC")
    private let textColor = Color(hex: "2C3E50")
    private let surfaceColor = Color(hex: "F8F5F7")
        
    private let accentGradient = LinearGradient(
       colors: [Color(hex: "FF6B6B"), Color(hex: "A28497")],
       startPoint: .topLeading,
       endPoint: .bottomTrailing
   )
   private let inactiveColor = Color(hex: "2C3E50").opacity(0.2)

    var body: some View {
        ZStack {
//            FlowingBackground(color: accentColor)
//                .opacity(0.2)
//                .ignoresSafeArea()

            Color(hex: "F5F5F5")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
//                TabNavigationView(selectedTimeframe: $selectedTimeframe)
//                    .padding(.top, 24)
//                
                contentView
                    .padding(.top, 8)
            }
        }
    }
    
//    private var tabView: some View {
//        Menu {
//            Button {
//                withAnimation(.easeInOut(duration: 0.2)) {
//                    tabManager.insightsSelectedTab = "today"
//                }
//            } label: {
//                Label(
//                    title: {
//                        Text("Today")
//                            .font(.custom("PPNeueMontreal-Medium", size: 15))
//                            .tracking(0.5)
//                    },
//                    icon: {
//                        Image(systemName: "circle.fill")
//                            .font(.system(size: 4))
//                            .opacity(tabManager.insightsSelectedTab == "today" ? 1 : 0)
//                    }
//                )
//            }
//            
//            Button {
//                withAnimation(.easeInOut(duration: 0.2)) {
//                    tabManager.insightsSelectedTab = "trends"
//                }
//            } label: {
//                Label(
//                    title: {
//                        Text("Trends")
//                            .font(.custom("PPNeueMontreal-Medium", size: 15))
//                            .tracking(0.5)
//                    },
//                    icon: {
//                        Image(systemName: "circle.fill")
//                            .font(.system(size: 4))
//                            .opacity(tabManager.insightsSelectedTab == "trends" ? 1 : 0)
//                    }
//                )
//            }
//        } label: {
//            HStack {
//                Spacer()
//                
//                VStack(alignment: .center, spacing: 6) {
//                    HStack {
//                        Spacer()
//                        
//                        Text(tabManager.insightsSelectedTab == "today" ? "TODAY" : "TRENDS")
//                            .font(.custom("PPNeueMontreal-Medium", size: 13))
//                            .tracking(1.2)
//                            .foregroundColor(textColor)
//                        
//                        Spacer()
//                    }
//                    
//                    Text(dateText)
//                        .font(.custom("PPNeueMontreal-Regular", size: 13))
//                        .foregroundColor(textColor.opacity(0.7))
//                }
//                
//                Spacer()
//                
//                Image(systemName: "chevron.down")
//                    .font(.system(size: 11, weight: .semibold))
//                    .foregroundColor(textColor.opacity(0.5))
//                    .padding(.leading, 4)
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 12)
//            .background(
//                RoundedRectangle(cornerRadius: 10)
//                    .fill(.white)
//                    .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 2)
//            )
//            .padding(.horizontal, 24)
//        }
//        .menuStyle(BorderlessButtonMenuStyle())
//    }
    
    private var dateText: String {
        if tabManager.insightsSelectedTab == "today" {
            return formattedTodayDate()
        } else {
            switch selectedTimeframe {
            case .week:
                return formattedWeekDateRange()
            case .month:
                return currentMonth()
            case .year:
                return currentYear()
            }
        }
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
        TrendsView(pageType: $pageType, selectedTimeframe: $selectedTimeframe)
    }
}

struct TabNavigationView: View {
    @ObservedObject var tabManager = TabManager.shared
    @Binding var selectedTimeframe: Timeframe
    
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        HStack {
            VStack(alignment: .center, spacing: 4) {
                Text("INSIGHTS")
                    .font(.custom("PPNeueMontreal-Bold", size: 24))
                    .foregroundColor(textColor)
                    .tracking(1.2)
                
                Text("From your check-ins and daily reflections")
                    .font(.custom("PPNeueMontreal-Regular", size: 15))
                    .foregroundColor(textColor.opacity(0.7))
            }

            
//            Menu {
//                Button {
//                    withAnimation(.easeInOut(duration: 0.2)) {
//                        tabManager.insightsSelectedTab = "today"
//                    }
//                } label: {
//                    HStack {
//                        Text("Today")
//                            .font(.custom("PPNeueMontreal-Medium", size: 15))
//                        
//                        if tabManager.insightsSelectedTab == "today" {
//                            Image(systemName: "checkmark")
//                                .font(.system(size: 12))
//                        }
//                    }
//                }
//                
//                Button {
//                    withAnimation(.easeInOut(duration: 0.2)) {
//                        tabManager.insightsSelectedTab = "trends"
//                    }
//                } label: {
//                    HStack {
//                        Text("Trends")
//                            .font(.custom("PPNeueMontreal-Medium", size: 15))
//                        
//                        if tabManager.insightsSelectedTab == "trends" {
//                            Image(systemName: "checkmark")
//                                .font(.system(size: 12))
//                        }
//                    }
//                }
//            } label: {
//                HStack(spacing: 8) {
//                    Text(tabManager.insightsSelectedTab == "today" ? "Today" : "Trends")
//                        .font(.custom("PPNeueMontreal-Medium", size: 15))
//                        .foregroundColor(textColor)
//                    
//                    Image(systemName: "chevron.down")
//                        .font(.system(size: 11, weight: .semibold))
//                        .foregroundColor(textColor.opacity(0.5))
//                }
//                .padding(.horizontal, 16)
//                .padding(.vertical, 8)
//                .background(
//                    Capsule()
//                        .fill(.white)
////                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2) // Added subtle shadow for depth
//                )
//            }
        }
        .padding(.horizontal, 24)
    }
    
    private func getDateText() -> String {
        switch selectedTimeframe {
        case .week:
            return formattedWeekDateRange()
        case .month:
            return currentMonth()
        case .year:
            return formattedYearRange()
        }
    }
    
    private func formattedTodayDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: Date())
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
    
    private func currentMonth() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }
    
    private func formattedYearRange() -> String {
        let calendar = Calendar.current
        let today = Date()
        
        guard let yearStart = calendar.date(from: calendar.dateComponents([.year], from: today)),
              let yearEnd = calendar.date(byAdding: .year, value: 1, to: yearStart) else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        
        return "\(formatter.string(from: yearStart)) - \(formatter.string(from: yearEnd))"
    }
}

struct AnimatedSelectionEffect: ViewModifier {
    let isSelected: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isSelected ? 1.05 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

//struct FlowLayout: Layout {
//    var spacing: CGFloat = 8
//    
//    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
//        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
//        return result.size
//    }
//    
//    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
//        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
//        for (index, frame) in result.frames {
//            let position = CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY)
//            subviews[index].place(at: position, proposal: ProposedViewSize(frame.size))
//        }
//    }
//    
//    struct FlowResult {
//        var size: CGSize
//        var frames: [Int: CGRect]
//        
//        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
//            var height: CGFloat = 0
//            var maxWidth: CGFloat = 0
//            var x: CGFloat = 0
//            var y: CGFloat = 0
//            var row: CGFloat = 0
//            var frames = [Int: CGRect]()
//            
//            for (index, subview) in subviews.enumerated() {
//                let size = subview.sizeThatFits(.unspecified)
//                
//                if x + size.width > width {
//                    x = 0
//                    y += row + spacing
//                    row = 0
//                }
//                
//                frames[index] = CGRect(x: x, y: y, width: size.width, height: size.height)
//                row = max(row, size.height)
//                x += size.width + spacing
//                maxWidth = max(maxWidth, x)
//                height = max(height, y + row)
//            }
//            
//            self.size = CGSize(width: maxWidth, height: height)
//            self.frames = frames
//        }
//    }
//}
//    
//struct ErrorView: View {
//    let error: AnalysisError
//    let textColor: Color
//    
//    var body: some View {
//        VStack(spacing: 12) {
//            Image(systemName: "exclamationmark.triangle")
//                .font(.system(size: 32))
//                .foregroundColor(.orange)
//            
//            VStack(spacing: 8) {
//                Text("Error Occurred")
//                    .font(.system(size: 17, weight: .medium))
//                    .foregroundColor(textColor)
//                
//                Text(getRawErrorMessage())
//                    .font(.system(size: 14))
//                    .foregroundColor(textColor.opacity(0.7))
//                    .multilineTextAlignment(.center)
//            }
//        }
//        .padding(24)
//        .background(Color.white)
//        .clipShape(RoundedRectangle(cornerRadius: 16))
//    }
//    
//    private func getRawErrorMessage() -> String {
//        switch error {
//        case .transcriptionFailed(let message):
//            return "Transcription Error: \(message)"
//        case .analysisFailure(let underlyingError):
//            return String(describing: underlyingError)
//        case .aiAnalysisFailed(let apiError):
//            return "API Error: \(apiError)"
//        case .invalidData(let details):
//            return "Data Error: \(details)"
//        case .missingFields(let fields):
//            return "Missing fields: \(fields.joined(separator: ", "))"
//        }
//    }
//}

#if DEBUG
struct InsightsView_Previews: PreviewProvider {
    static var previews: some View {
        InsightsView(pageType: .constant(.trends))
    }
}
#endif
