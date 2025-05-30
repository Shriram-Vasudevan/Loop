//
//  LoopsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/8/24.
//

import SwiftUI
import Darwin
import CoreData

struct LoopsView: View {
    @ObservedObject private var loopManager = LoopManager.shared
    @State private var selectedTab = "recent"
    @State private var selectedLoop: Loop?
    @State private var selectedMonthId: MonthIdentifier?
    @State private var backgroundOpacity = 0.2
    @State private var scrollOffset: CGFloat = 0
    
    private let accentColor = Color(hex: "A28497")
    private let backgroundColor = Color(hex: "FAFBFC")
    private let textColor = Color(hex: "2C3E50")
    private let surfaceColor = Color(hex: "F8F5F7")
    
    var body: some View {
        ZStack {
//            FlowingBackground(color: accentColor)
//                .opacity(backgroundOpacity)
//                .ignoresSafeArea()
//            
            Color(hex: "F5F5F5")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
//                headerView
//                    .padding(.top, 22)
                
                tabView
                    .padding(.top, 36)
                
                contentView
                    .padding(.top, 32)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 1.2)) {
                backgroundOpacity = 0.2
            }
            withAnimation {
                Task {
                    await loopManager.loadActiveMonths()
                }
            }
        }
        .fullScreenCover(item: $selectedLoop) { loop in
            ViewPastLoopView(loop: loop, isThroughRecordLoopsView: false)
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("JOURNAL")
                .font(.custom("PPNeueMontreal-Bold", size: 24))
                .foregroundColor(textColor)
                .tracking(1.2)
            
            Text("your reflections")
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(accentColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
    }
    
    private var tabView: some View {
        HStack(spacing: 32) {
            ForEach(["recent", "past"], id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 8) {
                        Text(tab)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(selectedTab == tab ? textColor : textColor.opacity(0.5))
                        
                        Rectangle()
                            .fill(selectedTab == tab ? accentColor : Color.clear)
                            .frame(height: 2)
                            .cornerRadius(1)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    @ViewBuilder
    private var contentView: some View {
        if selectedTab == "recent" {
            RecentLoopsView(selectedLoop: $selectedLoop)
        } else {
            if let monthId = selectedMonthId {
                MonthDetailView(monthId: monthId) {
                    withAnimation {
                        selectedMonthId = nil
                    }
                }
            } else {
                MonthsGridView(selectedMonthId: $selectedMonthId)
            }
        }
    }
}


struct RecentLoopsView: View {
    @ObservedObject private var loopManager = LoopManager.shared
    @Binding var selectedLoop: Loop?
    @State private var loadingMore = false
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    private let backgroundColor = Color(hex: "FAFBFC")
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                if loopManager.recentDates.isEmpty {
                    EmptyStateView(
                        title: "Start Reflecting",
                        message: "Your journal entries will appear here as you record them",
                        systemImage: "text.bubble"
                    )
                } else {
                    LazyVStack(spacing: 32) {
                        ForEach(loopManager.recentDates, id: \.self) { date in
                            DateSection(
                                date: date,
                                loops: loopManager.loopsByDate[date] ?? [],
                                selectedLoop: $selectedLoop
                            )
                        }
                    }
                }
                
                if loadingMore {
                    ProgressView()
                        .frame(height: 50)
                }
            }
            .padding(.horizontal, 24)
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .task {
            if loopManager.recentDates.isEmpty {
                await loadInitialLoops()
            }
        }
    }
    
    private func loadInitialLoops() async {
        loadingMore = true
        loopManager.fetchRecentDates(limit: 10) {
            loadingMore = false
        }
    }
}

struct DateSection: View {
    let date: Date
    let loops: [Loop]
    @Binding var selectedLoop: Loop?
    @ObservedObject private var checkinManager = DailyCheckinManager.shared
    @State private var dailySummary: String?
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    private let surfaceColor = Color(hex: "F8F5F7")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Date and Mood Section
            VStack(spacing: 12) {
                HStack(alignment: .bottom) {
                    Text(formatDate())
                        .font(.custom("PPNeueMontreal-Medium", size: 24)) // Increased size
                        .foregroundColor(textColor)
                    
                    Spacer()
                    
                    DayMoodIndicators(date: date)
                }
                
                if let summary = dailySummary {
                    summaryCard(summary)
                }
            }
            
            // Loops Section
            VStack(spacing: 16) {
                ForEach(loops) { loop in
                    LoopCard(loop: loop) {
                        selectedLoop = loop
                    }
                }
            }
        }
        .task {
            await loadDailySummary()
        }
    }
    
    private func summaryCard(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Summary")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(accentColor)
            
            Text(summary)
                .font(.system(size: 16))
                .foregroundColor(textColor.opacity(0.9))
                .lineSpacing(4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(surfaceColor.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(accentColor.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private func loadDailySummary() async {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DailySummaryEntity")
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        fetchRequest.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        fetchRequest.fetchLimit = 1
        
        do {
            if let summaryEntity = try checkinManager.context.fetch(fetchRequest).first,
               let summaryText = summaryEntity.value(forKey: "summary") as? String {
                await MainActor.run {
                    self.dailySummary = summaryText
                }
            }
        } catch {
            print("❌ Failed to fetch daily summary: \(error)")
        }
    }
    
    private func formatDate() -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d"
      
            let dateString = formatter.string(from: date)
            return dateString.prefix(1).uppercased() + dateString.dropFirst().lowercased()
        }
    }
}

struct DayMoodIndicators: View {
    let date: Date
    @ObservedObject private var checkinManager = DailyCheckinManager.shared
    
    private let sadColor = Color(hex: "1E3D59")
    private let neutralColor = Color(hex: "94A7B7")
    private let happyColor = Color(hex: "B784A7")
    
    // Cache the fetch results
    @State private var moodRatings: [Double] = []
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(moodRatings, id: \.self) { rating in
                Circle()
                    .fill(getColor(for: rating))
                    .frame(width: 8, height: 8)
            }
        }
        .onAppear {
            loadMoodRatings()
        }
    }
    
    private func loadMoodRatings() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "DailyCheckinEntity")
        fetchRequest.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        
        do {
            let results = try checkinManager.context.fetch(fetchRequest)
            moodRatings = results.compactMap { $0.value(forKey: "rating") as? Double }
        } catch {
            print("❌ Failed to fetch mood ratings: \(error)")
        }
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


struct ScrollViewOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct MonthsGridView: View {
    @ObservedObject private var loopManager = LoopManager.shared
    @Binding var selectedMonthId: MonthIdentifier?
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    private let surfaceColor = Color(hex: "F8F5F7")
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            if loopManager.activeMonths.isEmpty {
                EmptyStateView(
                    title: "No Past Entries",
                    message: "Your monthly archives will appear here as you continue your reflection journey",
                    systemImage: "calendar"
                )
                
            } else {
                VStack(spacing: 40) {
                    ForEach(groupedMonths.keys.sorted().reversed(), id: \.self) { year in
                        YearSection(
                            year: year,
                            months: groupedMonths[year] ?? [],
                            selectedMonthId: $selectedMonthId
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 5)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }
    
    private var groupedMonths: [Int: [MonthIdentifier]] {
        Dictionary(grouping: loopManager.activeMonths) { $0.year }
    }
}

struct YearSection: View {
    let year: Int
    let months: [MonthIdentifier]
    @Binding var selectedMonthId: MonthIdentifier?
    
    private let textColor = Color(hex: "2C3E50")
    
    @ObservedObject private var loopManager = LoopManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Spacer()
                
                Text(String(year))
                    .font(.system(size: 14, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.6))

                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(months.sorted(by: { $0.month > $1.month }), id: \.self) { monthId in
                    MonthCard(monthId: monthId) {
                        withAnimation {
                            selectedMonthId = monthId
                            Task {
                                let monthSummary = await loopManager.loadMonthData(monthId: monthId)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct MonthCard: View {
    let monthId: MonthIdentifier
    let onTap: () -> Void
    
    @State private var summary: MonthSummary?
    @State private var isPressed = false
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    private let surfaceColor = Color(hex: "F8F5F7")
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                    onTap()
                }
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                Text(monthName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(textColor)
                
                if let summary = summary {
                    HStack(spacing: 4) {
                        Text("\(summary.totalEntries)")
                            .font(.custom("PPNeueMontreal-Medium", size: 16))
                        Text("entries")
                            .font(.system(size: 16, weight: .regular))
                    }
                    .foregroundColor(accentColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            .background(
                ZStack {
                    Color.white
                    
                    WavyBackground()
                        .foregroundColor(surfaceColor)
                        .opacity(0.5)
                        .cornerRadius(10)
                }
            )
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(accentColor.opacity(0.08), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
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
            return dateFormatter.string(from: date).lowercased()
        }
        return ""
    }
    
    private func loadSummary() async {
        do {
            self.summary = await LoopManager.shared.loadMonthData(monthId: monthId)
        } catch {
            print("Error loading month summary: \(error)")
        }
    }
}

struct MonthDetailView: View {
    let monthId: MonthIdentifier
    let onBack: () -> Void
    
    @ObservedObject private var loopManager = LoopManager.shared
    @State private var selectedLoop: Loop?
    @State private var scrollOffset: CGFloat = 0
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    private let surfaceColor = Color(hex: "F8F5F7")
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                headerSection
                    .padding(.horizontal, 24)
                    .padding(.top, 5)
                
                if let summary = loopManager.selectedMonthSummary {
                    VStack(spacing: 32) {
//                        monthOverview(summary)
//                            .padding(.top, 32)
//                        
                        loopsSection(summary)
                    }
                    .padding(.horizontal, 24)
                } else {
                    loadingView
                        .padding(.top, 40)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .fullScreenCover(item: $selectedLoop) { loop in
            ViewPastLoopView(loop: loop, isThroughRecordLoopsView: false)
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                        Text("back")
                            .font(.system(size: 16, weight: .regular))
                    }
                    .foregroundColor(accentColor)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
            
            HStack {
                Text(monthTitle)
                    .font(.custom("PPNeueMontreal-Medium", size: 37))
                    .foregroundColor(textColor)
                
                Spacer()
            }
        }
    }
    
    private func monthOverview(_ summary: MonthSummary) -> some View {
        VStack(spacing: 24) {
            HStack(spacing: 32) {
                statView(
                    value: summary.loops.count,
                    label: "entries",
                    color: accentColor
                )
                
                statView(
                    value: Set(summary.loops.map { Calendar.current.startOfDay(for: $0.timestamp) }).count,
                    label: "active days",
                    color: accentColor
                )
            }
            
            Divider()
                .background(accentColor.opacity(0.1))
        }
    }
    
    private func statView(value: Int, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(value)")
                .font(.custom("PPNeueMontreal-Medium", size: 24))
                .foregroundColor(textColor)
            
            Text(label)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func loopsSection(_ summary: MonthSummary) -> some View {
        VStack(spacing: 32) {
            ForEach(groupedLoops(summary.loops), id: \.0) { date, loops in
                DateSection(
                    date: date,
                    loops: loops,
                    selectedLoop: $selectedLoop
                )
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(accentColor)
            
            Text("loading entries...")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(textColor.opacity(0.6))
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
    
    private func groupedLoops(_ loops: [Loop]) -> [(Date, [Loop])] {
        let grouped = Dictionary(grouping: loops) { loop in
            Calendar.current.startOfDay(for: loop.timestamp)
        }
        return grouped.sorted { $0.key > $1.key }
    }
}

struct FlowingBackground: View {
    let color: Color
    @State private var phase = 0.0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                phase = time.truncatingRemainder(dividingBy: 6)
                
                for i in 0..<3 {
                    let path = createWavePath(
                        in: size,
                        phase: phase + Double(i) * .pi / 3,
                        amplitude: Double(20 + i * 5)
                    )
                    
                    context.opacity = 0.1 - Double(i) * 0.02
                    context.fill(
                        path,
                        with: .linearGradient(
                            Gradient(colors: [color, color.opacity(0.8)]),
                            startPoint: CGPoint(x: 0, y: size.height/2),
                            endPoint: CGPoint(x: size.width, y: size.height/2)
                        )
                    )
                }
            }
        }
    }
    
    private func createWavePath(in size: CGSize, phase: Double, amplitude: Double) -> Path {
        var path = Path()
        let width = size.width
        let height = size.height
        let midHeight = height / 2
        
        path.move(to: CGPoint(x: 0, y: height))
        
        for x in stride(from: 0, through: width, by: 5) {
            let normalizedX = x / width
            let wavePhase1 = normalizedX * 4 * .pi + phase
            let wavePhase2 = normalizedX * 2 * .pi + phase * 1.5
            
            let sinComponent = Darwin.sin(wavePhase1) * amplitude
            let cosComponent = Darwin.cos(wavePhase2) * (amplitude * 0.5)
            
            let y = midHeight + sinComponent + cosComponent
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}



#Preview {
    LoopsView()
}
