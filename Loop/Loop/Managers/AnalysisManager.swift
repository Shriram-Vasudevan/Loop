//
//  AnalysisManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/18/24.
//

import Foundation
import AVFoundation
import Speech
import NaturalLanguage
import Combine
import CoreData


class AnalysisManager: ObservableObject {
    static let shared = AnalysisManager()

    @Published var currentDailyAnalysis: DailyAnalysis?
    @Published var todaysLoops: [LoopAnalysis] = []
    
    
    @Published private(set) var isAnalyzing = false
    
    private let audioAnalyzer = AudioAnalyzer.shared
    
    private let analysisCache = UserDefaults.standard
    private let dailyAnalysisCacheKey = "DailyAnalysisCache"
    private let loopAnalysisCacheKey = "LoopAnalysisCache"
    private let lastAnalysisCacheDateKey = "LastAnalysisCacheDate"
    
    @Published private(set) var isLoadingWeekStats = false
    @Published private(set) var isLoadingMonthStats = false
    @Published private(set) var isLoadingYearStats = false
    
    
    @Published var analysisError: AnalysisError?
    private var analysisTimer: Timer?
    
    @Published private(set) var isFollowUpCompletedToday: Bool = false
    
    @Published private(set) var analysisState: AnalysisState = .noLoops
    
    @Published var weeklyAnalyses: [WeeklyAnalysis] = []
    @Published var isLoadingWeeklyAnalysis = false
    
    private let defaults = UserDefaults.standard
    private let weeklyAnalysisCacheKey = "WeeklyAnalyses"
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "LoopData")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    init() {
        if isCacheValidForToday() {
            loadAnalysisCache()
            isFollowUpCompletedToday = UserDefaults.standard.bool(forKey: "FollowUpCompletedToday")
        } else {
            resetAnalysisCache()
        }
    }
    
    func startAnalysis(_ loop: Loop) async {
        do {
            let analysis = try await analyzeLoop(loop)
            
            await MainActor.run {
                todaysLoops.append(analysis)
                
                if todaysLoops.count < 3 {
                    analysisState = .partial(count: todaysLoops.count)
                } else if todaysLoops.count == 3 {
                    Task {
                        await performCompleteAnalysis()
                    }
                }
            }
        } catch {
            await MainActor.run {
                analysisState = .failed(.analysisFailure(error))
            }
        }
    }
   
    func analyzeLoop(_ loop: Loop) async throws -> LoopAnalysis {
        guard let fileURL = loop.data.fileURL else {
            throw AnalysisError.invalidData("Loop file URL is nil")
        }
        
        do {
            let transcript = try await audioAnalyzer.transcribeAudio(url: fileURL)
            let duration = audioAnalyzer.getDuration(url: fileURL)
            
            let words = transcript.components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
                .map { $0.trimmingCharacters(in: .punctuationCharacters) }
                .filter { !$0.isEmpty }
            
            let uniqueWords = Set(words)
            let wpm = Double(words.count) / (duration / 60.0)
            let vocabularyDiversity = Double(uniqueWords.count) / Double(words.count)
            
            let metrics = LoopMetrics(
                duration: duration,
                wordCount: words.count,
                uniqueWordCount: uniqueWords.count,
                wordsPerMinute: wpm,
                vocabularyDiversity: vocabularyDiversity
            )
            
            return LoopAnalysis(
                id: loop.id,
                timestamp: loop.timestamp,
                promptText: loop.promptText,
                category: LoopManager.shared.getCategoryForPrompt(loop.promptText)?.rawValue ?? "Share Anything",
                transcript: transcript,
                metrics: metrics
            )
        } catch let error as AnalysisError {
            throw error
        } catch {
            throw AnalysisError.invalidData("Failed to analyze loop: \(error.localizedDescription)")
        }
    }
    
    private func performCompleteAnalysis() async {
        await MainActor.run {
            analysisState = .analyzing
        }
        
        do {
            let responsePairs = todaysLoops.map { loop in
                (question: loop.promptText, answer: loop.transcript)
            }
            
            // Get AI analysis
            let aiAnalysis = try await AIAnalyzer.shared.analyzeResponses(responsePairs)
            
            // Calculate aggregate metrics
            let aggregateMetrics = calculateAggregateMetrics(todaysLoops)
            
            // Create daily analysis
            let dailyAnalysis = DailyAnalysis(
                date: Date(),
                loops: todaysLoops,
                aggregateMetrics: aggregateMetrics,
                aiAnalysis: aiAnalysis
            )
            
            await MainActor.run {
                self.currentDailyAnalysis = dailyAnalysis
                self.analysisState = .completed(dailyAnalysis)
            }
            
            saveDailyAIAnalysis(aiAnalysis)
            QuantitativeTrendsManager.shared.saveDailyStats(dailyAnalysis)
        } catch {
            await MainActor.run {
                self.analysisState = .failed(.aiAnalysisFailed("AI analysis failed: \(error.localizedDescription)"))
            }
        }
    }
    
    private func calculateAggregateMetrics(_ loops: [LoopAnalysis]) -> AggregateMetrics {
        let totalWords = loops.reduce(0) { $0 + $1.metrics.wordCount }
        let totalUniqueWords = Set(loops.flatMap { loop in
            loop.transcript.components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
                .map { $0.trimmingCharacters(in: .punctuationCharacters) }
                .filter { !$0.isEmpty }
        }).count
        
        return AggregateMetrics(
            averageDuration: loops.reduce(0.0) { $0 + $1.metrics.duration } / Double(loops.count),
            averageWordCount: Double(totalWords) / Double(loops.count),
            averageWPM: loops.reduce(0.0) { $0 + $1.metrics.wordsPerMinute } / Double(loops.count),
            vocabularyDiversity: Double(totalUniqueWords) / Double(totalWords)
        )
    }
    

    private func isCacheValidForToday() -> Bool {
        print("\n📅 Checking daily analysis cache validity...")
        
        guard let cachedData = analysisCache.dictionary(forKey: dailyAnalysisCacheKey),
              let cacheDate = cachedData["cacheDate"] as? Date else {
            print("❌ No cache date found or invalid cache data")
            return false
        }
        
        let isValid = Calendar.current.isDateInToday(cacheDate)
        print(isValid ? "✅ Cache is valid for today" : "❌ Cache is outdated")
        print("Cache date: \(cacheDate.formatted())")
        return isValid
    }
    
    private func saveAnalysisCache() {
        print("\n💾 Saving daily analysis cache...")
        
        var analysisData: [String: Any] = [
            "lastAnalysisDate": Date(),
            "cacheDate": Date()
        ]
        
        // Debug current state
        print("Current state:")
        print("- Daily Analysis exists: \(currentDailyAnalysis != nil)")
        print("- Today's Loops count: \(todaysLoops.count)")
        print("- Analysis State: \(analysisState)")
        
        if case .completed(let analysis) = analysisState {
            if let dailyAnalysisData = try? JSONEncoder().encode(analysis) {
                analysisData["dailyAnalysis"] = dailyAnalysisData.base64EncodedString()
                print("✅ Encoded completed analysis")
            }
        }
        
        if let todaysLoopsData = try? JSONEncoder().encode(todaysLoops) {
            analysisData["todaysLoops"] = todaysLoopsData.base64EncodedString()
            print("✅ Encoded today's loops (\(todaysLoops.count) loops)")
        }
        
        analysisCache.set(analysisData, forKey: dailyAnalysisCacheKey)
        print("✅ Saved all data to cache")

    }

    private func loadAnalysisCache() {
        print("\n📂 Loading daily analysis cache...")
        
        guard let cachedData = analysisCache.dictionary(forKey: dailyAnalysisCacheKey) else {
            print("❌ No cached data found")
            return
        }
        
        let decoder = JSONDecoder()

        if let dailyAnalysisString = cachedData["dailyAnalysis"] as? String,
           let dailyAnalysisData = Data(base64Encoded: dailyAnalysisString) {
            do {
                let dailyAnalysis = try decoder.decode(DailyAnalysis.self, from: dailyAnalysisData)
                self.currentDailyAnalysis = dailyAnalysis
                self.analysisState = .completed(dailyAnalysis)
                print("✅ Loaded daily analysis from cache")
                print("- Analysis date: \(dailyAnalysis.date.formatted())")
                print("- Number of loops: \(dailyAnalysis.loops.count)")
            } catch {
                print("❌ Failed to decode daily analysis: \(error)")
            }
        }
        
        if let todaysLoopsString = cachedData["todaysLoops"] as? String,
           let todaysLoopsData = Data(base64Encoded: todaysLoopsString) {
            do {
                let loopAnalyses = try decoder.decode([LoopAnalysis].self, from: todaysLoopsData)
                self.todaysLoops = loopAnalyses
                
                if currentDailyAnalysis == nil {
                    self.analysisState = .partial(count: loopAnalyses.count)
                }
                print("✅ Loaded today's loops from cache (\(loopAnalyses.count) loops)")
            } catch {
                print("❌ Failed to decode today's loops: \(error)")
            }
        }
        
        print("📊 Cache load complete")
    }

    private func resetAnalysisCache() {
        print("\n🧹 Resetting analysis cache...")
        currentDailyAnalysis = nil
        todaysLoops = []
        analysisCache.removeObject(forKey: dailyAnalysisCacheKey)
        isFollowUpCompletedToday = false
        UserDefaults.standard.removeObject(forKey: "FollowUpCompletedToday")
        print("✅ Analysis cache reset complete")
    }

    func markFollowUpComplete() {
        isFollowUpCompletedToday = true
        UserDefaults.standard.set(true, forKey: "FollowUpCompletedToday")
    }

    
    
    private func getCurrentWeekDateRange() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let today = Date()
        
        // Since we're running this on Sunday, get the previous Monday
        guard let monday = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)),
              let sunday = calendar.date(byAdding: .day, value: 6, to: monday) else {
            // Fallback just in case - get last 7 days
            let end = calendar.startOfDay(for: today)
            let start = calendar.date(byAdding: .day, value: -6, to: end)!
            return (start, end)
        }
        
        // Get start and end of those days
        let weekStart = calendar.startOfDay(for: monday)
        let weekEnd = calendar.date(byAdding: .day, value: 1, to: sunday)!
        
        print("📅 Week range: \(weekStart) to \(weekEnd)")
        return (weekStart, weekEnd)
    }
    
    func performWeeklyAnalysis() async throws -> WeeklyAnalysis {
        let (weekStart, weekEnd) = getCurrentWeekDateRange()
        print("Fetching loops from \(weekStart.formatted()) to \(weekEnd.formatted())")
        
        let loops = try await LoopManager.shared.fetchLoopsForDateRange(start: weekStart, end: weekEnd)
  
        let dailyLoops = loops.filter { $0.isDailyLoop }
        
        let loopAnalyses = try await dailyLoops.asyncMap { loop in
            try await analyzeLoop(loop)
        }
        
        let weeklyMetrics = calculateWeeklyMetrics(loopAnalyses)
        
        let aiInsights = try await WeeklyAIAnalyzer.shared.analyzeWeek(loopAnalyses)
        
        return WeeklyAnalysis(
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            loops: loopAnalyses,
            keyMoments: aiInsights.keyMoments ?? [],
            themes: aiInsights.themes ?? [],
            aggregateMetrics: weeklyMetrics,
            aiInsights: aiInsights
        )
    }
    
    private func calculateWeeklyMetrics(_ analyses: [LoopAnalysis]) -> WeeklyMetrics {
        let totalWords = analyses.reduce(0) { $0 + $1.metrics.wordCount }
        let totalDuration = analyses.reduce(0.0) { $0 + $1.metrics.duration }
        let averageWPM = analyses.reduce(0.0) { $0 + $1.metrics.wordsPerMinute } / Double(analyses.count)
        
        let calendar = Calendar.current
        let uniqueDays = Set(analyses.map { calendar.startOfDay(for: $0.timestamp) }).count
        
        let wpmByDay = Dictionary(grouping: analyses) { analysis in
            calendar.startOfDay(for: analysis.timestamp)
        }.mapValues { analyses in
            analyses.reduce(0.0) { $0 + $1.metrics.wordsPerMinute } / Double(analyses.count)
        }
        
        let emotionalJourney = analyses.reduce(into: [Date: String]()) { result, analysis in
            if let mood = analysis.transcript.extractMood() {
                result[analysis.timestamp] = mood
            }
        }
        
        return WeeklyMetrics(
            totalWords: totalWords,
            averageDuration: totalDuration / Double(analyses.count),
            averageWordsPerMinute: averageWPM,
            totalUniqueDays: uniqueDays,
            emotionalJourney: emotionalJourney,
            weeklyWPMTrend: wpmByDay
        )
    }
    
    func loadWeeklyAnalyses() async {
        await MainActor.run {
            isLoadingWeeklyAnalysis = true
        }
        
        let cached = getAllCachedAnalyses()
        weeklyAnalyses = cached
        
        let calendar = Calendar.current
        let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: Date())!

        let haveLastWeek = cached.contains { analysis in
            calendar.isDate(analysis.weekStartDate, equalTo: lastWeek, toGranularity: .weekOfYear)
        }

        if !haveLastWeek {
            do {
                let analysis = try await getLastWeekAnalysis()
                cacheAnalysis(analysis)
                await MainActor.run {
                    weeklyAnalyses.insert(analysis, at: 0)
                    weeklyAnalyses.sort { $0.weekStartDate > $1.weekStartDate }
                }
            } catch {
                print("Failed to get last week's analysis: \(error)")
            }
        }
        
        await MainActor.run {
            isLoadingWeeklyAnalysis = false
        }
    }

    private func getLastWeekAnalysis() async throws -> WeeklyAnalysis {
        let calendar = Calendar.current
        let now = Date()
        
        let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: now)!
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: lastWeek)) else {
            throw AnalysisError.invalidData("Couldn't get week start date")
        }
        
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
        
        print("Getting analysis for \(weekStart) to \(weekEnd)")
        
        let loops = try await LoopManager.shared.fetchLoopsForDateRange(start: weekStart, end: weekEnd)
        let dailyLoops = loops.filter { $0.isDailyLoop }
        
        guard !dailyLoops.isEmpty else {
            throw AnalysisError.invalidData("No loops found for last week")
        }
        
        let analyses = try await dailyLoops.asyncMap { loop in
            try await analyzeLoop(loop)
        }

        let metrics = calculateWeeklyMetrics(analyses)
        let aiAnalysis = try await WeeklyAIAnalyzer.shared.analyzeWeek(analyses)
        
        return WeeklyAnalysis(
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            loops: analyses,
            keyMoments: aiAnalysis.keyMoments ?? [],
            themes: aiAnalysis.themes ?? [],
            aggregateMetrics: metrics,
            aiInsights: aiAnalysis
        )
    }

    private func getAllCachedAnalyses() -> [WeeklyAnalysis] {
        guard let data = UserDefaults.standard.data(forKey: weeklyAnalysisCacheKey),
              let analyses = try? JSONDecoder().decode([WeeklyAnalysis].self, from: data) else {
            return []
        }
        return analyses.sorted { $0.weekStartDate > $1.weekStartDate }
    }

    private func cacheAnalysis(_ analysis: WeeklyAnalysis) {
        var analyses = getAllCachedAnalyses()
        
        if let index = analyses.firstIndex(where: {
            Calendar.current.isDate($0.weekStartDate, equalTo: analysis.weekStartDate, toGranularity: .weekOfYear)
        }) {
            analyses.remove(at: index)
        }
        
        analyses.append(analysis)
        analyses.sort { $0.weekStartDate > $1.weekStartDate }
        
        if let encoded = try? JSONEncoder().encode(analyses) {
            UserDefaults.standard.set(encoded, forKey: weeklyAnalysisCacheKey)
        }
    }
    
    func saveDailyAIAnalysis(_ analysis: AIAnalysisResult) {
        AITrendsManager.shared.saveDailyAnalysis(analysis, date: Date())
    }
        
    
    func getWeekIdentifier(_ analysis: WeeklyAnalysis) -> String {
        let calendar = Calendar.current
        let weekNumber = calendar.component(.weekOfYear, from: analysis.weekStartDate)
        return "Week \(weekNumber) in Review"
    }

    // Plus a more detailed version for the full header
    func getDetailedWeekIdentifier(_ analysis: WeeklyAnalysis) -> String {
        let calendar = Calendar.current
        let weekNumber = calendar.component(.weekOfYear, from: analysis.weekStartDate)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "Week \(weekNumber) in Review (\(formatter.string(from: analysis.weekStartDate)) - \(formatter.string(from: analysis.weekEndDate)))"
    }
    
}
    


