//
//  LoopsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/8/24.
//

import SwiftUI
import SwiftUI

import SwiftUI

struct LoopsView: View {
    @ObservedObject private var loopManager = LoopManager.shared
    @State private var selectedLoop: Loop?
    @State private var showingRecordView = false
    @State private var selectedDate: Date = Date()
    @State private var calendarShown = false
    @State private var viewMode: ViewMode = .recent
    
    @State private var loading = true
    @State private var loadingMore = false
    @State private var hasMoreContent = true
    
    private let accentColor = Color(hex: "A28497")
    private let backgroundColor = Color(hex: "FAFBFC")
    private let textColor = Color(hex: "2C3E50")
    
    enum ViewMode {
        case recent, month, year
    }
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    headerSection
                    viewModeSelector
                    
                    switch viewMode {
                    case .recent:
                        timelineSection
                    case .month:
                        MonthView(loopManager: loopManager, selectedDate: $selectedDate)
                    case .year:
                        YearView(loopManager: loopManager, selectedDate: $selectedDate)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .overlay(alignment: .bottom) {
                if !loopManager.hasCompletedToday {
                    recordButton
                }
            }
        }
        .fullScreenCover(isPresented: $showingRecordView) {
            RecordLoopsView(isFirstLaunch: false)
        }
        .fullScreenCover(item: $selectedLoop) { loop in
            ViewPastLoopView(loop: loop)
        }
        .sheet(isPresented: $calendarShown) {
            CalendarPickerView(selectedDate: $selectedDate)
        }
        .onAppear {
            if loopManager.loopsByDate.isEmpty {
                fetchInitialLoops()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 24) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("journal")
                        .font(.system(size: 40, weight: .ultraLight))
                        .foregroundColor(textColor)
                    
                    Button(action: { calendarShown = true }) {
                        HStack(spacing: 8) {
                            Text(formatDate(selectedDate))
                                .font(.system(size: 16, weight: .light))
                            Image(systemName: "calendar")
                                .font(.system(size: 14, weight: .light))
                        }
                        .foregroundColor(accentColor)
                    }
                }
                
                Spacer()

                TodayProgressRing(
                    progress: Double(loopManager.currentPromptIndex) / Double(loopManager.prompts.count),
                    total: loopManager.prompts.count,
                    completed: loopManager.currentPromptIndex
                )
            }
        }
    }
    
    private var viewModeSelector: some View {
        HStack(spacing: 16) {
            ViewModeButton(title: "Recent", systemImage: "clock", isSelected: viewMode == .recent) {
                viewMode = .recent
            }
            
            ViewModeButton(title: "Month", systemImage: "calendar", isSelected: viewMode == .month) {
                viewMode = .month
            }
            
            ViewModeButton(title: "Year", systemImage: "calendar.badge.clock", isSelected: viewMode == .year) {
                viewMode = .year
            }
        }
    }
    
    private var timelineSection: some View {
        VStack(spacing: 24) {
            HStack {
                Text("timeline")
                    .font(.system(size: 24, weight: .ultraLight))
                    .foregroundColor(textColor)
                Spacer()
            }
            
            LazyVStack(spacing: 32) {
                ForEach(loopManager.recentDates, id: \.self) { date in
                    TimelineSection(date: date, loops: loopManager.loopsByDate[date] ?? []) { loop in
                        selectedLoop = loop
                    }
                }
                
                if loadingMore {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: accentColor))
                        .frame(height: 50)
                } else if hasMoreContent {
                    Color.clear
                        .frame(height: 50)
                        .onAppear {
                            fetchMoreLoops()
                        }
                }
            }
        }
    }
    
    private var recordButton: some View {
        Button(action: { showingRecordView = true }) {
            HStack(spacing: 12) {
                Image(systemName: "mic.fill")
                Text("record today's reflection")
            }
            .font(.system(size: 18, weight: .regular))
            .foregroundColor(.white)
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [accentColor, accentColor.opacity(0.9)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: accentColor.opacity(0.2), radius: 10, y: 5)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func fetchInitialLoops() {
        loading = true
        loopManager.fetchRecentDates(limit: 10) {
            loading = false
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

struct MonthView: View {
    let loopManager: LoopManager
    @Binding var selectedDate: Date
    
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("monthly view")
                .font(.system(size: 24, weight: .ultraLight))
                .foregroundColor(textColor)
            
            // Placeholder for month calendar grid
            Text("Monthly calendar view will be implemented here")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(textColor.opacity(0.6))
        }
    }
}

struct YearView: View {
    let loopManager: LoopManager
    @Binding var selectedDate: Date
    
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("yearly view")
                .font(.system(size: 24, weight: .ultraLight))
                .foregroundColor(textColor)
            
            // Placeholder for year summary
            Text("Yearly summary view will be implemented here")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(textColor.opacity(0.6))
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

struct DailyInsightCard<Content: View>: View {
    let title: String
    let icon: String
    var isWide: Bool = false
    @ViewBuilder let content: () -> Content
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(accentColor)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(textColor.opacity(0.6))
            }
            
            content()
        }
        .frame(maxWidth: isWide ? .infinity : nil)
        .frame(height: isWide ? nil : 120)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 15, x: 0, y: 8)
        )
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

struct CalendarPickerView: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) var dismiss
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    private let calendar = Calendar.current
    
    @State private var currentMonth: Date = Date()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        Button(action: previousMonth) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .medium))
                        }
                        
                        Spacer()
                        
                        Text(monthYearString(from: currentMonth))
                            .font(.system(size: 18, weight: .medium))
                        
                        Spacer()
                        
                        Button(action: nextMonth) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 20, weight: .medium))
                        }
                    }
                    .padding(.horizontal)
                    .foregroundColor(textColor)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(weekdaySymbols, id: \.self) { symbol in
                            Text(symbol)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(textColor.opacity(0.6))
                        }

                        ForEach(daysInMonth(), id: \.self) { date in
                            if let date = date {
                                DateCell(
                                    date: date,
                                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                    isToday: calendar.isDateInToday(date)
                                )
                                .onTapGesture {
                                    selectedDate = date
                                    dismiss()
                                }
                            } else {
                                Color.clear
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(accentColor)
                }
            }
        }
    }
    
    private var weekdaySymbols: [String] {
        calendar.veryShortWeekdaySymbols
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end - 1) else {
            return []
        }
        
        let dateInterval = DateInterval(start: monthFirstWeek.start, end: monthLastWeek.end)
        
        // Create array of dates
        var dates: [Date?] = []
        calendar.enumerateDates(
            startingAfter: dateInterval.start - 1,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) { date, _, stop in
            if let date = date {
                if date <= dateInterval.end {
                    if calendar.isDate(date, equalTo: monthInterval.start, toGranularity: .month) {
                        dates.append(date)
                    } else {
                        dates.append(nil)
                    }
                } else {
                    stop = true
                }
            }
        }
        return dates
    }
    
    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newDate
        }
    }
    
    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newDate
        }
    }
}

struct DateCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    
    private let calendar = Calendar.current
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        ZStack {
            if isSelected {
                Circle()
                    .fill(accentColor)
                    .frame(width: 36, height: 36)
            } else if isToday {
                Circle()
                    .stroke(accentColor, lineWidth: 1)
                    .frame(width: 36, height: 36)
            }
            
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 16, weight: isSelected ? .medium : .regular))
                .foregroundColor(isSelected ? .white : textColor)
        }
        .frame(height: 44)
    }
}

#Preview {
    LoopsView()
}
