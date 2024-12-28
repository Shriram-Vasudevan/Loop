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
    
    private let statsManager = StatsManager.shared
    
    @Published var currentDailyAnalysis: DailyAnalysis?
    @Published var todaysLoops: [LoopAnalysis] = []
    
    
    @Published private(set) var isAnalyzing = false
    
    private let audioAnalyzer = AudioAnalyzer.shared
    
    private let analysisCache = UserDefaults.standard
    private let dailyAnalysisCacheKey = "DailyAnalysisCache"
    private let loopAnalysisCacheKey = "LoopAnalysisCache"
    private let lastAnalysisCacheDateKey = "LastAnalysisCacheDate"
    
    @Published private(set) var currentWeekStats: [DailyStats] = []
    @Published private(set) var currentMonthWeeklyStats: [WeeklyStats] = []
    @Published private(set) var currentYearMonthlyStats: [MonthlyStats] = []
    
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
            
            saveDailyStats()
            statsManager.updateStats(with: dailyAnalysis)
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

    
    func saveDailyStats() {
        print("Starting to save daily stats")
        guard let analysis = currentDailyAnalysis else {
            print("No current daily analysis to save")
            return
        }
        
        guard let entity = NSEntityDescription.entity(forEntityName: "DailyStatsEntity", in: context) else {
            print("Failed to get DailyStatsEntity")
            return
        }
        
        let statsEntity = NSManagedObject(entity: entity, insertInto: context)
        print("Created new stats entity")
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .weekOfYear, .weekday], from: analysis.date)
        
        statsEntity.setValue(analysis.date, forKey: "date")
        statsEntity.setValue(Int16(components.year ?? 0), forKey: "year")
        statsEntity.setValue(Int16(components.month ?? 0), forKey: "month")
        statsEntity.setValue(Int16(components.weekOfYear ?? 0), forKey: "weekOfYear")
        statsEntity.setValue(Int16(components.weekday ?? 0), forKey: "weekday")
        
        statsEntity.setValue(analysis.aggregateMetrics.averageWPM, forKey: "averageWPM")
        statsEntity.setValue(analysis.aggregateMetrics.averageDuration, forKey: "averageDuration")
        statsEntity.setValue(analysis.aggregateMetrics.averageWordCount, forKey: "averageWordCount")

        statsEntity.setValue(Int16(analysis.loops.count), forKey: "loopCount")
        statsEntity.setValue(Date(), forKey: "lastUpdated")
        
        print("Set all values on stats entity")
        print("Date being saved: \(analysis.date)")
        print("Average WPM being saved: \(analysis.aggregateMetrics.averageWPM)")
        
        do {
            try context.save()
            print("Successfully saved daily stats to Core Data")
            
            let request = NSFetchRequest<NSManagedObject>(entityName: "DailyStatsEntity")
            let results = try context.fetch(request)
            print("After save, found \(results.count) total entries in DailyStatsEntity")
        } catch {
            print("Failed to save daily stats: \(error)")
        }
    }
    
    func fetchCurrentWeekStats() async {
        isLoadingWeekStats = true
        defer { isLoadingWeekStats = false }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekOfYear, .year], from: Date())
        
        guard let week = components.weekOfYear,
              let year = components.year else {
            print("❌ Failed to get current week components")
            return
        }
        
        print("\n🔍 Fetching stats for Week \(week) of \(year)")
        
        let request = NSFetchRequest<NSManagedObject>(entityName: "DailyStatsEntity")
        request.predicate = NSPredicate(format: "weekOfYear == %d AND year == %d", week, year)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        do {
            let results = try context.fetch(request)
            print("📊 Found \(results.count) entries for current week")
               
            results.forEach { entity in
                if let date = entity.value(forKey: "date") as? Date {
                    let weekNum = calendar.component(.weekOfYear, from: date)
                    print("Entry date: \(date), Week: \(weekNum)")
                }
            }
            
            currentWeekStats = results.compactMap { convertToDailyStats(from: $0) }
            print("📈 Converted \(currentWeekStats.count) entries to DailyStats")
            
        } catch {
            print("❌ Error fetching daily stats: \(error)")
            currentWeekStats = []
        }
    }

    func fetchCurrentMonthWeeklyStats() async {
        isLoadingMonthStats = true
        defer { isLoadingMonthStats = false }
        
        let calendar = Calendar.current
        let today = Date()
        guard let year = calendar.dateComponents([.year], from: today).year,
              let monthStart = calendar.date(from: DateComponents(year: year, month: calendar.component(.month, from: today))),
              let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart),
              let firstWeek = calendar.dateComponents([.weekOfYear], from: monthStart).weekOfYear,
              let lastWeek = calendar.dateComponents([.weekOfYear], from: monthEnd).weekOfYear else {
            print("❌ Error calculating date components for weekly stats")
            currentMonthWeeklyStats = []
            return
        }
        
        print("📅 Fetching weekly stats for:")
        print("Year: \(year)")
        print("First Week of Month: \(firstWeek)")
        print("Last Week of Month: \(lastWeek)")
        print("Month Start: \(monthStart)")
        print("Month End: \(monthEnd)")
        
        let request = NSFetchRequest<NSManagedObject>(entityName: "WeeklyStatsEntity")
        request.predicate = NSPredicate(format: "year == %d AND weekNumber >= %d AND weekNumber <= %d",
                                      year, firstWeek, lastWeek)
        
        print("🔍 Query predicate: year == \(year) AND weekNumber >= \(firstWeek) AND weekNumber <= \(lastWeek)")
        
        do {
            let results = try context.fetch(request)
            print("\n📊 Weekly stats query results:")
            print("Found \(results.count) entries")

            results.forEach { entity in
                let weekNum = entity.value(forKey: "weekNumber") as? Int16 ?? -1
                let yearVal = entity.value(forKey: "year") as? Int16 ?? -1
                print("Entry - Week: \(weekNum), Year: \(yearVal)")
            }
            
            currentMonthWeeklyStats = results.compactMap { convertToWeeklyStats(from: $0) }
            print("✅ Converted \(currentMonthWeeklyStats.count) entries")
        } catch {
            print("❌ Error fetching weekly stats: \(error)")
            currentMonthWeeklyStats = []
        }
    }
    
    func fetchCurrentYearMonthlyStats() async {
       isLoadingYearStats = true
       defer { isLoadingYearStats = false }
       
       let calendar = Calendar.current
       guard let year = calendar.dateComponents([.year], from: Date()).year else {
           print("Error getting current year")
           currentYearMonthlyStats = []
           return
       }
       
       let request = NSFetchRequest<NSManagedObject>(entityName: "MonthlyStatsEntity")
       request.predicate = NSPredicate(format: "year == %d", year)
       request.sortDescriptors = [NSSortDescriptor(key: "month", ascending: true)]
       
       do {
           let results = try context.fetch(request)
           print("\nFetching monthly stats:")
           print("Found \(results.count) entries")
           currentYearMonthlyStats = results.compactMap { convertToMonthlyStats(from: $0) }
           print("Converted \(currentYearMonthlyStats.count) entries")
       } catch {
           print("Error fetching monthly stats: \(error)")
           currentYearMonthlyStats = []
       }
    }
    
    private func convertToDailyStats(from entity: NSManagedObject) -> DailyStats? {
        guard let date = entity.value(forKey: "date") as? Date else {
            return nil
        }
        
        return DailyStats(
            date: date,
            year: entity.value(forKey: "year") as? Int16 ?? 0,
            month: entity.value(forKey: "month") as? Int16 ?? 0,
            weekOfYear: entity.value(forKey: "weekOfYear") as? Int16 ?? 0,
            weekday: entity.value(forKey: "weekday") as? Int16 ?? 0,
            averageWPM: entity.value(forKey: "averageWPM") as? Double ?? 0,
            averageDuration: entity.value(forKey: "averageDuration") as? Double ?? 0,
            averageWordCount: entity.value(forKey: "averageWordCount") as? Double ?? 0,
            averageUniqueWordCount: entity.value(forKey: "averageUniqueWordCount") as? Double ?? 0,
            vocabularyDiversityRatio: entity.value(forKey: "vocabularyDiversityRatio") as? Double ?? 0,
            loopCount: entity.value(forKey: "loopCount") as? Int16 ?? 0,
            lastUpdated: entity.value(forKey: "lastUpdated") as? Date
        )
    }
    
    private func convertToMonthlyStats(from entity: NSManagedObject) -> MonthlyStats? {
       guard let month = entity.value(forKey: "month") as? Int16,
             let year = entity.value(forKey: "year") as? Int16,
             let dataPointCount = entity.value(forKey: "dataPointCount") as? Int64 else {
           return nil
       }
       
       return MonthlyStats(
           dataPointCount: dataPointCount,
           averageWPM: entity.value(forKey: "averageWPM") as? Double ?? 0,
           averageDuration: entity.value(forKey: "averageDuration") as? Double ?? 0,
           averageWordCount: entity.value(forKey: "averageWordCount") as? Double ?? 0,
           averageUniqueWordCount: entity.value(forKey: "averageUniqueWordCount") as? Double ?? 0,
           vocabularyDiversityRatio: entity.value(forKey: "vocabularyDiversityRatio") as? Double ?? 0,
           lastUpdated: entity.value(forKey: "lastUpdated") as? Date,
           month: month,
           year: year
       )
    }

    private func convertToWeeklyStats(from entity: NSManagedObject) -> WeeklyStats? {
       guard let weekNumber = entity.value(forKey: "weekNumber") as? Int16,
             let year = entity.value(forKey: "year") as? Int16,
             let dataPointCount = entity.value(forKey: "dataPointCount") as? Int64 else {
           return nil
       }
       
       return WeeklyStats(
           dataPointCount: dataPointCount,
           averageWPM: entity.value(forKey: "averageWPM") as? Double ?? 0,
           averageDuration: entity.value(forKey: "averageDuration") as? Double ?? 0,
           averageWordCount: entity.value(forKey: "averageWordCount") as? Double ?? 0,
           averageUniqueWordCount: entity.value(forKey: "averageUniqueWordCount") as? Double ?? 0,
           vocabularyDiversityRatio: entity.value(forKey: "vocabularyDiversityRatio") as? Double ?? 0,
           lastUpdated: entity.value(forKey: "lastUpdated") as? Date,
           weekNumber: weekNumber,
           year: year
       )
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
    


