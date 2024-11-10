//
//  LoopApp.swift
//  Loop
//
//  Created by Shriram Vasudevan on 9/29/24.
//

import SwiftUI

@main
struct LoopApp: App {
    
    var body: some Scene {
        WindowGroup {
            OpeningViewsContainer()
        }
        
    }
}

struct OpeningViewsContainer: View {
    @State var showingSplashScreen: Bool = true
    @State var showLoops: Bool = false
    @State private var showIntroView = false
    
    var body: some View {
        ZStack {
            if showingSplashScreen {
                SplashScreen(showingSplashScreen: $showingSplashScreen, showLoops: $showLoops)
                    .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                    .onAppear {
                        Task {
                            showIntroView = await FirstLaunchManager.shared.useIntroView()
                        }
                        
                    }
                    .preferredColorScheme(.light)
            } else if showIntroView && !showingSplashScreen{
                IntroView(onIntroCompletion: {
                    withAnimation {
                        FirstLaunchManager.shared.markAsLaunched()
                        showIntroView = false
                    }
                })
                .preferredColorScheme(.light)
            } else {
                PagesHolderView(pageType: .home)
                    .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                    .preferredColorScheme(.light)
            }
        }
        .fullScreenCover(isPresented: $showLoops) {
            RecordLoopsView(isFirstLaunch: true)
        }
        .animation(.easeInOut, value: showingSplashScreen || showIntroView)
        .navigationBarBackButtonHidden()
    }
    
}
