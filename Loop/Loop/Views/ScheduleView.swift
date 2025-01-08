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
    @State private var selectedDate: Date?
    @State private var showingDayView = false
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    private var monthsToShow: [(month: Int, year: Int)] {
        let calendar = Calendar.current
        let current = Date()
        var months: [(Int, Int)] = []
        
        for monthOffset in 0...11 {
            if let date = calendar.date(byAdding: .month, value: -monthOffset, to: current) {
                let month = calendar.component(.month, from: date)
                let year = calendar.component(.year, from: date)
                months.append((month, year))
            }
        }
        
        return months
    }
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                HStack(spacing: 12) {
                    Text("CALENDAR")
                        .font(.system(size: 14, weight: .semibold))
                        .tracking(2)
                        .foregroundColor(textColor.opacity(0.5))
                    
                    Spacer()
                    
                    Button(action: { }) {
                        HStack(spacing: 4) {
                            Circle()
                                .stroke(textColor.opacity(0.2), lineWidth: 1)
                                .frame(width: 8, height: 8)
                            
                            Text("TAP TO VIEW")
                                .font(.system(size: 11, weight: .medium))
                                .tracking(1.5)
                                .foregroundColor(textColor.opacity(0.5))
                        }
                    }
                }
                .padding(.top, 30)
                
                VStack(spacing: 24) {
                    ForEach(monthsToShow, id: \.0) { month, year in
                        MonthRow(
                            month: month,
                            year: year,
                            accentColor: accentColor,
                            textColor: textColor,
                            selectedDate: $selectedDate,
                            showingDayView: $showingDayView
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .navigationDestination(item: $selectedDate, destination: { date in
            FullDayActivityView(date: date)
        })
    }
}

struct MonthRow: View {
    let month: Int
    let year: Int
    let accentColor: Color
    let textColor: Color
    @Binding var selectedDate: Date?
    @Binding var showingDayView: Bool
    
    private let calendar = Calendar.current
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]
    
    @ObservedObject private var scheduleManager = ScheduleManager.shared
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Calendar grid
            VStack(spacing: 8) {
                // Weekday headers
                HStack {
                    ForEach(weekdays, id: \.self) { day in
                        Text(day)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(textColor.opacity(0.4))
                            .frame(maxWidth: .infinity)
                    }
                }
                
                ForEach(weeks, id: \.self) { week in
                    HStack(spacing: 0) {
                        ForEach(week, id: \.self) { day in
                            if day > 0 {
                                Circle()
                                    .stroke(Color(hex: "2C3E50").opacity(0.1), lineWidth: 1)
                                    .background(
                                        Circle()
                                            .fill(getEmotionColor(for: day) ?? .clear)
                                    )
                                    .frame(width: 28, height: 28)
                                    .onTapGesture {
                                        if let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) {
                                            selectedDate = date
                                            showingDayView = true
                                        }
                                    }
                            } else {
                                Color.clear
                                    .frame(width: 28, height: 28)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            
            Text(monthName.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .tracking(2)
                .foregroundColor(textColor.opacity(0.5))
                .frame(width: 10, alignment: .leading)
        }
    }
    
    private var monthName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM"
        return dateFormatter.shortMonthSymbols[month - 1]
    }
    
    private var weeks: [[Int]] {
        let firstDay = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstDay)!.count
        
        var days: [[Int]] = []
        var week = Array(repeating: 0, count: firstWeekday - 1)
        
        for day in 1...daysInMonth {
            week.append(day)
            if week.count == 7 {
                days.append(week)
                week = []
            }
        }
        
        if !week.isEmpty {
            week.append(contentsOf: Array(repeating: 0, count: 7 - week.count))
            days.append(week)
        }
        
        return days
    }
    
    private func getEmotionColor(for day: Int) -> Color? {
        guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
            return nil
        }
        
        let startOfDay = calendar.startOfDay(for: date)

        if let emotion = scheduleManager.emotions[startOfDay] {
            return scheduleManager.emotionColors[emotion]
        }
 
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            print("Error: Could not calculate end of day")
            return nil
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "ActivityForToday")
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let activities = try scheduleManager.context.fetch(fetchRequest)
            if !activities.isEmpty {
                return Color.gray.opacity(0.5)
            }
        } catch {
            print("Error fetching activities: \(error)")
        }
        
        return nil
    }
}
struct ScheduleView_Previews: View {
    var body: some View {
        let previewData = PreviewData()
        ScheduleView()
    }
}

// Separate preview data struct
struct PreviewData {
    let emotions: [Date: String]
    let emotionColors: [String: Color]
    
    init() {
        self.emotionColors = [
            "Joy": Color(hex: "A28497"),     // Original accent (mauve)
            "Peace": Color(hex: "B5C4C9"),   // Light blue-grey
            "Gratitude": Color(hex: "C2CCBB"),// Light sage
            "Energy": Color(hex: "C4B5B5"),  // Light dusty rose
            "Focus": Color(hex: "BFB5C9")    // Light purple
        ]
        
        // Generate sample emotion data
        var sampleEmotions: [Date: String] = [:]
        let calendar = Calendar.current
        let today = Date()
        let emotions = Array(emotionColors.keys)
        
        // Fill in some random days in the past year
        for dayOffset in 0...365 {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                // Fill roughly 40% of days
                if Int.random(in: 1...10) <= 4 {
                    sampleEmotions[calendar.startOfDay(for: date)] = emotions.randomElement()!
                }
            }
        }
        
        self.emotions = sampleEmotions
    }
}

#Preview {
    ScheduleView_Previews()
}
