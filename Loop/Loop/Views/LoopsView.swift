//
//  LoopsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/8/24.
//

import SwiftUI
import SwiftUI

struct LoopsView: View {
    @ObservedObject private var loopManager = LoopManager.shared
    @State private var selectedDate: Date = Date()
    @State private var selectedViewMode: ViewMode = .recent
    @State private var selectedMonthId: MonthIdentifier?
    @State private var showingRecordView = false
    
    private let accentColor = Color(hex: "A28497")
    private let backgroundColor = Color(hex: "FAFBFC")
    private let textColor = Color(hex: "2C3E50")
    
    enum ViewMode {
        case recent, monthly, yearly
    }
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground()
            
            VStack(spacing: 0) {
                headerSection
                
                viewModeSelector
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                
                selectedView
            }
        }
        .task {
            await loopManager.loadActiveMonths()
        }
        .fullScreenCover(isPresented: $showingRecordView) {
            RecordLoopsView(isFirstLaunch: false)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 24) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("journal")
                        .font(.system(size: 40, weight: .ultraLight))
                        .foregroundColor(textColor)
                }
                
                Spacer()
                
                if !loopManager.hasCompletedToday {
                    TodayProgressRing(
                        progress: Double(loopManager.currentPromptIndex) / Double(loopManager.dailyPrompts.count),
                        total: loopManager.dailyPrompts.count,
                        completed: loopManager.currentPromptIndex
                    )
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
    
    private var viewModeSelector: some View {
        HStack(spacing: 16) {
            ViewModeButton(title: "Recent", systemImage: "clock", isSelected: selectedViewMode == .recent) {
                withAnimation { selectedViewMode = .recent }
            }
            
            ViewModeButton(title: "Monthly", systemImage: "calendar", isSelected: selectedViewMode == .monthly) {
                withAnimation { selectedViewMode = .monthly }
            }
            
            ViewModeButton(title: "Yearly", systemImage: "calendar.badge.clock", isSelected: selectedViewMode == .yearly) {
                withAnimation { selectedViewMode = .yearly }
            }
        }
    }
    
    @ViewBuilder
    private var selectedView: some View {
        ScrollView(showsIndicators: false) {
            switch selectedViewMode {
            case .recent:
                RecentLoopsView()
                    .transition(.opacity)
            case .monthly:
                MonthlyLoopsView(selectedMonthId: $selectedMonthId)
                    .transition(.opacity)
            case .yearly:
                YearlyLoopsView()
                    .transition(.opacity)
            }
        }
    }
}

// MARK: - Recent Loops View
struct RecentLoopsView: View {
    @ObservedObject private var loopManager = LoopManager.shared
    @State private var selectedLoop: Loop?
    @State private var loadingMore = false
    @State private var hasMoreContent = true
    
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        LazyVStack(spacing: 32) {
            ForEach(loopManager.recentDates, id: \.self) { date in
                TimelineSection(date: date, loops: loopManager.loopsByDate[date] ?? []) { loop in
                    selectedLoop = loop
                }
            }
            
            if loadingMore {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .frame(height: 50)
            } else if hasMoreContent {
                Color.clear
                    .frame(height: 50)
                    .onAppear {
                        fetchMoreLoops()
                    }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .fullScreenCover(item: $selectedLoop) { loop in
            ViewPastLoopView(loop: loop)
        }
        .onAppear {
            fetchInitialLoops()
        }
    }
    
    private func fetchInitialLoops() {
        loadingMore = true
        loopManager.fetchRecentDates(limit: 10) {
            loadingMore = false
        }
    }
    
    private func fetchMoreLoops() {
        guard !loadingMore && hasMoreContent else { return }
        loadingMore = true
        
        loopManager.fetchNextPageOfDates(limit: 10) {
            loadingMore = false
            hasMoreContent = !loopManager.recentDates.isEmpty
        }
    }
}


// MARK: - Monthly Loops View
struct MonthlyLoopsView: View {
    @ObservedObject private var loopManager = LoopManager.shared
    @Binding var selectedMonthId: MonthIdentifier?
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if let selectedMonthId = selectedMonthId {
                MonthDetailView(monthId: selectedMonthId)
            } else {
                monthsGrid
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
    
    private var monthsGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(loopManager.activeMonths, id: \.self) { monthId in
                MonthCard(monthId: monthId)
                    .onTapGesture {
                        withAnimation {
                            selectedMonthId = monthId
                            Task {
                                await loopManager.loadMonthData(monthId: monthId)
                            }
                        }
                    }
            }
        }
    }
}

struct MonthCard: View {
    let monthId: MonthIdentifier
    @State private var summary: MonthSummary?
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(monthName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(textColor)
                
                Text(String(monthId.year))
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(textColor.opacity(0.6))
            }
            
            if let summary = summary {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(summary.totalEntries)")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(accentColor)
                        
                        Text("entries")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(textColor.opacity(0.6))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(Int(summary.completionRate * 100))%")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(accentColor)
                        
                        Text("completed")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(textColor.opacity(0.6))
                    }
                }
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 15, x: 0, y: 8)
        )
        .task {
            await loadSummary()
        }
    }
    
    private var monthName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        var components = DateComponents()
        components.year = monthId.year
        components.month = monthId.month
        if let date = Calendar.current.date(from: components) {
            return dateFormatter.string(from: date)
        }
        return ""
    }
    
    private func loadSummary() async {
        do {
            summary = try await LoopCloudKitUtility.fetchMonthData(monthId: monthId)
        } catch {
            print("Error loading month summary: \(error)")
        }
    }
}

struct MonthDetailView: View {
    let monthId: MonthIdentifier
    @ObservedObject private var loopManager = LoopManager.shared
    @Environment(\.dismiss) private var dismiss
    
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(textColor)
                }
                
                Spacer()
            }
            
            if let summary = loopManager.selectedMonthSummary {
                VStack(alignment: .leading, spacing: 24) {
                    Text(monthTitle)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(textColor)
                    
                    ForEach(groupedLoopsByDay(summary.loops), id: \.0) { date, loops in
                        TimelineSection(date: date, loops: loops) { loop in
                            // Handle loop selection
                        }
                    }
                }
            } else {
                ProgressView()
            }
        }
    }
    
    private var monthTitle: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        var components = DateComponents()
        components.year = monthId.year
        components.month = monthId.month
        if let date = Calendar.current.date(from: components) {
            return dateFormatter.string(from: date)
        }
        return ""
    }
    
    private func groupedLoopsByDay(_ loops: [Loop]) -> [(Date, [Loop])] {
        let grouped = Dictionary(grouping: loops) { loop in
            Calendar.current.startOfDay(for: loop.timestamp)
        }
        return grouped.sorted { $0.key > $1.key }
    }
}

// MARK: - Yearly Loops View
struct YearlyLoopsView: View {
    @ObservedObject private var loopManager = LoopManager.shared
    @State private var selectedYear: Int
    private let textColor = Color(hex: "2C3E50")
    
    init() {
        _selectedYear = State(initialValue: Calendar.current.component(.year, from: Date()))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Spacer()
                
                Button(action: { selectedYear -= 1 }) {
                    Image(systemName: "chevron.left")
                }
                
                Text(String(selectedYear))
                    .font(.system(size: 20, weight: .medium))
                    .padding(.horizontal, 16)
                
                Button(action: { selectedYear += 1 }) {
                    Image(systemName: "chevron.right")
                }
                
                Spacer()
            }
            .foregroundColor(textColor)
            
            if let yearSummary = loopManager.yearSummaries[selectedYear] {
                YearStatsView(summaries: yearSummary)
                MonthlyBreakdownView(summaries: yearSummary)
            } else {
                ProgressView()
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .task(id: selectedYear) {
            await loopManager.loadYearData(year: selectedYear)
        }
    }
}

struct YearStatsView: View {
    let summaries: [MonthSummary]
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 32) {
                StatBox(
                    title: "Total Entries",
                    value: "\(totalEntries)",
                    icon: "text.bubble.fill"
                )
                
                StatBox(
                    title: "Active Days",
                    value: "\(activeDays)",
                    icon: "calendar"
                )
                
                StatBox(
                    title: "Avg. Completion",
                    value: "\(averageCompletion)%",
                    icon: "chart.bar.fill"
                )
            }
        }
    }
    
    private var totalEntries: Int {
        summaries.reduce(0) { $0 + $1.totalEntries }
    }
    
    private var activeDays: Int {
        summaries.reduce(0) { $0 + Int($1.completionRate * 30) }
    }
    
    private var averageCompletion: Int {
        guard !summaries.isEmpty else { return 0 }
        let avgRate = summaries.reduce(0.0) { $0 + $1.completionRate }
        return Int((avgRate / Double(summaries.count)) * 100)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(accentColor)
            
            Text(value)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(textColor)
            
            Text(title)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(textColor.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
    }
}

struct MonthlyBreakdownView: View {
    let summaries: [MonthSummary]
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Monthly Breakdown")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(textColor)
                        
            ForEach(summaries) { summary in
                HStack(spacing: 16) {
                    Text(summary.monthName)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(textColor)
                        .frame(width: 100, alignment: .leading)
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(accentColor.opacity(0.2))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(accentColor)
                                .frame(width: geometry.size.width * summary.completionRate, height: 8)
                        }
                    }
                    .frame(height: 8)
                    
                    Text("\(summary.totalEntries)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(textColor)
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 15, x: 0, y: 8)
        )
    }
}

// MARK: - Helper Views and Components
struct ViewModeButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : textColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? accentColor : Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
            )
        }
    }
}

struct AnimatedGradientBackground: View {
    @State private var phase = 0.0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let path = Path(CGRect(origin: .zero, size: size))
                context.clip(to: path)
                
                let colors = [
                    Color(hex: "FAFBFC").opacity(0.8),
                    Color(hex: "F8F5F7").opacity(0.5),
                    Color(hex: "FAFBFC").opacity(0.8)
                ]
                
                let updatedPhase = timeline.date.timeIntervalSinceReferenceDate.remainder(dividingBy: 10)
                let gradient = Gradient(colors: colors)
                
                var wavePath = Path()
                let width = size.width
                let height = size.height
                
                wavePath.move(to: CGPoint(x: 0, y: height * 0.5))
                
                for x in stride(from: 0, to: width, by: 1) {
                    let relativeX = x / width
                    let sine = sin(relativeX * .pi * 2 + updatedPhase)
                    let y = height * 0.5 + sine * 20
                    wavePath.addLine(to: CGPoint(x: x, y: y))
                }
                
                wavePath.addLine(to: CGPoint(x: width, y: height))
                wavePath.addLine(to: CGPoint(x: 0, y: height))
                wavePath.closeSubpath()
                
                context.fill(wavePath, with: .linearGradient(
                    gradient,
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: size.width, y: size.height)
                ))
            }
        }
        .ignoresSafeArea()
    }
}


struct TodayProgressRing: View {
    let progress: Double
    let total: Int
    let completed: Int
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(accentColor.opacity(0.2), lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(accentColor, lineWidth: 4)
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)
            
            VStack(spacing: 2) {
                Text("\(completed)/\(total)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(textColor)
                
                Text("today")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(textColor.opacity(0.6))
            }
            
        }
        .frame(width: 50, height: 50)
    }
}

struct TimelineSection: View {
    let date: Date
    let loops: [Loop]
    let onLoopSelected: (Loop) -> Void
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Text(formatDate(date))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(textColor)
                
                Line()
                    .stroke(textColor.opacity(0.1), lineWidth: 1)
                    .frame(height: 1)
            }

            LazyVStack(spacing: 16) {
                ForEach(loops) { loop in
                    TimelineLoopCard(loop: loop, onTap: {
                        onLoopSelected(loop)
                    })
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d"
            return formatter.string(from: date)
        }
    }
}
      
struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
    }
}

struct TimelineLoopCard: View {
    let loop: Loop
    let onTap: () -> Void
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    @State private var cardOffset: CGFloat = 50
    @State private var cardOpacity: Double = 0
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 16) {
                VStack(spacing: 4) {
                    Text(formatTime(loop.timestamp))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(textColor.opacity(0.6))
                    
                    Circle()
                        .fill(accentColor)
                        .frame(width: 8, height: 8)
                }
                .frame(width: 50)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(loop.promptText)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(textColor)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "waveform")
                                .font(.system(size: 12))
                            Text("0:30")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(accentColor.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(textColor.opacity(0.3))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 15, x: 0, y: 8)
            )
        }
        .offset(y: cardOffset)
        .opacity(cardOpacity)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                cardOffset = 0
                cardOpacity = 1
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
        
    }
    
}
#Preview {
    LoopsView()
}
