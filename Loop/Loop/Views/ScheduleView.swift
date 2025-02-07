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
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 40) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Calendar")
                        .font(.system(size: 34, weight: .medium))
                        .padding(.top, 16)
                    
                    Text(formatMonthYear(currentMonth).uppercased())
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.black.opacity(0.5))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                

                LazyVStack(spacing: 60) {
                    ForEach(scheduleManager.monthsToShow, id: \.self) { month in
                        MonthView(
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
        .background(Color(.systemBackground))
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
    
    private func formatMonthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}

struct MonthView: View {
    let month: Date
    @Binding var selectedDate: Date?
    @Binding var showingDayView: Bool
    @ObservedObject private var scheduleManager = ScheduleManager.shared
    
    private let weekdays = Calendar.current.veryShortWeekdaySymbols
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(month.formatted(.dateTime.month(.wide)))
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                HStack {
                    ForEach(weekdays, id: \.self) { day in
                        Text(day)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                

                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(daysInMonth(), id: \.self) { date in
                        if let date = date {
                            DayCell(
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

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let rating: Double?
    
    @ObservedObject private var scheduleManager = ScheduleManager.shared
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        let isToday = Calendar.current.isDateInToday(date)
        
        ZStack {
            if let rating = rating,
               let color = scheduleManager.ratingColors[rating] {
                color
                    .opacity(0.9)
            }
            
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 16, weight: isToday ? .medium : .regular))
                .foregroundColor(rating != nil ? .white : (isToday ? accentColor : .primary))
                .frame(maxWidth: .infinity)
        }
        .frame(height: 50)
//        .overlay(
//            Rectangle()
//                .stroke(isToday ? accentColor : Color.clear, lineWidth: isToday ? 5 : 0)
//                .cornerRadius(10)
//        )
    }
}

#Preview {
    ScheduleView(selectedScheduleDate: .constant(Date()))
}
