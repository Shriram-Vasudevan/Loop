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

class AnalysisManager: ObservableObject {
    static let shared = AnalysisManager()
       
       @Published private(set) var currentLoopAnalysis: LoopAnalysis?
       @Published private(set) var sessionStats: SessionStatistics
       @Published private(set) var isAnalyzing = false
       
       private let speechPatternAnalyzer = SpeechPatternAnalyzer()
       private let selfReferenceAnalyzer = SelfReferenceAnalyzer()
       
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
    
        let speechPatternAnalysis = await speechPatternAnalyzer.analyze(audioURL: fileURL, transcript: transcript)
        let selfReferenceAnalysis = selfReferenceAnalyzer.analyze(transcript)

        let analysis = LoopAnalysis(
            loopId: loop.id,
            timestamp: loop.timestamp,
            speechPattern: speechPatternAnalysis,
            selfReference: selfReferenceAnalysis
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
        
        // Speech pattern averages
        let avgWPM = analyzedLoops.reduce(0.0) { $0 + $1.speechPattern.wordsPerMinute } / totalLoops
        let avgPauseCount = analyzedLoops.reduce(0.0) { $0 + Double($1.speechPattern.pauseCount) } / totalLoops
        let avgPauseDuration = analyzedLoops.reduce(0.0) { $0 + $1.speechPattern.averagePauseDuration } / totalLoops
        
        // Self reference and tense percentages
        let avgSelfRef = analyzedLoops.reduce(0.0) { $0 + $1.selfReference.selfReferencePercentage } / totalLoops
        let avgPastTense = analyzedLoops.reduce(0.0) { $0 + $1.selfReference.pastTensePercentage } / totalLoops
        let avgFutureTense = analyzedLoops.reduce(0.0) { $0 + $1.selfReference.futureTensePercentage } / totalLoops
        
        // Total markers across all loops
        let totalUncertainty = analyzedLoops.reduce(0) { $0 + $1.selfReference.uncertaintyCount }
        let totalReflection = analyzedLoops.reduce(0) { $0 + $1.selfReference.reflectionCount }
        
        sessionStats = SessionStatistics(
            averageWordsPerMinute: avgWPM,
            averagePauseCount: avgPauseCount,
            averagePauseDuration: avgPauseDuration,
            averageSelfReferencePercentage: avgSelfRef,
            averagePastTensePercentage: avgPastTense,
            averageFutureTensePercentage: avgFutureTense,
            totalUncertaintyMarkers: totalUncertainty,
            totalReflectionMarkers: totalReflection,
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

