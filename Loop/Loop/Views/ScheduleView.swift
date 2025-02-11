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
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    private let backgroundColor = Color(hex: "FAFBFC")
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 48) {
                // Minimal Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Schedule")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundColor(textColor)
                        .padding(.top, 16)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                
                // Free-flowing Calendar
                LazyVStack(spacing: 64) {
                    ForEach(scheduleManager.monthsToShow, id: \.self) { month in
                        FlowingMonthView(
                            month: month,
                            selectedDate: $selectedDate,
                            showingDayView: $showingDayView
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .background(backgroundColor)
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

struct FlowingMonthView: View {
    let month: Date
    @Binding var selectedDate: Date?
    @Binding var showingDayView: Bool
    @ObservedObject private var scheduleManager = ScheduleManager.shared
    
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 7)
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            // Minimal month header
            Text(month.formatted(.dateTime.month(.wide)))
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(textColor.opacity(0.8))
            
            VStack(spacing: 24) {
                // Minimal weekday headers
                HStack {
                    ForEach(weekdays, id: \.self) { day in
                        Text(day)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(textColor.opacity(0.3))
                            .frame(maxWidth: .infinity)
                    }
                }
                
                // Open calendar grid
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(daysInMonth(), id: \.self) { date in
                        if let date = date {
                            MinimalDayCell(
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

struct MinimalDayCell: View {
    let date: Date
    let isSelected: Bool
    let rating: Double?
    
    @ObservedObject private var scheduleManager = ScheduleManager.shared
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        let isToday = Calendar.current.isDateInToday(date)
        let dayNumber = Calendar.current.component(.day, from: date)
        
        ZStack {
            if let rating = rating,
               let color = scheduleManager.ratingColors[rating] {
                // Emotion color background
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            } else if isToday {
                // Today's cell
                RoundedRectangle(cornerRadius: 6)
                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
            }
            
            Text("\(dayNumber)")
                .font(.system(size: 16, weight: isToday ? .medium : .regular))
                .foregroundColor(isToday ? accentColor : textColor.opacity(0.8))
        }
        .frame(height: 44)
        .background(Color.clear)
    }
}

#Preview {
    ScheduleView(selectedScheduleDate: .constant(Date()))
}
