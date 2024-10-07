//
//  LoopApp.swift
//  Loop
//
//  Created by Shriram Vasudevan on 9/29/24.
//

import SwiftUI

@main
struct LoopApp: App {
    @State var showingSplashScreen: Bool = true
    @State var showLoops: Bool = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showingSplashScreen {
                    SplashScreen(showingSplashScreen: $showingSplashScreen, showLoops: $showLoops)
                        .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                } else {
                    PagesHolderView(pageType: .home)
                        .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                }
                
            }
            .fullScreenCover(isPresented: $showLoops) {
                RecordLoopsView(isFirstLaunch: true)
            }
        }
        
    }
}
