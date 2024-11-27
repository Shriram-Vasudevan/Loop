//
//  LoopsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/8/24.
//

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
        case recent, monthly
    }
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerSection
                
                Picker("View Mode", selection: $selectedViewMode) {
                    Text("Recent").tag(ViewMode.recent)
                    Text("Archive").tag(ViewMode.monthly)
                }
                .pickerStyle(.segmented)
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
            HStack(alignment: .center) {
                Text("journal")
                    .font(.system(size: 40, weight: .ultraLight))
                    .foregroundColor(textColor)
                
                Spacer()
                
                if !loopManager.hasCompletedToday {
                    TodayProgressRing(
                        progress: Double(loopManager.currentPromptIndex) / Double(loopManager.dailyPrompts.count),
                        total: loopManager.dailyPrompts.count, completed: loopManager.currentPromptIndex
                    )
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
    
    @ViewBuilder
    private var selectedView: some View {
        ScrollView(showsIndicators: false) {
            switch selectedViewMode {
            case .recent:
                RecentLoopsView()
                    .transition(.opacity)
            case .monthly:
                ArchiveView(selectedMonthId: $selectedMonthId)
                    .transition(.opacity)
            }
        }
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
            if loopManager.recentDates.isEmpty {
                fetchInitialLoops()
            }
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

struct ArchiveView: View {
    @ObservedObject private var loopManager = LoopManager.shared
    @Binding var selectedMonthId: MonthIdentifier?
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        if let selectedMonthId = selectedMonthId {
            MonthDetailView(monthId: selectedMonthId, onBack: { self.selectedMonthId = nil })
        } else {
            monthGrid
        }
    }
    
    private var monthGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]
        
        return LazyVGrid(columns: columns, spacing: 16) {
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
        .padding(.horizontal, 24)
    }
}

struct MonthCard: View {
    let monthId: MonthIdentifier
    @State private var summary: MonthSummary?
    @State private var backgroundOpacity: Double = 0
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        ZStack(alignment: .leading) {
            if let summary = summary {
                Text("\(summary.totalEntries)")
                    .font(.system(size: 120, weight: .bold))
                    .foregroundColor(Color(hex: "F0F0F0"))
                    .offset(x: 10, y: -5)
                    .opacity(backgroundOpacity)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(monthName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(textColor)
                    
                    Text(String(monthId.year))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(textColor.opacity(0.6))
                }
                
                if let summary = summary {
                    Text("\(summary.totalEntries) memories")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(accentColor)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
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
            withAnimation(.easeOut(duration: 0.8)) {
                backgroundOpacity = 1
            }
        } catch {
            print("Error loading month summary: \(error)")
        }
    }
}

struct MonthDetailView: View {
    let monthId: MonthIdentifier
    let onBack: () -> Void
    @ObservedObject private var loopManager = LoopManager.shared
    
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Button(action: onBack) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .foregroundColor(textColor)
            }
            
            if let summary = loopManager.selectedMonthSummary {
                Text(monthTitle)
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(textColor)
                
                ForEach(groupedLoopsByDay(summary.loops), id: \.0) { date, loops in
                    TimelineSection(date: date, loops: loops) { loop in
                        // Loop selection handled by TimelineSection
                    }
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(.horizontal, 24)
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
                
                Rectangle()
                    .fill(textColor.opacity(0.1))
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

struct TimelineLoopCard: View {
    let loop: Loop
    let onTap: () -> Void
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 16) {
                Text(formatTime(loop.timestamp))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(textColor.opacity(0.6))
                    .frame(width: 50)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(loop.promptText)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(textColor)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "waveform")
                            .font(.system(size: 12))
                        Text("0:30")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(accentColor.opacity(0.1))
                    .cornerRadius(12)
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
                    .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
            )
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}


struct AnimatedGradientBackground: View {
    @State private var phase = 0.0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let colors = [
                    Color(hex: "FAFBFC").opacity(0.8),
                    Color(hex: "F8F5F7").opacity(0.5),
                    Color(hex: "FAFBFC").opacity(0.8)
                ]
                
                let updatedPhase = timeline.date.timeIntervalSinceReferenceDate.remainder(dividingBy: 10)
                let gradient = Gradient(colors: colors)
                
                var path = Path()
                let width = size.width
                let height = size.height
                
                path.move(to: CGPoint(x: 0, y: height * 0.5))
                
                for x in stride(from: 0, to: width, by: 1) {
                    let relativeX = x / width
                    let sine = sin(relativeX * .pi * 2 + updatedPhase)
                    let y = height * 0.5 + sine * 20
                    path.addLine(to: CGPoint(x: x, y: y))
                }
                
                path.addLine(to: CGPoint(x: width, y: height))
                path.addLine(to: CGPoint(x: 0, y: height))
                path.closeSubpath()
                
                context.fill(path, with: .linearGradient(
                    gradient,
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: size.width, y: size.height)
                ))
            }
        }
        .ignoresSafeArea()
    }
}


struct AudioPlayerView: View {
    let loop: Loop
    @State private var isPlaying = false
    @State private var progress: Double = 0
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 24) {
            ProgressBar(progress: progress)
                .frame(height: 4)
                .padding(.horizontal)
            
            HStack {
                Button(action: togglePlayback) {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 64, height: 64)
                        .overlay(
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        )
                }
            }
        }
    }
    
    private func togglePlayback() {
        isPlaying.toggle()
    }
}

struct ProgressBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color(hex: "A28497").opacity(0.2))
                
                Rectangle()
                    .fill(Color(hex: "A28497"))
                    .frame(width: geometry.size.width * progress)
            }
        }
        .cornerRadius(2)
    }
}
