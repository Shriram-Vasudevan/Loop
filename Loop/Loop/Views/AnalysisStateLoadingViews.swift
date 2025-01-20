////
////  AnalysisStateLoadingViews.swift
////  Loop
////
////  Created by Shriram Vasudevan on 12/29/24.
////
//
import SwiftUI

struct ProgressStateView: View {
    let icon: String
    let title: String
    let description: String
    var progress: Float? = nil
    var isLoading: Bool = false
    let accentColor: Color
    let textColor: Color
    
    @State private var rotation: Double = 0
    
    var body: some View {
        VStack(spacing: 20) {
            WavePattern()
                .fill(accentColor.opacity(0.7))
                .frame(height: 60)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.6))
                
                Text(description)
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
}
//
//struct ProgressBar: View {
//    let value: Float
//    let accentColor: Color
//    
//    var body: some View {
//        GeometryReader { geometry in
//            ZStack(alignment: .leading) {
//                Rectangle()
//                    .fill(accentColor.opacity(0.2))
//                
//                Rectangle()
//                    .fill(accentColor)
//                    .frame(width: CGFloat(value) * geometry.size.width)
//            }
//        }
//        .clipShape(RoundedRectangle(cornerRadius: 2))
//    }
//}
//
//struct ErrorStateView: View {
//    let error: AnalysisError
//    let accentColor: Color
//    let textColor: Color
//    
//    var body: some View {
//        VStack(spacing: 8) {
//            Image(systemName: "exclamationmark.triangle.fill")
//                .font(.system(size: 48))
//                .foregroundColor(.orange)
//            
//            Text("Analysis Error")
//                .font(.system(size: 24, weight: .medium))
//                .foregroundColor(textColor)
//            
//            Text(getErrorMessage())
//                .font(.system(size: 16))
//                .foregroundColor(textColor.opacity(0.7))
//                .multilineTextAlignment(.center)
//        }
//        .padding(32)
//    }
//    
//    private func getErrorMessage() -> String {
//        switch error {
//        case .transcriptionFailed:
//            return "Unable to transcribe your audio. Please try recording again."
//        case .analysisFailure:
//            return "There was a problem analyzing your reflections. Please try again."
//        case .aiAnalysisFailed:
//            return "Unable to generate insights. Please try again later."
//        case .invalidData:
//            return "There was a problem with your recording data. Please try again."
//        case .missingFields:
//            return "Some required information is missing. Please try recording again."
//        }
//    }
//}
