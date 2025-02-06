////
////  EmotionSchedulePreview.swift
////  Loop
////
////  Created by Shriram Vasudevan on 1/4/25.
////
//

import SwiftUI

import CoreData

struct EmotionSchedulePreviewView: View {
    @ObservedObject private var scheduleManager = ScheduleManager.shared
        @Binding var pageType: PageType
        @Binding var selectedScheduleDate: Date?
        
        private let horizontalPadding: CGFloat = 24
        private let spacing: CGFloat = 16 // Increased for more breathing room
        
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
            .frame(height: 65) // Slightly taller for more spacious feel
        }
        
        private func daysList(itemWidth: CGFloat) -> some View {
            HStack(spacing: spacing) {
                ForEach(dates, id: \.self) { date in
                    dayView(for: date, width: itemWidth)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedScheduleDate = date
                                pageType = .schedule
                            }
                        }
                }
            }
            .padding(.horizontal, horizontalPadding)
        }
        
        private func dayView(for date: Date, width: CGFloat) -> some View {
            let isCompleted = checkForActivity(on: date)
            let isToday = Calendar.current.isDate(date, inSameDayAs: Date())
            
            return VStack(spacing: 6) {
                // Day of week
                Text(formatDayOfWeek(date))
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "2C3E50").opacity(0.5))
                
                // Date or completion indicator
                ZStack {
                    if isCompleted {
                        Circle()
                            .fill(Color(hex: "A28497").opacity(0.15))
                            .frame(width: 28, height: 28)
                        
                        Circle()
                            .fill(Color(hex: "A28497").opacity(0.3))
                            .frame(width: 6, height: 6)
                    } else {
                        Text(formatDay(date))
                            .font(.system(size: 16, weight: isToday ? .medium : .regular))
                    }
                }
                .frame(height: 28)
            }
            .frame(width: width)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isToday ?
                        Color(hex: "A28497").opacity(0.08) :
                        Color.clear)
                    .padding(.horizontal, -4)
            )
            .contentShape(Rectangle())
        }
        
        private func formatDayOfWeek(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "E" // Just first letter for a cleaner look
            return formatter.string(from: date).prefix(1).uppercased()
        }
        
        private func formatDay(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "d"
            return formatter.string(from: date)
        }
    
    private func checkForActivity(on date: Date) -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return false
        }
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "ActivityForToday")
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let activities = try scheduleManager.context.fetch(fetchRequest)
            return !activities.isEmpty
        } catch {
            print("Error fetching activities: \(error)")
            return false
        }
    }
}

struct EmotionSchedulePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        EmotionSchedulePreviewView(pageType: .constant(.home), selectedScheduleDate: .constant(.now))
            .previewLayout(.sizeThatFits)
            .padding()
            .background(Color(hex: "FAFBFC"))
    }
}
