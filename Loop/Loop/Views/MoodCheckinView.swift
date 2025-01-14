//
//  MoodCheckinView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/12/25.
//

import SwiftUI

struct MoodCheckinView: View { 
    let accentColor = Color(hex: "A28497")
    let secondaryColor = Color(hex: "B7A284")
    let textColor = Color(hex: "2C3E50")
    
        
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject private var checkinManager = DailyCheckinManager.shared
    @State private var dayRating: Double = 0.5
    @State private var showingDayRating: Bool = true
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.black)
                    }

                    Spacer()
                }
                .padding()
                Spacer()
            }
            
            VStack (spacing: 16) {
                VStack(spacing: 24) {
                    VStack (spacing: 10) {
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12))
                                .foregroundColor(accentColor.opacity(0.3))
                            
                            Text("HOW ARE YOU FEELING TODAY?")
                                .font(.system(size: 13, weight: .medium))
                                .tracking(1.5)
                                .foregroundColor(textColor.opacity(0.5))
                        }
                    }
                
                    VStack(spacing: 40) {
                        VStack(spacing: 24) {

                            HStack(alignment: .bottom, spacing: 4) {
                                Text(String(format: "%.1f", dayRating * 10))
                                    .font(.system(size: 54, weight: .medium))
                                    .foregroundColor(textColor)
                                    .contentTransition(.numericText())
                                
                                Text("/10")
                                    .font(.system(size: 24, weight: .light))
                                    .foregroundColor(textColor.opacity(0.3))
                                    .offset(y: -12)
                            }
                        }
                        
                        // Slider
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color(hex: "F8F9FA"))
                                    .overlay(
                                        Capsule()
                                            .stroke(accentColor.opacity(0.1), lineWidth: 1)
                                    )
                                
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                accentColor.opacity(0.15),
                                                accentColor.opacity(0.1)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * CGFloat(dayRating))
                                
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 28, height: 28)
                                    .shadow(color: accentColor.opacity(0.1), radius: 8, x: 0, y: 2)
                                    .overlay(
                                        Circle()
                                            .stroke(accentColor.opacity(0.15), lineWidth: 1)
                                    )
                                    .overlay(
                                        Circle()
                                            .fill(accentColor.opacity(0.1))
                                            .frame(width: 8, height: 8)
                                    )
                                    .offset(x: (geometry.size.width - 28) * CGFloat(dayRating))
                            }
                            .frame(height: 44)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { gesture in
                                        let newValue = gesture.location.x / geometry.size.width
                                        dayRating = min(max(0, newValue), 1)
                                    }
                            )
                        }
                        .frame(height: 44)
                    }
                    
                    VStack(spacing: 16) {
                        Button(action: {
                            checkinManager.saveDailyCheckin(rating: dayRating * 10)
                            withAnimation {
                                 dismiss()
                            }
                        }) {
                            Text("complete")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundColor(.white)
                                .frame(height: 56)
                                .frame(maxWidth: .infinity)
                                .background(accentColor)
                                .cornerRadius(28)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(32)
            }
        }
        .onAppear {
            if let rating = checkinManager.checkIfCheckinCompleted() {
                self.dayRating = rating
            }
        }
    }
}

#Preview {
    MoodCheckinView()
}
