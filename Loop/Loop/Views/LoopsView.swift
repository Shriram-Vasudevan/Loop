//
//  LoopsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/8/24.
//

import SwiftUI
import Darwin
import SwiftUI

struct LoopsView: View {
    @ObservedObject private var loopManager = LoopManager.shared
    @State private var selectedTab = "recent"
    @State private var selectedLoop: Loop?
    @State private var selectedMonthId: MonthIdentifier?
    @State private var backgroundOpacity = 1.0
    @State private var scrollOffset: CGFloat = 0
    
    private let accentColor = Color(hex: "A28497")
    private let backgroundColor = Color(hex: "FAFBFC")
    private let textColor = Color(hex: "2C3E50")
    private let surfaceColor = Color(hex: "F8F5F7")
    
    var body: some View {
        ZStack {
            FlowingBackground(color: accentColor)
                .opacity(backgroundOpacity)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                    .padding(.top, 45)
                
                tabView
                    .padding(.top, 24)
                
                contentView
                    .padding(.top, 32)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 1.2)) {
                backgroundOpacity = 0.2
            }
            Task {
                await loopManager.loadActiveMonths()
            }
        }
        .fullScreenCover(item: $selectedLoop) { loop in
            ViewPastLoopView(loop: loop, isThroughRecordLoopsView: false)
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("journal")
                .font(.custom("PPNeueMontreal-Medium", size: 37))
                .foregroundColor(textColor)
            
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
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(formatDate())
                .font(.custom("PPNeueMontreal-Medium", size: 16))
                .foregroundColor(textColor)
            
            VStack(spacing: 16) {
                ForEach(loops) { loop in
                    LoopCard(loop: loop) {
                        selectedLoop = loop
                    }
                }
            }
        }
    }
    
    private func formatDate() -> String {
        if Calendar.current.isDateInToday(date) {
            return "today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d"
            return formatter.string(from: date).lowercased()
        }
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
                .padding(.vertical, 20)
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
        VStack(alignment: .leading, spacing: 24) {
            Text(String(year))
                .font(.custom("PPNeueMontreal-Medium", size: 37))
                .foregroundColor(textColor)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(months.sorted(by: { $0.month > $1.month }), id: \.self) { monthId in
                    MonthCard(monthId: monthId) {
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
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 2)
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
            summary = try await LoopCloudKitUtility.fetchMonthData(monthId: monthId)
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
                    .padding(.top, 20)
                
                if let summary = loopManager.selectedMonthSummary {
                    VStack(spacing: 32) {
                        monthOverview(summary)
                            .padding(.top, 32)
                        
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
            
            Text(monthTitle)
                .font(.custom("PPNeueMontreal-Medium", size: 37))
                .foregroundColor(textColor)
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
            return dateFormatter.string(from: date).lowercased()
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


//struct LoopsView: View {
//    @ObservedObject private var loopManager = LoopManager.shared
//    @State private var selectedTab = "recent"
//    @State private var selectedLoop: Loop?
//    @State private var selectedMonthId: MonthIdentifier?
//    @State private var backgroundOpacity = 1.0
//    
//    private let accentColor = Color(hex: "A28497")
//    private let secondaryColor = Color(hex: "B7A284")
//    private let backgroundColor = Color(hex: "FAFBFC")
//    private let surfaceColor = Color(hex: "F8F5F7")
//    private let textColor = Color(hex: "2C3E50")
//    
//    var body: some View {
//        ZStack {
//            FlowingBackground(color: accentColor)
//                .opacity(backgroundOpacity)
//                .ignoresSafeArea()
//            
//            VStack(spacing: 0) {
//                headerSection
//                
//                tabNavigation
//                    .padding(.top, 15)
//                
//                if selectedTab == "recent" {
//                    RecentLoopsView(selectedLoop: $selectedLoop)
//                } else {
//                    if let monthId = selectedMonthId {
//                        MonthDetailView(monthId: monthId) {
//                            withAnimation {
//                                selectedMonthId = nil
//                            }
//                        }
//                    } else {
//                        MonthsGridView(selectedMonthId: $selectedMonthId)
//                    }
//                }
//            }
//        }
//        .onAppear {
//            withAnimation(.easeIn(duration: 1.2)) {
//                backgroundOpacity = 0.3
//            }
//            Task {
//                await loopManager.loadActiveMonths()
//            }
//        }
//        .fullScreenCover(item: $selectedLoop) { loop in
//            ViewPastLoopView(loop: loop, isThroughRecordLoopsView: false)
//        }
//    }
//    
//    private var headerSection: some View {
//        VStack(spacing: 16) {
//            HStack {
//                VStack(alignment: .leading, spacing: 0) {
//                    Text("journal")
//                        .font(.system(size: 40, weight: .bold))
//                        .foregroundColor(textColor)
//                    
//                    HStack(spacing: 4) {
//                        Text("see")
//                            .font(.system(size: 20, weight: .light))
//                            .foregroundColor(.gray)
//                        Text("your")
//                            .font(.system(size: 20, weight: .light))
//                            .foregroundColor(.gray)
//                        Text("reflections")
//                            .font(.system(size: 20, weight: .medium))
//                            .foregroundColor(accentColor)
//                    }
//                    .padding(.top, -5)
//
//                }
//
//                Spacer()
////
////                if !loopManager.hasCompletedToday {
////                    CircularProgress(
////                        progress: CGFloat(loopManager.currentPromptIndex) / CGFloat(loopManager.dailyPrompts.count),
////                        color: accentColor
////                    )
////                    .frame(width: 50, height: 50)
////                }
//            }
//        }
//        .padding(.horizontal, 24)
//        .padding(.top, 16)
//    }
//    
//    private var tabNavigation: some View {
//        Menu {
//            Button("recent") {
//                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
//                    selectedTab = "recent"
//                }
//            }
//            Button("past") {
//                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
//                    selectedTab = "past"
//                }
//            }
//        } label: {
//            ZStack {
//
//                HStack(spacing: 8) {
//                    Text(selectedTab)
//                        .font(.system(size: 20, weight: .medium))
//                        .foregroundColor(.black)
//                }
//                .frame(height: 56)
//                .frame(maxWidth: .infinity)
//                .background(
//                    RoundedRectangle(cornerRadius: 20)
//                        .fill(
//                            LinearGradient(
//                                gradient: Gradient(colors: [
//                                    backgroundColor,
//                                    Color(hex: "FFFFFF")
//                                ]),
//                                startPoint: .topLeading,
//                                endPoint: .bottomTrailing
//                            )
//                        )
//                )
//                .cornerRadius(28)
//                .shadow(color: accentColor.opacity(0.15), radius: 12, y: 6)
//                .padding(.horizontal)
//                
//                HStack {
//                    Spacer()
//                    Image(systemName: "chevron.down")
//                        .font(.system(size: 18, weight: .medium))
//                        .foregroundColor(.black)
//                        .padding(.trailing)
//                }
//                .padding(.horizontal)
//            }
//        }
//        .buttonStyle(ScaleButtonStyle())
//    }
//}
//
//struct RecentLoopsView: View {
//    @ObservedObject private var loopManager = LoopManager.shared
//    @Binding var selectedLoop: Loop?
//    @State private var loadingMore = false
//    
//    private let accentColor = Color(hex: "A28497")
//    private let textColor = Color(hex: "2C3E50")
//    
//    var body: some View {
//        ScrollView(showsIndicators: false) {
//            LazyVStack(spacing: 24) {
//                if loopManager.recentDates.isEmpty {
//                    EmptyStateView(
//                        title: "No Recent Entries",
//                        message: "Your journal entries will appear here once you start recording.",
//                        systemImage: "text.bubble"
//                    )
//                } else {
//                    LazyVStack(spacing: 24) {
//                        ForEach(loopManager.recentDates, id: \.self) { date in
//                            DaySection(
//                                date: date,
//                                loops: loopManager.loopsByDate[date] ?? [],
//                                selectedLoop: $selectedLoop
//                            )
//                        }
//                        
//                        if loadingMore {
//                            ProgressView()
//                                .frame(height: 50)
//                        }
//                    }
//                }
//                if loadingMore {
//                    ProgressView()
//                        .frame(height: 50)
//                }
//            }
//            .padding(.horizontal, 24)
//            .padding(.vertical, 20)
//        }
//        .task {
//            if loopManager.recentDates.isEmpty {
//                await loadInitialLoops()
//            }
//        }
//    }
//    
//    private func loadInitialLoops() async {
//        loadingMore = true
//        loopManager.fetchRecentDates(limit: 10) {
//            loadingMore = false
//        }
//    }
//}
//
//struct DaySection: View {
//    let date: Date
//    let loops: [Loop]
//    @Binding var selectedLoop: Loop?
//    
//    private let accentColor = Color(hex: "A28497")
//    private let textColor = Color(hex: "2C3E50")
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            HStack(spacing: 12) {
//                Text(formatDate())
//                    .font(.system(size: 16, weight: .medium))
//                    .foregroundColor(textColor)
//                
//                Rectangle()
//                    .fill(textColor.opacity(0.1))
//                    .frame(height: 1)
//            }
//            
//            ForEach(loops) { loop in
//                LoopCard(loop: loop) {
//                    selectedLoop = loop
//                }
//            }
//        }
//    }
//    
//    private func formatDate() -> String {
//        if Calendar.current.isDateInToday(date) {
//            return "Today"
//        } else if Calendar.current.isDateInYesterday(date) {
//            return "Yesterday"
//        } else {
//            let formatter = DateFormatter()
//            formatter.dateFormat = "MMMM d"
//            return formatter.string(from: date)
//        }
//    }
//}
//
//
//struct MenuButton: View {
//    @Binding var showDeleteConfirmation: Bool
//    let textColor: Color
//    
//    var body: some View {
//        Menu {
//            Button(role: .destructive) {
//                showDeleteConfirmation = true
//            } label: {
//                Label("Delete", systemImage: "trash")
//            }
//        } label: {
//            Image(systemName: "ellipsis")
//                .font(.system(size: 20))
//                .foregroundColor(textColor.opacity(0.6))
//                .frame(width: 44, height: 44)
//                .contentShape(Rectangle())
//        }
//        .buttonStyle(MenuButtonStyle())
//        .simultaneousGesture(TapGesture().onEnded { })
//    }
//}
//
//// Custom button style for the entire card
//struct CardButtonStyle: ButtonStyle {
//    let isPressed: Bool
//    
//    func makeBody(configuration: Configuration) -> some View {
//        configuration.label
//            .scaleEffect(isPressed ? 0.97 : 1)
//            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
//    }
//}
//
//
//// Badge for loop types
//struct LoopTypeBadge: View {
//    let text: String
//    let color: Color
//    
//    var body: some View {
//        Text(text)
//            .font(.system(size: 12, weight: .medium))
//            .foregroundColor(color)
//            .padding(.horizontal, 8)
//            .padding(.vertical, 4)
//            .background(
//                Capsule()
//                    .fill(color.opacity(0.12))
//            )
//    }
//}
//
//struct MenuButtonStyle: ButtonStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        configuration.label
//            .background(
//                Circle()
//                    .fill(Color.black.opacity(configuration.isPressed ? 0.05 : 0))
//            )
//            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
//    }
//}
//
//struct MonthsGridView: View {
//    @ObservedObject private var loopManager = LoopManager.shared
//    @Binding var selectedMonthId: MonthIdentifier?
//    
//    private let accentColor = Color(hex: "A28497")
//    private let textColor = Color(hex: "2C3E50")
//    private let backgroundColor = Color(hex: "FAFBFC")
//    
//    var body: some View {
//        ScrollView(showsIndicators: false) {
//            if loopManager.activeMonths.isEmpty {
//                EmptyStateView(
//                    title: "No Past Entries",
//                    message: "Your monthly archives will appear here once you start recording.",
//                    systemImage: "calendar"
//                )
//            } else {
//                VStack(spacing: 24) {
//                    yearSections
//                }
//                .padding(.horizontal, 24)
//                .padding(.bottom, 32)
//                .padding(.top, 20)
//            }
//        }
//    }
//    
//    private var yearSections: some View {
//        let groupedByYear = Dictionary(grouping: loopManager.activeMonths) { $0.year }
//        return ForEach(groupedByYear.keys.sorted().reversed(), id: \.self) { year in
//            VStack(alignment: .leading, spacing: 8) {
//                Text(String(year))
//                    .font(.system(size: 45))
//                    .fontWeight(.bold)
//                    .foregroundColor(textColor.opacity(0.8))
//                    .padding(.leading, 8)
//                
//                VStack(spacing: 20) {
//                    ForEach(groupedByYear[year]?.sorted(by: { $0.month > $1.month }) ?? [], id: \.self) { monthId in
//                        MonthCard(monthId: monthId) {
//                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
//                                selectedMonthId = monthId
//                                Task {
//                                    await loopManager.loadMonthData(monthId: monthId)
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
//}
//struct MonthCard: View {
//    let monthId: MonthIdentifier
//    let onTap: () -> Void
//    
//    @State private var summary: MonthSummary?
//    @State private var isHovered = false
//    
//    private let accentColor = Color(hex: "A28497")
//    private let textColor = Color(hex: "2C3E50")
//    
//    var body: some View {
//        Button(action: onTap) {
//            HStack {
//                VStack(alignment: .leading, spacing: 20) {
//                    // Header Section
//                    HStack {
//                        VStack(alignment: .leading, spacing: 4) {
//                            Text(monthName)
//                                .font(.system(size: 28))
//                                .fontWeight(.bold)
//                                .foregroundColor(textColor)
//                            
//                            if let summary = summary {
//                                Text("\(summary.totalEntries) memories")
//                                    .font(.system(size: 18))
//                                    .fontWeight(.medium)
//                                    .foregroundColor(accentColor)
//                            }
//                        }
//                        
//                        Spacer()
//                        
//                        Image(systemName: "chevron.right.circle.fill")
//                            .imageScale(.large)
//                            .fontWeight(.semibold)
//                            .foregroundColor(accentColor)
//
//                    }
//                }
//                .padding(24)
//            }
//            .background(
//                RoundedRectangle(cornerRadius: 24)
//                    .fill(Color.white)
//                    .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
//            )
//            .overlay(
//                RoundedRectangle(cornerRadius: 24)
//                    .strokeBorder(
//                        LinearGradient(
//                            gradient: Gradient(colors: [
//                                accentColor.opacity(0.2),
//                                accentColor.opacity(0.05)
//                            ]),
//                            startPoint: .topLeading,
//                            endPoint: .bottomTrailing
//                        ),
//                        lineWidth: 1
//                    )
//            )
//        }
//        .buttonStyle(PlainButtonStyle())
//        .onHover { isHovered = $0 }
//        .task {
//            await loadSummary()
//        }
//    }
//    
//    private func statView(icon: String, value: Int, label: String) -> some View {
//        HStack(spacing: 12) {
//            Image(systemName: icon)
//                .imageScale(.medium)
//                .foregroundColor(accentColor)
//            
//            VStack(alignment: .leading, spacing: 2) {
//                Text("\(value)")
//                    .font(.system(size: 16))
//                    .fontWeight(.semibold)
//                    .foregroundColor(textColor)
//                
//                Text(label)
//                    .font(.system(size: 14))
//                    .fontWeight(.medium)
//                    .foregroundColor(textColor.opacity(0.6))
//            }
//        }
//        .padding(.horizontal, 16)
//        .padding(.vertical, 8)
//        .background(
//            RoundedRectangle(cornerRadius: 12)
//                .fill(accentColor.opacity(0.05))
//        )
//    }
//    
//    private var monthName: String {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "MMMM"
//        var components = DateComponents()
//        components.year = monthId.year
//        components.month = monthId.month
//        if let date = Calendar.current.date(from: components) {
//            return dateFormatter.string(from: date)
//        }
//        return ""
//    }
//    
//    private func loadSummary() async {
//        do {
//            summary = try await LoopCloudKitUtility.fetchMonthData(monthId: monthId)
//        } catch {
//            print("Error loading month summary: \(error)")
//        }
//    }
//}
//
//
//struct MonthDetailView: View {
//    let monthId: MonthIdentifier
//    let onBack: () -> Void
//    @ObservedObject private var loopManager = LoopManager.shared
//    @State private var selectedLoop: Loop?
//    @State private var scrollOffset: CGFloat = 0
//    
//    private let textColor = Color(hex: "2C3E50")
//    private let accentColor = Color(hex: "A28497")
//    
//    var body: some View {
//        ZStack {
//            // Decorative background elements
//            VStack {
//                Circle()
//                    .fill(accentColor.opacity(0.05))
//                    .frame(width: 300, height: 300)
//                    .offset(x: -100, y: -100)
//                    .blur(radius: 60)
//                Spacer()
//            }
//            
//            ScrollView {
//                VStack(alignment: .leading, spacing: 0) {
//                    headerSection
//                        .padding(.horizontal, 24)
//                        .padding(.top, 16)
//                        .padding(.bottom, 32)
//                    
//                    if let summary = loopManager.selectedMonthSummary {
//                        loopsSection(summary)
//                    } else {
//                        loadingView
//                    }
//                }
//            }
//            .overlay(
//                GeometryReader { proxy in
//                    Color.clear.preference(
//                        key: ScrollOffsetPreferenceKey.self,
//                        value: proxy.frame(in: .named("scroll")).minY
//                    )
//                }
//            )
//            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
//                scrollOffset = offset
//            }
//            .coordinateSpace(name: "scroll")
//        }
//        .navigationBarHidden(true)
//        .fullScreenCover(item: $selectedLoop) { loop in
//            ViewPastLoopView(loop: loop, isThroughRecordLoopsView: false)
//        }
//    }
//    
//    private var headerSection: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            Button(action: onBack) {
//                HStack(spacing: 12) {
//                    Image(systemName: "chevron.left")
//                        .font(.system(size: 16, weight: .semibold))
//                    Text("Back")
//                        .font(.system(size: 16, weight: .medium))
//                }
//                .foregroundColor(accentColor)
//                .padding(12)
//                .background(
//                    RoundedRectangle(cornerRadius: 12)
//                        .fill(accentColor.opacity(0.1))
//                )
//            }
//            .buttonStyle(SpringyButton())
//            
//            Text(monthTitle)
//                .font(.system(size: 40))
//                .fontWeight(.bold)
//                .foregroundColor(textColor)
//                .opacity(max(0, min(1.0, 1.0 + (scrollOffset / 500))))
//
//        }
//        .background(Color.white.opacity(scrollOffset < 0 ? 1 : 0))
//    }
//    
//    private func monthSummarySection(_ summary: MonthSummary) -> some View {
//        HStack(spacing: 20) {
//            statisticCard(
//                title: "Total Entries",
//                value: "\(summary.loops.count)",
//                icon: "doc.text.fill"
//            )
//            
//            statisticCard(
//                title: "Active Days",
//                value: "\(Set(summary.loops.map { Calendar.current.startOfDay(for: $0.timestamp) }).count)",
//                icon: "calendar"
//            )
//        }
//    }
//    
//    private func statisticCard(title: String, value: String, icon: String) -> some View {
//        VStack(alignment: .leading, spacing: 12) {
//            HStack(spacing: 12) {
//                Image(systemName: icon)
//                    .font(.system(size: 18))
//                    .foregroundColor(accentColor)
//                
//                Text(title)
//                    .font(.system(size: 14, weight: .medium))
//                    .foregroundColor(textColor.opacity(0.6))
//            }
//            
//            Text(value)
//                .font(.system(size: 32, weight: .bold))
//                .foregroundColor(textColor)
//        }
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .padding(20)
//        .background(
//            RoundedRectangle(cornerRadius: 20)
//                .fill(Color.white)
//                .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
//        )
//    }
//    
//    private func loopsSection(_ summary: MonthSummary) -> some View {
//        VStack(spacing: 32) {
//            ForEach(groupedLoops(summary.loops), id: \.0) { date, loops in
//                DaySection(date: date, loops: loops, selectedLoop: $selectedLoop)
//            }
//        }
//        .padding(.horizontal, 24)
//    }
//    
//    private var loadingView: some View {
//        VStack(spacing: 20) {
//            ProgressView()
//                .scaleEffect(1.5)
//            Text("Loading entries...")
//                .font(.system(size: 16, weight: .medium))
//                .foregroundColor(textColor.opacity(0.6))
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .padding(.top, 100)
//    }
//    
//    private var monthTitle: String {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "MMMM yyyy"
//        var components = DateComponents()
//        components.year = monthId.year
//        components.month = monthId.month
//        if let date = Calendar.current.date(from: components) {
//            return dateFormatter.string(from: date)
//        }
//        return ""
//    }
//    
//    private func groupedLoops(_ loops: [Loop]) -> [(Date, [Loop])] {
//        let grouped = Dictionary(grouping: loops) { loop in
//            Calendar.current.startOfDay(for: loop.timestamp)
//        }
//        return grouped.sorted { $0.key > $1.key }
//    }
//}
//struct WaveformIndicator: View {
//    let color: Color
//    @State private var isAnimating = false
//    
//    var body: some View {
//        HStack(spacing: 3) {
//            ForEach(0..<3) { index in
//                RoundedRectangle(cornerRadius: 1)
//                    .fill(color)
//                    .frame(width: 2, height: getHeight(for: index))
//                    .animation(
//                        Animation.easeInOut(duration: 0.6)
//                            .repeatForever()
//                            .delay(Double(index) * 0.2),
//                        value: isAnimating
//                    )
//            }
//        }
//        .onAppear { isAnimating = true }
//    }
//    
//    private func getHeight(for index: Int) -> CGFloat {
//        isAnimating ? [8, 16, 8][index] : 12
//    }
//}
//
//struct CircularProgress: View {
//    let progress: CGFloat
//    let color: Color
//    
//    var body: some View {
//        ZStack {
//            Circle()
//                .stroke(color.opacity(0.2), lineWidth: 4)
//            
//            Circle()
//                .trim(from: 0, to: progress)
//                .stroke(color, lineWidth: 4)
//                .rotationEffect(.degrees(-90))
//            
//            VStack(spacing: 2) {
//                Text("\(Int(progress * 3))/3")
//                    .font(.system(size: 12, weight: .medium))
//                Text("today")
//                    .font(.system(size: 10, weight: .regular))
//            }
//            .foregroundColor(color)
//        }
//    }
//}
//
        
//
//struct SpringyButton: ButtonStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        configuration.label
//            .scaleEffect(configuration.isPressed ? 0.97 : 1)
//            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
//    }
//}
//
//extension Collection {
//    subscript(safe index: Index) -> Element? {
//        indices.contains(index) ? self[index] : nil
//    }
//}
//
//struct ScrollOffsetPreferenceKey: PreferenceKey {
//    static var defaultValue: CGFloat = 0
//    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
//        value = nextValue()
//    }
//}

#Preview {
    LoopsView()
}
