//
//  HomeView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/1/24.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var loopManager = LoopManager.shared
    @State private var isRecording = false
    @State private var countdownText: String = "00:00:00"
    @State private var timer: Timer? = nil
    
    var body: some View {
        VStack(spacing: 8) {
            topBar
            mainContentSection
            bottomBar
        }
        .background(Color.white)
        .onAppear {
            if let loopRevealDate = loopManager.loopRevealDate {
                print("onAppear: loopRevealDate is already set: \(loopRevealDate)")
                startCountdown()
            }
        }
        .onChange(of: loopManager.loopRevealDate) { newDate in
            if let newDate = newDate {
                print("onChange: loopRevealDate updated to \(newDate)")
                startCountdown()
            }
        }
    }
    
    private var topBar: some View {
        HStack {
            Text("LOOP")
                .font(.system(size: 24, weight: .bold, design: .default))
                .foregroundColor(.black)
            Spacer()
            Button(action: {
                // Open settings
            }) {
                Image(systemName: "gearshape")
                    .foregroundColor(.black)
                    .font(.system(size: 20))
            }
        }
        .padding([.horizontal, .top])
    }
    
    private var countdownView: some View {
        VStack(spacing: 12) {
            Text("Next Loop Reveal")
                .font(.system(size: 20, weight: .medium, design: .default))
                .foregroundColor(.black)
                .padding(.top, 10)

            Text(countdownText)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .center)
        .background(Color.black.opacity(0.05))
        .cornerRadius(10)
    }


    
    private var mainContentSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                headerSection
                countdownView
                latestLoopSection
                insightsSection
                timelineSection
            }
            .padding(.horizontal)
        }
    }
    
    private var bottomBar: some View {
        HStack {
            Spacer()
            navigationButton(icon: "chart.bar", destination: Text("Insights View"))
            Spacer()
            navigationButton(icon: "circle.fill", destination: Text("Record View"))
            Spacer()
            navigationButton(icon: "archivebox", destination: Text("Archive View"))
            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.bottom, 10)
        .background(Color.white)
    }
    
    private func navigationButton(icon: String, destination: some View) -> some View {
        NavigationLink(destination: destination) {
            Image(systemName: icon)
                .foregroundColor(.black)
                .font(.system(size: 20))
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("Welcome back")
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundColor(.gray)
                Text("John Doe")
                    .font(.system(size: 24, weight: .semibold, design: .default))
                    .foregroundColor(.black)
            }
            Spacer()
            Text(getFormattedDate())
                .font(.system(size: 14, weight: .regular, design: .default))
                .foregroundColor(.gray)
        }
    }
    
    private var latestLoopSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Latest Loop")
                .font(.system(size: 18, weight: .semibold, design: .default))
                .foregroundColor(.black)
            HStack {
                Text("Reflecting on my progress...")
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundColor(.gray)
                Spacer()
                Button(action: {
                    // Play latest loop
                }) {
                    Image(systemName: "play.circle")
                        .foregroundColor(.black)
                        .font(.system(size: 20))
                }
            }
            .padding()
            .background(Color.black.opacity(0.05))
            .cornerRadius(8)
        }
    }
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Insights")
                .font(.system(size: 18, weight: .semibold, design: .default))
                .foregroundColor(.black)
            HStack(spacing: 20) {
                insightCard(title: "Total Loops", value: "143")
                insightCard(title: "This Month", value: "12")
                insightCard(title: "Streak", value: "7 days")
            }
        }
    }
    
    private func insightCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 12, weight: .regular, design: .default))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .default))
                .foregroundColor(.black)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your Timeline")
                .font(.system(size: 18, weight: .semibold, design: .default))
                .foregroundColor(.black)
            VStack(spacing: 15) {
                timelineItem(date: "Oct 1", title: "Career goals reflection")
                timelineItem(date: "Sep 30", title: "Weekly progress update")
                timelineItem(date: "Sep 30", title: "New project kickoff thoughts")
            }
        }
    }
    
    private func timelineItem(date: String, title: String) -> some View {
        HStack(spacing: 15) {
            Text(date)
                .font(.system(size: 12, weight: .regular, design: .default))
                .foregroundColor(.gray)
                .frame(width: 50, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .foregroundColor(.black)
                
                Button(action: {
                    // Play this loop
                }) {
                    Text("Play")
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
        }
    }
    
    private func getFormattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy"
        return formatter.string(from: Date())
    }
    
    private func startCountdown() {
        guard let revealDate = loopManager.loopRevealDate else {
            print("startCountdown: loopRevealDate is nil.")
            countdownText = "00:00:00"
            return
        }

        print("startCountdown: Timer started, revealDate: \(revealDate)")

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let currentTime = Date()
            let remainingTime = revealDate.timeIntervalSince(currentTime)
            
            if remainingTime > 0 {
                countdownText = formatTime(remainingTime)
            } else {
                countdownText = "00:00:00"
                timer?.invalidate()
            }
        }
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

#Preview {
    ContentView()
}

