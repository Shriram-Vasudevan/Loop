//
//  StatsLoadingView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/15/24.
//

import SwiftUI

struct StatsLoadingView: View {
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: accentColor))
                .scaleEffect(1.5)
            
            Text("Loading stats...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(accentColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    StatsLoadingView()
}
