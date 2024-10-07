//
//  ThankYouView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/6/24.
//

import SwiftUI

struct ThankYouView: View {
    @Environment(\.dismiss) var dismiss
    @State private var opacity: Double = 0
    
    let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 16) {
                Text("Thanks for Looping!")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(Color(hex: "333333"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Text("You're making great progress\non your journey.")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(Color.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            .padding(.bottom, 40)
            Spacer()

            VStack(spacing: 20) {
                Text("See you tomorrow for more Loops.")
                    .font(.system(size: 25, weight: .regular))
                    .foregroundColor(accentColor)
                    .multilineTextAlignment(.center)

                Button(action: {
                    dismiss()
                }) {
                    Text("Close")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 150, height: 50)
                        .background(accentColor)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 1.5)) {
                opacity = 1
            }
        }
    }
}


#Preview {
    ThankYouView()
}
