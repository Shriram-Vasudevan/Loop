////
////  EmotionSchedulePreview.swift
////  Loop
////
////  Created by Shriram Vasudevan on 1/4/25.
////
//

import SwiftUI

struct EmotionSchedulePreviewView: View {
    @ObservedObject private var scheduleManager = ScheduleManager.shared
    private let horizontalPadding: CGFloat = 24
    private let spacing: CGFloat = 12
    
    var dates: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0...6).reversed().compactMap { dayOffset in
            calendar.date(byAdding: .day, value: -dayOffset, to: today)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - (horizontalPadding * 2)
            let itemWidth = (availableWidth - (spacing * 6)) / 7
            
            daysList(itemWidth: itemWidth)
        }
        .frame(height: 50)
        .onAppear {
            Task {
                await scheduleManager.loadWeekDataAndAssignColors()
            }
        }
    }
    
    private func daysList(itemWidth: CGFloat) -> some View {
        HStack(spacing: spacing) {
            ForEach(dates, id: \.self) { date in
                dayView(for: date, width: itemWidth)
            }
        }
        .padding(.horizontal, horizontalPadding)
    }
    
    private func dayView(for date: Date, width: CGFloat) -> some View {
        let isCompleted = scheduleManager.weekEmotions[date] != nil
        let isToday = Calendar.current.isDate(date, inSameDayAs: Date())
        return VStack(spacing: 4) {
            Text(formatDayOfWeek(date))
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "2C3E50").opacity(0.6))
            
            Text(formatDay(date))
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "2C3E50"))
        }
        .frame(width: width)
        .padding(.vertical, 8)
        .background(isToday ? Color(hex: "A28497").opacity(0.08) : Color.clear)
        .opacity(isCompleted ? 0.7 : 1)
    }
    
    private func formatDayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

struct EmotionSchedulePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        EmotionSchedulePreviewView()
            .previewLayout(.sizeThatFits)
            .padding()
            .background(Color(hex: "FAFBFC"))
    }
}
