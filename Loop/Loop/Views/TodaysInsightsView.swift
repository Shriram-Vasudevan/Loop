//
//  TodaysInsightsView.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/27/24.
//

import SwiftUI

struct TodaysInsightsView: View {
    @ObservedObject var analysisManager = AnalysisManager.shared
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                switch analysisManager.analysisState {
                case .notStarted:
                    ProgressStateView(
                        icon: "pencil.circle",
                        title: "REFLECTIONS NEEDED",
                        description: "Complete your daily reflection to see insights",
                        accentColor: accentColor,
                        textColor: textColor
                    )
                case .retrievingResponses, .analyzingQuantitative, .analyzingAI:
                    ProgressStateView(
                        icon: "gear",
                        title: "ANALYZING",
                        description: "Processing your reflections",
                        isLoading: true,
                        accentColor: accentColor,
                        textColor: textColor
                    )
                case .completed(let analysis):
                    analysisContent(analysis)
                case .failed(let error):
                    ProgressStateView(
                        icon: "exclamationmark.circle",
                        title: "ANALYSIS UNAVAILABLE",
                        description: error.description,
                        accentColor: accentColor,
                        textColor: textColor
                    )
                }
            }
            .padding(24)
        }
        .background(Color(hex: "F5F5F5"))
    }
    
    @ViewBuilder
    private func analysisContent(_ analysis: DailyAnalysis) -> some View {
        VStack(spacing: 24) {
            analysisHeader()
            wordCountMetric(analysis)
         //   moodSection(analysis)
            standoutMomentSection(analysis)
            additionalMomentsSection(analysis)
            recurringThemesSection(analysis)
            fillerWordSection(analysis)
        }
    }

    @ViewBuilder
    private func analysisHeader() -> some View {
        HStack {
            Text("TODAY'S INSIGHTS")
                .font(.system(size: 13, weight: .medium))
                .tracking(1.5)
                .foregroundColor(textColor.opacity(0.5))
            Spacer()
        }
    }

    @ViewBuilder
    private func wordCountMetric(_ analysis: DailyAnalysis) -> some View {
        MetricCard(
            value: "\(analysis.quantitativeMetrics.totalWordCount)",
            label: "WORDS",
            sublabel: getWordCountDescription(analysis.quantitativeMetrics.totalWordCount),
            icon: "text.word.spacing",
            color: accentColor
        )
    }

//    private func moodSection(_ analysis: DailyAnalysis) -> some View {
//        guard let moodData = analysis.aiAnalysis.moodData,
//              let rating = moodData.rating else {
//            return AnyView(EmptyView())
//        }
//
//        return AnyView(
//            MoodInsightCard(
//                rating: rating,
//                sleep: analysis.aiAnalysis.sleepData?.hours
//            )
//        )
//    }



    @ViewBuilder
    private func standoutMomentSection(_ analysis: DailyAnalysis) -> some View {
        if let standout = analysis.aiAnalysis.standoutAnalysis,
           let moment = standout.keyMoment,
           let category = standout.category {
            StandoutMomentCard(
                moment: moment,
                category: category,
                color: accentColor
            )
        }
    }

    @ViewBuilder
    private func additionalMomentsSection(_ analysis: DailyAnalysis) -> some View {
        if let additionalMoments = analysis.aiAnalysis.additionalKeyMoments?.moments,
           !additionalMoments.isEmpty {
            KeyMomentsCard(moments: additionalMoments)
        }
    }

    @ViewBuilder
    private func recurringThemesSection(_ analysis: DailyAnalysis) -> some View {
        if let themes = analysis.aiAnalysis.recurringThemes?.themes,
           !themes.isEmpty {
            RecurringThemesCard(themes: themes)
        }
    }

    @ViewBuilder
    private func fillerWordSection(_ analysis: DailyAnalysis) -> some View {
        FillerWordCard(count: analysis.aiAnalysis.fillerAnalysis.totalCount)
    }

    
    private func getWordCountDescription(_ count: Int) -> String {
        if count > 250 {
            return "Very detailed reflection"
        } else if count > 175 {
            return "Good depth of expression"
        } else if count > 100 {
            return "Clear and concise thoughts"
        } else {
            return "Brief reflection"
        }
    }
}

struct StandoutMomentCard: View {
    let moment: String
    let category: MomentCategory
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("KEY MOMENT")
                .font(.system(size: 13, weight: .medium))
                .tracking(1.5)
                .foregroundColor(Color(hex: "2C3E50").opacity(0.5))
            
            HStack(spacing: 8) {
                Text(category.rawValue.uppercased())
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(color)
            }
            
            Text(moment)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "2C3E50"))
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 4)
        )
    }
}

struct KeyMomentsCard: View {
    let moments: [KeyMomentModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ADDITIONAL INSIGHTS")
                .font(.system(size: 13, weight: .medium))
                .tracking(1.5)
                .foregroundColor(Color(hex: "2C3E50").opacity(0.5))
            
            VStack(spacing: 16) {
                ForEach(moments, id: \.keyMoment) { moment in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(moment.category.rawValue.uppercased())
                            .font(.system(size: 11, weight: .medium))
                            .tracking(1.5)
                            .foregroundColor(Color(hex: "A28497"))
                        
                        Text(moment.keyMoment)
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "2C3E50"))
                    }
                    
                    if moment.keyMoment != moments.last?.keyMoment {
                        Divider()
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 4)
        )
    }
}

struct RecurringThemesCard: View {
    let themes: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("RECURRING THEMES")
                .font(.system(size: 13, weight: .medium))
                .tracking(1.5)
                .foregroundColor(Color(hex: "2C3E50").opacity(0.5))
            
            HStack(spacing: 8) {
                ForEach(themes, id: \.self) { theme in
                    Text(theme)
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color(hex: "A28497").opacity(0.1))
                        )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 4)
        )
    }
}

struct FillerWordCard: View {
    let count: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("FILLER WORDS")
                .font(.system(size: 13, weight: .medium))
                .tracking(1.5)
                .foregroundColor(Color(hex: "2C3E50").opacity(0.5))
            
            HStack(alignment: .firstTextBaseline) {
                Text("\(count)")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(Color(hex: "2C3E50"))
                
                Text("used today")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "2C3E50").opacity(0.6))
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 4)
        )
    }
}

// Preview
struct TodaysInsightsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Empty State
            TodaysInsightsView()
                .environmentObject(mockManager(with: .notStarted))
                .previewDisplayName("Empty State")
            
            // Processing State
            TodaysInsightsView()
                .environmentObject(mockManager(with: .analyzingAI))
                .previewDisplayName("Processing")
            
            // Completed State
            TodaysInsightsView()
                .environmentObject(mockManager(with: .completed(mockAnalysis())))
                .previewDisplayName("Complete")
            
            // Error State
            TodaysInsightsView()
                .environmentObject(mockManager(with: .failed(.noResponses)))
                .previewDisplayName("Error")
        }
    }
    
    static func mockManager(with state: AnalysisState) -> AnalysisManager {
        let manager = AnalysisManager.shared
        // Simulate the state
        return manager
    }
    
    static func mockAnalysis() -> DailyAnalysis {
        DailyAnalysis(
            date: Date(),
            quantitativeMetrics: QuantitativeMetrics(
                totalWordCount: 856,
                totalDurationSeconds: 0,
                averageWordsPerRecording: 0,
                averageDurationPerRecording: 0
            ),
            aiAnalysis: DailyAIAnalysisResult(
                date: Date(),
                moodData: MoodData(exists: true, rating: 8.5),
                sleepData: SleepData(exists: true, hours: 7.5),
                standoutAnalysis: StandoutAnalysis(
                    exists: true,
                    primaryTopic: .growth,
                    category: .realization,
                    sentiment: .positive,
                    keyMoment: "Realized the importance of morning routines"
                ),
                additionalKeyMoments: AdditionalKeyMoments(
                    exists: true,
                    moments: [
                        KeyMomentModel(
                            keyMoment: "Made progress on project deadlines",
                            category: .success,
                            sourceType: .summary
                        ),
                        KeyMomentModel(
                            keyMoment: "Need to improve work-life balance",
                            category: .challenge,
                            sourceType: .summary
                        )
                    ]
                ),
                recurringThemes: RecurringThemes(
                    exists: true,
                    themes: ["Productivity", "Wellness", "Growth"]
                ),
                summaryAnalysis: nil,
                freeformAnalysis: nil,
                fillerAnalysis: FillerAnalysis(totalCount: 12)
            )
        )
    }
}

struct MetricCard: View {
    let value: String
    let label: String
    let sublabel: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color.opacity(0.6))
                
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(color.opacity(0.6))
            }
            .frame(height: 20)
            
            Text(value)
                .font(.system(size: 32, weight: .light))
                .foregroundColor(Color(hex: "2C3E50"))
                .frame(height: 38)
            
            Text(sublabel)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "2C3E50").opacity(0.6))
                .lineLimit(2)
                .frame(height: 36, alignment: .top)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 100)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 4)
        )
    }
}

struct MoodInsightCard: View {
    let rating: Double
    let sleep: Int?
    private let textColor = Color(hex: "2C3E50")
    
    private var moodColor: Color {
        if rating <= 5 {
            return Color(hex: "1E3D59") // Sad color
        } else if rating <= 7 {
            return Color(hex: "94A7B7") // Neutral color
        } else {
            return Color(hex: "B784A7") // Happy color
        }
    }
    
    private var moodDescription: String {
        if rating <= 3 {
            return "feeling down"
        } else if rating <= 4 {
            return "not great"
        } else if rating <= 6 {
            return "okay"
        } else if rating <= 8 {
            return "pretty good"
        } else {
            return "feeling great"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("MOOD & ENERGY")
                .font(.system(size: 13, weight: .medium))
                .tracking(1.5)
                .foregroundColor(textColor.opacity(0.5))
            
            HStack(spacing: 24) {
                // Mood indicator
                Circle()
                    .fill(moodColor)
                    .frame(width: 64, height: 64)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .shadow(color: moodColor.opacity(0.2), radius: 10)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(moodDescription)
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(textColor)
                    
                    if let sleep = sleep {
                        Text("\(sleep) hours of sleep")
                            .font(.system(size: 14))
                            .foregroundColor(textColor.opacity(0.6))
                    }
                }
                
                Spacer()
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 4)
        )
    }
}

struct TopicsCard: View {
    let topics: Set<TopicCategory>
    private let textColor = Color(hex: "2C3E50")
    private let accentColor = Color(hex: "A28497")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("TOPICS DISCUSSED")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1.5)
                    .foregroundColor(textColor.opacity(0.5))
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(topics), id: \.self) { topic in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(accentColor.opacity(0.2))
                            .frame(width: 8, height: 8)
                        
                        Text(topic.rawValue)
                            .font(.system(size: 16))
                            .foregroundColor(textColor)
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 4)
        )
    }
}


