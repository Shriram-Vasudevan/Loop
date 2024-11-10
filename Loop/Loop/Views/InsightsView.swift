//
//  InsightsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 10/7/24.
//

import SwiftUI

struct InsightsView: View {
    private let mockInsights = Insights(
        recentLoop: LoopSummary(
            date: Date(),
            topMood: "Happy",
            moodScores: [
                MoodScore(mood: "Happy", percentage: 70.0),
                MoodScore(mood: "Calm", percentage: 20.0),
                MoodScore(mood: "Anxious", percentage: 10.0)
            ]
        ),
        topMentionedWord: "Stress",
        monthlyMoodDistribution: [
            MoodScore(mood: "Happy", percentage: 40.0),
            MoodScore(mood: "Calm", percentage: 30.0),
            MoodScore(mood: "Anxious", percentage: 20.0),
            MoodScore(mood: "Sad", percentage: 10.0)
        ],
        goalSuggestion: "Take a 10-minute walk today to maintain your calm mood."
    )

    private let accentColor = Color(hex: "A28497")
    private let groupBackgroundColor = Color(hex: "F8F5F7")

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Insights")
                    .font(.system(size: 36, weight: .thin, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.top, 10)

                recentLoopView
                wordMentionView
                monthlyMoodDistributionView
                goalSuggestionView
            }
            .padding(.horizontal, 16)
          //  .background(WaveBackground())
        }
    }

    // MARK: - Recent Loop View
    private var recentLoopView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today’s Mood")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.black)

            if let recentLoop = mockInsights.recentLoop {
                HStack {
                    VStack(alignment: .leading) {
                        Text(formattedDate(recentLoop.date))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)

                        Text(recentLoop.topMood)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(accentColor)
                    }
                    Spacer()

                    moodBarChart(recentLoop.moodScores)
                }
            } else {
                Text("No loops recorded today.")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(groupBackgroundColor)
        .cornerRadius(15)
    }

    // MARK: - Word Mention View
    private var wordMentionView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Top Mentioned Word")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.black)

            Text("You've mentioned '\(mockInsights.topMentionedWord)' several times recently.")
                .font(.system(size: 16))
                .foregroundColor(.gray)
        }
        .padding()
        .background(groupBackgroundColor)
        .cornerRadius(15)
    }

    // MARK: - Monthly Mood Distribution View
    private var monthlyMoodDistributionView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mood Distribution (This Month)")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.black)

            moodBarChart(mockInsights.monthlyMoodDistribution)
        }
        .padding()
        .background(groupBackgroundColor)
        .cornerRadius(15)
    }

    // MARK: - Goal Suggestion View
    private var goalSuggestionView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Goal Suggestion")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.black)

            Text(mockInsights.goalSuggestion)
                .font(.system(size: 16))
                .foregroundColor(accentColor)
        }
        .padding()
        .background(groupBackgroundColor)
        .cornerRadius(15)
    }

    // MARK: - Mood Bar Chart
    private func moodBarChart(_ moodScores: [MoodScore]) -> some View {
        HStack(spacing: 8) {
            ForEach(moodScores) { score in
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(accentColor)
                        .frame(width: 20, height: CGFloat(score.percentage) * 2)
                    Text(score.mood)
                        .font(.caption)
                        .rotationEffect(.degrees(-45))
                        .frame(width: 50)
                }
            }
        }
    }

    // MARK: - Helper Functions
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Preview
#Preview {
    InsightsView()
}
