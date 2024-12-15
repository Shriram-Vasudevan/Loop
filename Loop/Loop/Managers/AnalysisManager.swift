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


class TextAnalyzer {
    static let shared = TextAnalyzer()
    
    private let stopWords: Set<String> = ["the", "be", "to", "of", "and", "a", "in", "that", "have", "it", "for", "not", "on", "with", "he", "as", "you", "do", "at", "this", "but", "his", "by", "from", "they", "we", "say", "her", "she", "or", "an", "will", "my", "one", "all", "would", "there", "their", "what", "so", "up", "out", "if", "about", "who", "get", "which", "go", "when", "um", "uh"]
    
    private let selfReferenceWords: Set<String> = ["i", "me", "my", "mine", "myself", "i'm", "i've", "i'll", "i'd"]
    
    func analyzeText(_ text: String) -> ([String], [String]) {
        let words = text.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }
        
        let uniqueWords = Array(Set(words).subtracting(stopWords))
        return (words, uniqueWords)
    }
    
    func findMostUsedWords(_ words: [String], limit: Int = 10) -> [WordCount] {
        let wordCounts = words.filter { !stopWords.contains($0) }
            .reduce(into: [:]) { counts, word in
                counts[word, default: 0] += 1
            }
        
        return wordCounts.map { WordCount(word: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(limit)
            .map { $0 }
    }
    
    func calculateOverlap(_ words1: [String], _ words2: [String]) -> Double {
        let set1 = Set(words1)
        let set2 = Set(words2)
        let intersection = set1.intersection(set2)
        let union = set1.union(set2)
        return union.isEmpty ? 0 : Double(intersection.count) / Double(union.count)
    }
    
    func analyzeSelfReferences(_ words: [String]) -> (count: Int, types: [String]) {
        let refs = words.filter { selfReferenceWords.contains($0) }
        return (refs.count, Array(Set(refs)))
    }
    
    func calculateAverageWordLength(_ words: [String]) -> Double {
        guard !words.isEmpty else { return 0 }
        let totalLength = words.reduce(0) { $0 + $1.count }
        return Double(totalLength) / Double(words.count)
    }
}

class AudioAnalyzer {
    static let shared = AudioAnalyzer()
    
    func transcribeAudio(url: URL) async throws -> String {
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        guard let recognizer = recognizer else {
            throw AnalysisError.transcriptionFailed
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        
        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let result = result, result.isFinal {
                    continuation.resume(returning: result.bestTranscription.formattedString)
                }
            }
        }
    }
    
    func getDuration(url: URL) -> TimeInterval {
        let asset = AVURLAsset(url: url)
        return CMTimeGetSeconds(asset.duration)
    }
}


class AnalysisManager: ObservableObject {
    static let shared = AnalysisManager()
    
    private let statsManager = StatsManager.shared
    
    @Published var currentDailyAnalysis: DailyAnalysis?
    @Published var todaysLoops: [LoopAnalysis] = []
    @Published  var pastLoopAnalysis: LoopAnalysis?
    
    @Published private(set) var loopComparison: LoopComparison?
    @Published private(set) var allTimeComparison: LoopComparison?
    @Published private(set) var monthlyComparison: LoopComparison?
    @Published var weeklyComparison: LoopComparison?
    
    @Published private(set) var isAnalyzing = false
    
    private let textAnalyzer = TextAnalyzer.shared
    private let audioAnalyzer = AudioAnalyzer.shared
    
    private let analysisCache = UserDefaults.standard
    private let dailyAnalysisCacheKey = "DailyAnalysisCache"
    private let loopAnalysisCacheKey = "LoopAnalysisCache"
    private let pastLoopAnalysisCacheKey = "PastLoopAnalysisCache"
    private let lastAnalysisCacheDateKey = "LastAnalysisCacheDate"
    
    @Published private(set) var currentWeekStats: [DailyStats] = []
    @Published private(set) var currentMonthWeeklyStats: [WeeklyStats] = []
    @Published private(set) var currentYearMonthlyStats: [MonthlyStats] = []
    
    @Published private(set) var isLoadingWeekStats = false
    @Published private(set) var isLoadingMonthStats = false
    @Published private(set) var isLoadingYearStats = false
    
    init() {
        if isCacheValidForToday() {
            loadAnalysisCache()
        } else {
            resetAnalysisCache()
        }
    }
    
    func startAnalysis(_ loop: Loop, isPastLoop: Bool) async throws {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        let analysis = try await analyzeLoop(loop)
        
        await MainActor.run {
            if isPastLoop {
                pastLoopAnalysis = analysis
                self.loopComparison = compareWithPastLoop()
            } else {
                todaysLoops.append(analysis)
                if todaysLoops.count == 3 {
                    print("reached three loops analyzed")
                    
                    Task {
                        let dailyAnalysis = await createDailyAnalysis(todaysLoops)
                        currentDailyAnalysis = dailyAnalysis
                        
                        allTimeComparison = statsManager.compareWithAllTimeStats(dailyAnalysis)
                        monthlyComparison = statsManager.compareWithMonthlyStats(dailyAnalysis)
                        weeklyComparison = statsManager.compareWithWeeklyStats(dailyAnalysis)
                        
                        statsManager.updateStats(with: dailyAnalysis)
                        
                        saveDailyStats()
                        saveAnalysisCache()
                    }
                }
                else {
                    saveAnalysisCache()
                }
            }
        }
    }
    
    func analyzeLoop(_ loop: Loop) async throws -> LoopAnalysis {
        guard let fileURL = loop.data.fileURL else {
            throw AnalysisError.invalidData
        }
        
        let transcript = try await audioAnalyzer.transcribeAudio(url: fileURL)
        let duration = audioAnalyzer.getDuration(url: fileURL)
        
        let (words, uniqueWords) = textAnalyzer.analyzeText(transcript)
        let selfRefs = textAnalyzer.analyzeSelfReferences(words)
        let avgWordLength = textAnalyzer.calculateAverageWordLength(words)
        let mostUsed = textAnalyzer.findMostUsedWords(words)
        
        let metrics = LoopMetrics(
            duration: duration,
            wordCount: words.count,
            uniqueWordCount: uniqueWords.count,
            wordsPerMinute: Double(words.count) / (duration / 60.0),
            selfReferenceCount: selfRefs.count,
            uniqueSelfReferenceCount: selfRefs.types.count,
            averageWordLength: avgWordLength
        )
        
        let wordAnalysis = WordAnalysis(
            words: words,
            uniqueWords: uniqueWords,
            mostUsedWords: mostUsed,
            selfReferenceTypes: selfRefs.types
        )
        
        print("finished analying loop")
        return LoopAnalysis(
            id: loop.id,
            timestamp: loop.timestamp,
            promptText: loop.promptText,
            category: LoopManager.shared.getCategoryForPrompt(loop.promptText)?.rawValue ?? "Share Anything", transcript: transcript,
            metrics: metrics,
            wordAnalysis: wordAnalysis
        )
    }
    
    private func createDailyAnalysis(_ loops: [LoopAnalysis]) async -> DailyAnalysis {
        let aggregateMetrics = calculateAggregateMetrics(loops)
        let wordPatterns = analyzeWordPatterns(loops)
        let overlapAnalysis = analyzeOverlap(loops)
        let rangeAnalysis = calculateRanges(loops)
        
        let transcripts = loops.map { $0.transcript }
        
        let aiAnalysis = try? await AIAnalyzer.shared.analyzeResponses(transcripts)
        
        return DailyAnalysis(
            date: Date(),
            loops: loops,
            aggregateMetrics: aggregateMetrics,
            wordPatterns: wordPatterns,
            overlapAnalysis: overlapAnalysis,
            rangeAnalysis: rangeAnalysis,
            aiAnalysis: aiAnalysis
        )
    }
    
    private func calculateAggregateMetrics(_ loops: [LoopAnalysis]) -> AggregateMetrics {
        let totalWords = loops.reduce(0) { $0 + $1.metrics.wordCount }
        let totalUniqueWords = loops.reduce(0) { $0 + $1.metrics.uniqueWordCount }
        
        return AggregateMetrics(
            averageDuration: loops.reduce(0) { $0 + $1.metrics.duration } / Double(loops.count),
            averageWordCount: Double(totalWords) / Double(loops.count),
            averageUniqueWordCount: Double(totalUniqueWords) / Double(loops.count),
            averageWPM: loops.reduce(0) { $0 + $1.metrics.wordsPerMinute } / Double(loops.count),
            averageSelfReferences: Double(loops.reduce(0) { $0 + $1.metrics.selfReferenceCount }) / Double(loops.count),
            vocabularyDiversityRatio: Double(totalUniqueWords) / Double(totalWords)
        )
    }
    
    private func analyzeWordPatterns(_ loops: [LoopAnalysis]) -> WordPatterns {
        let allWords = loops.flatMap { $0.wordAnalysis.words }
        let uniqueWords = Array(Set(allWords))
        
        let wordsInAll = loops.map { Set($0.wordAnalysis.words) }
            .reduce(Set(allWords)) { $0.intersection($1) }
        
        let mostUsed = textAnalyzer.findMostUsedWords(allWords)
        
        return WordPatterns(
            totalUniqueWords: uniqueWords,
            wordsInAllResponses: Array(wordsInAll),
            mostUsedWords: mostUsed
        )
    }
    
    private func analyzeOverlap(_ loops: [LoopAnalysis]) -> OverlapAnalysis {
        var pairwiseOverlap: [String: Double] = [:]
        var commonWords: [String: [String]] = [:]
        
        for i in 0..<loops.count {
            for j in (i + 1)..<loops.count {
                let key = "\(loops[i].id)-\(loops[j].id)"
                let overlap = textAnalyzer.calculateOverlap(
                    loops[i].wordAnalysis.words,
                    loops[j].wordAnalysis.words
                )
                pairwiseOverlap[key] = overlap
                
                let common = Set(loops[i].wordAnalysis.words)
                    .intersection(Set(loops[j].wordAnalysis.words))
                commonWords[key] = Array(common)
            }
        }
        
        let overallSimilarity = pairwiseOverlap.values.reduce(0, +) / Double(pairwiseOverlap.count)
        
        return OverlapAnalysis(
            pairwiseOverlap: pairwiseOverlap,
            commonWords: commonWords,
            overallSimilarity: overallSimilarity
        )
    }
    
    private func calculateRanges(_ loops: [LoopAnalysis]) -> RangeAnalysis {
        let wpms = loops.map { $0.metrics.wordsPerMinute }
        let durations = loops.map { $0.metrics.duration }
        let wordCounts = loops.map { $0.metrics.wordCount }
        let selfRefs = loops.map { $0.metrics.selfReferenceCount }
        
        return RangeAnalysis(
            wpmRange: MinMaxRange(
                min: wpms.min() ?? 0,
                max: wpms.max() ?? 0
            ),
            durationRange: MinMaxRange(
                min: durations.min() ?? 0,
                max: durations.max() ?? 0
            ),
            wordCountRange: IntRange(
                min: wordCounts.min() ?? 0,
                max: wordCounts.max() ?? 0
            ),
            selfReferenceRange: IntRange(
                min: selfRefs.min() ?? 0,
                max: selfRefs.max() ?? 0
            )
        )
    }
    
    func compareWithPastLoop() -> LoopComparison? {
        guard let daily = currentDailyAnalysis,
              let past = pastLoopAnalysis else {
            return nil
        }
        
        func createComparison(current: Double, past: Double) -> MetricComparison {
            let percentChange = ((current - past) / past) * 100
            let direction: ComparisonDirection
            if abs(percentChange) < 1 {
                direction = .same
            } else if percentChange > 0 {
                direction = .increase
            } else {
                direction = .decrease
            }
            return MetricComparison(direction: direction, percentageChange: abs(percentChange))
        }
        
        return LoopComparison(
            date: daily.date,
            pastLoopDate: past.timestamp,
            
            durationComparison: createComparison(
                current: daily.aggregateMetrics.averageDuration,
                past: past.metrics.duration
            ),
            
            wpmComparison: createComparison(
                current: daily.aggregateMetrics.averageWPM,
                past: past.metrics.wordsPerMinute
            ),
            
            wordCountComparison: createComparison(
                current: daily.aggregateMetrics.averageWordCount,
                past: Double(past.metrics.wordCount)
            ),
            
            uniqueWordComparison: createComparison(
                current: daily.aggregateMetrics.averageUniqueWordCount,
                past: Double(past.metrics.uniqueWordCount)
            ),
            
            vocabularyDiversityComparison: createComparison(
                current: daily.aggregateMetrics.vocabularyDiversityRatio,
                past: Double(past.metrics.uniqueWordCount) / Double(past.metrics.wordCount)
            ),
            
            averageWordLengthComparison: createComparison(
                current: daily.loops.reduce(0.0) { $0 + $1.metrics.averageWordLength } / Double(daily.loops.count),
                past: past.metrics.averageWordLength
            ),
            
            selfReferenceComparison: createComparison(
                current: daily.aggregateMetrics.averageSelfReferences,
                past: Double(past.metrics.selfReferenceCount)
            ),
            
            similarityScore: textAnalyzer.calculateOverlap(
                daily.loops.flatMap { $0.wordAnalysis.uniqueWords },
                past.wordAnalysis.uniqueWords
            ),
            
            commonWords: Array(Set(daily.loops.flatMap { $0.wordAnalysis.uniqueWords })
                .intersection(Set(past.wordAnalysis.uniqueWords)))
        )
    }
    
    private func isCacheValidForToday() -> Bool {
        guard let cachedData = analysisCache.dictionary(forKey: dailyAnalysisCacheKey),
              let cacheDate = cachedData["cacheDate"] as? Date else {
            return false
        }
        return Calendar.current.isDateInToday(cacheDate)
    }
    
    private func saveAnalysisCache() {
        let analysisData: [String: Any] = [
            "dailyAnalysis": try? JSONEncoder().encode(currentDailyAnalysis),
            "todaysLoops": try? JSONEncoder().encode(todaysLoops),
            "pastLoopAnalysis": try? JSONEncoder().encode(pastLoopAnalysis),
            "loopComparison": try? JSONEncoder().encode(loopComparison),
            "allTimeComparison": try? JSONEncoder().encode(allTimeComparison),
            "monthlyComparison": try? JSONEncoder().encode(monthlyComparison),
            "weeklyComparison": try? JSONEncoder().encode(weeklyComparison),
            "lastAnalysisDate": Date(),
            "cacheDate": Date()
        ]
        
        analysisCache.set(analysisData, forKey: dailyAnalysisCacheKey)
    }
    
    private func loadAnalysisCache() {
        guard let cachedData = analysisCache.dictionary(forKey: dailyAnalysisCacheKey) else {
            return
        }
        
        if let dailyAnalysisData = cachedData["dailyAnalysis"] as? Data,
           let dailyAnalysis = try? JSONDecoder().decode(DailyAnalysis.self, from: dailyAnalysisData) {
            self.currentDailyAnalysis = dailyAnalysis
        }
        
        if let todaysLoopsData = cachedData["todaysLoops"] as? Data,
           let loopAnalyses = try? JSONDecoder().decode([LoopAnalysis].self, from: todaysLoopsData) {
            self.todaysLoops = loopAnalyses
        }
        
        if let pastLoopData = cachedData["pastLoopAnalysis"] as? Data,
           let pastAnalysis = try? JSONDecoder().decode(LoopAnalysis.self, from: pastLoopData) {
            self.pastLoopAnalysis = pastAnalysis
        }
        
        if let comparisonData = cachedData["loopComparison"] as? Data,
           let comparison = try? JSONDecoder().decode(LoopComparison.self, from: comparisonData) {
            self.loopComparison = comparison
        }
        
        if let allTimeComparisonData = cachedData["allTimeComparison"] as? Data,
           let allTimeComparison = try? JSONDecoder().decode(LoopComparison.self, from: allTimeComparisonData) {
            self.allTimeComparison = allTimeComparison
        }
        
        if let monthlyComparisonData = cachedData["monthlyComparison"] as? Data,
           let monthlyComparison = try? JSONDecoder().decode(LoopComparison.self, from: monthlyComparisonData) {
            self.monthlyComparison = monthlyComparison
        }
        
        if let weeklyComparisonData = cachedData["weeklyComparison"] as? Data,
           let weeklyComparison = try? JSONDecoder().decode(LoopComparison.self, from: weeklyComparisonData) {
            self.weeklyComparison = weeklyComparison
        }
    }
    
    private func resetAnalysisCache() {
        currentDailyAnalysis = nil
        todaysLoops = []
        pastLoopAnalysis = nil
        loopComparison = nil
        allTimeComparison = nil
        monthlyComparison = nil
        weeklyComparison = nil
        analysisCache.removeObject(forKey: dailyAnalysisCacheKey)
    }
    
    func saveDailyStats() {
        guard let analysis = currentDailyAnalysis,
              let entity = NSEntityDescription.entity(forEntityName: "DailyStatsEntity", in: statsManager.context) else {
            print("Failed to get DailyStatsEntity")
            return
        }
        
        let statsEntity = NSManagedObject(entity: entity, insertInto: statsManager.context)
        
        // Set basic info
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .weekOfYear, .weekday], from: analysis.date)
        
        statsEntity.setValue(analysis.date, forKey: "date")
        statsEntity.setValue(Int16(components.year ?? 0), forKey: "year")
        statsEntity.setValue(Int16(components.month ?? 0), forKey: "month")
        statsEntity.setValue(Int16(components.weekOfYear ?? 0), forKey: "weekOfYear")
        statsEntity.setValue(Int16(components.weekday ?? 0), forKey: "weekday")
        
        // Set metrics
        statsEntity.setValue(analysis.aggregateMetrics.averageWPM, forKey: "averageWPM")
        statsEntity.setValue(analysis.aggregateMetrics.averageDuration, forKey: "averageDuration")
        statsEntity.setValue(analysis.aggregateMetrics.averageWordCount, forKey: "averageWordCount")
        statsEntity.setValue(analysis.aggregateMetrics.averageUniqueWordCount, forKey: "averageUniqueWordCount")
        statsEntity.setValue(analysis.aggregateMetrics.averageSelfReferences, forKey: "averageSelfReferences")
        statsEntity.setValue(analysis.aggregateMetrics.vocabularyDiversityRatio, forKey: "vocabularyDiversityRatio")
        
        // Additional metrics
        statsEntity.setValue(Int16(analysis.loops.count), forKey: "loopCount")
        statsEntity.setValue(analysis.loops.reduce(0.0) { $0 + $1.metrics.averageWordLength } / Double(analysis.loops.count), forKey: "averageWordLength")
        statsEntity.setValue(Date(), forKey: "lastUpdated")
        
        do {
            try statsManager.context.save()
            print("Successfully saved daily stats")
        } catch {
            print("Failed to save daily stats: \(error)")
        }
    }
    
    func fetchCurrentWeekStats() async {
        isLoadingWeekStats = true
        defer { isLoadingWeekStats = false }
        
        let calendar = Calendar.current
        let today = Date()
        
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)),
              let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            currentWeekStats = []
            return
        }
        
        let context = statsManager.context
        // Change this line to use DailyStatsEntity instead of DailyStats
        let request = NSFetchRequest<DailyStatsEntity>(entityName: "DailyStatsEntity")
        
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@",
                                        weekStart as NSDate,
                                        weekEnd as NSDate)
        
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        do {
            // Update the property type to match
            let results = try context.fetch(request)
            currentWeekStats = results.compactMap { entity -> DailyStats? in
                // Convert DailyStatsEntity to DailyStats here if needed
                return entity as? DailyStats
            }
        } catch {
            print("Error fetching daily stats: \(error)")
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
            print("Error calculating date components for weekly stats")
            currentMonthWeeklyStats = []
            return
        }
        
        let context = statsManager.context
        let request = NSFetchRequest<WeeklyStatsEntity>(entityName: "WeeklyStatsEntity")
        
        request.predicate = NSPredicate(format: "year == %d AND weekNumber >= %d AND weekNumber <= %d",
                                        year, firstWeek, lastWeek)
        
        request.sortDescriptors = [NSSortDescriptor(key: "weekNumber", ascending: true)]
        
        do {
            let results = try context.fetch(request)
            currentMonthWeeklyStats = results.compactMap { entity -> WeeklyStats? in
                return entity as? WeeklyStats
            }
        } catch {
            print("Error fetching weekly stats: \(error)")
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
        
        let context = statsManager.context
        let request = NSFetchRequest<MonthlyStatsEntity>(entityName: "MonthlyStatsEntity")
        
        request.predicate = NSPredicate(format: "year == %d", year)
        request.sortDescriptors = [NSSortDescriptor(key: "month", ascending: true)]
        
        do {
            let results = try context.fetch(request)
            currentYearMonthlyStats = results.compactMap { entity -> MonthlyStats? in
                return entity as? MonthlyStats
            }
        } catch {
            print("Error fetching monthly stats: \(error)")
            currentYearMonthlyStats = []
        }
    }
}
    
class StatsManager {
    static let shared = StatsManager()
    
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
    
    
    
    private func fetchAllTimeStats() -> AllTimeStats? {
        let request = NSFetchRequest<AllTimeStats>(entityName: "AllTimeStatsEntity")
        return try? context.fetch(request).first
    }
    
    private func fetchCurrentMonthStats() -> MonthlyStats? {
        let request = NSFetchRequest<MonthlyStats>(entityName: "MonthlyStatsEntity")
        let components = Calendar.current.dateComponents([.month, .year], from: Date())
        guard let month = components.month,
              let year = components.year else { return nil }
        
        request.predicate = NSPredicate(format: "month == %d AND year == %d", month, year)
        return try? context.fetch(request).first
    }
    
    private func fetchCurrentWeekStats() -> WeeklyStats? {
        let request = NSFetchRequest<WeeklyStats>(entityName: "WeeklyStatsEntity")
        let components = Calendar.current.dateComponents([.weekOfYear, .year], from: Date())
        guard let week = components.weekOfYear,
              let year = components.year else { return nil }
        
        request.predicate = NSPredicate(format: "weekNumber == %d AND year == %d", week, year)
        return try? context.fetch(request).first
    }
    
    private func createAllTimeStats() -> AllTimeStats? {
        guard let entity = NSEntityDescription.entity(forEntityName: "AllTimeStatsEntity", in: context) else {
            print("Failed to get AllTimeStatsEntity")
            return nil
        }
        
        let statsEntity = NSManagedObject(entity: entity, insertInto: context)
        
        // Set values like your Loop code
        statsEntity.setValue(0, forKey: "dataPointCount")
        statsEntity.setValue(0.0, forKey: "averageWPM")
        statsEntity.setValue(0.0, forKey: "averageDuration")
        statsEntity.setValue(0.0, forKey: "averageWordCount")
        statsEntity.setValue(0.0, forKey: "averageUniqueWordCount")
        statsEntity.setValue(0.0, forKey: "averageSelfReferences")
        statsEntity.setValue(0.0, forKey: "vocabularyDiversityRatio")
        statsEntity.setValue(0.0, forKey: "averageWordLength")
        statsEntity.setValue(Date(), forKey: "lastUpdated")
        
        do {
            try context.save()
            // Cast to AllTimeStats after saving
            return statsEntity as? AllTimeStats
        } catch {
            print("Failed to save AllTimeStats: \(error)")
            return nil
        }
    }
    
    private func createMonthlyStats() -> MonthlyStats? {
        let components = Calendar.current.dateComponents([.month, .year], from: Date())
        guard let month = components.month,
              let year = components.year,
              let entity = NSEntityDescription.entity(forEntityName: "MonthlyStatsEntity", in: context) else {
            print("Failed to get MonthlyStatsEntity")
            return nil
        }
        
        let statsEntity = NSManagedObject(entity: entity, insertInto: context)
        
        statsEntity.setValue(0, forKey: "dataPointCount")
        statsEntity.setValue(0.0, forKey: "averageWPM")
        statsEntity.setValue(0.0, forKey: "averageDuration")
        statsEntity.setValue(0.0, forKey: "averageWordCount")
        statsEntity.setValue(0.0, forKey: "averageUniqueWordCount")
        statsEntity.setValue(0.0, forKey: "averageSelfReferences")
        statsEntity.setValue(0.0, forKey: "vocabularyDiversityRatio")
        statsEntity.setValue(0.0, forKey: "averageWordLength")
        statsEntity.setValue(Date(), forKey: "lastUpdated")
        statsEntity.setValue(Int16(month), forKey: "month")
        statsEntity.setValue(Int16(year), forKey: "year")
        
        do {
            try context.save()
            return statsEntity as? MonthlyStats
        } catch {
            print("Failed to save MonthlyStats: \(error)")
            return nil
        }
    }

    private func createWeeklyStats() -> WeeklyStats? {
        let components = Calendar.current.dateComponents([.weekOfYear, .year], from: Date())
        guard let week = components.weekOfYear,
              let year = components.year,
              let entity = NSEntityDescription.entity(forEntityName: "WeeklyStatsEntity", in: context) else {
            print("Failed to get WeeklyStatsEntity")
            return nil
        }
        
        let statsEntity = NSManagedObject(entity: entity, insertInto: context)
        
        statsEntity.setValue(0, forKey: "dataPointCount")
        statsEntity.setValue(0.0, forKey: "averageWPM")
        statsEntity.setValue(0.0, forKey: "averageDuration")
        statsEntity.setValue(0.0, forKey: "averageWordCount")
        statsEntity.setValue(0.0, forKey: "averageUniqueWordCount")
        statsEntity.setValue(0.0, forKey: "averageSelfReferences")
        statsEntity.setValue(0.0, forKey: "vocabularyDiversityRatio")
        statsEntity.setValue(0.0, forKey: "averageWordLength")
        statsEntity.setValue(Date(), forKey: "lastUpdated")
        statsEntity.setValue(Int16(week), forKey: "weekNumber")
        statsEntity.setValue(Int16(year), forKey: "year")
        
        do {
            try context.save()
            return statsEntity as? WeeklyStats
        } catch {
            print("Failed to save WeeklyStats: \(error)")
            return nil
        }
    }
    
    private func updateRunningAverage(currentAvg: Double, currentCount: Int, newValue: Double) -> Double {
        let newCount = currentCount + 1
        return ((currentAvg * Double(currentCount)) + newValue) / Double(newCount)
    }
    
    func updateStats(with analysis: DailyAnalysis) {
        let allTimeStats = fetchAllTimeStats() ?? createAllTimeStats()
        let monthlyStats = fetchCurrentMonthStats() ?? createMonthlyStats()
        let weeklyStats = fetchCurrentWeekStats() ?? createWeeklyStats()
        
        if let allTimeStats = allTimeStats {
            allTimeStats.averageWPM = updateRunningAverage(currentAvg: allTimeStats.averageWPM,
                                                            currentCount: Int(allTimeStats.dataPointCount),
                                                           newValue: analysis.aggregateMetrics.averageWPM)
            allTimeStats.averageDuration = updateRunningAverage(currentAvg: allTimeStats.averageDuration,
                                                                currentCount: Int(allTimeStats.dataPointCount),
                                                                newValue: analysis.aggregateMetrics.averageDuration)
            allTimeStats.averageWordCount = updateRunningAverage(currentAvg: allTimeStats.averageWordCount,
                                                                 currentCount: Int(allTimeStats.dataPointCount),
                                                                 newValue: analysis.aggregateMetrics.averageWordCount)
            allTimeStats.averageUniqueWordCount = updateRunningAverage(currentAvg: allTimeStats.averageUniqueWordCount,
                                                                       currentCount: Int(allTimeStats.dataPointCount),
                                                                       newValue: analysis.aggregateMetrics.averageUniqueWordCount)
            allTimeStats.averageSelfReferences = updateRunningAverage(currentAvg: allTimeStats.averageSelfReferences,
                                                                      currentCount: Int(allTimeStats.dataPointCount),
                                                                      newValue: analysis.aggregateMetrics.averageSelfReferences)
            allTimeStats.vocabularyDiversityRatio = updateRunningAverage(currentAvg: allTimeStats.vocabularyDiversityRatio,
                                                                         currentCount: Int(allTimeStats.dataPointCount),
                                                                         newValue: analysis.aggregateMetrics.vocabularyDiversityRatio)
            allTimeStats.averageWordLength = updateRunningAverage(currentAvg: allTimeStats.averageWordLength,
                                                                  currentCount: Int(allTimeStats.dataPointCount),
                                                                  newValue: analysis.loops.reduce(0.0) { $0 + $1.metrics.averageWordLength } / Double(analysis.loops.count))
            allTimeStats.dataPointCount += 1
            allTimeStats.lastUpdated = Date()
        }
        
        if let monthlyStats = monthlyStats {
            monthlyStats.averageWPM = updateRunningAverage(currentAvg: monthlyStats.averageWPM,
                                                           currentCount: Int(monthlyStats.dataPointCount),
                                                           newValue: analysis.aggregateMetrics.averageWPM)
            monthlyStats.averageDuration = updateRunningAverage(currentAvg: monthlyStats.averageDuration,
                                                                currentCount: Int(monthlyStats.dataPointCount),
                                                                newValue: analysis.aggregateMetrics.averageDuration)
            monthlyStats.averageWordCount = updateRunningAverage(currentAvg: monthlyStats.averageWordCount,
                                                                 currentCount: Int(monthlyStats.dataPointCount),
                                                                 newValue: analysis.aggregateMetrics.averageWordCount)
            monthlyStats.averageUniqueWordCount = updateRunningAverage(currentAvg: monthlyStats.averageUniqueWordCount,
                                                                       currentCount: Int(monthlyStats.dataPointCount),
                                                                       newValue: analysis.aggregateMetrics.averageUniqueWordCount)
            monthlyStats.averageSelfReferences = updateRunningAverage(currentAvg: monthlyStats.averageSelfReferences,
                                                                      currentCount: Int(monthlyStats.dataPointCount),
                                                                      newValue: analysis.aggregateMetrics.averageSelfReferences)
            monthlyStats.vocabularyDiversityRatio = updateRunningAverage(currentAvg: monthlyStats.vocabularyDiversityRatio,
                                                                         currentCount: Int(monthlyStats.dataPointCount),
                                                                         newValue: analysis.aggregateMetrics.vocabularyDiversityRatio)
            monthlyStats.averageWordLength = updateRunningAverage(currentAvg: monthlyStats.averageWordLength,
                                                                  currentCount: Int(monthlyStats.dataPointCount),
                                                                  newValue: analysis.loops.reduce(0.0) { $0 + $1.metrics.averageWordLength } / Double(analysis.loops.count))
            monthlyStats.dataPointCount += 1
            monthlyStats.lastUpdated = Date()
        }
        
        if let weeklyStats = weeklyStats {
            weeklyStats.averageWPM = updateRunningAverage(currentAvg: weeklyStats.averageWPM,
                                                          currentCount: Int(weeklyStats.dataPointCount),
                                                          newValue: analysis.aggregateMetrics.averageWPM)
            weeklyStats.averageDuration = updateRunningAverage(currentAvg: weeklyStats.averageDuration,
                                                               currentCount: Int(weeklyStats.dataPointCount),
                                                               newValue: analysis.aggregateMetrics.averageDuration)
            weeklyStats.averageWordCount = updateRunningAverage(currentAvg: weeklyStats.averageWordCount,
                                                                currentCount: Int(weeklyStats.dataPointCount),
                                                                newValue: analysis.aggregateMetrics.averageWordCount)
            weeklyStats.averageUniqueWordCount = updateRunningAverage(currentAvg: weeklyStats.averageUniqueWordCount,
                                                                      currentCount: Int(weeklyStats.dataPointCount),
                                                                      newValue: analysis.aggregateMetrics.averageUniqueWordCount)
            weeklyStats.averageSelfReferences = updateRunningAverage(currentAvg: weeklyStats.averageSelfReferences,
                                                                     currentCount: Int(weeklyStats.dataPointCount),
                                                                     newValue: analysis.aggregateMetrics.averageSelfReferences)
            weeklyStats.vocabularyDiversityRatio = updateRunningAverage(currentAvg: weeklyStats.vocabularyDiversityRatio,
                                                                        currentCount: Int(weeklyStats.dataPointCount),
                                                                        newValue: analysis.aggregateMetrics.vocabularyDiversityRatio)
            weeklyStats.averageWordLength = updateRunningAverage(currentAvg: weeklyStats.averageWordLength,
                                                                 currentCount: Int(weeklyStats.dataPointCount),
                                                                 newValue: analysis.loops.reduce(0.0) { $0 + $1.metrics.averageWordLength } / Double(analysis.loops.count))
            weeklyStats.dataPointCount += 1
            weeklyStats.lastUpdated = Date()
        }
        
        try? context.save()
    }
    
    func compareWithCurrentStats(_ analysis: DailyAnalysis) -> LoopComparison? {
        let allTimeStats = fetchAllTimeStats() ?? createAllTimeStats()
        let monthlyStats = fetchCurrentMonthStats()
        let weeklyStats = fetchCurrentWeekStats()
        
        func createComparison(current: Double, past: Double) -> MetricComparison {
            let percentChange = ((current - past) / past) * 100
            let direction: ComparisonDirection
            if abs(percentChange) < 1 {
                direction = .same
            } else if percentChange > 0 {
                direction = .increase
            } else {
                direction = .decrease
            }
            return MetricComparison(direction: direction, percentageChange: abs(percentChange))
        }
        
        if let allTimeStats = allTimeStats {
            return LoopComparison(
                date: analysis.date,
                pastLoopDate: allTimeStats.lastUpdated ?? Date(),
                durationComparison: createComparison(
                    current: analysis.aggregateMetrics.averageDuration,
                    past: allTimeStats.averageDuration
                ),
                wpmComparison: createComparison(
                    current: analysis.aggregateMetrics.averageWPM,
                    past: allTimeStats.averageWPM
                ),
                wordCountComparison: createComparison(
                    current: analysis.aggregateMetrics.averageWordCount,
                    past: allTimeStats.averageWordCount
                ),
                uniqueWordComparison: createComparison(
                    current: analysis.aggregateMetrics.averageUniqueWordCount,
                    past: allTimeStats.averageUniqueWordCount
                ),
                vocabularyDiversityComparison: createComparison(
                    current: analysis.aggregateMetrics.vocabularyDiversityRatio,
                    past: allTimeStats.vocabularyDiversityRatio
                ),
                averageWordLengthComparison: createComparison(
                    current: analysis.loops.reduce(0.0) { $0 + $1.metrics.averageWordLength } / Double(analysis.loops.count),
                    past: allTimeStats.averageWordLength
                ),
                selfReferenceComparison: createComparison(
                    current: analysis.aggregateMetrics.averageSelfReferences,
                    past: allTimeStats.averageSelfReferences
                ),
                similarityScore: 0,
                commonWords: []
            )
        }
        
        return nil
    }
    
    func compareWithAllTimeStats(_ analysis: DailyAnalysis) -> LoopComparison? {
        guard let allTimeStats = fetchAllTimeStats() else { return nil }
        
        func createComparison(current: Double, past: Double) -> MetricComparison {
            let percentChange = ((current - past) / past) * 100
            let direction: ComparisonDirection
            if abs(percentChange) < 1 {
                direction = .same
            } else if percentChange > 0 {
                direction = .increase
            } else {
                direction = .decrease
            }
            return MetricComparison(direction: direction, percentageChange: abs(percentChange))
        }
        
        return LoopComparison(
            date: analysis.date,
            pastLoopDate: allTimeStats.lastUpdated ?? Date(),
            durationComparison: createComparison(
                current: analysis.aggregateMetrics.averageDuration,
                past: allTimeStats.averageDuration
            ),
            wpmComparison: createComparison(
                current: analysis.aggregateMetrics.averageWPM,
                past: allTimeStats.averageWPM
            ),
            wordCountComparison: createComparison(
                current: analysis.aggregateMetrics.averageWordCount,
                past: allTimeStats.averageWordCount
            ),
            uniqueWordComparison: createComparison(
                current: analysis.aggregateMetrics.averageUniqueWordCount,
                past: allTimeStats.averageUniqueWordCount
            ),
            vocabularyDiversityComparison: createComparison(
                current: analysis.aggregateMetrics.vocabularyDiversityRatio,
                past: allTimeStats.vocabularyDiversityRatio
            ),
            averageWordLengthComparison: createComparison(
                current: analysis.loops.reduce(0.0) { $0 + $1.metrics.averageWordLength } / Double(analysis.loops.count),
                past: allTimeStats.averageWordLength
            ),
            selfReferenceComparison: createComparison(
                current: analysis.aggregateMetrics.averageSelfReferences,
                past: allTimeStats.averageSelfReferences
            ),
            similarityScore: 0,
            commonWords: []
        )
    }
    
    func compareWithMonthlyStats(_ analysis: DailyAnalysis) -> LoopComparison? {
        guard let monthlyStats = fetchCurrentMonthStats() else { return nil }
        
        func createComparison(current: Double, past: Double) -> MetricComparison {
            let percentChange = ((current - past) / past) * 100
            let direction: ComparisonDirection
            if abs(percentChange) < 1 {
                direction = .same
            } else if percentChange > 0 {
                direction = .increase
            } else {
                direction = .decrease
            }
            return MetricComparison(direction: direction, percentageChange: abs(percentChange))
        }
        
        return LoopComparison(
            date: analysis.date,
            pastLoopDate: monthlyStats.lastUpdated ?? Date(),
            durationComparison: createComparison(
                current: analysis.aggregateMetrics.averageDuration,
                past: monthlyStats.averageDuration
            ),
            wpmComparison: createComparison(
                current: analysis.aggregateMetrics.averageWPM,
                past: monthlyStats.averageWPM
            ),
            wordCountComparison: createComparison(
                current: analysis.aggregateMetrics.averageWordCount,
                past: monthlyStats.averageWordCount
            ),
            uniqueWordComparison: createComparison(
                current: analysis.aggregateMetrics.averageUniqueWordCount,
                past: monthlyStats.averageUniqueWordCount
            ),
            vocabularyDiversityComparison: createComparison(
                current: analysis.aggregateMetrics.vocabularyDiversityRatio,
                past: monthlyStats.vocabularyDiversityRatio
            ),
            averageWordLengthComparison: createComparison(
                current: analysis.loops.reduce(0.0) { $0 + $1.metrics.averageWordLength } / Double(analysis.loops.count),
                past: monthlyStats.averageWordLength
            ),
            selfReferenceComparison: createComparison(
                current: analysis.aggregateMetrics.averageSelfReferences,
                past: monthlyStats.averageSelfReferences
            ),
            similarityScore: 0,
            commonWords: []
        )
    }
    
    func compareWithWeeklyStats(_ analysis: DailyAnalysis) -> LoopComparison? {
        guard let weeklyStats = fetchCurrentWeekStats() else { return nil }
        
        func createComparison(current: Double, past: Double) -> MetricComparison {
            let percentChange = ((current - past) / past) * 100
            let direction: ComparisonDirection
            if abs(percentChange) < 1 {
                direction = .same
            } else if percentChange > 0 {
                direction = .increase
            } else {
                direction = .decrease
            }
            return MetricComparison(direction: direction, percentageChange: abs(percentChange))
        }
        
        return LoopComparison(
            date: analysis.date,
            pastLoopDate: weeklyStats.lastUpdated ?? Date(),
            durationComparison: createComparison(
                current: analysis.aggregateMetrics.averageDuration,
                past: weeklyStats.averageDuration
            ),
            wpmComparison: createComparison(
                current: analysis.aggregateMetrics.averageWPM,
                past: weeklyStats.averageWPM
            ),
            wordCountComparison: createComparison(
                current: analysis.aggregateMetrics.averageWordCount,
                past: weeklyStats.averageWordCount
            ),
            uniqueWordComparison: createComparison(
                current: analysis.aggregateMetrics.averageUniqueWordCount,
                past: weeklyStats.averageUniqueWordCount
            ),
            vocabularyDiversityComparison: createComparison(
                current: analysis.aggregateMetrics.vocabularyDiversityRatio,
                past: weeklyStats.vocabularyDiversityRatio
            ),
            averageWordLengthComparison: createComparison(
                current: analysis.loops.reduce(0.0) { $0 + $1.metrics.averageWordLength } / Double(analysis.loops.count),
                past: weeklyStats.averageWordLength
            ),
            selfReferenceComparison: createComparison(
                current: analysis.aggregateMetrics.averageSelfReferences,
                past: weeklyStats.averageSelfReferences
            ),
            similarityScore: 0,
            commonWords: []
        )
    }
}

class AIAnalyzer {
    static let shared = AIAnalyzer()
    
    private let apiKey: String
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    
    init(apiKey: String = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "") {
        self.apiKey = apiKey
    }
    
    func analyzeResponses(_ responses: [String]) async throws -> AIAnalysisResult {
        print("analyzing")
        
        let prompt = """
    Analyze these 3 responses:
    
    Response 1:
    \(responses[0])
    
    Response 2:
    \(responses[1])
    
    Response 3:
    \(responses[2])
    
    1. feeling: [adjective]
    2. description: [explain feeling in 2 detailed sentences addressing the user in the second person ("Your responses")]
    3. tense: [past/present/future]
    4. description: [explain tense briefly]
    5. self-references: [count of I/me/my]
    6. action-reflection: [%action/%reflection]
    7. description: [brief explanation of whether they're doing things or thinking about them]
    8. solution-focus: [problem%/solution%]
    9. description: [brief explanation of problem vs solution orientation]
    10. follow-up: [thoughtful question based on content]
    
    Format: label: answer
    Keep descriptions informal and brief.
    """
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": "You are an analyzer that responds in the exact format requested, no additional text."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.3,
            "max_tokens": 1000,
            "top_p": 0.1,
            "frequency_penalty": 0.0,
            "presence_penalty": 0.0
        ]
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        print("ai response \(data)")
        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        guard let content = response.choices.first?.message.content else {
            throw AnalysisError.aiAnalysisFailed
        }
        
        return try parseAIResponse(content)
    }
    
    private func parseAIResponse(_ response: String) throws -> AIAnalysisResult {
        let lines = response.components(separatedBy: .newlines)
        var feeling: String?
        var feelingDescription: String?
        var tense: String?
        var tenseDescription: String?
        var selfReferenceCount: Int?
        var followUp: String?
        var actionReflectionRatio: String?
        var actionReflectionDescription: String?
        var solutionFocus: String?
        var solutionFocusDescription: String?
        
        var currentSection = ""
        
        for line in lines {
            let lowercasedLine = line.lowercased()
            
            switch true {
            case lowercasedLine.starts(with: "1. feeling:"):
                currentSection = "feeling"
                feeling = line.replacing("1. feeling:", with: "").trimmingCharacters(in: .whitespaces)
            case lowercasedLine.starts(with: "2. description:") && currentSection == "feeling":
                feelingDescription = line.replacing("2. description:", with: "").trimmingCharacters(in: .whitespaces)
            case lowercasedLine.starts(with: "3. tense:"):
                currentSection = "tense"
                tense = line.replacing("3. tense:", with: "").trimmingCharacters(in: .whitespaces)
            case lowercasedLine.starts(with: "4. description:") && currentSection == "tense":
                tenseDescription = line.replacing("4. description:", with: "").trimmingCharacters(in: .whitespaces)
            case lowercasedLine.starts(with: "5. self-references:"):
                let countString = line.replacing("5. self-references:", with: "").trimmingCharacters(in: .whitespaces)
                selfReferenceCount = Int(countString) ?? 0
            case lowercasedLine.starts(with: "6. action-reflection:"):
                currentSection = "action"
                actionReflectionRatio = line.replacing("6. action-reflection:", with: "").trimmingCharacters(in: .whitespaces)
            case lowercasedLine.starts(with: "7. description:") && currentSection == "action":
                actionReflectionDescription = line.replacing("7. description:", with: "").trimmingCharacters(in: .whitespaces)
            case lowercasedLine.starts(with: "8. solution-focus:"):
                currentSection = "solution"
                solutionFocus = line.replacing("8. solution-focus:", with: "").trimmingCharacters(in: .whitespaces)
            case lowercasedLine.starts(with: "9. description:") && currentSection == "solution":
                solutionFocusDescription = line.replacing("9. description:", with: "").trimmingCharacters(in: .whitespaces)
            case lowercasedLine.starts(with: "10. follow-up:"):
                followUp = line.replacing("10. follow-up:", with: "").trimmingCharacters(in: .whitespaces)
            default:
                continue
            }
        }
        
        guard let feeling = feeling,
              let feelingDescription = feelingDescription,
              let tense = tense,
              let tenseDescription = tenseDescription,
              let selfReferenceCount = selfReferenceCount,
              let followUp = followUp,
              let actionReflectionRatio = actionReflectionRatio,
              let actionReflectionDescription = actionReflectionDescription,
              let solutionFocus = solutionFocus,
              let solutionFocusDescription = solutionFocusDescription else {
            throw AnalysisError.invalidAIResponse
        }
        
        return AIAnalysisResult(
            feeling: feeling,
            feelingDescription: feelingDescription,
            tense: tense,
            tenseDescription: tenseDescription,
            selfReferenceCount: selfReferenceCount,
            followUp: followUp,
            actionReflectionRatio: actionReflectionRatio,
            actionReflectionDescription: actionReflectionDescription,
            solutionFocus: solutionFocus,
            solutionFocusDescription: solutionFocusDescription
        )
    }
}

// Response models
private struct OpenAIResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let content: String
    }
}
