//
//  AudioBulletJournal.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/9/24.
//

import SwiftUI

struct YearMoodView: View {
    @ObservedObject var loopManager: LoopManager
    private let months = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]
    private let daysInMonth = 31
    private let cellSize: CGFloat = 20
    private let spacing: CGFloat = 2
    
    let textColor = Color(hex: "2C3E50")
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 24) {
                ZStack {
                    HStack {
                        VStack(alignment: .center, spacing: 8) {
                            Text("year in squares")
                                .font(.system(size: 40, weight: .ultraLight))
                                .foregroundColor(Color(hex: "2C3E50"))
                            
                            Text("2024")
                                .font(.system(size: 16, weight: .light))
                                .foregroundColor(Color(hex: "A28497"))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(textColor)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: spacing) {
                        VStack(spacing: spacing) {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(width: 24, height: cellSize)
                            
                            ForEach(1...daysInMonth, id: \.self) { day in
                                Text("\(day)")
                                    .font(.system(size: 10, weight: .light))
                                    .foregroundColor(Color(hex: "2C3E50").opacity(0.6))
                                    .frame(width: 24, height: cellSize)
                            }
                        }
                        
                        ForEach(months.indices, id: \.self) { index in
                            VStack(spacing: spacing) {
                                Text(months[index])
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(hex: "2C3E50"))
                                    .frame(width: cellSize, height: cellSize)
                                
                                ForEach(1...daysInMonth, id: \.self) { day in
                                    let date = getDate(forDay: day, month: index + 1)
                                    MoodCell(
                                        mood: loopManager.moodData[date],
                                        size: cellSize
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
    
                VStack(alignment: .leading, spacing: 16) {
                    Text("moods")
                        .font(.system(size: 16, weight: .ultraLight))
                        .foregroundColor(Color(hex: "2C3E50"))
                    
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 150))
                    ], spacing: 12) {
                        ForEach(Array(loopManager.moodColors.keys.sorted()), id: \.self) { mood in
                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(loopManager.moodColors[mood] ?? .gray)
                                    .frame(width: 16, height: 16)
                                
                                Text(mood)
                                    .font(.system(size: 14, weight: .light))
                                    .foregroundColor(Color(hex: "2C3E50"))
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.04), radius: 10)
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }
            .padding(.bottom, 32)
        }
        .background(Color(hex: "FAFBFC"))
        .navigationBarBackButtonHidden()
    }
    
    private func getDate(forDay day: Int, month: Int) -> Date {
        var components = DateComponents()
        components.year = 2024
        components.month = month
        components.day = day
        return Calendar.current.date(from: components) ?? Date()
    }
}

struct MoodCell: View {
    let mood: String?
    var size: CGFloat = 20
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        if let mood = mood {
            Rectangle()
                .fill(LoopManager.shared.moodColors[mood] ?? .gray)
                .frame(width: size, height: size)
        } else {
            Rectangle()
                .stroke(Color(hex: "2C3E50").opacity(0.1), lineWidth: 1)
                .frame(width: size, height: size)
                .background(
                    Rectangle()
                        .fill(colorScheme == .dark ? Color.black.opacity(0.1) : Color.white)
                )
        }
    }
}

struct MoodPreviewWidget: View {
    @ObservedObject var loopManager: LoopManager
    private let previewDays = 7
    private let cellSize: CGFloat = 32
    
    @State var navigateToFullYearInSqaures: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("mood tracker")
                    .font(.system(size: 24, weight: .ultraLight))
                    .foregroundColor(Color(hex: "2C3E50"))
                
                Spacer()
                
                Button {
                    navigateToFullYearInSqaures = true
                } label: {
                    Text("view all")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(Color(hex: "A28497"))
                }
            }
            
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 4) {
                    ForEach(0..<previewDays, id: \.self) { dayOffset in
                        let date = Calendar.current.date(
                            byAdding: .day,
                            value: -dayOffset,
                            to: Date()
                        ) ?? Date()
                        
                        VStack(spacing: 4) {
                            MoodCell(
                                mood: loopManager.moodData[date],
                                size: cellSize
                            )
                            
                            Text(formatDay(date))
                                .font(.system(size: 10, weight: .light))
                                .foregroundColor(Color(hex: "2C3E50").opacity(0.6))
                        }
                    }
                }
                
                HStack(spacing: 12) {
                    ForEach(Array(loopManager.moodColors.keys.prefix(3)), id: \.self) { mood in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(loopManager.moodColors[mood] ?? .gray)
                                .frame(width: 8, height: 8)
                            
                            Text(mood)
                                .font(.system(size: 12, weight: .light))
                                .foregroundColor(Color(hex: "2C3E50").opacity(0.8))
                        }
                    }
                    
                    if loopManager.moodColors.count > 3 {
                        Text("+\(loopManager.moodColors.count - 3) more")
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(Color(hex: "2C3E50").opacity(0.6))
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 15)
        )
        .navigationDestination(isPresented: $navigateToFullYearInSqaures) {
            YearMoodView(loopManager: loopManager)
        }
    }
    
    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter.string(from: date)
    }
}

private func getDate(forDay day: Int, month: Int) -> Date {
    var components = DateComponents()
    components.year = 2024
    components.month = month
    components.day = day
    return Calendar.current.date(from: components) ?? Date()
}
