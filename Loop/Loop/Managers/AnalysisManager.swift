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

enum TranscriptionError: Error {
    case authorizationFailed
    case recognizerUnavailable
    case transcriptionFailed(String)
}

class AudioAnalyzer {
    static let shared = AudioAnalyzer()
    
    func transcribeAudio(url: URL) async throws -> String {
        let authStatus = SFSpeechRecognizer.authorizationStatus()
        print("Speech recognition authorization status: \(authStatus.rawValue)")
        
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        print("Recognizer exists: \(recognizer != nil)")
        
        guard let recognizer = recognizer else {
            print("Failed to create recognizer")
            throw AnalysisError.transcriptionFailed
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        
        // Check the audio file
        let asset = AVURLAsset(url: url)
        print("Audio URL: \(url)")
        print("Audio file exists: \(FileManager.default.fileExists(atPath: url.path))")
        print("Audio duration: \(CMTimeGetSeconds(asset.duration))")
        
        print("Starting transcription")
        
        return try await withCheckedThrowingContinuation { continuation in
            // Create task
            let task = recognizer.recognitionTask(with: request) { result, error in
                if let error = error as NSError? {
                    print("Transcription error:")
                    print("Domain: \(error.domain)")
                    print("Code: \(error.code)")
                    print("Description: \(error.localizedDescription)")
                    print("User Info: \(error.userInfo)")
                    
                    continuation.resume(throwing: error)
                } else if let result = result, result.isFinal {
                    print("Transcription completed successfully with text length: \(result.bestTranscription.formattedString.count)")
                    continuation.resume(returning: result.bestTranscription.formattedString)
                }
            }
            
            if task == nil {
                print("Failed to create recognition task")
                continuation.resume(throwing: AnalysisError.transcriptionFailed)
            } else {
                print("Recognition task created successfully")
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
    
    
    @Published var analysisError: AnalysisError?
    private var analysisTimer: Timer?
    
    @Published private(set) var isFollowUpCompletedToday: Bool = false
    
    @Published private(set) var analysisState: AnalysisState = .noLoops
    
    init() {
        if isCacheValidForToday() {
            loadAnalysisCache()
            isFollowUpCompletedToday = UserDefaults.standard.bool(forKey: "FollowUpCompletedToday")
        } else {
            resetAnalysisCache()
        }
    }
    
    func startAnalysis(_ loop: Loop, isPastLoop: Bool) async {
        if !isPastLoop {
            // If this is first loop, move to partial state
            if todaysLoops.isEmpty {
                DispatchQueue.main.async {
                    self.analysisState = .partial(count: 1)
                }
            }
        }
        
        do {
            DispatchQueue.main.async {
                self.analysisState = .transcribing
            }
            
            let analysis = try await analyzeLoop(loop)
            
            if isPastLoop {
                pastLoopAnalysis = analysis
                self.loopComparison = compareWithPastLoop()
            } else {
                todaysLoops.append(analysis)
                
                if todaysLoops.count < 3 {
                    DispatchQueue.main.async {
                        self.analysisState = .partial(count: self.todaysLoops.count)
                    }
                    saveAnalysisCache()
                } else {
                    print("reached three loops analyzed")
                    
                    Task {
                        DispatchQueue.main.async {
                            self.analysisState = .analyzing
                        }
                        
                        startAnalysisWithTimeout()
                        
                        DispatchQueue.main.async {
                            self.analysisState = .analyzing_ai
                        }
                        
                        let dailyAnalysis = await createDailyAnalysis(todaysLoops)
                        
                        DispatchQueue.main.async {
                            self.currentDailyAnalysis = dailyAnalysis
                            self.analysisState = .completed(dailyAnalysis)
                            
                            self.allTimeComparison = self.statsManager.compareWithAllTimeStats(dailyAnalysis)
                            self.monthlyComparison = self.statsManager.compareWithMonthlyStats(dailyAnalysis)
                            self.weeklyComparison = self.statsManager.compareWithWeeklyStats(dailyAnalysis)
                            
                            self.statsManager.updateStats(with: dailyAnalysis)
                            
                            self.saveDailyStats()
                            self.saveAnalysisCache()
                        }
                    }
                }
            }
        } catch {
            print("Analysis error: \(error)")
            DispatchQueue.main.async {
                if let analysisError = error as? AnalysisError {
                    self.analysisState = .failed(analysisError)
                } else {
                    self.analysisState = .failed(.analysisFailure)
                }
            }
        }
    }
        
    
    func analyzeLoop(_ loop: Loop) async throws -> LoopAnalysis {
        guard let fileURL = loop.data.fileURL else {
            throw AnalysisError.invalidData
        }
        
        do {
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
        } catch {
            throw AnalysisError.invalidData
        }
    }
    
    private func createDailyAnalysis(_ loops: [LoopAnalysis]) async -> DailyAnalysis {
        let aggregateMetrics = calculateAggregateMetrics(loops)
        let wordPatterns = analyzeWordPatterns(loops)
        let overlapAnalysis = analyzeOverlap(loops)
        let rangeAnalysis = calculateRanges(loops)
        
        let transcripts = loops.map { $0.transcript }
        
        DispatchQueue.main.async {
            self.analysisState = .analyzing_ai
        }
        
        let aiAnalysis = try? await AIAnalyzer.shared.analyzeResponses(transcripts)
        
        if aiAnalysis == nil {
            DispatchQueue.main.async {
                self.analysisState = .failed(.aiAnalysisFailed)
            }
        }
        
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
        var analysisData: [String: Any] = [
            "lastAnalysisDate": Date(),
            "cacheDate": Date()
        ]
        
        if case .completed(let analysis) = analysisState {
            if let dailyAnalysisData = try? JSONEncoder().encode(analysis) {
                analysisData["dailyAnalysis"] = dailyAnalysisData.base64EncodedString()
            }
        }
        
        if let dailyAnalysisData = try? JSONEncoder().encode(currentDailyAnalysis) {
            analysisData["dailyAnalysis"] = dailyAnalysisData.base64EncodedString()
        }
        
        if let todaysLoopsData = try? JSONEncoder().encode(todaysLoops) {
            analysisData["todaysLoops"] = todaysLoopsData.base64EncodedString()
        }
        
        if let pastLoopData = try? JSONEncoder().encode(pastLoopAnalysis) {
            analysisData["pastLoopAnalysis"] = pastLoopData.base64EncodedString()
        }
        
        if let comparisonData = try? JSONEncoder().encode(loopComparison) {
            analysisData["loopComparison"] = comparisonData.base64EncodedString()
        }
        
        if let allTimeComparisonData = try? JSONEncoder().encode(allTimeComparison) {
            analysisData["allTimeComparison"] = allTimeComparisonData.base64EncodedString()
        }
        
        if let monthlyComparisonData = try? JSONEncoder().encode(monthlyComparison) {
            analysisData["monthlyComparison"] = monthlyComparisonData.base64EncodedString()
        }
        
        if let weeklyComparisonData = try? JSONEncoder().encode(weeklyComparison) {
            analysisData["weeklyComparison"] = weeklyComparisonData.base64EncodedString()
        }
        
        analysisCache.set(analysisData, forKey: dailyAnalysisCacheKey)
    }
    
    private func loadAnalysisCache() {
        guard let cachedData = analysisCache.dictionary(forKey: dailyAnalysisCacheKey) else {
            return
        }
        
        if let dailyAnalysisString = cachedData["dailyAnalysis"] as? String,
           let dailyAnalysisData = Data(base64Encoded: dailyAnalysisString),
           let dailyAnalysis = try? JSONDecoder().decode(DailyAnalysis.self, from: dailyAnalysisData) {
            self.currentDailyAnalysis = dailyAnalysis
        }
        
        if let todaysLoopsString = cachedData["todaysLoops"] as? String,
           let todaysLoopsData = Data(base64Encoded: todaysLoopsString),
           let loopAnalyses = try? JSONDecoder().decode([LoopAnalysis].self, from: todaysLoopsData) {
            self.todaysLoops = loopAnalyses
        }
        
        if let pastLoopString = cachedData["pastLoopAnalysis"] as? String,
           let pastLoopData = Data(base64Encoded: pastLoopString),
           let pastAnalysis = try? JSONDecoder().decode(LoopAnalysis.self, from: pastLoopData) {
            self.pastLoopAnalysis = pastAnalysis
        }
        
        if let comparisonString = cachedData["loopComparison"] as? String,
           let comparisonData = Data(base64Encoded: comparisonString),
           let comparison = try? JSONDecoder().decode(LoopComparison.self, from: comparisonData) {
            self.loopComparison = comparison
        }
        
        if let allTimeComparisonString = cachedData["allTimeComparison"] as? String,
           let allTimeComparisonData = Data(base64Encoded: allTimeComparisonString),
           let allTimeComparison = try? JSONDecoder().decode(LoopComparison.self, from: allTimeComparisonData) {
            self.allTimeComparison = allTimeComparison
        }
        
        if let monthlyComparisonString = cachedData["monthlyComparison"] as? String,
           let monthlyComparisonData = Data(base64Encoded: monthlyComparisonString),
           let monthlyComparison = try? JSONDecoder().decode(LoopComparison.self, from: monthlyComparisonData) {
            self.monthlyComparison = monthlyComparison
        }
        
        if let weeklyComparisonString = cachedData["weeklyComparison"] as? String,
           let weeklyComparisonData = Data(base64Encoded: weeklyComparisonString),
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
        isFollowUpCompletedToday = false
        UserDefaults.standard.removeObject(forKey: "FollowUpCompletedToday")
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
        
        guard let entity = NSEntityDescription.entity(forEntityName: "DailyStatsEntity", in: statsManager.context) else {
            print("Failed to get DailyStatsEntity")
            return
        }
        
        let statsEntity = NSManagedObject(entity: entity, insertInto: statsManager.context)
        print("Created new stats entity")
        
        // Set basic info
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
        statsEntity.setValue(analysis.aggregateMetrics.averageUniqueWordCount, forKey: "averageUniqueWordCount")
        statsEntity.setValue(analysis.aggregateMetrics.averageSelfReferences, forKey: "averageSelfReferences")
        statsEntity.setValue(analysis.aggregateMetrics.vocabularyDiversityRatio, forKey: "vocabularyDiversityRatio")

        statsEntity.setValue(Int16(analysis.loops.count), forKey: "loopCount")
        statsEntity.setValue(analysis.loops.reduce(0.0) { $0 + $1.metrics.averageWordLength } / Double(analysis.loops.count), forKey: "averageWordLength")
        statsEntity.setValue(Date(), forKey: "lastUpdated")
        
        print("Set all values on stats entity")
        print("Date being saved: \(analysis.date)")
        print("Average WPM being saved: \(analysis.aggregateMetrics.averageWPM)")
        
        do {
            try statsManager.context.save()
            print("Successfully saved daily stats to Core Data")
            
            // Verify save by immediately fetching
            let request = NSFetchRequest<NSManagedObject>(entityName: "DailyStatsEntity")
            let results = try statsManager.context.fetch(request)
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
            let results = try statsManager.context.fetch(request)
            print("📊 Found \(results.count) entries for current week")
            
            // Debug info for each entry
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
        
        // Debug the actual query
        print("🔍 Query predicate: year == \(year) AND weekNumber >= \(firstWeek) AND weekNumber <= \(lastWeek)")
        
        do {
            let results = try statsManager.context.fetch(request)
            print("\n📊 Weekly stats query results:")
            print("Found \(results.count) entries")
            
            // Debug each result before conversion
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
           let results = try statsManager.context.fetch(request)
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
            averageSelfReferences: entity.value(forKey: "averageSelfReferences") as? Double ?? 0,
            vocabularyDiversityRatio: entity.value(forKey: "vocabularyDiversityRatio") as? Double ?? 0,
            averageWordLength: entity.value(forKey: "averageWordLength") as? Double ?? 0,
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
           averageSelfReferences: entity.value(forKey: "averageSelfReferences") as? Double ?? 0,
           vocabularyDiversityRatio: entity.value(forKey: "vocabularyDiversityRatio") as? Double ?? 0,
           averageWordLength: entity.value(forKey: "averageWordLength") as? Double ?? 0,
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
           averageSelfReferences: entity.value(forKey: "averageSelfReferences") as? Double ?? 0,
           vocabularyDiversityRatio: entity.value(forKey: "vocabularyDiversityRatio") as? Double ?? 0,
           averageWordLength: entity.value(forKey: "averageWordLength") as? Double ?? 0,
           lastUpdated: entity.value(forKey: "lastUpdated") as? Date,
           weekNumber: weekNumber,
           year: year
       )
    }

    func startAnalysisWithTimeout() {
        analysisTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
            self?.handleTimeout()
        }
    }
    
    private func handleTimeout() {
        DispatchQueue.main.async {
            self.analysisError = .analysisFailure
            if let currentAnalysis = self.currentDailyAnalysis {
                let fallbackAnalysis = DailyAnalysis(
                    date: currentAnalysis.date,
                    loops: currentAnalysis.loops,
                    aggregateMetrics: currentAnalysis.aggregateMetrics,
                    wordPatterns: currentAnalysis.wordPatterns,
                    overlapAnalysis: currentAnalysis.overlapAnalysis,
                    rangeAnalysis: currentAnalysis.rangeAnalysis,
                    aiAnalysis: nil
                )
                self.currentDailyAnalysis = fallbackAnalysis
            }
        }
    }
}
    


