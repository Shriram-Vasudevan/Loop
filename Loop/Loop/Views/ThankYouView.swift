//
//  ThankYouView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/6/24.
//

import SwiftUI

struct ThankYouView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var showParticles = false
    
    var body: some View {
        ZStack {

            Color.white.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Spacer()
                
                // Primary message
                Text("Well Done!")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(Color.black)
                    .multilineTextAlignment(.center)
                    .scaleEffect(showParticles ? 1 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.5, blendDuration: 0), value: showParticles)
                
                // Motivational message
                Text("You're making great progress on your journey.")
                    .font(.system(size: 20, weight: .light, design: .rounded))
                    .foregroundColor(Color.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                Spacer()
                
                // Call to action
                Text("Come back tomorrow for another Loop!")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(Color.gray)
                    .padding(.bottom, 20)
                
                // Done button
                Button(action: {
                    dismiss()
                }) {
                    Text("Close")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 150)
                        .background(Color.black)
                        .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // Subtle particle effect for celebration
            if showParticles {
                ParticleEffect()
                    .transition(.scale)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 1.5)) {
                showParticles = true
            }
        }
    }
}


struct ParticleEffect: View {
    @State private var particles: [Particle] = []
    
    let particleCount = 25

    var body: some View {
        GeometryReader { geometry in
            ForEach(particles) { particle in
                Circle()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: particle.size, height: particle.size)
                    .position(x: particle.xPosition(in: geometry.size),
                              y: particle.yPosition(in: geometry.size))
                    .scaleEffect(particle.isActive ? 1.5 : 1)
                    .animation(
                        Animation.easeInOut(duration: 2)
                            .repeatForever()
                            .delay(Double(particle.id) * 0.1),
                        value: particle.isActive
                    )
            }
        }
        .onAppear {
            // Create particles with random starting values
            particles = Array(0..<particleCount).map { Particle(id: $0) }
            
            // Activate particles to start animation
            for index in 0..<particleCount {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                    particles[index].isActive = true
                }
            }
        }
    }
}
#Preview {
    ThankYouView()
}
