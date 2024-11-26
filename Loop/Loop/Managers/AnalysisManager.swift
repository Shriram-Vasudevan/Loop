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


struct EmotionAnalysis: Codable {
    let emotionalWords: [String: Double]
    let overallSentiment: Double
    let primaryEmotions: [String]
    let emotionalIntensity: Double
    let emotionalComplexity: Int
}

struct SpeechPatternAnalysis: Codable {
    let wordsPerMinute: Double
    let pauseCount: Int
    let averagePauseDuration: Double
    let longestPause: Double
    let speechFlowScore: Double
    let articulationRate: Double
}

struct CognitiveAnalysis: Codable {
    let analyticalScore: Double
    let insightWords: [String]
    let complexityScore: Double
    let qualifierFrequency: Double
    let causalityScore: Double
    let discrepancyWords: [String]
}

struct SelfReferenceAnalysis: Codable {
    let selfReferences: Int
    let selfReferencePercentage: Double
    let otherReferences: Int
    let pastTensePercentage: Double
    let presentTensePercentage: Double
    let futureTensePercentage: Double
    let activeVoicePercentage: Double
}

struct ThematicAnalysis: Codable {
    let keyTopics: [String: Double]
    let significantPhrases: [String]
    let namedEntities: [String]
    let contextualKeywords: [String: Double]
    let topicCoherence: Double
}

struct LoopAnalysis: Codable {
    let loopId: String
    let timestamp: Date
    let emotion: EmotionAnalysis
    let speechPattern: SpeechPatternAnalysis
    let cognitive: CognitiveAnalysis
    let selfReference: SelfReferenceAnalysis
    let thematic: ThematicAnalysis
}

struct SessionStatistics: Codable {
    var averageWordsPerMinute: Double
    var averageEmotionalIntensity: Double
    var averageComplexityScore: Double
    var averageSelfReferencePercentage: Double
    var dominantEmotions: [String]
    var commonTopics: [String]
    var analysisCount: Int
}

class EmotionAnalyzer {
    private let emotionLexicon: [String: Double] = [
        "happy": 0.8, "sad": -0.7, "angry": -0.8, "excited": 0.9,
        "worried": -0.6, "proud": 0.7, "anxious": -0.6, "frustrated": -0.7,
        "grateful": 0.8, "passionate": 0.8, "confused": -0.4, "confident": 0.7,
        "overwhelmed": -0.5, "inspired": 0.9, "disappointed": -0.6,
        "joyful": 0.9, "depressed": -0.8, "furious": -0.9, "thrilled": 0.9,
        "nervous": -0.5, "accomplished": 0.8, "fearful": -0.7, "irritated": -0.6,
        "thankful": 0.8, "enthusiastic": 0.8, "uncertain": -0.4, "assured": 0.6,
        "stressed": -0.7, "motivated": 0.8, "discouraged": -0.6
    ]
    
    private let intensifiers: Set<String> = [
        "very", "extremely", "incredibly", "absolutely", "completely",
        "totally", "utterly", "really", "quite", "particularly",
        "especially", "remarkably", "notably", "decidedly", "truly"
    ]
    
    func analyze(_ text: String) -> EmotionAnalysis {
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        var emotionalWords: [String: Double] = [:]
        var intensity = 0.0
        var complexity = 0
        var overallSentiment = 0.0
        
        for (index, word) in words.enumerated() {
            if let emotionScore = emotionLexicon[word] {
                let contextScore = calculateContextScore(words: words, currentIndex: index)
                emotionalWords[word] = emotionScore * contextScore
                overallSentiment += emotionScore * contextScore
                complexity += 1
            }
            
            if intensifiers.contains(word) {
                intensity += 0.5
            }
        }
        
        let primaryEmotions = emotionalWords
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }
        
        return EmotionAnalysis(
            emotionalWords: emotionalWords,
            overallSentiment: overallSentiment / Double(max(1, emotionalWords.count)),
            primaryEmotions: primaryEmotions,
            emotionalIntensity: intensity,
            emotionalComplexity: complexity
        )
    }
    
    private func calculateContextScore(words: [String], currentIndex: Int) -> Double {
        var score = 1.0
        let window = 2
        let start = max(0, currentIndex - window)
        let end = min(words.count - 1, currentIndex + window)
        
        for i in start...end {
            if i != currentIndex && intensifiers.contains(words[i]) {
                score += 0.3
            }
        }
        
        return score
    }
}

class SpeechPatternAnalyzer {
    func analyze(audioURL: URL, transcript: String) async -> SpeechPatternAnalysis {
        let words = transcript.components(separatedBy: .whitespacesAndNewlines)
        let duration = getAudioDuration(url: audioURL)
        let wordsPerMinute = calculateWordsPerMinute(wordCount: words.count, duration: duration)
        let pauseAnalysis = await analyzePauses(audioURL: audioURL)
        
        return SpeechPatternAnalysis(
            wordsPerMinute: wordsPerMinute,
            pauseCount: pauseAnalysis.count,
            averagePauseDuration: pauseAnalysis.average,
            longestPause: pauseAnalysis.longest,
            speechFlowScore: calculateFlowScore(wpm: wordsPerMinute, pauseAnalysis: pauseAnalysis),
            articulationRate: calculateArticulationRate(wordCount: words.count, duration: duration, totalPauseDuration: pauseAnalysis.total)
        )
    }
    
    private func getAudioDuration(url: URL) -> TimeInterval {
        let audioAsset = AVURLAsset(url: url)
        return CMTimeGetSeconds(audioAsset.duration)
    }
    
    private func calculateWordsPerMinute(wordCount: Int, duration: TimeInterval) -> Double {
        return Double(wordCount) / (duration / 60.0)
    }
    
    private func analyzePauses(audioURL: URL) async -> (count: Int, average: Double, longest: Double, total: Double) {
        let threshold = -50.0
        let asset = AVAsset(url: audioURL)
        var pauseCount = 0
        var totalPauseDuration = 0.0
        var longestPause = 0.0
        
        guard let audioTrack = try? await asset.loadTracks(withMediaType: .audio).first else {
            return (0, 0, 0, 0)
        }
        
        let audioFormat = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1
        ] as [String: Any]
        
        guard let reader = try? AVAssetReader(asset: asset),
              let output = try? AVAssetReaderTrackOutput(track: audioTrack, outputSettings: audioFormat) else {
            return (0, 0, 0, 0)
        }
        
        reader.add(output)
        reader.startReading()
        
        while let sampleBuffer = output.copyNextSampleBuffer() {
            let cmTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            let time = CMTimeGetSeconds(cmTime)
            
            guard let channelData = readAudioBuffer(from: sampleBuffer) else { continue }
            
            if channelData < Float(threshold) {
                pauseCount += 1
                let pauseDuration = time
                totalPauseDuration += pauseDuration
                longestPause = max(longestPause, pauseDuration)
            }
        }
        
        return (pauseCount, totalPauseDuration / Double(max(1, pauseCount)), longestPause, totalPauseDuration)
    }
    
    private func readAudioBuffer(from sampleBuffer: CMSampleBuffer) -> Float? {
        guard let audioBufferList = sampleBuffer.audioBufferList,
              let data = audioBufferList.mBuffers.mData else {
            return nil
        }
        
        let buffer = data.assumingMemoryBound(to: Float.self)
        let size = Int(audioBufferList.mBuffers.mDataByteSize) / MemoryLayout<Float>.size
        let samples = Array(UnsafeBufferPointer(start: buffer, count: size))
        
        // Calculate RMS (Root Mean Square) of the samples
        let rms = sqrt(samples.map { $0 * $0 }.reduce(0, +) / Float(samples.count))
        return 20 * log10(rms) // Convert to dB
    }
    
    private func calculateFlowScore(wpm: Double, pauseAnalysis: (count: Int, average: Double, longest: Double, total: Double)) -> Double {
        let optimalWPM = 130.0
        let wpmScore = 1.0 - abs(wpm - optimalWPM) / optimalWPM
        let pauseScore = 1.0 - (Double(pauseAnalysis.count) * pauseAnalysis.average / 30.0)
        return (wpmScore + pauseScore) / 2.0
    }
    
    private func calculateArticulationRate(wordCount: Int, duration: TimeInterval, totalPauseDuration: Double) -> Double {
        let speechDuration = duration - totalPauseDuration
        return Double(wordCount) / speechDuration
    }
}

class CognitiveAnalyzer {
    private let insightWords: Set<String> = [
        "realize", "understand", "learn", "discover", "recognize",
        "comprehend", "conclude", "determine", "notice", "grasp",
        "appreciate", "acknowledge", "perceive", "deduce", "infer"
    ]
    
    private let causalWords: Set<String> = [
        "because", "therefore", "consequently", "thus", "hence",
        "since", "due", "result", "cause", "effect",
        "leads", "impacts", "influences", "affects", "determines"
    ]
    
    private let qualifiers: Set<String> = [
        "maybe", "perhaps", "possibly", "probably", "likely",
        "seemingly", "apparently", "presumably", "generally", "typically",
        "usually", "often", "sometimes", "occasionally", "rarely"
    ]
    
    private let discrepancyWords: Set<String> = [
        "should", "would", "could", "might", "must",
        "ought", "need", "want", "desire", "wish",
        "hope", "expect", "anticipate", "plan", "intend"
    ]
    
    func analyze(_ text: String) -> CognitiveAnalysis {
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let wordCount = Double(words.count)
        
        var insightCount = 0
        var causalCount = 0
        var qualifierCount = 0
        var discrepancyCount = 0
        var foundInsightWords: [String] = []
        var foundDiscrepancyWords: [String] = []
        
        for word in words {
            if insightWords.contains(word) {
                insightCount += 1
                foundInsightWords.append(word)
            }
            if causalWords.contains(word) {
                causalCount += 1
            }
            if qualifiers.contains(word) {
                qualifierCount += 1
            }
            if discrepancyWords.contains(word) {
                discrepancyCount += 1
                foundDiscrepancyWords.append(word)
            }
        }
        
        let analyticalScore = calculateAnalyticalScore(
            causalCount: causalCount,
            insightCount: insightCount,
            wordCount: wordCount
        )
        
        let complexityScore = calculateComplexityScore(
            text: text,
            qualifierCount: qualifierCount,
            wordCount: wordCount
        )
        
        return CognitiveAnalysis(
            analyticalScore: analyticalScore,
            insightWords: Array(Set(foundInsightWords)),
            complexityScore: complexityScore,
            qualifierFrequency: Double(qualifierCount) / wordCount,
            causalityScore: Double(causalCount) / wordCount,
            discrepancyWords: Array(Set(foundDiscrepancyWords))
        )
    }
    
    private func calculateAnalyticalScore(causalCount: Int, insightCount: Int, wordCount: Double) -> Double {
        let causalWeight = 0.4
        let insightWeight = 0.6
        
        let causalScore = Double(causalCount) / wordCount
        let insightScore = Double(insightCount) / wordCount
        
        return (causalScore * causalWeight + insightScore * insightWeight) * 100
    }
    
    private func calculateComplexityScore(text: String, qualifierCount: Int, wordCount: Double) -> Double {
        let sentences = text.components(separatedBy: ".").filter { !$0.isEmpty }
        let avgWordsPerSentence = wordCount / Double(sentences.count)
        let qualifierDensity = Double(qualifierCount) / wordCount
        
        let baseScore = (avgWordsPerSentence / 20.0) * 50.0
        let qualifierScore = qualifierDensity * 50.0
        
        return min(100, baseScore + qualifierScore)
    }
}

class SelfReferenceAnalyzer {
    private let tagger = NLTagger(tagSchemes: [.lexicalClass])
    
    private let selfReferenceWords: Set<String> = [
        "i", "me", "my", "mine", "myself",
        "we", "us", "our", "ours", "ourselves"
    ]
    
    private let otherReferenceWords: Set<String> = [
        "he", "him", "his", "himself",
        "she", "her", "hers", "herself",
        "they", "them", "their", "theirs", "themselves",
        "you", "your", "yours", "yourself", "yourselves"
    ]
    
    func analyze(_ text: String) -> SelfReferenceAnalysis {
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let wordCount = Double(words.count)
        
        var selfRefs = 0
        var otherRefs = 0
        var pastTense = 0
        var presentTense = 0
        var futureTense = 0
        var activeVoice = 0
        var totalVerbs = 0
        
        tagger.string = text
        let range = text.startIndex..<text.endIndex
        
        tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass) { tag, tokenRange in
            let word = String(text[tokenRange]).lowercased()
                        
    if selfReferenceWords.contains(word) {
        selfRefs += 1
    } else if otherReferenceWords.contains(word) {
        otherRefs += 1
    }
    
    if tag == .verb {
        totalVerbs += 1
        if word.hasSuffix("ed") {
            pastTense += 1
        } else if word.hasPrefix("will") || word.contains("going to") {
            futureTense += 1
        } else {
            presentTense += 1
        }
        
        if !word.hasSuffix("was") && !word.hasSuffix("were") {
            activeVoice += 1
        }
            }
            
            return true
        }
        
        return SelfReferenceAnalysis(
            selfReferences: selfRefs,
            selfReferencePercentage: Double(selfRefs) / wordCount * 100,
            otherReferences: otherRefs,
            pastTensePercentage: Double(pastTense) / Double(max(1, totalVerbs)) * 100,
            presentTensePercentage: Double(presentTense) / Double(max(1, totalVerbs)) * 100,
            futureTensePercentage: Double(futureTense) / Double(max(1, totalVerbs)) * 100,
            activeVoicePercentage: Double(activeVoice) / Double(max(1, totalVerbs)) * 100
        )
    }
}

class ThematicAnalyzer {
    private let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
    private let tokenizer = NLTokenizer(unit: .word)
    
    private let significantTags: Set<NLTag> = [.noun, .verb, .adjective]
    private let stopWords: Set<String> = [
        "the", "be", "to", "of", "and", "a", "in", "that", "have",
        "i", "it", "for", "not", "on", "with", "he", "as", "you",
        "do", "at", "this", "but", "his", "by", "from", "they",
        "we", "say", "her", "she", "or", "an", "will", "my",
        "one", "all", "would", "there", "their", "what", "so",
        "up", "out", "if", "about", "who", "get", "which", "go",
        "me", "when", "make", "can", "like", "time", "no", "just",
        "him", "know", "take", "people", "into", "year", "your",
        "good", "some", "could", "them", "see", "other", "than",
        "then", "now", "look", "only", "come", "its", "over",
        "think", "also", "back", "after", "use", "two", "how",
        "our", "work", "first", "well", "way", "even", "new",
        "want", "because", "any", "these", "give", "day", "most"
    ]
    
    func analyze(_ text: String) -> ThematicAnalysis {
        var keyTopics: [String: Double] = [:]
        var significantPhrases: [String] = []
        var namedEntities: [String] = []
        var contextualKeywords: [String: Double] = [:]
        
        // Named Entity Recognition
        tagger.string = text
        let range = text.startIndex..<text.endIndex
        
        tagger.enumerateTags(in: range, unit: .word, scheme: .nameType) { tag, tokenRange in
            if let tag = tag {
                let entity = String(text[tokenRange])
                if tag == .personalName || tag == .placeName || tag == .organizationName {
                    namedEntities.append(entity)
                }
            }
            return true
        }
        
        // Key Topics and Contextual Keywords
        let words = tokenizeAndFilter(text)
        let wordFrequencies = calculateWordFrequencies(words)
        let tfIdfScores = calculateTfIdf(wordFrequencies, totalWords: Double(words.count))
        
        for (word, score) in tfIdfScores {
            if score > 0.1 {
                keyTopics[word] = score
            }
            
            let contextScore = calculateContextualScore(word: word, words: words)
            if contextScore > 0.05 {
                contextualKeywords[word] = contextScore
            }
        }
        
        // Significant Phrases
        significantPhrases = extractSignificantPhrases(text, keyTopics: keyTopics)
        
        return ThematicAnalysis(
            keyTopics: keyTopics,
            significantPhrases: significantPhrases,
            namedEntities: Array(Set(namedEntities)),
            contextualKeywords: contextualKeywords,
            topicCoherence: calculateTopicCoherence(keyTopics: keyTopics, words: words)
        )
    }
    
    private func tokenizeAndFilter(_ text: String) -> [String] {
        tokenizer.string = text
        return tokenizer.tokens(for: text.startIndex..<text.endIndex)
            .map { String(text[$0]).lowercased() }
            .filter { !stopWords.contains($0) && $0.count > 2 }
    }
    
    private func calculateWordFrequencies(_ words: [String]) -> [String: Int] {
        var frequencies: [String: Int] = [:]
        words.forEach { frequencies[$0, default: 0] += 1 }
        return frequencies
    }
    
    private func calculateTfIdf(_ frequencies: [String: Int], totalWords: Double) -> [String: Double] {
        var tfIdf: [String: Double] = [:]
        let maxFreq = Double(frequencies.values.max() ?? 1)
        
        for (word, freq) in frequencies {
            let tf = Double(freq) / maxFreq
            let idf = log(totalWords / Double(freq))
            tfIdf[word] = tf * idf
        }
        
        return tfIdf
    }
    
    private func calculateContextualScore(word: String, words: [String]) -> Double {
        let windowSize = 3
        var score = 0.0
        
        for i in 0..<words.count {
            if words[i] == word {
                let start = max(0, i - windowSize)
                let end = min(words.count - 1, i + windowSize)
                let context = Array(words[start...end])
                score += calculateContextRelevance(word: word, context: context)
            }
        }
        
        return score
    }
    
    private func calculateContextRelevance(word: String, context: [String]) -> Double {
        var relevance = 0.0
        let wordSet = Set(context)
        
        for contextWord in wordSet {
            if contextWord != word {
                relevance += 0.1
            }
        }
        
        return relevance
    }
    
    private func extractSignificantPhrases(_ text: String, keyTopics: [String: Double]) -> [String] {
        var phrases: [String] = []
        let sentences = text.components(separatedBy: ".").filter { !$0.isEmpty }
        
        for sentence in sentences {
            let words = sentence.lowercased().components(separatedBy: .whitespacesAndNewlines)
            for i in 0..<words.count-2 {
                let phrase = words[i...i+2].joined(separator: " ")
                if keyTopics.keys.contains(where: { phrase.contains($0) }) {
                    phrases.append(phrase.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
        }
        
        return Array(Set(phrases))
    }
    
    private func calculateTopicCoherence(keyTopics: [String: Double], words: [String]) -> Double {
        var coherence = 0.0
        let topicWords = Array(keyTopics.keys)
        
        for i in 0..<topicWords.count {
            for j in i+1..<topicWords.count {
                coherence += calculateWordCoherence(word1: topicWords[i], word2: topicWords[j], words: words)
            }
        }
        
        return coherence / max(1.0, Double(topicWords.count * (topicWords.count - 1)) / 2.0)
    }
    
    private func calculateWordCoherence(word1: String, word2: String, words: [String]) -> Double {
        var cooccurrence = 0
        let windowSize = 5
        
        for i in 0..<words.count {
            let start = max(0, i - windowSize)
            let end = min(words.count - 1, i + windowSize)
            let window = Array(words[start...end])
            
            if window.contains(word1) && window.contains(word2) {
                cooccurrence += 1
            }
        }
        
        return Double(cooccurrence) / Double(words.count)
    }
}

class AnalysisManager: ObservableObject {
    static let shared = AnalysisManager()
    
    @Published private(set) var currentLoopAnalysis: LoopAnalysis?
    @Published private(set) var sessionStats: SessionStatistics
    @Published private(set) var isAnalyzing = false
    
    private let emotionAnalyzer = EmotionAnalyzer()
    private let speechPatternAnalyzer = SpeechPatternAnalyzer()
    private let cognitiveAnalyzer = CognitiveAnalyzer()
    private let selfReferenceAnalyzer = SelfReferenceAnalyzer()
    private let thematicAnalyzer = ThematicAnalyzer()
    
    var analyzedLoops: [LoopAnalysis] = []
    
    init() {
        self.sessionStats = SessionStatistics(
            averageWordsPerMinute: 0,
            averageEmotionalIntensity: 0,
            averageComplexityScore: 0,
            averageSelfReferencePercentage: 0,
            dominantEmotions: [],
            commonTopics: [],
            analysisCount: 0
        )
    }
    
    func analyzeLoop(_ loop: Loop) async throws {
        guard let fileURL = loop.data.fileURL else {
            throw AnalysisError.invalidFileURL
        }
        
        DispatchQueue.main.async {
            self.isAnalyzing = true
        }
        
        let transcript = try await transcribeAudio(url: fileURL)
        
        let emotionAnalysis = emotionAnalyzer.analyze(transcript)
        let speechPatternAnalysis = await speechPatternAnalyzer.analyze(audioURL: fileURL, transcript: transcript)
        let cognitiveAnalysis = cognitiveAnalyzer.analyze(transcript)
        let selfReferenceAnalysis = selfReferenceAnalyzer.analyze(transcript)
        let thematicAnalysis = thematicAnalyzer.analyze(transcript)
        
        let analysis = LoopAnalysis(
            loopId: loop.id,
            timestamp: loop.timestamp,
            emotion: emotionAnalysis,
            speechPattern: speechPatternAnalysis,
            cognitive: cognitiveAnalysis,
            selfReference: selfReferenceAnalysis,
            thematic: thematicAnalysis
        )
        
        await updateSessionStatistics(with: analysis)
        
        DispatchQueue.main.async {
            self.currentLoopAnalysis = analysis
            self.isAnalyzing = false
        }
    }
    
    private func transcribeAudio(url: URL) async throws -> String {
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        guard let recognizer = recognizer else {
            throw AnalysisError.transcriptionFailed
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
    
    @MainActor
    private func updateSessionStatistics(with analysis: LoopAnalysis) {
        analyzedLoops.append(analysis)
        
        let totalLoops = Double(analyzedLoops.count)
        
        let avgWPM = analyzedLoops.reduce(0.0) { $0 + $1.speechPattern.wordsPerMinute } / totalLoops
        let avgEmotionalIntensity = analyzedLoops.reduce(0.0) { $0 + $1.emotion.emotionalIntensity } / totalLoops
        let avgComplexity = analyzedLoops.reduce(0.0) { $0 + $1.cognitive.complexityScore } / totalLoops
        let avgSelfRef = analyzedLoops.reduce(0.0) { $0 + $1.selfReference.selfReferencePercentage } / totalLoops
        
        var emotionCounts: [String: Int] = [:]
        var topicCounts: [String: Int] = [:]
        
        for loop in analyzedLoops {
            loop.emotion.primaryEmotions.forEach { emotionCounts[$0, default: 0] += 1 }
            loop.thematic.keyTopics.forEach { topicCounts[$0.key, default: 0] += 1 }
        }
        
        let dominantEmotions = Array(emotionCounts.sorted { $0.value > $1.value }.prefix(5).map { $0.key })
        let commonTopics = Array(topicCounts.sorted { $0.value > $1.value }.prefix(5).map { $0.key })
        
        sessionStats = SessionStatistics(
            averageWordsPerMinute: avgWPM,
            averageEmotionalIntensity: avgEmotionalIntensity,
            averageComplexityScore: avgComplexity,
            averageSelfReferencePercentage: avgSelfRef,
            dominantEmotions: dominantEmotions,
            commonTopics: commonTopics,
            analysisCount: analyzedLoops.count
        )
    }
}

enum AnalysisError: Error {
    case invalidFileURL
    case audioProcessingFailed
    case transcriptionFailed
    case transcriptionNotAuthorized
    case analysisFailure
    case audioFormatError
    case noAudioTrack
    case noSpeechRecognizer
    
    var description: String {
        switch self {
        case .invalidFileURL:
            return "Invalid file URL provided"
        case .audioProcessingFailed:
            return "Failed to process audio file"
        case .transcriptionFailed:
            return "Failed to transcribe audio"
        case .transcriptionNotAuthorized:
            return "Speech recognition not authorized"
        case .analysisFailure:
            return "Analysis failed to complete"
        case .audioFormatError:
            return "Invalid audio format"
        case .noAudioTrack:
            return "No audio track found"
        case .noSpeechRecognizer:
            return "Speech recognizer not available"
        }
    }
}

