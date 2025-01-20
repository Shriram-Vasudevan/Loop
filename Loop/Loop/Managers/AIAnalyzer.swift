//
//  AIAnalyzer.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/16/24.
//

import Foundation
import os.log

class AIAnalyzer {
    static let shared = AIAnalyzer()
    
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    private let apiKey: String
    
    init() {
        self.apiKey = ConfigurationKey.apiKey
    }
    
    func analyzeResponses() async throws -> DailyAIAnalysisResult {
        let responses = await getTodaysResponses()
        let formattedResponses = responses.map { "\($0.question): \($0.answer)" }
            .joined(separator: "\n\n")
        
        let prompt = """
        Analyze these responses to provide structured insights. Keep everything general and avoid specific personal details:

        \(formattedResponses)

        1. Expression Analysis
        - style: [SELECT ONE: analytical/emotional/practical/reflective]
        - topics: [LIST matching topics: work, personal, relationships, health, learning, creativity, purpose, wellbeing, growth]
        - tone: [SELECT ONE: positive/neutral/reflective/challenging]

        2. Notable Elements
        For each category, assign each response to only one category where it fits best. Do not reuse content across categories.

        - insights: Describe any new awareness or understanding they've gained
        - wins: Describe any achievements or progress they've made
        - challenges: Describe any difficulties or obstacles they're facing
        - positives: Describe any positive experiences or moments they've shared
        - strategies: Describe any approaches or methods that worked for them
        - intentions: Describe any future plans or goals they've mentioned

        Example formats:
        insights: You're recognizing how your energy affects your work.
        wins: You've started a new morning routine.
        challenges: none
        (Length should match the depth of their response)

        3. Mood Information
        - rating: [Extract mood rating 1-10]
        - sleep: [Extract sleep hours]

        4. Follow-Up Focus
        - question: [ONE specific but generalized question based on their responses]
        - purpose: [brief note on why this question matters for their development]
        """
        
        let requestBody: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": "You are an expert at analyzing personal reflections while maintaining privacy. Focus on finding clear elements rather than forcing insights. Assign each response to only one category to avoid redundancy."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.3,
            "max_tokens": 1500
        ]
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        guard let content = response.choices.first?.message.content else {
            throw AnalysisError.aiAnalysisFailed("No content in response")
        }
        
        return try parseAIResponse(content)
    }

    
    private func parseAIResponse(_ response: String) throws -> DailyAIAnalysisResult {
        let lines = response.components(separatedBy: .newlines)
        var currentSection = ""
        
        var expressionStyle: CommunicationStyle?
        var topics: Set<TopicCategory> = []
        var tone: ToneCategory?
        
        var notableElements: [NotableElement] = []
        
        var moodRating: Double?
        var sleepRating: Int?
        
        var followUpData: [String: String] = [:]
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine.starts(with: "1. Expression Analysis") {
                currentSection = "expression"
                continue
            } else if trimmedLine.starts(with: "2. Notable Elements") {
                currentSection = "notable"
                continue
            } else if trimmedLine.starts(with: "3. Mood Information") {
                currentSection = "mood"
                continue
            } else if trimmedLine.starts(with: "4. Follow-Up Focus") {
                currentSection = "followUp"
                continue
            }
            
            
            if trimmedLine.starts(with: "-") {
                let content = extractContent(from: trimmedLine, prefix: "-")
                
                if let colonIndex = content.firstIndex(of: ":") {
                    let key = String(content[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                    let value = String(content[content.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                    
                    switch currentSection {
                    case "expression":
                        switch key {
                        case "style":
                            expressionStyle = CommunicationStyle(rawValue: value.lowercased())
                        case "topics":
                            topics = parseTopics(from: value)
                        case "tone":
                            tone = ToneCategory(rawValue: value.lowercased())
                        default:
                            break
                        }
                        
                    case "notable":
                        if value.lowercased() != "none" {
                            let elements = parseNotableElements(key: key, value: value)
                            notableElements.append(contentsOf: elements)
                        }
                        
                    case "mood":
                        switch key {
                        case "rating":
                            let numericValue = value.components(separatedBy: CharacterSet.decimalDigits.inverted).joined(separator: ".").trimmingCharacters(in: .whitespacesAndNewlines)
                            moodRating = Double(numericValue)

                            if let moodRating = moodRating {
                                print("Parsed mood rating: \(moodRating)")
                            } else {
                                print("Failed to parse mood rating from value: \(value)")
                            }
                        case "sleep":
                            sleepRating = Int(value.components(separatedBy: CharacterSet.decimalDigits.inverted).joined())
                        default:
                            break
                        }
                        
                    case "followUp":
                        switch key {
                        case "question":
                            followUpData["question"] = value
                        case "purpose":
                            followUpData["purpose"] = value
                        default:
                            break
                        }
                        
                    default:
                        break
                    }
                }
            }
        }
        
        guard let style = expressionStyle,
              let toneValue = tone else {
            throw AnalysisError.missingRequiredFields(fields: ["style", "tone"])
        }
        
        let expression = DailyExpression(
            style: style,
            topics: topics,
            tone: toneValue
        )
        
        let mood = MoodCorrelation(
            rating: moodRating, sleep: sleepRating
        )
        
        return DailyAIAnalysisResult(
            date: Date(),
            expression: expression,
            notableElements: notableElements,
            mood: mood,
            followUp: FollowUp(
                question: followUpData["question"] ?? "",
                purpose: followUpData["purpose"] ?? ""
            )
        )
    }
    
    private func parseTopics(from string: String) -> Set<TopicCategory> {
        let cleanedString = string.replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
        
        let topicStrings = cleanedString.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        
        return Set(topicStrings.compactMap { TopicCategory(rawValue: $0) })
    }
    
    private func parseNotableElements(key: String, value: String) -> [NotableElement] {
        let cleanedValue = value.replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
        
        let elements = cleanedValue.components(separatedBy: "\",")
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: " \"")) }
        
        let elementType: NotableElement.ElementType
        switch key {
        case "insights":
            elementType = .insight
        case "wins":
            elementType = .win
        case "challenges":
            elementType = .challenge
        case "positives":
            elementType = .positive
        case "strategies":
            elementType = .strategy
        case "intentions":
            elementType = .intention
        default:
            return []
        }
        
        return elements.filter { !$0.isEmpty }.map {
            NotableElement(type: elementType, content: $0)
        }
    }
    
    private func extractContent(from line: String, prefix: String) -> String {
        if let range = line.range(of: prefix) {
            return String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        }
        return line.trimmingCharacters(in: .whitespaces)
    }
    
    private func getTodaysResponses() async -> [(question: String, answer: String)] {
        var responses: [(question: String, answer: String)] = []

        if let moodRating = DailyCheckinManager.shared.todaysCheckIn?.rating {
            responses.append((
                question: "How are you feeling today?",
                answer: "Rated mood as \(Double(moodRating)) out of 10"
            ))
            
            print("the mooding rating: \(moodRating)")
        }
        
        let cachedResponses = ReflectionSessionManager.shared.getTodaysCachedResponses()
        responses.append(contentsOf: cachedResponses.map { response in
            (question: response.prompt, answer: response.transcript)
        })
        
        return responses
    }
}



private struct OpenAIResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let content: String
    }
}
