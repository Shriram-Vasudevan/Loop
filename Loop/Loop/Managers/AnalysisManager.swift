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
    
    @Published var currentDailyAnalysis: DailyAnalysis?
    @Published var isAnalyzing = false
    
    private let tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType])
    private let tokenizer = NLTokenizer(unit: .word)
        
    func beginAnalysis(for loop: Loop) async throws {
        guard let fileURL = loop.data.fileURL else {
            throw AnalysisError.invalidFileURL
        }
        
        if currentDailyAnalysis == nil {
            currentDailyAnalysis = DailyAnalysis(date: Date())
        }

        if !currentDailyAnalysis!.prompts.contains(loop.promptText) {
            currentDailyAnalysis!.prompts.append(loop.promptText)
        }
        
        let transcript = try await transcribeAudio(url: fileURL)
       
        await analyzeLoop(transcript: transcript, duration: getAudioDuration(url: fileURL))
    }
    
    private func analyzeLoop(transcript: String, duration: TimeInterval) async {
        guard var analysis = currentDailyAnalysis else { return }
        
        analysis.completedLoopCount += 1

        analysis.totalDuration += duration
        let words = tokenizer.tokenizeWords(transcript)
        analysis.totalWordCount += words.count
        
        let minutesDuration = duration / 60
        let currentPace = Double(words.count) / minutesDuration
        analysis.averageSpeakingPace = ((analysis.averageSpeakingPace * Double(analysis.completedLoopCount - 1)) + currentPace) / Double(analysis.completedLoopCount)

        let patterns = analyzeLanguagePatterns(transcript)
        let past = patterns.pastTense
        let future = patterns.futureTense
        let selfRefs = patterns.selfReferences
        
        let totalVerbs = Double(past + future)
        if totalVerbs > 0 {
            analysis.pastTensePercentage = (analysis.pastTensePercentage * Double(analysis.completedLoopCount - 1) + (Double(past) / totalVerbs)) / Double(analysis.completedLoopCount)
            analysis.futureTensePercentage = (analysis.futureTensePercentage * Double(analysis.completedLoopCount - 1) + (Double(future) / totalVerbs)) / Double(analysis.completedLoopCount)
        }
        
        let previousAverage = analysis.selfReferencePercentage * Double(analysis.completedLoopCount - 1)
        let currentRatio = Double(selfRefs) / Double(words.count)
        analysis.selfReferencePercentage = (previousAverage + currentRatio) / Double(analysis.completedLoopCount)

        let newKeywords = await extractMeaningfulKeywords(from: transcript)
        analysis.keywords = Array(Set(analysis.keywords + newKeywords))
        
        let newNames = extractNames(from: transcript)
        analysis.names = Array(Set(analysis.names + newNames))
    
        if analysis.completedLoopCount == 3 {
            analysis.isComplete = true
        }
        
        DispatchQueue.main.sync {
            self.currentDailyAnalysis = analysis
        }
    }
    
    private func tokenizeWords(_ text: String) -> [String] {
        tokenizer.string = text
        return tokenizer.tokens(for: text.startIndex..<text.endIndex).map { String(text[$0]) }
    }
    
    private func analyzeLanguagePatterns(_ text: String) -> (pastTense: Int, futureTense: Int, selfReferences: Int) {
        var pastCount = 0
        var futureCount = 0
        var selfCount = 0
        
        let selfWords = Set(["i", "me", "my", "mine", "myself"])
        
        tagger.string = text
        let range = text.startIndex..<text.endIndex
        
        tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass) { tag, tokenRange in
            let word = text[tokenRange].lowercased()
            
            if let tag = tag {
                if tag == .verb {
                    if word.hasSuffix("ed") || word.hasSuffix("was") || word.hasSuffix("were") {
                        pastCount += 1
                    } else if word.hasPrefix("will") || word.hasPrefix("going") {
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
        let tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType])
        tagger.string = text
        
        let meaningfulTags: Set<NLTag> = [.noun, .verb, .adjective]
        let stopWords = Set(["am", "is", "are", "was", "were", "be", "have", "has", "had",
                           "do", "does", "did", "will", "would", "should", "could", "might",
                           "must", "and", "or", "but", "so", "because", "if", "when", "where",
                           "what", "which", "who", "whom", "whose", "why", "how"])
        
        var keywords: [(String, Double)] = []
        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation]
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, range in
            guard let tag = tag,
                  meaningfulTags.contains(tag) else { return true }
            
            let word = text[range].lowercased()
            guard word.count > 2,
                  !stopWords.contains(word) else { return true }

            let contextRange = getContextRange(around: range, in: text)
            let context = String(text[contextRange])

            let score = scoreWordImportance(word, in: context)
            keywords.append((word, score))
            
            return true
        }
        
        // Sort by score and take top results
        return keywords
            .sorted { $0.1 > $1.1 }
            .prefix(10)
            .map { $0.0 }
    }
    
    private func scoreWordImportance(_ word: String, in context: String) -> Double {
        var score = 1.0
        
        // Increase score for words that:
        // 1. Are part of meaningful phrases
        if context.contains("feel") || context.contains("think") {
            score += 0.5
        }
        
        // 2. Are associated with reflection
        let reflectionWords = Set(["realize", "understand", "learn", "grow", "change"])
        if reflectionWords.contains(word) {
            score += 1.0
        }
        
        // 3. Are associated with emotions or experiences
        let emotionalWords = Set(["happy", "sad", "angry", "excited", "worried", "proud"])
        if emotionalWords.contains(word) {
            score += 0.8
        }
        
        return score
    }
    
    private func extractNames(from text: String) -> [String] {
        tagger.string = text
        var names: [String] = []
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: [.omitWhitespace, .omitPunctuation]) { tag, range in
            if tag == .personalName {
                names.append(String(text[range]))
            }
            return true
        }
        
        return names
    }
    
    private func getContextRange(around range: Range<String.Index>, in text: String) -> Range<String.Index> {
        let contextWords = 5
        var start = range.lowerBound
        var end = range.upperBound
        
        let contextRange = { (range: Range<String.Index>, text: String) -> Range<String.Index> in
            let contextWords = 5
            let start = max(text.startIndex, text.index(range.lowerBound, offsetBy: -contextWords))
            let end = min(text.endIndex, text.index(range.upperBound, offsetBy: contextWords))
            return start..<end
        }
        
        return start..<end
    }
    
    private func getAudioDuration(url: URL) -> TimeInterval {
        let asset = AVAsset(url: url)
        return CMTimeGetSeconds(asset.duration)
    }
    
    private func transcribeAudio(url: URL) async throws -> String {
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: url)
        
        return try await withCheckedThrowingContinuation { continuation in
            recognizer?.recognitionTask(with: request) { result, error in
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
    case analysisFailure
}

extension NLTokenizer {
    func tokenizeWords(_ text: String) -> [String] {
        self.string = text
        return self.tokens(for: text.startIndex..<text.endIndex).map { String(text[$0]) }
    }
}

