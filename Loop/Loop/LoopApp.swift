//
//  LoopApp.swift
//  Loop
//
//  Created by Shriram Vasudevan on 9/29/24.
//

import SwiftUI
import CloudKit

@main
struct LoopApp: App {
    
    var body: some Scene {
        WindowGroup {
            AppPromo()
            // OpeningViewsContainer()
//            ViewPastLoopView(loop: Loop(id: "vvevwevwe", data: CKAsset(fileURL: URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("sampleFile.dat")), timestamp: Calendar.current.date(from: DateComponents(year: 2024, month: 9, day: 27))!, promptText: "What's a goal you're working towards?", freeResponse: false, isVideo: false))
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
                OnboardingView(onIntroCompletion: {
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
