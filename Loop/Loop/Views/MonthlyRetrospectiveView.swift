//
//  MonthlyRetrospectiveView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 3/16/25.
//

import SwiftUI

struct MonthlyRetrospectiveView: View {
    @ObservedObject private var retrospectiveManager = MonthlyRetrospectiveManager.shared
    @ObservedObject private var premiumManager = PremiumManager.shared
    @State private var showingPremiumUpgrade = false
    
    private let accentColor = Color(hex: "94A7B7")
    private let textColor = Color(hex: "2C3E50")
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "F5F5F5")
                .ignoresSafeArea()
            
            if retrospectiveManager.isLoading {
                loadingView
            } else if !premiumManager.isUserPremium() {
                premiumUpgradeView
            } else {
                mainContentView
            }
        }
        .navigationTitle("Monthly Reflection")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPremiumUpgrade) {
            PremiumUpgradeView()
        }
        .onAppear {
            Task {
                await retrospectiveManager.loadMonthData()
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading your month in review...")
                .font(.system(size: 17))
                .foregroundColor(textColor)
        }
    }
    
    private var premiumUpgradeView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 64))
                .foregroundColor(accentColor)
            
            Text("Monthly Reflection")
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(textColor)
            
            Text("Gain insights from your past month of journaling and set intentions for personal growth.")
                .font(.system(size: 17))
                .multilineTextAlignment(.center)
                .foregroundColor(textColor.opacity(0.7))
                .padding(.horizontal, 32)
            
            Spacer()
            
            Button(action: {
                showingPremiumUpgrade = true
            }) {
                Text("Upgrade to Premium")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(accentColor)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            ProgressIndicator(
                totalSteps: retrospectiveManager.sectionTitles.count,
                currentStep: retrospectiveManager.currentSection,
                accentColor: accentColor
            )
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            // Paged content
            TabView(selection: $retrospectiveManager.currentSection) {
                monthOverviewPage
                    .tag(0)
                
                emotionalPatternsPage
                    .tag(1)
                
                keyMomentsPage
                    .tag(2)
                
                insightsPage
                    .tag(3)
                
                intentionsPage
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: retrospectiveManager.currentSection)
            .transition(.opacity)
            
            // Navigation buttons
            navigationButtons
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
    }
    
    // MARK: - Content Pages
    
    private var monthOverviewPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                sectionHeader(title: "Past Month Overview")
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Reflection Activity")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(textColor)
                    
                    HStack(alignment: .bottom, spacing: 8) {
                        Text("\(retrospectiveManager.monthReflections.count)")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(accentColor)
                        
                        Text("total reflections")
                            .font(.system(size: 16))
                            .foregroundColor(textColor.opacity(0.7))
                            .padding(.bottom, 4)
                    }
                    
                    Text("You've been most consistent on weekends, with morning being your preferred reflection time.")
                        .font(.system(size: 16))
                        .foregroundColor(textColor.opacity(0.7))
                        .padding(.top, 4)
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(16)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Monthly Themes")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(textColor)
                    
                    Text("Your reflections have focused around:")
                        .font(.system(size: 16))
                        .foregroundColor(textColor.opacity(0.7))
                    
                    HStack(spacing: 8) {
                        ForEach(retrospectiveManager.monthlyThemes, id: \.self) { theme in
                            Text(theme)
                                .font(.system(size: 15))
                                .foregroundColor(accentColor)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(accentColor.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(16)
            }
            .padding(24)
        }
    }
    
    private var emotionalPatternsPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                sectionHeader(title: "Emotional Patterns")
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your top emotions this month")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(textColor)
                    
                    Text("Based on your reflection content")
                        .font(.system(size: 14))
                        .foregroundColor(textColor.opacity(0.7))
                    
                    VStack(spacing: 16) {
                        ForEach(retrospectiveManager.topEmotions, id: \.emotion) { emotion in
                            HStack {
                                Text(emotion.emotion)
                                    .font(.system(size: 16))
                                    .foregroundColor(textColor)
                                
                                Spacer()
                                
                                Text("\(Int(emotion.percentage))%")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(accentColor)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(16)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Emotional Insights")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(textColor)
                    
                    Text("You tend to feel most positive in the mornings and when discussing creative projects. Your challenging moments often connect to work demands.")
                        .font(.system(size: 16))
                        .foregroundColor(textColor.opacity(0.7))
                        .lineSpacing(4)
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(16)
            }
            .padding(24)
        }
    }
    
    private var keyMomentsPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                sectionHeader(title: "Key Moments")
                
                if retrospectiveManager.monthReflections.isEmpty {
                    VStack(spacing: 16) {
                        Text("No reflections found for the past month")
                            .font(.system(size: 16))
                            .foregroundColor(textColor.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(24)
                            .background(Color.white)
                            .cornerRadius(16)
                    }
                } else {
                    ForEach(retrospectiveManager.monthReflections.prefix(3), id: \.id) { loop in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(formattedDate(loop.timestamp))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(accentColor)
                                
                                Spacer()
                                
                                if loop.isVideo {
                                    Image(systemName: "video.fill")
                                        .foregroundColor(accentColor)
                                } else {
                                    Image(systemName: "waveform")
                                        .foregroundColor(accentColor)
                                }
                            }
                            
                            Text(loop.promptText)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(textColor)
                            
                            if let transcript = loop.transcript, !transcript.isEmpty {
                                Text(transcript.prefix(120) + (transcript.count > 120 ? "..." : ""))
                                    .font(.system(size: 15))
                                    .foregroundColor(textColor.opacity(0.7))
                                    .lineSpacing(4)
                            }
                            
                            Button(action: {
                                // Play the loop
                            }) {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("Play")
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(accentColor)
                                .padding(.vertical, 8)
                            }
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(16)
                    }
                }
            }
            .padding(24)
        }
    }
    
    private var insightsPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                sectionHeader(title: "Insights & Learnings")
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Monthly Insights")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(textColor)
                    
                    Text(retrospectiveManager.insightsText)
                        .font(.system(size: 16))
                        .foregroundColor(textColor.opacity(0.8))
                        .lineSpacing(4)
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(16)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your Growth")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(textColor)
                    
                    Text("Looking at your reflections, you've shown growth in:")
                        .font(.system(size: 16))
                        .foregroundColor(textColor.opacity(0.7))
                    
                    VStack(alignment: .leading, spacing: 12) {
                        growthItem(icon: "brain.head.profile", text: "Self-awareness")
                        growthItem(icon: "heart.text.square", text: "Emotional regulation")
                        growthItem(icon: "figure.mind.and.body", text: "Mindfulness practice")
                    }
                    .padding(.top, 8)
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(16)
            }
            .padding(24)
        }
    }
    
    private var intentionsPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                sectionHeader(title: "Next Month Intentions")
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Set your intentions")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(textColor)
                    
                    Text("What would you like to focus on next month?")
                        .font(.system(size: 16))
                        .foregroundColor(textColor.opacity(0.7))
                    
                    VStack(spacing: 16) {
                        ForEach(0..<3) { index in
                            if index < retrospectiveManager.nextMonthIntentions.count {
                                intentionTextField(index: index)
                            } else {
                                Button(action: {
                                    retrospectiveManager.nextMonthIntentions.append("")
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add another intention")
                                    }
                                    .font(.system(size: 16))
                                    .foregroundColor(accentColor)
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(16)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Suggested intentions")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(textColor)
                    
                    Text("Based on your reflections")
                        .font(.system(size: 16))
                        .foregroundColor(textColor.opacity(0.7))
                    
                    VStack(alignment: .leading, spacing: 12) {
                        suggestionItem(text: "Practice mindfulness for 5 minutes daily")
                        suggestionItem(text: "Journal about creative inspirations")
                        suggestionItem(text: "Take time for self-care each weekend")
                    }
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(16)
            }
            .padding(24)
        }
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(textColor)
                
                Spacer()
            }
            
            Divider()
                .background(Color.gray.opacity(0.2))
        }
    }
    
    private func growthItem(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(accentColor)
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(textColor)
            
            Spacer()
        }
    }
    
    private func intentionTextField(index: Int) -> some View {
        TextField("I intend to...", text: Binding(
            get: {
                if index < retrospectiveManager.nextMonthIntentions.count {
                    return retrospectiveManager.nextMonthIntentions[index]
                }
                return ""
            },
            set: { newValue in
                if index < retrospectiveManager.nextMonthIntentions.count {
                    retrospectiveManager.nextMonthIntentions[index] = newValue
                }
            }
        ))
        .font(.system(size: 16))
        .padding(12)
        .background(Color(hex: "F5F5F5"))
        .cornerRadius(8)
    }
    
    private func suggestionItem(text: String) -> some View {
        Button(action: {
            if retrospectiveManager.nextMonthIntentions.count > 0 && retrospectiveManager.nextMonthIntentions[0].isEmpty {
                retrospectiveManager.nextMonthIntentions[0] = text
            } else {
                retrospectiveManager.nextMonthIntentions.append(text)
            }
        }) {
            HStack(spacing: 12) {
                Text(text)
                    .font(.system(size: 16))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Image(systemName: "plus.circle")
                    .foregroundColor(accentColor)
            }
            .padding(12)
            .background(Color(hex: "F5F5F5"))
            .cornerRadius(8)
        }
    }
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if retrospectiveManager.currentSection > 0 {
                Button(action: {
                    withAnimation {
                        retrospectiveManager.currentSection -= 1
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Previous")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(accentColor, lineWidth: 1)
                    )
                }
            }
            
            Button(action: {
                withAnimation {
                    if retrospectiveManager.currentSection < retrospectiveManager.sectionTitles.count - 1 {
                        retrospectiveManager.currentSection += 1
                    } else {
                        // Save intentions and finish
                        retrospectiveManager.saveIntentions()
                        dismiss()
                    }
                }
            }) {
                HStack {
                    Text(retrospectiveManager.currentSection < retrospectiveManager.sectionTitles.count - 1 ? "Next" : "Complete")
                    
                    if retrospectiveManager.currentSection < retrospectiveManager.sectionTitles.count - 1 {
                        Image(systemName: "chevron.right")
                    }
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(accentColor)
                )
            }
        }
        .padding(.top, 16)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

