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


struct LoopAnalysis: Codable {
    let loopId: String
    let timestamp: Date
    let speechPattern: SpeechPatternAnalysis
    let selfReference: SelfReferenceAnalysis
    let voicePattern: VoiceAnalysis
    let languagePattern: LanguagePatternAnalysis
}


struct SpeechPatternAnalysis: Codable {
    let wordsPerMinute: Double
    let pauseCount: Int
    let averagePauseDuration: Double
    let longestPause: Double
}

struct SelfReferenceAnalysis: Codable {
    let selfReferences: Int
    let selfReferencePercentage: Double
    let pastTensePercentage: Double
    let presentTensePercentage: Double
    let futureTensePercentage: Double
    let uncertaintyCount: Int
    let reflectionCount: Int
}

struct VoiceAnalysis: Codable {
    let fillerWordCount: Int
    let fillerWordPercentage: Double
    let pitchVariation: Double
    let averagePitch: Double
    let rhythmConsistency: Double // 0-1, higher means more consistent
}

struct LanguagePatternAnalysis: Codable {
    let emotionalToneScore: Double // -1 to 1, negative to positive
    let positiveWordCount: Int
    let negativeWordCount: Int
    let causalConjunctionCount: Int
    let adversativeConjunctionCount: Int
    let socialPronouns: SocialPronounAnalysis
}

struct SocialPronounAnalysis: Codable {
    let weCount: Int
    let theyCount: Int
    let weTheyRatio: Double
}

// MARK: - Analysis Message Types

enum AnalysisMessageCategory {
    case speechRate
    case pausePattern
    case fillerWords
    case selfReference
    case emotionalTone
    case pronounUsage
    case sentenceStructure
    case pitchPattern
    case rhythmPattern
}

struct AnalysisMessage: Identifiable {
    let id = UUID()
    let category: AnalysisMessageCategory
    let severity: MessageSeverity
    let message: String
}

enum MessageSeverity: Int, Codable {
    case neutral
    case notable
    case significant
}

class SelfReferenceAnalyzer {
    private let tagger = NLTagger(tagSchemes: [.lexicalClass])
    
    // Comprehensive self-reference markers
    private let selfReferenceWords: Set<String> = [
        "i", "me", "my", "mine", "myself",
        "i've", "i'd", "i'll", "i'm", "i've been",
        "i'd been", "i'll be", "i'm going",
        "we", "us", "our", "ours", "ourselves",
        "we've", "we'd", "we'll", "we're"
    ]
    
    // Reliable past tense markers
    private let pastTenseMarkers: Set<String> = [
        "was", "were", "had", "did", "felt", "thought",
        "wished", "could", "would", "should", "used to",
        "couldn't", "wouldn't", "shouldn't", "hadn't",
        "didn't", "went", "came", "made", "took",
        "wanted", "needed", "tried", "hoped", "realized",
        "remembered", "forgot", "meant to", "started to",
        "began to", "tried to"
    ]
    
    // Future tense markers
    private let futureTenseMarkers: Set<String> = [
        "will", "going to", "plan to", "hope to", "want to",
        "expect to", "intend to", "about to", "planning to",
        "thinking of", "considering", "looking to",
        "will be", "gonna", "will have", "shall"
    ]
    
    // Uncertainty markers
    private let uncertaintyMarkers: Set<String> = [
        "might", "maybe", "perhaps", "possibly", "probably",
        "could", "would", "should", "wonder if", "not sure",
        "uncertain", "unsure", "guess", "think", "seem",
        "appears", "potentially", "likely", "unlikely",
        "sometimes", "occasionally"
    ]
    
    // Reflection markers
    private let reflectionMarkers: Set<String> = [
        "feel like", "think that", "realize", "remember",
        "wish", "hope", "wonder", "reflect", "understand",
        "recognize", "notice", "sense", "believe",
        "occurred to me", "reminds me", "reminded me",
        "made me think", "makes me think", "got me thinking"
    ]
    
    func analyze(_ text: String) -> SelfReferenceAnalysis {
        let words = text.lowercased().split(separator: " ").map(String.init)
        let wordPairs = zip(words, words.dropFirst()).map { "\($0) \($1)" }
        let wordCount = Double(words.count)
        
        var selfRefs = 0
        var pastTense = 0
        var futureTense = 0
        var presentTense = 0
        var uncertaintyCount = 0
        var reflectionCount = 0
        
        // Check single words
        for word in words {
            if selfReferenceWords.contains(word) {
                selfRefs += 1
            }
            if pastTenseMarkers.contains(word) || word.hasSuffix("ed") {
                pastTense += 1
            }
            if uncertaintyMarkers.contains(word) {
                uncertaintyCount += 1
            }
        }
        
        // Check word pairs for complex markers
        for pair in wordPairs {
            if futureTenseMarkers.contains(pair) {
                futureTense += 1
            }
            if reflectionMarkers.contains(pair) {
                reflectionCount += 1
            }
        }
        
        // Tag remaining verbs
        tagger.string = text
        let range = text.startIndex..<text.endIndex
        
        tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass) { tag, tokenRange in
            guard tag == .verb else { return true }
            
            let word = String(text[tokenRange]).lowercased()
            if !pastTenseMarkers.contains(word) && !futureTenseMarkers.contains(word) {
                presentTense += 1
            }
            
            return true
        }
        
        let totalVerbs = max(1, Double(pastTense + presentTense + futureTense))
        
        return SelfReferenceAnalysis(
            selfReferences: selfRefs,
            selfReferencePercentage: Double(selfRefs) / wordCount * 100,
            pastTensePercentage: Double(pastTense) / totalVerbs * 100,
            presentTensePercentage: Double(presentTense) / totalVerbs * 100,
            futureTensePercentage: Double(futureTense) / totalVerbs * 100,
            uncertaintyCount: uncertaintyCount,
            reflectionCount: reflectionCount
        )
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
           longestPause: pauseAnalysis.longest
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
       let threshold: Float = -30.0  // Increased threshold for better pause detection
       let minimumPauseDuration: Float = 0.5 // Minimum pause length in seconds
       
       let asset = AVAsset(url: audioURL)
       var pauseCount = 0
       var totalPauseDuration = 0.0
       var longestPause = 0.0
       var currentPauseStart: Double?
       
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
           
           guard let level = readAudioLevel(from: sampleBuffer) else { continue }
           
           if level < threshold {
               // Start of pause
               if currentPauseStart == nil {
                   currentPauseStart = time
               }
           } else {
               // End of pause
               if let pauseStart = currentPauseStart {
                   let pauseDuration = time - pauseStart
                   if pauseDuration >= Double(minimumPauseDuration) {
                       pauseCount += 1
                       totalPauseDuration += pauseDuration
                       longestPause = max(longestPause, pauseDuration)
                   }
                   currentPauseStart = nil
               }
           }
       }
       
       // Handle any pause that might be ongoing at the end
       if let pauseStart = currentPauseStart {
           let finalTime = CMTimeGetSeconds(asset.duration)
           let pauseDuration = finalTime - pauseStart
           if pauseDuration >= Double(minimumPauseDuration) {
               pauseCount += 1
               totalPauseDuration += pauseDuration
               longestPause = max(longestPause, pauseDuration)
           }
       }
       
       let averagePauseDuration = pauseCount > 0 ? totalPauseDuration / Double(pauseCount) : 0
       
       return (pauseCount, averagePauseDuration, longestPause, totalPauseDuration)
   }
   
   private func readAudioLevel(from sampleBuffer: CMSampleBuffer) -> Float? {
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
}

// Add this class alongside SpeechPatternAnalyzer and SelfReferenceAnalyzer

class VoicePatternAnalyzer {
    private let minimumPitchChange: Double = 10.0 // Hz
    
    func analyze(audioURL: URL, transcript: String) async throws -> VoiceAnalysis {
        let words = transcript.lowercased().split(separator: " ").map(String.init)
        let fillerWordCount = countFillerWords(in: words)
        let wordCount = Double(words.count)
        
        let (pitchVariation, avgPitch) = try await analyzePitch(audioURL: audioURL)
        let rhythmConsistency = try await analyzeRhythm(audioURL: audioURL)
        
        return VoiceAnalysis(
            fillerWordCount: fillerWordCount,
            fillerWordPercentage: (Double(fillerWordCount) / wordCount) * 100,
            pitchVariation: pitchVariation,
            averagePitch: avgPitch,
            rhythmConsistency: rhythmConsistency
        )
    }
    
    private func countFillerWords(in words: [String]) -> Int {
        let fillerWords: Set<String> = [
            "um", "uh", "like", "you know", "sort of", "kind of", "basically",
            "actually", "literally", "just", "stuff", "things"
        ]
        
        return words.filter { fillerWords.contains($0) }.count
    }
    
    private func analyzePitch(audioURL: URL) async throws -> (variation: Double, average: Double) {
        let audioEngine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        let file = try AVAudioFile(forReading: audioURL)
        
        audioEngine.attach(player)
        audioEngine.connect(player, to: audioEngine.mainMixerNode, format: file.processingFormat)
        
        var pitchValues: [Double] = []
        let bufferSize = 4096
        let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(bufferSize))!
        
        try audioEngine.start()
        
        while file.framePosition < file.length {
            try file.read(into: buffer)
            if let channelData = buffer.floatChannelData?[0] {
                let frames = UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength))
                let pitch = calculatePitch(samples: Array(frames), sampleRate: Float(file.processingFormat.sampleRate))
                if pitch > 0 {
                    pitchValues.append(Double(pitch))
                }
            }
        }
        
        audioEngine.stop()
        
        let average = pitchValues.reduce(0.0, +) / Double(pitchValues.count)
        let variation = pitchValues.map { abs($0 - average) }.reduce(0.0, +) / Double(pitchValues.count)
        
        return (variation, average)
    }
    
    private func calculatePitch(samples: [Float], sampleRate: Float) -> Float {
        // Basic zero-crossing pitch detection
        var crossings = 0
        var prevSample: Float = 0
        
        for sample in samples {
            if (sample >= 0 && prevSample < 0) || (sample < 0 && prevSample >= 0) {
                crossings += 1
            }
            prevSample = sample
        }
        
        let duration = Float(samples.count) / sampleRate
        return Float(crossings) / (2 * duration)
    }
    
    private func analyzeRhythm(audioURL: URL) async throws -> Double {
        let asset = AVAsset(url: audioURL)
        let duration = CMTimeGetSeconds(asset.duration)
        let samples = try await extractAmplitudeSamples(from: audioURL)
        
        // Calculate rhythm consistency based on amplitude variations
        let amplitudeChanges = zip(samples, samples.dropFirst()).map { abs($0 - $1) }
        let averageChange = amplitudeChanges.reduce(0.0, +) / Double(amplitudeChanges.count)
        
        // Normalize to 0-1 range where 1 is most consistent
        return max(0, min(1, 1 - (averageChange / 0.5)))
    }
    
    private func extractAmplitudeSamples(from url: URL) async throws -> [Double] {
        let asset = AVAsset(url: url)
        guard let audioTrack = try? await asset.loadTracks(withMediaType: .audio).first else {
            throw AnalysisError.noAudioTrack
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
            throw AnalysisError.audioProcessingFailed
        }
        
        reader.add(output)
        reader.startReading()
        
        var samples: [Double] = []
        while let sampleBuffer = output.copyNextSampleBuffer() {
            if let level = readAudioLevel(from: sampleBuffer) {
                samples.append(Double(level))
            }
        }
        
        return samples
    }
    
    private func readAudioLevel(from sampleBuffer: CMSampleBuffer) -> Float? {
        guard let audioBufferList = sampleBuffer.audioBufferList,
              let data = audioBufferList.mBuffers.mData else {
            return nil
        }
        
        let buffer = data.assumingMemoryBound(to: Float.self)
        let size = Int(audioBufferList.mBuffers.mDataByteSize) / MemoryLayout<Float>.size
        let samples = Array(UnsafeBufferPointer(start: buffer, count: size))
        
        let rms = sqrt(samples.map { $0 * $0 }.reduce(0, +) / Float(samples.count))
        return rms
    }
}

class LanguagePatternAnalyzer {
    // Word Sets for Analysis
    private let positiveWords: Set<String> = [
        "happy", "good", "great", "excited", "wonderful", "amazing", "fantastic",
        "peaceful", "joy", "love", "hopeful", "confident", "grateful", "blessed",
        "successful", "accomplished", "proud", "satisfied", "optimistic", "motivated",
        "inspired", "determined", "enthusiastic", "positive", "excellent",
        "delighted", "thrilled", "cheerful", "content", "pleased"
    ]
    
    private let negativeWords: Set<String> = [
        "sad", "bad", "worried", "anxious", "frustrated", "angry", "upset",
        "disappointed", "stressed", "overwhelmed", "tired", "afraid", "hurt",
        "confused", "lonely", "miserable", "depressed", "unhappy", "discouraged",
        "irritated", "annoyed", "troubled", "concerned", "distressed", "negative",
        "pessimistic", "doubtful", "fearful", "regretful", "uncomfortable"
    ]
    
    private let causalConjunctions: Set<String> = [
        "because", "since", "therefore", "thus", "consequently", "hence",
        "so", "as", "due to", "thanks to", "accordingly", "for this reason",
        "on account of", "owing to", "in view of", "considering",
        "given that", "seeing that", "in that", "inasmuch as"
    ]
    
    private let adversativeConjunctions: Set<String> = [
        "but", "however", "although", "though", "yet", "nevertheless",
        "despite", "in spite of", "contrary to", "whereas", "while",
        "even though", "on the other hand", "conversely", "instead",
        "rather", "alternatively", "otherwise", "notwithstanding", "still"
    ]
    
    private let socialPronouns: (collective: Set<String>, others: Set<String>) = (
        collective: ["we", "our", "us", "ourselves", "ours", "we've", "we're", "we'll", "we'd"],
        others: ["they", "their", "them", "themselves", "theirs", "they've", "they're", "they'll", "they'd"]
    )
    
    func analyze(_ text: String) -> LanguagePatternAnalysis {
        let words = text.lowercased().split(separator: " ").map(String.init)
        let wordCount = Double(words.count)
        
        // Count word occurrences
        let positiveCount = countWords(in: words, matching: positiveWords)
        let negativeCount = countWords(in: words, matching: negativeWords)
        let causalCount = countWords(in: words, matching: causalConjunctions)
        let adversativeCount = countWords(in: words, matching: adversativeConjunctions)
        
        // Analyze social pronouns
        let weCount = countWords(in: words, matching: socialPronouns.collective)
        let theyCount = countWords(in: words, matching: socialPronouns.others)
        
        // Calculate emotional score (-1 to 1)
        let emotionalScore = if wordCount > 0 {
            (Double(positiveCount) - Double(negativeCount)) / wordCount
        } else {
            0.0
        }
        
        return LanguagePatternAnalysis(
            emotionalToneScore: emotionalScore,
            positiveWordCount: positiveCount,
            negativeWordCount: negativeCount,
            causalConjunctionCount: causalCount,
            adversativeConjunctionCount: adversativeCount,
            socialPronouns: SocialPronounAnalysis(
                weCount: weCount,
                theyCount: theyCount,
                weTheyRatio: theyCount > 0 ? Double(weCount) / Double(theyCount) : 0
            )
        )
    }
    
    private func countWords(in text: [String], matching wordSet: Set<String>) -> Int {
        text.filter { wordSet.contains($0) }.count
    }
    
    // Helper method to determine if text contains specific emotional markers
    func getEmotionalValence(_ text: String) -> (positive: Bool, negative: Bool) {
        let words = text.lowercased().split(separator: " ").map(String.init)
        let hasPositive = words.contains { positiveWords.contains($0) }
        let hasNegative = words.contains { negativeWords.contains($0) }
        return (hasPositive, hasNegative)
    }
    
    // Helper method to check if text contains causal reasoning
    func hasCausalReasoning(_ text: String) -> Bool {
        let words = text.lowercased().split(separator: " ").map(String.init)
        return words.contains { causalConjunctions.contains($0) }
    }
    
    // Helper method to analyze social context
    func analyzeSocialContext(_ text: String) -> (collectiveFocus: Bool, othersFocus: Bool) {
        let words = text.lowercased().split(separator: " ").map(String.init)
        let hasCollective = words.contains { socialPronouns.collective.contains($0) }
        let hasOthers = words.contains { socialPronouns.others.contains($0) }
        return (hasCollective, hasOthers)
    }
}

class MessageGenerator {
    func generateMessages(
        speechPattern: SpeechPatternAnalysis,
        voiceAnalysis: VoiceAnalysis,
        selfReference: SelfReferenceAnalysis,
        languagePattern: LanguagePatternAnalysis
    ) -> [AnalysisMessage] {
        var messages: [AnalysisMessage] = []
        
        // Speech rate message
        messages.append(generateSpeechRateMessage(wpm: speechPattern.wordsPerMinute))
        
        // Pause pattern message
        messages.append(generatePauseMessage(
            pauseCount: speechPattern.pauseCount,
            avgDuration: speechPattern.averagePauseDuration
        ))
        
        // Filler words message
        messages.append(generateFillerWordMessage(
            percentage: voiceAnalysis.fillerWordPercentage
        ))
        
        // Self-reference message
        messages.append(generateSelfReferenceMessage(
            percentage: selfReference.selfReferencePercentage,
            pastTense: selfReference.pastTensePercentage,
            futureTense: selfReference.futureTensePercentage
        ))
        
        // Emotional tone message
        messages.append(generateEmotionalToneMessage(
            score: languagePattern.emotionalToneScore
        ))
        
        return messages
    }
    
    private func generateSpeechRateMessage(wpm: Double) -> AnalysisMessage {
        let (message, severity): (String, MessageSeverity) = switch wpm {
        case 0...100:
            ("Your measured pace suggests thoughtful reflection.", .neutral)
        case 100...150:
            ("Your speaking pace indicates comfortable engagement.", .neutral)
        case 150...200:
            ("Your quick pace might reflect heightened engagement.", .notable)
        default:
            ("Consider taking measured breaths between thoughts.", .significant)
        }
        
        return AnalysisMessage(
            category: .speechRate,
            severity: severity,
            message: message
        )
    }
    
    private func generatePauseMessage(pauseCount: Int, avgDuration: Double) -> AnalysisMessage {
        let (message, severity): (String, MessageSeverity) = switch (pauseCount, avgDuration) {
        case (0...2, _):
            ("Your speech flows continuously.", .neutral)
        case (3...5, 0...1):
            ("You use brief pauses to structure your thoughts.", .neutral)
        case (3...5, _):
            ("Your thoughtful pauses may indicate deeper reflection.", .notable)
        default:
            ("Your speech pattern includes regular moments of reflection.", .neutral)
        }
        
        return AnalysisMessage(
            category: .pausePattern,
            severity: severity,
            message: message
        )
    }
    
    private func generateFillerWordMessage(percentage: Double) -> AnalysisMessage {
        let (message, severity): (String, MessageSeverity) = switch percentage {
        case 0...5:
            ("Your speech shows strong clarity and directness.", .neutral)
        case 5...10:
            ("Consider how pauses might enhance your expression.", .neutral)
        case 10...15:
            ("Taking brief pauses might help organize thoughts.", .notable)
        default:
            ("Practice using pauses to gather thoughts.", .significant)
        }
        
        return AnalysisMessage(
            category: .fillerWords,
            severity: severity,
            message: message
        )
    }
    
    private func generateSelfReferenceMessage(percentage: Double, pastTense: Double, futureTense: Double) -> AnalysisMessage {
        let (message, severity): (String, MessageSeverity) = switch (percentage, pastTense, futureTense) {
        case (0...20, _, _):
            ("Your response focuses on external observations.", .neutral)
        case (20...40, _, 40...100):
            ("You're balancing personal experience with future possibilities.", .notable)
        case (20...40, 40...100, _):
            ("You're drawing from personal experiences.", .neutral)
        default:
            ("Your response shows personal engagement with the topic.", .neutral)
        }
        
        return AnalysisMessage(
            category: .selfReference,
            severity: severity,
            message: message
        )
    }
    
    private func generateEmotionalToneMessage(score: Double) -> AnalysisMessage {
        let (message, severity): (String, MessageSeverity) = switch score {
        case 0.5...1.0:
            ("Your tone reflects optimistic engagement.", .notable)
        case 0.0...0.5:
            ("You're expressing balanced perspectives.", .neutral)
        case -0.5...0.0:
            ("You're acknowledging various aspects of the situation.", .neutral)
        default:
            ("You're processing complex experiences.", .notable)
        }
        
        return AnalysisMessage(
            category: .emotionalTone,
            severity: severity,
            message: message
        )
    }
}

class AnalysisManager: ObservableObject {
    static let shared = AnalysisManager()
       
   @Published private(set) var currentLoopAnalysis: LoopAnalysis?
   @Published private(set) var sessionStats: SessionStatistics
   @Published private(set) var isAnalyzing = false
   
    @Published private(set) var voiceAnalysis: VoiceAnalysis?
    @Published private(set) var languageAnalysis: LanguagePatternAnalysis?
    @Published private(set) var analysisMessages: [AnalysisMessage] = []
    @Published private(set) var trendingPatterns: [String: Double] = [:]
    
   private let speechPatternAnalyzer = SpeechPatternAnalyzer()
   private let selfReferenceAnalyzer = SelfReferenceAnalyzer()
    private let voicePatternAnalyzer = VoicePatternAnalyzer()
    private let messageGenerator = MessageGenerator()
    private let languagePatternAnalyzer = LanguagePatternAnalyzer()
    
   var analyzedLoops: [LoopAnalysis] = []
   
    struct SessionStatistics: Codable {
        var averageWordsPerMinute: Double
        var averagePauseCount: Double
        var averagePauseDuration: Double
        var averageSelfReferencePercentage: Double
        var averagePastTensePercentage: Double
        var averageFutureTensePercentage: Double
        var totalUncertaintyMarkers: Int
        var totalReflectionMarkers: Int
        var analysisCount: Int
        
        // New voice analysis averages
        var averageFillerWordPercentage: Double
        var averagePitchVariation: Double
        var averageRhythmConsistency: Double
        
        // New language analysis averages
        var averageEmotionalToneScore: Double
        var averageWeTheyRatio: Double
        var totalPositiveWords: Int
        var totalNegativeWords: Int
        var totalCausalConjunctions: Int
        var totalAdversativeConjunctions: Int
    }
   
    init() {
        self.sessionStats = SessionStatistics(
            averageWordsPerMinute: 0,
            averagePauseCount: 0,
            averagePauseDuration: 0,
            averageSelfReferencePercentage: 0,
            averagePastTensePercentage: 0,
            averageFutureTensePercentage: 0,
            totalUncertaintyMarkers: 0,
            totalReflectionMarkers: 0,
            analysisCount: 0,
            averageFillerWordPercentage: 0,
            averagePitchVariation: 0,
            averageRhythmConsistency: 0,
            averageEmotionalToneScore: 0,
            averageWeTheyRatio: 0,
            totalPositiveWords: 0,
            totalNegativeWords: 0,
            totalCausalConjunctions: 0,
            totalAdversativeConjunctions: 0
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
        
        async let speechPatternAnalysis = speechPatternAnalyzer.analyze(audioURL: fileURL, transcript: transcript)
        async let voiceAnalysis = voicePatternAnalyzer.analyze(audioURL: fileURL, transcript: transcript)
        
        let selfReferenceAnalysis = selfReferenceAnalyzer.analyze(transcript)
        let languageAnalysis = languagePatternAnalyzer.analyze(transcript)
        
        // Wait for async analyses to complete
        let (speechPattern, voice) = await (try speechPatternAnalysis, try voiceAnalysis)
        
        let analysis = LoopAnalysis(
            loopId: loop.id,
            timestamp: loop.timestamp,
            speechPattern: speechPattern,
            selfReference: selfReferenceAnalysis,
            voicePattern: voice,
            languagePattern: languageAnalysis
        )
        
        let messages = messageGenerator.generateMessages(
            speechPattern: speechPattern,
            voiceAnalysis: voice,
            selfReference: selfReferenceAnalysis,
            languagePattern: languageAnalysis
        )
        
        await updateSessionStatistics(with: analysis)
        
        DispatchQueue.main.async {
            self.currentLoopAnalysis = analysis
            self.voiceAnalysis = voice
            self.languageAnalysis = languageAnalysis
            self.analysisMessages = messages
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
        
        // Original stats
        let avgWPM = analyzedLoops.reduce(0.0) { $0 + $1.speechPattern.wordsPerMinute } / totalLoops
        let avgPauseCount = analyzedLoops.reduce(0.0) { $0 + Double($1.speechPattern.pauseCount) } / totalLoops
        let avgPauseDuration = analyzedLoops.reduce(0.0) { $0 + $1.speechPattern.averagePauseDuration } / totalLoops
        let avgSelfRef = analyzedLoops.reduce(0.0) { $0 + $1.selfReference.selfReferencePercentage } / totalLoops
        let avgPastTense = analyzedLoops.reduce(0.0) { $0 + $1.selfReference.pastTensePercentage } / totalLoops
        let avgFutureTense = analyzedLoops.reduce(0.0) { $0 + $1.selfReference.futureTensePercentage } / totalLoops
        let totalUncertainty = analyzedLoops.reduce(0) { $0 + $1.selfReference.uncertaintyCount }
        let totalReflection = analyzedLoops.reduce(0) { $0 + $1.selfReference.reflectionCount }
        
        // Voice analysis stats
        let avgFillerWord = analyzedLoops.reduce(0.0) { $0 + $1.voicePattern.fillerWordPercentage } / totalLoops
        let avgPitchVar = analyzedLoops.reduce(0.0) { $0 + $1.voicePattern.pitchVariation } / totalLoops
        let avgRhythm = analyzedLoops.reduce(0.0) { $0 + $1.voicePattern.rhythmConsistency } / totalLoops
        
        // Language pattern stats
        let avgEmotionalTone = analyzedLoops.reduce(0.0) { $0 + $1.languagePattern.emotionalToneScore } / totalLoops
        let avgWeTheyRatio = analyzedLoops.reduce(0.0) { $0 + $1.languagePattern.socialPronouns.weTheyRatio } / totalLoops
        let totalPositive = analyzedLoops.reduce(0) { $0 + $1.languagePattern.positiveWordCount }
        let totalNegative = analyzedLoops.reduce(0) { $0 + $1.languagePattern.negativeWordCount }
        let totalCausal = analyzedLoops.reduce(0) { $0 + $1.languagePattern.causalConjunctionCount }
        let totalAdversative = analyzedLoops.reduce(0) { $0 + $1.languagePattern.adversativeConjunctionCount }
        
        sessionStats = SessionStatistics(
            averageWordsPerMinute: avgWPM,
            averagePauseCount: avgPauseCount,
            averagePauseDuration: avgPauseDuration,
            averageSelfReferencePercentage: avgSelfRef,
            averagePastTensePercentage: avgPastTense,
            averageFutureTensePercentage: avgFutureTense,
            totalUncertaintyMarkers: totalUncertainty,
            totalReflectionMarkers: totalReflection,
            analysisCount: analyzedLoops.count,
            averageFillerWordPercentage: avgFillerWord,
            averagePitchVariation: avgPitchVar,
            averageRhythmConsistency: avgRhythm,
            averageEmotionalToneScore: avgEmotionalTone,
            averageWeTheyRatio: avgWeTheyRatio,
            totalPositiveWords: totalPositive,
            totalNegativeWords: totalNegative,
            totalCausalConjunctions: totalCausal,
            totalAdversativeConjunctions: totalAdversative
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

