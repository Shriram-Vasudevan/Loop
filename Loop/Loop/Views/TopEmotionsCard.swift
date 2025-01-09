//
//  TopEmotionsCard.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/8/25.
//

import SwiftUI

struct TopEmotionsCard: View {
   let emotions: [FrequencyResult]
   let accentColor: Color
   let textColor: Color
   @ObservedObject private var scheduleManager = ScheduleManager.shared
   
   // Maximum height for tallest bar
   private let maxBarHeight: CGFloat = 120
   
   var body: some View {
       VStack(alignment: .leading, spacing: 24) {
           HStack {
               Spacer()

               Text("Top Emotions")
                   .font(.system(size: 13, weight: .regular))
                   .foregroundColor(textColor.opacity(0.6))
           }
           
           if emotions.isEmpty {
               // No data view
               VStack(spacing: 20) {
                   VStack(spacing: 8) {
                       Text("REFLECTIONS REQUIRED")
                           .font(.system(size: 13, weight: .medium))
                           .tracking(1.5)
                           .foregroundColor(textColor.opacity(0.6))
       
                       Text("Complete reflections to see your emotional patterns")
                           .font(.system(size: 17))
                           .foregroundColor(textColor)
                           .multilineTextAlignment(.center)
                   }
               }
               .frame(maxWidth: .infinity)
               .padding(.vertical, 20)
           } else {
               // Bar chart
               ScrollView(.horizontal) {
                   HStack(alignment: .bottom, spacing: 24) {
                       ForEach(emotions.prefix(4), id: \.value) { emotion in
                           VStack(spacing: 8) {
                               RoundedRectangle(cornerRadius: 8)
                                   .fill(scheduleManager.emotionColors[emotion.value] ?? accentColor)
                                   .frame(height: maxBarHeight * (emotion.percentage))
                                   .frame(width: 32)
                               
                               Text(emotion.value.lowercased())
                                   .font(.system(size: 12, weight: .medium))
                                   .foregroundColor(textColor)
                           }
                           .frame(maxWidth: emotions.count == 1 ? .infinity : nil, alignment: .leading)
                       }
                       if emotions.count == 1 {
                           Spacer()
                       }
                   }
                   .frame(maxWidth: .infinity, alignment: emotions.count == 1 ? .leading : .center)
                   .padding(.horizontal, emotions.count == 1 ? 0 : 24)
               }
               }
       }
       .padding(24)
       .background(Color.white)
       .clipShape(RoundedRectangle(cornerRadius: 10))
       .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 4)
   }
}

// Preview
#Preview {
   VStack(spacing: 20) {
       // Empty state
       TopEmotionsCard(
           emotions: [],
           accentColor: Color(hex: "A28497"),
           textColor: Color(hex: "2C3E50")
       )
       
       // Single emotion
       TopEmotionsCard(
           emotions: [
               FrequencyResult(value: "Peaceful", count: 5, percentage: 100)
           ],
           accentColor: Color(hex: "A28497"),
           textColor: Color(hex: "2C3E50")
       )
       
       // Multiple emotions
       TopEmotionsCard(
           emotions: [
               FrequencyResult(value: "Peaceful", count: 5, percentage: 40),
               FrequencyResult(value: "Grateful", count: 3, percentage: 30),
               FrequencyResult(value: "Focused", count: 2, percentage: 20),
               FrequencyResult(value: "Energetic", count: 1, percentage: 10)
           ],
           accentColor: Color(hex: "A28497"),
           textColor: Color(hex: "2C3E50")
       )
   }
   .padding()
   .background(Color(hex: "F5F5F5"))
}
