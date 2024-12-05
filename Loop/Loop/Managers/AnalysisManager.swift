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
    let promptText: String
    let speechPattern: SpeechPatternAnalysis
    let selfReference: SelfReferenceAnalysis
    let voicePattern: VoiceAnalysis
    let languagePattern: LanguagePatternAnalysis
}

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
    var averageFillerWordPercentage: Double
    var averagePitchVariation: Double
    var averageRhythmConsistency: Double
    var averageEmotionalToneScore: Double
    var averageWeTheyRatio: Double
    var totalPositiveWords: Int
    var totalNegativeWords: Int
    var totalCausalConjunctions: Int
    var totalAdversativeConjunctions: Int
}

struct MetricInsight: Codable {
    let value: Double
    let interpretation: String
}

struct SpeechPatternAnalysis: Codable {
    let wordsPerMinute: MetricInsight
    let pauseCount: Int
    let averagePauseDuration: MetricInsight
    let longestPause: Double
}

struct VoiceAnalysis: Codable {
    let fillerWords: MetricInsight
    let pitchVariation: MetricInsight
    let rhythmConsistency: MetricInsight
    let averagePitch: Double  // raw data, might not need interpretation
}

struct SelfReferenceAnalysis: Codable {
    let selfReference: MetricInsight
    let tenseDistribution: MetricInsight  // insight about past/present/future balance
    let uncertaintyCount: Int
    let reflectionCount: MetricInsight
}

struct LanguagePatternAnalysis: Codable {
    let emotionalTone: MetricInsight
    let wordSentiment: MetricInsight  // combines positive/negative word insights
    let expressionStyle: MetricInsight  // insight about causal/adversative usage
    let socialContext: MetricInsight  // insight about we/they usage
    
    // Raw data that might not need interpretation
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
        let selfRefPercentage = Double(selfRefs) / wordCount * 100
        let pastTensePercentage = Double(pastTense) / totalVerbs * 100
        let presentTensePercentage = Double(presentTense) / totalVerbs * 100
        let futureTensePercentage = Double(futureTense) / totalVerbs * 100
        
        return SelfReferenceAnalysis(
            selfReference: interpretSelfReference(percentage: selfRefPercentage),
            tenseDistribution: interpretTenseDistribution(
                past: pastTensePercentage,
                present: presentTensePercentage,
                future: futureTensePercentage
            ),
            uncertaintyCount: uncertaintyCount,
            reflectionCount: interpretReflectionMarkers(count: reflectionCount)
        )
    }
    
    private func interpretSelfReference(percentage: Double) -> MetricInsight {
        let interpretation = switch percentage {
            case 0...10:
                "Minimal self-reference might suggest a focus on external observations or events"
            case 10...25:
                "Balanced self-reference could indicate a mix of personal and external perspectives"
            case 25...40:
                "Moderate self-reference might reflect personal engagement with the topic"
            default:
                "Frequent self-reference could suggest deep personal connection to the subject"
        }
        
        return MetricInsight(value: percentage, interpretation: interpretation)
    }
    
    private func interpretTenseDistribution(past: Double, present: Double, future: Double) -> MetricInsight {
        let primaryTense: String
        let interpretation: String
        
        if past > present && past > future {
            primaryTense = "past"
            interpretation = "Emphasis on past experiences might suggest reflection on previous events"
        } else if future > present && future > past {
            primaryTense = "future"
            interpretation = "Future-oriented language could indicate forward-thinking or planning"
        } else {
            primaryTense = "present"
            interpretation = "Present-focused language might suggest immediate engagement with current experiences"
        }
        
        // Use the dominant tense's percentage as the value
        let value = max(past, max(present, future))
        
        return MetricInsight(
            value: value,
            interpretation: interpretation
        )
    }
    
    private func interpretReflectionMarkers(count: Int) -> MetricInsight {
        let interpretation = switch count {
            case 0...2:
                "Few reflection markers might indicate direct or factual expression"
            case 3...5:
                "Some reflection markers could suggest thoughtful consideration"
            case 6...8:
                "Regular use of reflection markers might indicate analytical thinking"
            default:
                "Frequent reflection markers could suggest deep introspection"
        }
        
        return MetricInsight(value: Double(count), interpretation: interpretation)
    }
}

class SpeechPatternAnalyzer {
    func analyze(audioURL: URL, transcript: String) async -> SpeechPatternAnalysis {
        let words = transcript.components(separatedBy: .whitespacesAndNewlines)
        let duration = getAudioDuration(url: audioURL)
        let wpm = calculateWordsPerMinute(wordCount: words.count, duration: duration)
        let pauseAnalysis = await analyzePauses(audioURL: audioURL)
        
        let wpmInsight = interpretWPM(wpm)
        let pauseInsight = interpretPauseDuration(pauseAnalysis.average)
        
        return SpeechPatternAnalysis(
            wordsPerMinute: wpmInsight,
            pauseCount: pauseAnalysis.count,
            averagePauseDuration: pauseInsight,
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
    
    private func interpretWPM(_ wpm: Double) -> MetricInsight {
        let interpretation = switch wpm {
            case 0...100:
                "Speaking at a measured pace, which might suggest thoughtful consideration"
            case 100...150:
                "Maintaining a natural conversational rhythm"
            case 150...200:
                "Speaking at an energetic pace, possibly indicating engagement or enthusiasm"
            default:
                "Speaking at a swift pace, which could reflect heightened emotional involvement"
        }
        
        return MetricInsight(value: wpm, interpretation: interpretation)
    }
    
    private func interpretPauseDuration(_ duration: Double) -> MetricInsight {
        let interpretation = switch duration {
            case 0...0.5:
                "Brief pauses might indicate a flowing train of thought"
            case 0.5...1.5:
                "Natural pauses could suggest comfortable reflection"
            default:
                "Longer pauses might indicate deeper contemplation between thoughts"
        }
        
        return MetricInsight(value: duration, interpretation: interpretation)
    }
}


class VoicePatternAnalyzer {
    private let minimumPitchChange: Double = 10.0 // Hz
    
    func analyze(audioURL: URL, transcript: String) async throws -> VoiceAnalysis {
        let words = transcript.lowercased().split(separator: " ").map(String.init)
        let wordCount = Double(words.count)
        
        // Calculate filler words
        let fillerWordCount = countFillerWords(in: words)
        let fillerPercentage = (Double(fillerWordCount) / wordCount) * 100
        let fillerInsight = interpretFillerWords(percentage: fillerPercentage)
        
        // Analyze pitch and rhythm
        let (pitchVariation, avgPitch) = try await analyzePitch(audioURL: audioURL)
        let pitchInsight = interpretPitchVariation(variation: pitchVariation)
        
        let rhythmConsistency = try await analyzeRhythm(audioURL: audioURL)
        let rhythmInsight = interpretRhythmConsistency(rhythmConsistency)
        
        return VoiceAnalysis(
            fillerWords: fillerInsight,
            pitchVariation: pitchInsight,
            rhythmConsistency: rhythmInsight,
            averagePitch: avgPitch
        )
    }
    
    private func interpretFillerWords(percentage: Double) -> MetricInsight {
        let interpretation = switch percentage {
            case 0...3:
                "Very few filler words, suggesting clear and direct expression"
            case 3...7:
                "Occasional use of filler words, maintaining natural conversational flow"
            case 7...12:
                "Moderate use of filler words, which might offer moments for thought gathering"
            default:
                "Frequent use of filler words, possibly indicating active processing of thoughts"
        }
        
        return MetricInsight(value: percentage, interpretation: interpretation)
    }
    
    private func interpretPitchVariation(variation: Double) -> MetricInsight {
        let interpretation = switch variation {
            case 0...20:
                "Steady vocal tone, which might suggest a calm or measured approach"
            case 20...40:
                "Natural pitch variation, potentially indicating comfortable engagement"
            case 40...60:
                "Dynamic voice modulation, which could reflect emotional engagement"
            default:
                "Expressive pitch range, possibly showing heightened emotional involvement"
        }
        
        return MetricInsight(value: variation, interpretation: interpretation)
    }
    
    private func interpretRhythmConsistency(_ consistency: Double) -> MetricInsight {
        let interpretation = switch consistency {
            case 0...0.3:
                "Variable rhythm, which might indicate spontaneous expression"
            case 0.3...0.6:
                "Balanced rhythm, suggesting natural conversational flow"
            case 0.6...0.8:
                "Consistent rhythm, which could reflect focused articulation"
            default:
                "Highly consistent rhythm, possibly indicating structured thought process"
        }
        
        return MetricInsight(value: consistency * 100, interpretation: interpretation)
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
        
        // Count occurrences
        let positiveCount = countWords(in: words, matching: positiveWords)
        let negativeCount = countWords(in: words, matching: negativeWords)
        let causalCount = countWords(in: words, matching: causalConjunctions)
        let adversativeCount = countWords(in: words, matching: adversativeConjunctions)
        let weCount = countWords(in: words, matching: socialPronouns.collective)
        let theyCount = countWords(in: words, matching: socialPronouns.others)
        
        // Calculate emotional score (-1 to 1)
        let emotionalScore = if wordCount > 0 {
            (Double(positiveCount) - Double(negativeCount)) / wordCount
        } else {
            0.0
        }
        
        return LanguagePatternAnalysis(
            emotionalTone: interpretEmotionalTone(score: emotionalScore),
            wordSentiment: interpretWordSentiment(positive: positiveCount, negative: negativeCount, total: Int(wordCount)),
            expressionStyle: interpretExpressionStyle(causal: causalCount, adversative: adversativeCount),
            socialContext: interpretSocialContext(weCount: weCount, theyCount: theyCount),
            
            // Raw counts for reference
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
    
    private func interpretEmotionalTone(score: Double) -> MetricInsight {
        let interpretation = switch score {
            case 0.5...1.0:
                "Language choices tend toward optimistic or constructive expression"
            case 0.2...0.5:
                "Word choices suggest a generally positive perspective"
            case -0.2...0.2:
                "Balanced use of positive and negative expressions might indicate neutral or measured reflection"
            case -0.5...(-0.2):
                "Word choices might reflect processing of challenging experiences"
            default:
                "Language suggests engagement with more complex or difficult themes"
        }
        
        return MetricInsight(value: score, interpretation: interpretation)
    }
    
    private func interpretWordSentiment(positive: Int, negative: Int, total: Int) -> MetricInsight {
        let ratio = Double(positive + negative) / Double(total)
        let dominantType = positive >= negative ? "positive" : "negative"
        
        let interpretation = switch ratio {
            case 0...0.1:
                "Primarily neutral language with minimal emotional descriptors"
            case 0.1...0.2:
                "Moderate use of \(dominantType) descriptors might suggest measured expression"
            case 0.2...0.3:
                "Regular use of \(dominantType) language could indicate emotional engagement"
            default:
                "Frequent emotional descriptors might reflect heightened expressive emphasis"
        }
        
        return MetricInsight(value: ratio * 100, interpretation: interpretation)
    }
    
    private func interpretExpressionStyle(causal: Int, adversative: Int) -> MetricInsight {
        let total = Double(causal + adversative)
        let ratio = causal > adversative ? Double(causal) / total : Double(adversative) / total
        
        let interpretation = if causal > adversative {
            switch causal {
                case 0...2:
                    "Simple connective expression with occasional cause-effect relationships"
                case 3...5:
                    "Regular use of causal connections might suggest analytical thinking"
                default:
                    "Frequent causal links could indicate systematic reasoning patterns"
            }
        } else {
            switch adversative {
                case 0...2:
                    "Direct expression with some contrasting elements"
                case 3...5:
                    "Regular contrast markers might suggest nuanced perspective"
                default:
                    "Frequent use of contrasts could indicate comparative thinking"
            }
        }
        
        return MetricInsight(value: ratio * 100, interpretation: interpretation)
    }
    
    private func interpretSocialContext(weCount: Int, theyCount: Int) -> MetricInsight {
        let total = Double(weCount + theyCount)
        let ratio = total > 0 ? Double(weCount) / total : 0
        
        let interpretation = switch ratio {
            case 0...0.2:
                "Focus tends toward external or third-person perspectives"
            case 0.2...0.4:
                "Mixed use of collective and external references might suggest balanced viewpoint"
            case 0.4...0.6:
                "Balance between collective and individual perspectives"
            case 0.6...0.8:
                "Emphasis on collective experience or shared perspectives"
            default:
                "Strong focus on collective or community-oriented expression"
        }
        
        return MetricInsight(value: ratio * 100, interpretation: interpretation)
    }

}

class AnalysisManager: ObservableObject {
    static let shared = AnalysisManager()
    private let debugPrefix = "📊 AnalysisManager"
    
    // MARK: - Published Properties
    @Published private(set) var currentLoopAnalysis: LoopAnalysis? {
        didSet {
            print("\(debugPrefix) currentLoopAnalysis updated: \(String(describing: currentLoopAnalysis?.loopId))")
        }
    }
    
    @Published private(set) var sessionStats: SessionStatistics {
        didSet {
            print("\(debugPrefix) sessionStats updated - analysis count: \(sessionStats.analysisCount)")
        }
    }
    
    @Published private(set) var isAnalyzing = false {
        didSet {
            print("\(debugPrefix) isAnalyzing updated to: \(isAnalyzing)")
        }
    }
    
    @Published private(set) var analyzedLoops: [LoopAnalysis] = [] {
        didSet {
            print("\(debugPrefix) analyzedLoops updated - count: \(analyzedLoops.count)")
            print("\(debugPrefix) Loop IDs: \(analyzedLoops.map { $0.loopId })")
        }
    }
    
    // MARK: - Private Properties
    private let speechPatternAnalyzer = SpeechPatternAnalyzer()
    private let selfReferenceAnalyzer = SelfReferenceAnalyzer()
    private let voicePatternAnalyzer = VoicePatternAnalyzer()
    private let languagePatternAnalyzer = LanguagePatternAnalyzer()
    
    
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
            promptText: loop.promptText,
            speechPattern: speechPattern,
            selfReference: selfReferenceAnalysis,
            voicePattern: voice,
            languagePattern: languageAnalysis
        )
    
        DispatchQueue.main.async {
            self.currentLoopAnalysis = analysis
            self.analyzedLoops.append(analysis)
            self.isAnalyzing = false
        }
        
        await updateSessionStatistics()
        
        print("completed analysis")
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
    private func updateSessionStatistics() {
        guard !analyzedLoops.isEmpty else { return }
        
        let totalLoops = Double(analyzedLoops.count)
        
        // Speech Pattern Stats
        let avgWPM = analyzedLoops.reduce(0.0) { $0 + $1.speechPattern.wordsPerMinute.value } / totalLoops
        let avgPauseCount = analyzedLoops.reduce(0.0) { $0 + Double($1.speechPattern.pauseCount) } / totalLoops
        let avgPauseDuration = analyzedLoops.reduce(0.0) { $0 + $1.speechPattern.averagePauseDuration.value } / totalLoops
        
        // Self Reference Stats
        let avgSelfRef = analyzedLoops.reduce(0.0) { $0 + $1.selfReference.selfReference.value } / totalLoops
        let tenseDistribution = analyzedLoops.map { $0.selfReference.tenseDistribution.value }
        let avgPastTense = tenseDistribution.reduce(0.0, +) / totalLoops
        let totalUncertainty = analyzedLoops.reduce(0) { $0 + $1.selfReference.uncertaintyCount }
        let totalReflection = analyzedLoops.reduce(0) { $0 + Int($1.selfReference.reflectionCount.value) }
        
        // Voice Analysis Stats
        let avgFillerWord = analyzedLoops.reduce(0.0) { $0 + $1.voicePattern.fillerWords.value } / totalLoops
        let avgPitchVar = analyzedLoops.reduce(0.0) { $0 + $1.voicePattern.pitchVariation.value } / totalLoops
        let avgRhythm = analyzedLoops.reduce(0.0) { $0 + $1.voicePattern.rhythmConsistency.value } / totalLoops
        
        // Language Pattern Stats
        let avgEmotionalTone = analyzedLoops.reduce(0.0) { $0 + $1.languagePattern.emotionalTone.value } / totalLoops
        let avgWeTheyRatio = analyzedLoops.reduce(0.0) { $0 + $1.languagePattern.socialContext.value } / totalLoops
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
            averageFutureTensePercentage: 0, // This is now part of tenseDistribution insight
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
    case apiError
    
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
        case .apiError:
            return "AI not available"
        }
    }
}

