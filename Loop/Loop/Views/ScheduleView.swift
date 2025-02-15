//
//  ScheduleView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/3/25.
//

import SwiftUI
import CoreData


struct ScheduleView: View {
    @ObservedObject private var scheduleManager = ScheduleManager.shared
    @Binding var selectedScheduleDate: Date?
    @State private var selectedDate: Date?
    @State private var showingDayView = false
    @State private var currentMonth: Date = Date()
    @State private var scrollOffset: CGFloat = 0
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 60) {
                LazyVStack(spacing: 80) {
                    ForEach(scheduleManager.monthsToShow, id: \.self) { month in
                        AbstractMonthView(
                            month: month,
                            selectedDate: $selectedDate,
                            showingDayView: $showingDayView
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.top, 40)
            }
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetKey.self) { offset in
            scrollOffset = offset
        }
        .background(
            ZStack {
                Color(hex: "FAFBFC")
                
                FlowingBackground(color: accentColor)
                    .opacity(max(0.2 - scrollOffset/1000, 0))
            }
        )
        .task {
            await scheduleManager.loadYearDataAndAssignColors()
            if let date = selectedScheduleDate {
                selectedDate = date
                selectedScheduleDate = nil
                showingDayView = true
            }
        }
        .navigationDestination(isPresented: $showingDayView) {
            if let date = selectedDate {
                FullDayActivityView(date: date)
            }
        }
    }
}

struct AbstractMonthView: View {
    let month: Date
    @Binding var selectedDate: Date?
    @Binding var showingDayView: Bool
    @ObservedObject private var scheduleManager = ScheduleManager.shared
    
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 7)
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            Text(month.formatted(.dateTime.month(.wide)).lowercased())
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(textColor.opacity(0.6))
                .tracking(2)
            
            VStack(spacing: 24) {
                HStack {
                    ForEach(weekdays, id: \.self) { day in
                        Text(day)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(textColor.opacity(0.3))
                            .frame(maxWidth: .infinity)
                    }
                }
                
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(daysInMonth(), id: \.self) { date in
                        if let date = date {
                            AbstractDayCell(
                                date: date,
                                isSelected: selectedDate == date,
                                rating: scheduleManager.ratings[Calendar.current.startOfDay(for: date)]
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedDate = date
                                    showingDayView = true
                                }
                            }
                        } else {
                            Color.clear
                                .aspectRatio(1, contentMode: .fill)
                        }
                    }
                }
            }
        }
    }
    
    private func daysInMonth() -> [Date?] {
        let calendar = Calendar.current
        let interval = calendar.dateInterval(of: .month, for: month)!
        let firstWeekday = calendar.component(.weekday, from: interval.start)
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        let numberOfDays = calendar.range(of: .day, in: .month, for: month)!.count
        
        let dateComponents = calendar.dateComponents([.year, .month], from: month)
        
        for day in 1...numberOfDays {
            var components = dateComponents
            components.day = day
            if let date = calendar.date(from: components) {
                days.append(date)
            }
        }
        
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
}

struct AbstractDayCell: View {
    let date: Date
    let isSelected: Bool
    let rating: Double?
    
    @ObservedObject private var scheduleManager = ScheduleManager.shared
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    private var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var body: some View {
        ZStack {
            if let rating = rating,
               let color = scheduleManager.ratingColors[rating] {
                color.opacity(0.15)
            }
            
            Text("\(dayNumber)")
                .font(.system(size: 15, weight: isToday ? .medium : .light))
                .foregroundColor(isToday ? accentColor : textColor.opacity(0.8))
                .frame(maxWidth: .infinity)
        }
        .frame(height: 44)
        .background(
            GeometryReader { geo in
                if isToday {
                    let size = min(geo.size.width, geo.size.height)
                    Circle()
                        .stroke(accentColor.opacity(0.2), lineWidth: 1)
                        .frame(width: size, height: size)
                        .position(x: geo.size.width/2, y: geo.size.height/2)
                }
            }
        )
        .overlay(
            Group {
                if let rating = rating {
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(scheduleManager.ratingColors[rating] ?? .clear)
                            .frame(height: 2)
                    }
                }
            }
        )
    }
}

struct ScheduleScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    ScheduleView(selectedScheduleDate: .constant(Date()))
}
