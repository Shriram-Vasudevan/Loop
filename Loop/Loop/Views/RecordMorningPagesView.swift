//
//  RecordMorningPagesView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 3/7/25.
//

import SwiftUI

struct RecordMorningPagesView: View {
    @State var selection: Int = 0
    
    var body: some View {
        ZStack {
            TabView(selection: $selection) {
                introView
                    .tag(0)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
    
    var introView: some View {
        ZStack {
            Text("Welcome to Morning Pages")
                .font(.system(size: 42, weight: .medium))
                .foregroundColor(.black)
        }
    }
}

#Preview {
    RecordMorningPagesView()
}
