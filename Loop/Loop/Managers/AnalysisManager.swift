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
    
    func beginAnalysisForLoop(loop: Loop) {
        guard let fileURL = loop.data.fileURL else { return }
        transcribeAudio(url: fileURL) { transcript in
            guard let transcript = transcript else { return }
            
            self.keywordAnalysis(transcript: transcript)
            self.sentimentAnalysis(transcript: transcript)
        }
    }

    //modify
    func keywordAnalysis(transcript: String) -> [String] {
        // Step 1: Count word frequencies
        var wordFrequencies = [String: Int]()
        let words = transcript.lowercased().components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
        
        for word in words {
            guard !word.isEmpty else { continue }
            wordFrequencies[word, default: 0] += 1
        }

        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = transcript
        
        let unwantedTags: [NLTag] = [.determiner, .preposition, .conjunction, .particle, .otherWord]
        let unwantedWords: Set<String> = ["uh", "um", "like", "you know", "hmm"]
        
        var filteredFrequencies = [String: Int]()
        
        for (word, count) in wordFrequencies {
            let range = transcript.range(of: word)
            if let range = range {
                tagger.setLanguage(.english, range: range)
                let (tag, _) = tagger.tag(at: range.lowerBound, unit: .word, scheme: .lexicalClass)
                
                if !unwantedTags.contains(tag ?? .otherWord) && !unwantedWords.contains(word) {
                    filteredFrequencies[word] = count
                }
            }
        }
        
        let sortedKeywords = filteredFrequencies.sorted { $0.value > $1.value }.map { $0.key }
        
        return sortedKeywords
    }


    //modify
    func sentimentAnalysis(transcript: String) -> Double {
        let sentimentAnalyzer = NLTagger(tagSchemes: [.sentimentScore])
        sentimentAnalyzer.string = transcript
        let (sentiment, _) = sentimentAnalyzer.tag(at: transcript.startIndex, unit: .paragraph, scheme: .sentimentScore)
        return Double(sentiment?.rawValue ?? "0.0") ?? 0.0
    }

    
    func getAverageTimeOfRecordedLoops() {
        
    }
    
    func transcribeAudio(url: URL, completion: @escaping (String?) -> Void) {
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: url)
        recognizer?.recognitionTask(with: request) { result, error in
            if let result = result {
                completion(result.bestTranscription.formattedString)
            } else {
                completion(nil)
            }
        }
    }

    
}
