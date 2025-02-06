//
//  MoodCheckinView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/12/25.
//

import SwiftUI
import CoreData

struct MoodCheckInView: View {
    @Binding var dayRating: Double
    let isEditable: Bool
    let isOpenedFromPlus: Bool

    var onCompletion: (() -> Void)?

    private let accentColor = Color(hex: "A28497")
    
    private let sadColor = Color(hex: "1E3D59")
    private let neutralColor = Color(hex: "94A7B7")
    private let happyColor = Color(hex: "B784A7")
    
    @ObservedObject private var checkinManager: DailyCheckinManager
    @State private var isAnimating = false
    
    @Environment(\.dismiss) var dismiss
    
    init(dayRating: Binding<Double>, isEditable: Bool, isOpenedFromPlus: Bool, onCompletion: (() -> Void)? = nil) {
        self._dayRating = dayRating
        self.isOpenedFromPlus = isOpenedFromPlus
        self.isEditable = isEditable
        self.onCompletion = onCompletion
        self.checkinManager = DailyCheckinManager.shared
    }
    
    init(dayRating: Binding<Double>, isEditable: Bool, isOpenedFromPlus: Bool, previewManager: DailyCheckinManager) {
        self._dayRating = dayRating
        self.isOpenedFromPlus = isOpenedFromPlus
        self.isEditable = isEditable
        self.onCompletion = nil
        self.checkinManager = previewManager
    }
    
    var body: some View {
        VStack(spacing: 48) {
            if isOpenedFromPlus {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(accentColor.opacity(0.8))
                    }
                    
                    
                    Spacer()
                }
                .padding(.bottom, 30)
            }
            VStack(spacing: 8) {
                Text("HOW ARE YOU FEELING TODAY?")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(Color(hex: "2C3E50").opacity(0.5))
                
                Text(getMoodDescription(for: dayRating))
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(Color(hex: "2C3E50"))
                    .multilineTextAlignment(.center)
            }
            
            ZStack {
                Circle()
                    .fill(getColor(for: dayRating))
                    .frame(width: 140, height: 140)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                    )
                    .shadow(color: getColor(for: dayRating).opacity(0.2), radius: 15, x: 0, y: 8)
                    .scaleEffect(isAnimating ? 1.05 : 1.0)
            }
            .padding(.vertical, 20)
            
            if isEditable {
                VStack(spacing: 16) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Gradient bar
                            LinearGradient(
                                gradient: Gradient(colors: [sadColor, neutralColor, happyColor]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(height: 16)
                            .cornerRadius(8)
                            .contentShape(Rectangle())
                            .onTapGesture { location in
                                let ratio = max(0, min(1, location.x / geometry.size.width))
                                dayRating = 1 + (9 * ratio)
                                if !isOpenedFromPlus {
                                    checkinManager.saveDailyCheckin(rating: dayRating, isThroughDailySession: true)
                                }
                                onCompletion?()
                            }
                            
                            Circle()
                                .fill(Color.white)
                                .frame(width: 36, height: 36)
                                .offset(x: -18 + geometry.size.width * (dayRating / 10))
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            let ratio = max(0, min(1, (value.location.x + 18) / geometry.size.width))
                                            dayRating = 10 * ratio
                                            if !isOpenedFromPlus {
                                                checkinManager.saveDailyCheckin(rating: dayRating, isThroughDailySession: true)
                                            }
                                            
                                            onCompletion?()
                                        }
                                )
                        }
                    }
                    .frame(height: 36)

                    
                    HStack {
                        Text("feeling down")
                            .foregroundColor(sadColor.opacity(0.8))
                        Spacer()
                        Text("feeling great")
                            .foregroundColor(happyColor.opacity(0.8))
                    }
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.5)
                }
                .padding(.horizontal, 20)
            }

            if isOpenedFromPlus {
                Button(action: {
                    withAnimation (.smooth(duration: 0.4)) {
                        checkinManager.saveDailyCheckin(rating: dayRating, isThroughDailySession: false)
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
                
                
                Spacer()
            }
        }
        .padding(32)
        .onAppear {
            isAnimating = true
            if !isOpenedFromPlus {
                if let savedRating = checkinManager.checkIfDailyCheckinCompleted() {
                    dayRating = savedRating
                } else {
                    dayRating = 5.0
                }
            } else {
                dayRating = 5.0
            }
        }
    }
    
    private func getColor(for rating: Double) -> Color {
        if rating <= 5 {
            let t = (rating - 1) / 4
            return interpolateColor(from: sadColor, to: neutralColor, with: t)
        } else {
            let t = (rating - 5) / 5
            return interpolateColor(from: neutralColor, to: happyColor, with: t)
        }
    }
    
    private func interpolateColor(from: Color, to: Color, with percentage: Double) -> Color {
        let fromUIColor = UIColor(from)
        let toUIColor = UIColor(to)
        
        var fromR: CGFloat = 0
        var fromG: CGFloat = 0
        var fromB: CGFloat = 0
        var fromA: CGFloat = 0
        fromUIColor.getRed(&fromR, green: &fromG, blue: &fromB, alpha: &fromA)
        
        var toR: CGFloat = 0
        var toG: CGFloat = 0
        var toB: CGFloat = 0
        var toA: CGFloat = 0
        toUIColor.getRed(&toR, green: &toG, blue: &toB, alpha: &toA)
        
        let r = fromR + (toR - fromR) * CGFloat(percentage)
        let g = fromG + (toG - fromG) * CGFloat(percentage)
        let b = fromB + (toB - fromB) * CGFloat(percentage)
        let a = fromA + (toA - fromA) * CGFloat(percentage)
        
        return Color(UIColor(red: r, green: g, blue: b, alpha: a))
    }
    
    private func getMoodDescription(for rating: Double) -> String {
        switch rating {
        case 0...3:
            return "feeling down"
        case 3...4:
            return "not great"
        case 4...6:
            return "okay"
        case 6...8:
            return "pretty good"
        case 8...10:
            return "feeling great"
        default:
            return "okay"
        }
    }
}

// Mock manager for previews
class PreviewDailyCheckinManager: DailyCheckinManager {
    override init() {
        // Initialize with an empty persistent container
        super.init()
    }
    
    override func checkIfDailyCheckinCompleted() -> Double? {
        return 5.0 // Always return middle value for preview
    }
    
    override func saveDailyCheckin(rating: Double, isThroughDailySession status: Bool) {
        print("Preview: Would save rating \(rating)")
    }
}

// Preview wrapper to handle state
struct PreviewWrapper: View {
    @State private var rating: Double = 5.0
    
    var body: some View {
        ZStack {
            Color(hex: "F5F5F5").edgesIgnoringSafeArea(.all)
            
            MoodCheckInView(
                dayRating: $rating,
                isEditable: true,
                isOpenedFromPlus: false, previewManager: PreviewDailyCheckinManager()
            )
        }
    }
}

struct MoodCheckInView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewWrapper()
    }
}
