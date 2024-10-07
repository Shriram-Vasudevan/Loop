//
//  SplashScreen.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/7/24.
//

import SwiftUI

struct SplashScreen: View {
    @Binding var showingSplashScreen: Bool
    @Binding var showLoops: Bool
    
    var body: some View {
        ZStack {
            Text("Welcome")
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                showLoops = LaunchManager.shared.isFirstLaunchOfDay()
                showingSplashScreen = false
            })
        }
    }
}

//#Preview {
//    SplashScreen()
//}
