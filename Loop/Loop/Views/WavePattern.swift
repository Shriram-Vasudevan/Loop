//
//  WavePattern.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/19/25.
//

import SwiftUI

struct WavePattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height / 2
        let waveHeight = height * 0.25
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let y = midHeight + sin(relativeX * .pi * 4) * waveHeight
            
            if x == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        return path
    }
}
