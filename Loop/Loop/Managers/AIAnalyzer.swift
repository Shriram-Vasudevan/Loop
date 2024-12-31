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
    
    
    func analyzeResponses(_ responses: [(question: String, answer: String)]) async throws -> AIAnalysisResult {
        // Format the responses for the prompt
        let formattedResponses = responses.enumerated().map { index, response in
            """
            Question \(index + 1): \(response.question)
            Response \(index + 1): \(response.answer)
            """
        }.joined(separator: "\n\n")
        
        let prompt = """
        Analyze these three responses as a unified whole. Provide a cohesive analysis focusing on consistent patterns across all responses. Address the user in second person ("your responses"):

        \(formattedResponses)

        1. Emotion:
        - primary: [single dominant emotion - e.g., frustrated, hopeful, concerned]
        - intensity: [1-10 scale]
        - tone: [how emotion is expressed - e.g., reserved, direct, candid]
        - description: [1 sentence showing how this sentiment appears across responses]

        2. Time Focus:
        - orientation: [past/present/future/mixed]
        - description: [1 sentence about how time perspective shapes responses]

        3. Focus Analysis:
        - pattern: [how user processes information - e.g., analytical, practical, experiential, action-focused]
        - description: [1 short sentence demonstrating this pattern]

        4. Significant Phrases:
        - insights: [1-2 quotes showing key realizations]
        - reflections: [1-2 quotes showing self-awareness]
        - decisions: [1-2 quotes showing choices/commitments]
        - description: [1 sentence connecting these elements]

        5. Follow-up:
        - question: [short single follow-up question targeting main pattern]
        - context: [1 shore phrase explaining relevance]
        - focus: [specific aspect being explored]
        """
        
        let requestBody: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": "You are an expert at analyzing personal reflections and providing insights while maintaining appropriate boundaries. You focus on patterns and themes across multiple responses."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.4,
            "top_p": 0.9,
            "max_tokens": 900,
            "frequency_penalty": 0.0,
            "presence_penalty": 0.0
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
    
    private func parseAIResponse(_ response: String) throws -> AIAnalysisResult {
            let lines = response.components(separatedBy: .newlines)
            
            func extractContent(from line: String, prefix: String) -> String {
                if let range = line.range(of: prefix, options: .caseInsensitive) {
                    return String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                }
                return line.trimmingCharacters(in: .whitespaces)
            }
            
            func parsePhrases(_ content: String) -> [String] {
                if content.lowercased() == "none" {
                    return []
                }
                return content.components(separatedBy: ", ")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
            }
            
            var emotion: EmotionAnalysis?
            var timeFocus: TimeFocus?
            var focus: FocusAnalysis?
            var phrases: SignificantPhrases?
            var followUp: FollowUp?
            
            var currentSection = ""
            var tempEmotionData: [String: String] = [:]
            var tempTimeData: [String: String] = [:]
            var focusData: [String: String] = [:]
            var tempPhrasesData: [String: String] = [:]
            var tempFollowUpData: [String: String] = [:]
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                
                switch true {
                case trimmedLine.starts(with: "1. Emotion:"):
                    currentSection = "emotion"
                case trimmedLine.starts(with: "2. Time Focus:"):
                    currentSection = "time"
                case trimmedLine.starts(with: "3. Focus Analysis:"):
                    currentSection = "focus"
                case trimmedLine.starts(with: "4. Significant Phrases:"):
                    currentSection = "phrases"
                case trimmedLine.starts(with: "5. Follow-up:"):
                    currentSection = "followup"
                case trimmedLine.starts(with: "-"):
                    let content = extractContent(from: trimmedLine, prefix: "-")
                    if let colonIndex = content.firstIndex(of: ":") {
                        let key = String(content[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                        let value = String(content[content.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                        
                        switch currentSection {
                        case "emotion":
                            tempEmotionData[key] = value
                        case "time":
                            tempTimeData[key] = value
                        case "focus":
                            focusData[key] = value
                        case "phrases":
                            tempPhrasesData[key] = value
                        case "followup":
                            tempFollowUpData[key] = value
                        default:
                            break
                        }
                    }
                default:
                    break
                }
            }
            
            // Parse Emotion Analysis
            if let primary = tempEmotionData["primary"],
               let intensityStr = tempEmotionData["intensity"],
               let intensity = Int(intensityStr.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()),
               let tone = tempEmotionData["tone"],
               let description = tempEmotionData["description"] {
                emotion = EmotionAnalysis(
                    primary: primary,
                    intensity: intensity,
                    tone: tone,
                    description: description
                )
            }
            
            // Parse Time Focus
            if let orientationStr = tempTimeData["orientation"],
               let description = tempTimeData["description"] {
                let orientation = TimeOrientation(rawValue: orientationStr.lowercased()) ?? .mixed
                timeFocus = TimeFocus(
                    orientation: orientation,
                    description: description
                )
            }
            
            // Parse Focus Analysis
            if let pattern = focusData["pattern"],
               let description = focusData["description"] {
                focus = FocusAnalysis(
                    pattern: pattern,
                    description: description
                )
            }
            
            // Parse Significant Phrases
            if let insights = tempPhrasesData["insights"],
               let reflections = tempPhrasesData["reflections"],
               let decisions = tempPhrasesData["decisions"],
               let description = tempPhrasesData["description"] {
                phrases = SignificantPhrases(
                    insightPhrases: parsePhrases(insights),
                    reflectionPhrases: parsePhrases(reflections),
                    decisionPhrases: parsePhrases(decisions),
                    description: description
                )
            }
            
            // Parse Follow Up
            if let question = tempFollowUpData["question"],
               let context = tempFollowUpData["context"],
               let focus = tempFollowUpData["focus"] {
                followUp = FollowUp(
                    question: question,
                    context: context,
                    focus: focus
                )
            }
            
            // Validate all required components are present
            guard let emotion = emotion,
                  let timeFocus = timeFocus,
                  let focus = focus,
                  let phrases = phrases,
                  let followUp = followUp else {
                let missingFields = [
                    emotion == nil ? "emotion" : nil,
                    timeFocus == nil ? "timeFocus" : nil,
                    focus == nil ? "focus" : nil,
                    phrases == nil ? "phrases" : nil,
                    followUp == nil ? "followUp" : nil
                ].compactMap { $0 }
                
                throw AnalysisError.missingFields(fields: missingFields)
            }
            
            return AIAnalysisResult(
                emotion: emotion,
                timeFocus: timeFocus,
                focus: focus,
                phrases: phrases,
                followUp: followUp
            )
        }
}

class WeeklyAIAnalyzer {
    static let shared = WeeklyAIAnalyzer()
    private let apiKey: String
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    
    init() {
        self.apiKey = ConfigurationKey.apiKey
    }
    
    func analyzeWeek(_ loops: [LoopAnalysis]) async throws -> WeeklyAIInsights {
        // Format transcripts by date for the prompt
        let formattedTranscripts = loops.map { loop in
            """
            Date: \(formatDate(loop.timestamp))
            Transcript: \(loop.transcript)
            """
        }.joined(separator: "\n\n")
        
        let prompt = """
        Analyze these daily reflections from the past week:

        \(formattedTranscripts)

        Respond in exactly the following format with no additional text. Use "nil" if unable to determine any section:

        1. key_moments:
        [for each moment (up to 3), provide exactly:
        - date: [YYYY-MM-DD]
        - quote: [exact quote]
        - context: [1 sentence context]
        - significance: [1 sentence significance]
        ]
        or "nil" if none found

        2. themes:
        [for each theme (up to 2), provide exactly:
        - name: [single word or short phrase]
        - description: [1-2 sentences]
        - quotes: [list of up to 2 quotes with dates in YYYY-MM-DD format]
        ]
        or "nil" if none found

        3. overall_tone: [one word descriptor]

        4. progress_notes: [2-3 sentences about progress or changes observed]
        or "nil" if none found

        5. patterns: [1-2 sentences about behavioral or thought patterns]
        or "nil" if none found

        6. suggestions: [1-2 concrete suggestions based on the analysis]
        or "nil" if none found
        """
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": "You are an analyzer that responds in the exact format requested. Use 'nil' when unable to determine something. Never deviate from the format."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.3,
            "max_tokens": 4000,
            "top_p": 0.1
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
        
        return try parseWeeklyAIResponse(content)
    }
    
    private func parseWeeklyAIResponse(_ response: String) throws -> WeeklyAIInsights {
        let sections = response.components(separatedBy: "\n\n")
        var keyMoments: [KeyMoment]?
        var themes: [Theme]?
        var overallTone = ""
        var progressNotes: String?
        var patterns: String?
        var suggestions: String?
        
        for section in sections {
            if section.contains("1. key_moments:") {
                if !section.contains("nil") {
                    keyMoments = try parseKeyMoments(section)
                }
            } else if section.contains("2. themes:") {
                if !section.contains("nil") {
                    themes = try parseThemes(section)
                }
            } else if section.contains("3. overall_tone:") {
                overallTone = section.components(separatedBy: ":")[1].trimmingCharacters(in: .whitespaces)
            } else if section.contains("4. progress_notes:") {
                let content = section.components(separatedBy: ":")[1].trimmingCharacters(in: .whitespaces)
                progressNotes = content != "nil" ? content : nil
            } else if section.contains("5. patterns:") {
                let content = section.components(separatedBy: ":")[1].trimmingCharacters(in: .whitespaces)
                patterns = content != "nil" ? content : nil
            } else if section.contains("6. suggestions:") {
                let content = section.components(separatedBy: ":")[1].trimmingCharacters(in: .whitespaces)
                suggestions = content != "nil" ? content : nil
            }
        }
        
        return WeeklyAIInsights(
            keyMoments: keyMoments,
            themes: themes,
            overallTone: overallTone,
            progressNotes: progressNotes,
            patterns: patterns,
            suggestions: suggestions
        )
    }
    
    private func parseKeyMoments(_ section: String) throws -> [KeyMoment] {
        var moments: [KeyMoment] = []
        let lines = section.components(separatedBy: "\n")
        
        var currentMoment: [String: String] = [:]
        for line in lines {
            if line.contains("date:") {
                if !currentMoment.isEmpty {
                    if let moment = createKeyMoment(from: currentMoment) {
                        moments.append(moment)
                    }
                    currentMoment = [:]
                }
            }
            
            if line.contains("date:") {
                currentMoment["date"] = line.components(separatedBy: "date:")[1].trimmingCharacters(in: .whitespaces)
            } else if line.contains("quote:") {
                currentMoment["quote"] = line.components(separatedBy: "quote:")[1].trimmingCharacters(in: .whitespaces)
            } else if line.contains("context:") {
                currentMoment["context"] = line.components(separatedBy: "context:")[1].trimmingCharacters(in: .whitespaces)
            } else if line.contains("significance:") {
                currentMoment["significance"] = line.components(separatedBy: "significance:")[1].trimmingCharacters(in: .whitespaces)
            }
        }
        
        if !currentMoment.isEmpty {
            if let moment = createKeyMoment(from: currentMoment) {
                moments.append(moment)
            }
        }
        
        return moments
    }
    
    private func parseThemes(_ section: String) throws -> [Theme] {
        var themes: [Theme] = []
        let lines = section.components(separatedBy: "\n")
        
        var currentTheme: [String: Any] = [:]
        var currentQuotes: [QuoteReference] = []
        
        for line in lines {
            if line.contains("name:") {
                if !currentTheme.isEmpty {
                    if let theme = createTheme(from: currentTheme, quotes: currentQuotes) {
                        themes.append(theme)
                    }
                    currentTheme = [:]
                    currentQuotes = []
                }
            }
            
            if line.contains("name:") {
                currentTheme["name"] = line.components(separatedBy: "name:")[1].trimmingCharacters(in: .whitespaces)
            } else if line.contains("description:") {
                currentTheme["description"] = line.components(separatedBy: "description:")[1].trimmingCharacters(in: .whitespaces)
            } else if line.contains("quotes:") {
                let quotesText = line.components(separatedBy: "quotes:")[1].trimmingCharacters(in: .whitespaces)
                currentQuotes = parseQuoteReferences(quotesText)
            }
        }
        
        if !currentTheme.isEmpty {
            if let theme = createTheme(from: currentTheme, quotes: currentQuotes) {
                themes.append(theme)
            }
        }
        
        return themes
    }
    
    private func createKeyMoment(from dict: [String: String]) -> KeyMoment? {
        guard let dateStr = dict["date"],
              let quote = dict["quote"],
              let context = dict["context"],
              let significance = dict["significance"],
              let date = parseDate(dateStr) else {
            return nil
        }
        
        return KeyMoment(
            date: date,
            quote: quote,
            context: context,
            significance: significance
        )
    }
    
    private func createTheme(from dict: [String: Any], quotes: [QuoteReference]) -> Theme? {
        guard let name = dict["name"] as? String,
              let description = dict["description"] as? String else {
            return nil
        }
        
        return Theme(
            name: name,
            description: description,
            relatedQuotes: quotes
        )
    }
    
    private func parseQuoteReferences(_ text: String) -> [QuoteReference] {
        let quotePairs = text.components(separatedBy: "], [")
        return quotePairs.compactMap { pair in
            let components = pair.components(separatedBy: " (")
            guard components.count == 2,
                  let quote = components.first?.trimmingCharacters(in: CharacterSet(charactersIn: "[]")),
                  let dateStr = components.last?.trimmingCharacters(in: CharacterSet(charactersIn: ")")),
                  let date = parseDate(dateStr) else {
                return nil
            }
            return QuoteReference(quote: quote, date: date)
        }
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
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
