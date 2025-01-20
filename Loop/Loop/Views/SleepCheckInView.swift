//
//  SleepCheckInView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/19/25.
//

import SwiftUI

struct MinimalSleepCheckInView: View {
    @Binding var hoursSlept: Double
    let isEditable: Bool
    var onCompletion: (() -> Void)?
    
    private let accentColor = Color(hex: "1E3D59")
    
    @ObservedObject private var checkinManager = SleepCheckinManager.shared
    
    var body: some View {
        VStack(spacing: 48) {
            VStack(spacing: 4) {
                Text("HOW DID YOU SLEEP?")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(accentColor.opacity(0.5))
                
                Text(getSleepDescription(for: hoursSlept))
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(accentColor)
                    .multilineTextAlignment(.center)
                    .animation(.snappy, value: hoursSlept)
                    .frame(height: 32)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(hoursSlept >= 11 ? "11+" : String(Int(hoursSlept)))
                    .font(.system(size: 72, weight: .light))
                    .foregroundColor(accentColor)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: hoursSlept)
                
                Text("hrs")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(accentColor.opacity(0.5))
            }
            
            if isEditable {
                VStack(spacing: 24) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background bar
                            RoundedRectangle(cornerRadius: 2)
                                .fill(accentColor.opacity(0.1))
                                .frame(height: 4)
                            
                            // Progress bar
                            RoundedRectangle(cornerRadius: 2)
                                .fill(accentColor)
                                .frame(width: geometry.size.width * CGFloat((hoursSlept - 2) / 9), height: 4)
                            
                            // Drag handle
                            Circle()
                                .fill(accentColor)
                                .frame(width: 24, height: 24)
                                .offset(x: geometry.size.width * CGFloat((hoursSlept - 2) / 9) - 12)
                                .shadow(color: accentColor.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let ratio = min(max(0, value.location.x / geometry.size.width), 1)
                                    hoursSlept = 2 + (ratio * 9)
                                    checkinManager.saveDailyCheckin(hours: Double(hoursSlept))
                                    onCompletion?()
                                }
                        )
                    }
                    .frame(height: 24)

                    HStack {
                        Text("not enough")
                            .foregroundColor(accentColor.opacity(0.6))
                        Spacer()
                        Text("plenty")
                            .foregroundColor(accentColor.opacity(0.6))
                    }
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.5)
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(32)
    }
    
    private func getSleepDescription(for hours: Double) -> String {
        switch hours {
        case 4..<5:
            return "barely slept"
        case 5..<6:
            return "very tired"
        case 6..<7:
            return "a bit tired"
        case 7..<8:
            return "pretty good"
        case 8..<9:
            return "well rested"
        case 9...12:
            return "very well rested"
        default:
            return "okay"
        }
    }
}

struct PreviewMinimalSleepWrapper: View {
    @State private var hoursSlept: Double = 8.0
    
    var body: some View {
        ZStack {
            Color(hex: "F5F5F5").edgesIgnoringSafeArea(.all)
            
            MinimalSleepCheckInView(
                hoursSlept: $hoursSlept,
                isEditable: true
            )
        }
    }
}

struct MinimalSleepCheckInView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewMinimalSleepWrapper()
    }
}
