//
//  PagesHolderView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/7/24.
//

import SwiftUI

struct PagesHolderView: View {
    @State var pageType: PageType
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    switch pageType {
                        case .home:
                            HomeView()
                        case .insights:
                            InsightsView()
                        }
                }
            }
        }
    }
}

#Preview {
    PagesHolderView(pageType: .home)
}
