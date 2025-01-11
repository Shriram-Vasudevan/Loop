//
//  FullDayActivityView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/6/25.
//

import SwiftUI

struct FullDayActivityView: View {
    @State var date: Date
    @State private var activity: DayActivity?
    @State private var selectedLoop: Loop?
    @Environment(\.dismiss) var dismiss
    
    private let accentColor = Color(hex: "A28497")
    private let backgroundColor = Color(hex: "FAFBFC")
    private let textColor = Color(hex: "2C3E50")
    
    var body: some View {
        ScrollView {
            VStack {
                VStack(spacing: 10) {
                    ZStack {
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(textColor)
                            }
                            Spacer()
                        }
                        
                        Text(formatDate())
                            .font(.custom("PPNeueMontreal-Bold", size: 35))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
                
                if let activity = activity {
                    if activity.dailyLoops.isEmpty && activity.thematicLoops.isEmpty &&
                        activity.followUpLoops.isEmpty && activity.colorHex == nil {
                        emptyStateView
                            .padding(.horizontal, 24)
                    } else {
                        VStack(spacing: 32) {
                            if let colorHex = activity.colorHex {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(hex: colorHex))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 32)
                            }
                            
                            if !activity.dailyLoops.isEmpty {
                                sectionView(title: "Daily Loops", loops: activity.dailyLoops)
                            }
                            
                            if !activity.thematicLoops.isEmpty {
                                sectionView(title: "Thematic Loops", loops: activity.thematicLoops)
                            }
                            
                            if !activity.followUpLoops.isEmpty {
                                sectionView(title: "Follow-up Loops", loops: activity.followUpLoops)
                            }
                        }
                        .padding(.top, 16)
                        .padding(.horizontal, 24)
                    }
                } else {
                    ProgressView()
                        .padding(.top, 40)
                }
            }
        }
        .fullScreenCover(item: $selectedLoop) { loop in
            ViewPastLoopView(loop: loop, isThroughRecordLoopsView: false)
        }
        .task {
            do {
                let cloudLoops = try await ActivityCloudKitUtility.fetchLoopsForDate(date)
                let localLoops = try await ActivityLocalStorageUtility.shared.fetchLoopsForDate(date)
                let allLoops = Array(Set(cloudLoops + localLoops))
                let colorHex = ScheduleManager.shared.dailyColors.first(where: { DailyColorHex in
                    Calendar.current.isDate(date, inSameDayAs: DailyColorHex.date)
                })
                
                activity = DayActivity.categorize(allLoops, colorHex: colorHex?.colorHex)
            } catch {
                print("Error fetching loosps: \(error)")
            }
        }
        .navigationBarBackButtonHidden()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            WavePattern()
                .fill(accentColor.opacity(0.7))
                .frame(height: 60)
            
            VStack(spacing: 8) {
                Text("NO ENTRIES FOUND FOR THIS DAY")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.6))
                
                Text("Make sure to keep your reflections consisent!")
                    .font(.system(size: 17))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                
//                Image(systemName: icon)
//                    .font(.system(size: 48))
//                    .foregroundColor(accentColor)
//                    .rotationEffect(.degrees(isLoading ? rotation : 0))
//                    .onAppear {
//                        if isLoading {
//                            withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
//                                rotation = 360
//                            }
//                        }
//                    }
//
            }
        }
        .frame(height: 150)
    }
    private func formatDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d"
        return dateFormatter.string(from: date).lowercased()
    }
    
    private func sectionView(title: String, loops: [Loop]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .tracking(2)
                .foregroundColor(textColor.opacity(0.5))
            
            VStack(spacing: 16) {
                ForEach(loops) { loop in
                    LoopCard(loop: loop) {
                        selectedLoop = loop
                    }
                }
            }
        }
    }
}

#Preview {
    FullDayActivityView(date: Date())
}
