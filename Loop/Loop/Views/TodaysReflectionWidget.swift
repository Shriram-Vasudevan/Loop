//
//  TodaysReflectionWidget.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/16/25.
//

import SwiftUI

//
//  SunsetReflectionView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/1/24.
//  Updated on 2/25/25.
//

import SwiftUI

struct SunsetReflectionView: View {
    @State private var showingRecordLoopsView = false
    
    private let accentColor = Color(hex: "A28497")
    private let textColor = Color(hex: "2C3E50")
    
    private let lightMauve = Color(hex: "D5C5CC")
    private let midMauve = Color(hex: "BBA4AD")
    
    var body: some View {
        Button {
            showingRecordLoopsView = true
        } label: {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        lightMauve.opacity(0.3),
                        Color.white.opacity(0.9)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                GeometricMountains()
                    .fill(midMauve)
                    .opacity(0.2)
                    .frame(height: 120)
                    .offset(y: 40)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("DAILY REFLECTION")
                            .font(.system(size: 13, weight: .medium))
                            .tracking(1.5)
                            .foregroundColor(textColor.opacity(0.5))
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("Take time to look back on your day")
                            .font(.system(size: 23, weight: .medium))
                            .tracking(1.5)
                            .foregroundColor(textColor)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
                .padding(32)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
        .fullScreenCover(isPresented: $showingRecordLoopsView) {
            RecordLoopsView(isFirstLaunch: false)
        }
    }
}

struct GeometricMountains: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.width * 0.3, y: rect.height * 0.2))
        path.addLine(to: CGPoint(x: rect.width * 0.5, y: rect.maxY))
        
        path.move(to: CGPoint(x: rect.width * 0.3, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.width * 0.7, y: rect.height * 0.3))
        path.addLine(to: CGPoint(x: rect.width, y: rect.maxY))
        
        return path
    }
}

struct MorningSunriseView: View {
    @State private var showMorningReflection = false
    

    private let accentColor = Color(hex: "94A7B7")
    private let textColor = Color(hex: "2C3E50")
    
    private let lightBlue = Color(hex: "B5D5E2")
    private let sunriseYellow = Color(hex: "B7A284")
    
    var body: some View {
        Button {
            showMorningReflection = true
        } label: {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        lightBlue.opacity(0.3),
                        Color.white.opacity(0.9)
                    ]),
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
                
                GeometricSunrise()
                    .fill(sunriseYellow)
                    .opacity(0.2)
                    .frame(height: 120)
                    .offset(y: 40)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("MINDFUL START")
                            .font(.system(size: 13, weight: .medium))
                            .tracking(1.5)
                            .foregroundColor(textColor.opacity(0.5))
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("Begin your day with clarity and intention")
                            .font(.system(size: 23, weight: .medium))
                            .tracking(1.5)
                            .foregroundColor(textColor)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
                .padding(32)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
        .fullScreenCover(isPresented: $showMorningReflection) {
            MorningReflectionView()
        }
    }
}

struct GeometricSunrise: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let sunRadius = rect.width * 0.15
        let sunCenter = CGPoint(x: rect.width * 0.7, y: rect.height * 0.4)
        path.addArc(center: sunCenter,
                   radius: sunRadius,
                   startAngle: .degrees(0),
                   endAngle: .degrees(360),
                   clockwise: false)
        
        path.move(to: CGPoint(x: rect.minX, y: rect.height * 0.8))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.8))

        path.move(to: CGPoint(x: rect.minX, y: rect.height * 0.8))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.3, y: rect.height * 0.8),
            control1: CGPoint(x: rect.width * 0.1, y: rect.height * 0.7),
            control2: CGPoint(x: rect.width * 0.2, y: rect.height * 0.75)
        )
        
        path.move(to: CGPoint(x: rect.width * 0.4, y: rect.height * 0.8))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.8, y: rect.height * 0.8),
            control1: CGPoint(x: rect.width * 0.5, y: rect.height * 0.65),
            control2: CGPoint(x: rect.width * 0.7, y: rect.height * 0.75)
        )
        
        return path
    }
}

struct MorningSunriseView_Previews: PreviewProvider {
    static var previews: some View {
        MorningSunriseView()
            .padding()
            .background(Color.white)
    }
}
