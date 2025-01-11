////
////  DayRatingSlider.swift
////  Loop
////
//  Created by Shriram Vasudevan on 12/26/24.
////
//
//import SwiftUI
//
//struct DayRatingSlider: View {
//    @ObservedObject private var checkinManager = DailyCheckinManager.shared
//    @State private var value: Double = 0.5
//    @State private var isDragging = false
//    @State private var isCompleted = false
//    
//    let accentColor = Color(hex: "A28497")
//    let textColor = Color(hex: "2C3E50")
//    let surfaceColor = Color(hex: "F8F9FA")
//    
//    var body: some View {
//        VStack(spacing: 40) {
//            VStack(spacing: 24) {
//                HStack(spacing: 12) {
//                    Image(systemName: "sparkles")
//                        .font(.system(size: 12))
//                        .foregroundColor(accentColor.opacity(0.3))
//                    
//                    Text("HOW WOULD YOU RATE TODAY?")
//                        .font(.system(size: 11, weight: .medium))
//                        .tracking(1.5)
//                        .foregroundColor(textColor.opacity(0.5))
//                }
//
//                HStack(alignment: .bottom, spacing: 4) {
//                    Text(String(format: "%.1f", value * 10))
//                        .font(.system(size: 54, weight: .medium))
//                        .foregroundColor(textColor)
//                        .contentTransition(.numericText())
//                    
//                    if !isDragging {
//                        Text("/10")
//                            .font(.system(size: 24, weight: .light))
//                            .foregroundColor(textColor.opacity(0.3))
//                            .offset(y: -12)
//                    }
//                }
//                .frame(height: 80)
//                
//                // Refined slider
//                GeometryReader { geometry in
//                    ZStack(alignment: .leading) {
//                        Capsule()
//                            .fill(surfaceColor)
//                            .overlay(
//                                Capsule()
//                                    .stroke(accentColor.opacity(0.1), lineWidth: 1)
//                            )
//                        
//                        Capsule()
//                            .fill(
//                                LinearGradient(
//                                    gradient: Gradient(colors: [
//                                        accentColor.opacity(0.15),
//                                        accentColor.opacity(0.1)
//                                    ]),
//                                    startPoint: .leading,
//                                    endPoint: .trailing
//                                )
//                            )
//                            .frame(width: geometry.size.width * CGFloat(value))
//                        
//                        Circle()
//                            .fill(Color.white)
//                            .frame(width: 28, height: 28)
//                            .shadow(color: accentColor.opacity(0.1), radius: 8, x: 0, y: 2)
//                            .overlay(
//                                Circle()
//                                    .stroke(accentColor.opacity(0.15), lineWidth: 1)
//                            )
//                            .overlay(
//                                Circle()
//                                    .fill(accentColor.opacity(0.1))
//                                    .frame(width: 8, height: 8)
//                            )
//                            .offset(x: (geometry.size.width - 28) * CGFloat(value))
//                            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.1), value: value)
//                    }
//                    .frame(height: 44)
//                    .contentShape(Rectangle())
//                    .gesture(
//                        DragGesture(minimumDistance: 0)
//                            .onChanged { gesture in
//                                isDragging = true
//                                let newValue = gesture.location.x / geometry.size.width
//                                self.value = min(max(0, newValue), 1)
//                            }
//                            .onEnded { _ in
//                                isDragging = false
//                                checkinManager.saveDailyCheckin(rating: value * 10)
//                            }
//                    )
//                }
//                .frame(height: 44)
//            }
//            .padding(.horizontal, 32)
//            .padding(.vertical, 32)
//        }
//        .background(
//            RoundedRectangle(cornerRadius: 16)
//                .fill(Color.white)
//                .shadow(color: Color.black.opacity(0.03), radius: 20, x: 0, y: 4)
//        )
//        .onAppear {
//            print("🎚️ DayRatingSlider appeared")
//            if let existing = checkinManager.todaysCheckIn {
//                print("Found existing rating: \(existing.rating)")
//                value = existing.rating / 10  // Convert back to 0-1 range
//                print("Updated slider value to: \(value)")
//            } else {
//                print("No existing rating found, using default")
//            }
//        }
//    }
//}
//
//#Preview {
//    DayRatingSlider()
//}
