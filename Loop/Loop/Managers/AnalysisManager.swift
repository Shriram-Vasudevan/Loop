//
//  AnalysisManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 11/18/24.
//

import Foundation
import AVFoundation
import Speech
import CoreML
import NaturalLanguage


class AnalysisManager: ObservableObject {
    static let shared = AnalysisManager()
    
    @Published private(set) var currentDailyAnalysis: DailyAnalysis?
    @Published private(set) var isAnalyzing = false
    
    private let cacheManager = AnalysisCacheManager()
    private let tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType])
    private let tokenizer = NLTokenizer(unit: .word)
    
    init() {
        loadTodaysCachedAnalysis()
    }
    
    func loadTodaysCachedAnalysis() {
        let today = Calendar.current.startOfDay(for: Date())
        if let cached = cacheManager.loadAnalysis(for: today) {
            self.currentDailyAnalysis = cached
        }
    }
    
    func beginAnalysis(for loop: Loop) async throws -> PromptAnalysis {
        guard let fileURL = loop.data.fileURL else {
            throw AnalysisError.invalidFileURL
        }
        
        DispatchQueue.main.async { [self] in
            self.isAnalyzing = true
            do { isAnalyzing = false }
        }
        
        let transcript = try await transcribeAudio(url: fileURL)
        let duration = getAudioDuration(url: fileURL)
        let analysis = try await analyzePrompt(
            transcript: transcript,
            duration: duration,
            promptText: loop.promptText
        )
        
        await updateDailyAnalysis(with: analysis)
        
        return analysis
    }
    
    private func analyzePrompt(transcript: String, duration: TimeInterval, promptText: String) async throws -> PromptAnalysis {
        let words = tokenizer.tokenizeWords(transcript)
        let speakingPace = Double(words.count) / (duration / 60)
        
        let patterns = analyzeLanguagePatterns(transcript)
        let totalVerbs = Double(patterns.pastTense + patterns.futureTense)
        let pastTensePercentage = totalVerbs > 0 ? (Double(patterns.pastTense) / totalVerbs) * 100 : 0
        let futureTensePercentage = totalVerbs > 0 ? (Double(patterns.futureTense) / totalVerbs) * 100 : 0
        let selfReferencePercentage = (Double(patterns.selfReferences) / Double(words.count)) * 100
        
        let keywords = await extractMeaningfulKeywords(from: transcript)
        let names = extractNames(from: transcript)
        
        return PromptAnalysis(
            promptText: promptText,
            wordCount: words.count,
            duration: duration,
            speakingPace: speakingPace,
            pastTensePercentage: pastTensePercentage,
            futureTensePercentage: futureTensePercentage,
            selfReferencePercentage: selfReferencePercentage,
            keywords: keywords,
            names: names,
            timestamp: Date()
        )
    }
    
    @MainActor
    private func updateDailyAnalysis(with promptAnalysis: PromptAnalysis) {
        let today = Calendar.current.startOfDay(for: Date())
        
        if var existing = currentDailyAnalysis {
            existing.promptAnalyses.append(promptAnalysis)
            existing.isComplete = existing.promptAnalyses.count >= 3
            currentDailyAnalysis = existing
        } else {
            currentDailyAnalysis = DailyAnalysis(
                date: today,
                promptAnalyses: [promptAnalysis],
                isComplete: false
            )
        }
        
        if let analysis = currentDailyAnalysis {
            cacheManager.cacheAnalysis(analysis)
        }
    }
    
    private func analyzeLanguagePatterns(_ text: String) -> (pastTense: Int, futureTense: Int, selfReferences: Int) {
        var pastCount = 0
        var futureCount = 0
        var selfCount = 0
        
        let selfWords = Set(["i", "me", "my", "mine", "myself"])
        
        tagger.string = text.lowercased()
        let range = text.startIndex..<text.endIndex
        
        tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass) { tag, tokenRange in
            let word = text[tokenRange].lowercased()
            
            if let tag = tag {
                if tag == .verb {
                    if word.hasSuffix("ed") || word.hasSuffix("was") || word.hasSuffix("were") {
                        pastCount += 1
                    } else if word.hasPrefix("will") || word.contains("going to") || word.contains("gonna") {
                        futureCount += 1
                    }
                }
            }
            
            if selfWords.contains(word) {
                selfCount += 1
            }
            
            return true
        }
        
        return (pastCount, futureCount, selfCount)
    }
    
    private func extractMeaningfulKeywords(from text: String) async -> [String] {
        var keywords: [(String, Double)] = []
        let meaningfulTags: Set<NLTag> = [.noun, .verb, .adjective]
        let stopWords = Set([
            "am", "is", "are", "was", "were", "be", "have", "has", "had",
            "do", "does", "did", "will", "would", "should", "could", "might",
            "must", "and", "or", "but", "so", "because", "if", "when", "where",
            "what", "which", "who", "whom", "whose", "why", "how", "the", "a", "an",
            "this", "that", "these", "those", "like", "just", "get", "got", "getting",
            "think", "thought", "feel", "felt", "really", "actually", "basically",
            "literally", "very", "quite", "pretty", "kind", "sort"
        ])
        
        tagger.string = text.lowercased()
        let range = text.startIndex..<text.endIndex
        
        tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass, options: [.omitWhitespace, .omitPunctuation]) { tag, tokenRange in
            guard let tag = tag,
                  meaningfulTags.contains(tag) else { return true }
            
            let word = text[tokenRange].lowercased()
            guard word.count > 2,
                  !stopWords.contains(word),
                  !word.hasPrefix("http"),
                  !word.contains("@"),
                  !word.contains("#") else { return true }
            
            let score = calculateKeywordScore(word, tag: tag)
            keywords.append((word, score))
            
            return true
        }
        
        let sortedKeywords = keywords
            .sorted { $0.1 > $1.1 }
            .prefix(15)
            .map { $0.0 }
        
        return Array(Set(sortedKeywords))
    }
    
    private func calculateKeywordScore(_ word: String, tag: NLTag) -> Double {
        var score = 1.0
        
        let emotionalWords = Set([
            "happy", "sad", "angry", "excited", "worried", "proud",
            "anxious", "frustrated", "grateful", "passionate", "confused",
            "confident", "overwhelmed", "inspired", "disappointed"
        ])
        
        let reflectionWords = Set([
            "realize", "understand", "learn", "grow", "change",
            "reflect", "consider", "recognize", "acknowledge", "decide",
            "discover", "explore", "question", "wonder", "contemplate"
        ])
        
        let significantWords = Set([
            "important", "significant", "crucial", "essential", "critical",
            "major", "key", "fundamental", "vital", "primary",
            "central", "core", "main", "principal", "decisive"
        ])
        
        if emotionalWords.contains(word) {
            score += 1.5
        }
        
        if reflectionWords.contains(word) {
            score += 2.0
        }
        
        if significantWords.contains(word) {
            score += 1.0
        }
        
        switch tag {
        case .adjective:
            score *= 1.2
        case .verb:
            score *= 1.1
        case .noun:
            score *= 1.0
        default:
            score *= 0.8
        }
        
        score += Double(word.count) * 0.1
        
        return score
    }
    
    private func extractNames(from text: String) -> [String] {
        var names: [String] = []
        tagger.string = text
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: [.omitWhitespace, .omitPunctuation, .joinNames]) { tag, range in
            if tag == .personalName {
                let name = String(text[range])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .components(separatedBy: .whitespacesAndNewlines)
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                
                if !name.isEmpty {
                    names.append(name)
                }
            }
            return true
        }
        
        return Array(Set(names))
    }
    
    private func tokenizeWords(_ text: String) -> [String] {
        tokenizer.string = text
        return tokenizer.tokens(for: text.startIndex..<text.endIndex).map { String(text[$0]) }
    }
    
    private func getAudioDuration(url: URL) -> TimeInterval {
        let audioAsset = AVURLAsset(url: url)
        return CMTimeGetSeconds(audioAsset.duration)
    }
    
    private func transcribeAudio(url: URL) async throws -> String {
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        guard let recognizer = recognizer else {
            throw AnalysisError.transcriptionFailed
        }
        
        guard await SFSpeechRecognizer.hasAuthorizationToRecognize() else {
            throw AnalysisError.transcriptionNotAuthorized
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        request.taskHint = .dictation
        
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
}



enum AnalysisError: Error {
    case invalidFileURL
    case transcriptionFailed
    case transcriptionNotAuthorized
    case analysisFailure
}


class AnalysisCacheManager {
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    init() {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        cacheDirectory = documentsDirectory.appendingPathComponent("AnalysisCache")
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func cacheAnalysis(_ analysis: DailyAnalysis) {
        let fileName = getFileName(for: analysis.date)
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(analysis)
            try data.write(to: fileURL)
        } catch {
            print("Failed to cache analysis: \(error)")
        }
    }
    
    func loadAnalysis(for date: Date) -> DailyAnalysis? {
        let fileName = getFileName(for: date)
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            return try decoder.decode(DailyAnalysis.self, from: data)
        } catch {
            print("Failed to load cached analysis: \(error)")
            return nil
        }
    }
    
    private func getFileName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "analysis-\(formatter.string(from: date)).json"
    }
}
