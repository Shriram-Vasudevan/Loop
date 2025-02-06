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
    
    // Soft, approachable colors
    private let backgroundColor = Color(hex: "F8F9FA")
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    private let softGray = Color(hex: "E9ECEF")
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Modern header with subtle gradient
                HeaderView()
                
                // Calendar grid
                LazyVStack(spacing: 32) {
                    ForEach(scheduleManager.monthsToShow, id: \.self) { month in
                        MonthSection(
                            month: month,
                            selectedDate: $selectedDate,
                            showingDayView: $showingDayView
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(backgroundColor.ignoresSafeArea())
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

struct HeaderView: View {
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        VStack(spacing: 16) {
            // Title with subtle animation
            Text("CALENDAR")
                .font(.custom("PPNeueMontreal-Bold", size: 24))
                .foregroundColor(textColor)
                .tracking(1.2)
                .padding(.top, 24)
        }
    }
}

struct LegendItem: View {
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "2C3E50"))
        }
    }
}

struct MonthSection: View {
    let month: Date
    @Binding var selectedDate: Date?
    @Binding var showingDayView: Bool
    @ObservedObject private var scheduleManager = ScheduleManager.shared
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(month.formatted(.dateTime.month(.wide)))
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(hex: "2C3E50"))
            
            HStack {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "2C3E50").opacity(0.6))
                        .frame(maxWidth: .infinity)
                }
            }
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(daysInMonth(for: month), id: \.self) { date in
                    if let date = date {
                        let calendar = Calendar.current
                        let startOfDay = calendar.startOfDay(for: date)
                        DayCell(
                            date: date,
                            isSelected: selectedDate == date,
                            rating: scheduleManager.ratings[startOfDay]
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                selectedDate = date
                                showingDayView = true
                            }
                        }
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
    }
    
    private func daysInMonth(for date: Date) -> [Date?] {
        let calendar = Calendar.current
        let monthInterval = calendar.dateInterval(of: .month, for: date)!
        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        
        let dateComponents = calendar.dateComponents([.year, .month], from: date)
        let numberOfDays = calendar.range(of: .day, in: .month, for: date)!.count
        
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
    
    var body: some View {
        ZStack {
            Circle()
                .fill(getRatingColor())
                .overlay(
                    Circle()
                        .stroke(Color(hex: "2C3E50").opacity(0.1), lineWidth: isSelected ? 2 : 0)
                )
            
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(rating == nil ? .black.opacity(0.6) : .white)
        }
        .frame(height: 40)
        .animation(.spring(response: 0.3), value: isSelected)
    }
    
    private func getRatingColor() -> Color {
        if let rating = rating,
           let color = scheduleManager.ratingColors[rating] {
            return color
        }
        return Color(hex: "F1F3F5")
    }
}

extension Date: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.timeIntervalSince1970)
    }
}

// Preview
struct ModernCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleView(selectedScheduleDate: .constant(Date()))
            .preferredColorScheme(.light)
    }
}
