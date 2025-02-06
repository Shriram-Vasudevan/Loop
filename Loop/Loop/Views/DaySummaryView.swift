//
//  DaySummaryView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 2/4/25.
//

import SwiftUI

struct DaySummaryView: View {
    let accentColor = Color(hex: "A28497")
    let textColor = Color(hex: "2C3E50")

    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color(hex: "F8F9FA")
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                Image(systemName: "quote.opening")
                    .font(.system(size: 200))
                    .foregroundColor(Color(hex: "E9ECEF"))
                    .offset(x: 0, y: -150)
                    .opacity(0.6)
            }
            
            VStack(spacing: 0) {
                ZStack {
                    HStack {
                        Text("SUMMARY")
                            .font(.system(size: 14, weight: .semibold))
                            .tracking(2)
                            .foregroundColor(textColor.opacity(0.5))
                    }
                    
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(textColor)
                        }
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {

                        Text("daily summary for \(formatDate())")
                            .font(.system(size: 31, weight: .bold))
                            .foregroundColor(textColor)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 15)
                            .padding(.horizontal, 24)

                        Text("\(AnalysisManager.shared.currentDailyAnalysis?.aiAnalysis.dailySummary?.summary ?? "No summary found.")")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(textColor.opacity(0.8))
                            .lineSpacing(8)
                            .multilineTextAlignment(.leading)
                            .padding(24)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transition(.opacity.combined(with: .scale(scale: 1.02)))
                    }

                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
    
        }
        .navigationBarBackButtonHidden()

    }
    
    func formatDate() -> String {
        let dayNumber = Calendar.current.component(.day, from: Date())
        
        let formatString = "MMMM d"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = formatString
        var formattedDate = dateFormatter.string(from: Date())
        
        var suffix: String
        switch dayNumber {
            case 1, 21, 31: suffix = "st"
            case 2, 22: suffix = "nd"
            case 3, 23: suffix = "rd"
            default: suffix = "th"
        }
        
        formattedDate.append(suffix)
        
        return formattedDate
    }

}

#Preview {
    DaySummaryView()
}
