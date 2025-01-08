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
        let formattedResponses = responses.enumerated().map { index, response in
            """
            Question \(index + 1): \(response.question)
            Response \(index + 1): \(response.answer)
            """
        }.joined(separator: "\n\n")
        
        let prompt = """
        You are analyzing these three daily journal entries as a UNIFIED WHOLE to provide clear, supportive insights. Keep all responses brief and direct, using "you/your" in descriptions.

        Analyze these responses:

        \(formattedResponses)

        1. Emotional State
        - emotion: [SELECT ONE: energetic, hopeful, peaceful, determined, curious, overwhelmed, thoughtful, excited, grateful, focused, inspired, confident, reflective, anxious, content, motivated, tired, somber, tender, vulnerable]
        - description: [ONE clear sentence showing how this appears in their writing]

        2. Expression Style
        - filler_words: [SELECT ONE: minimal/moderate/frequent]
        - pattern: [SELECT ONE: analytical, practical, emotional, action-focused, reflective]
        - note: [ONE observation about their communication style]

        3. Social Landscape
        - focus: [SELECT ONE: self-centered/relationship-focused/balanced]
        - context: [SELECT ONE: work/personal/mixed]
        - connections: [ONE sentence about key relationships or interactions mentioned]

        4. Next Steps
        If actions mentioned:
        - List each clear action or intention expressed (keep brief)
        If none: "No specific actions identified"

        5. Challenges
        If challenges mentioned:
        - List each clear challenge or concern expressed (keep brief)
        If none: "No specific challenges identified"

        6. Follow-up
        - question: [ONE specific question based on their main focus/challenge]
        - purpose: [ONE brief sentence explaining why this question matters for their growth]
        
        7. key_moments:
        [Identify 1-2 most meaningful SELF-REFLECTIVE statements that directly address their prompts. Focus on personal insights, realizations, or feelings about themselves.]

        Requirements:
        - Each insight must explicitly answer/address its prompt
        - Must be about the user's own experiences, feelings, growth, or self-understanding
        - Include enough context to understand the insight independently
        - Prioritize:
          * Personal realizations about themselves
          * Self-awareness moments
          * Their own feelings or reactions
          * Their personal growth or changes
        - AVOID:
          * Observations about others
          * General statements about situations
          * External events without personal reflection
          * Overly private or sensitive revelations
        - Return "nil" if no qualifying self-reflective statements found

        Format each as:
        - prompt: [the exact question asked]
        - insight: [the exact response phrase that shows self-reflection]
        or "nil" if no qualifying statements found
        

        Key Requirements:
        - All descriptions must be in second person ("you are")
        - Keep everything concise and clear
        - Frame observations constructively
        - Multiple actions/challenges can be listed but keep each brief
        - Follow-up questions should encourage reflection without being leading
        - If unclear on emotion, choose the more constructive option
        """
        
        let requestBody: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": "You are an expert at analyzing personal reflections and providing insights while maintaining appropriate boundaries. You focus on patterns and themes across multiple responses."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.4,
            "top_p": 0.9,
            "max_tokens": 1200,
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
        
        var currentSection = ""
        var emotionData: [String: String] = [:]
        var expressionData: [String: String] = [:]
        var socialData: [String: String] = [:]
        var nextStepsData: [String] = []
        var challengesData: [String] = []
        var followUpData: [String: String] = [:]
        
        // Track if we've hit the key_moments section
        var keyMomentsLines: [String] = []
        var inKeyMomentsSection = false
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Handle section changes
            switch true {
            case trimmedLine.starts(with: "1. Emotional State"):
                currentSection = "emotion"
                inKeyMomentsSection = false
            case trimmedLine.starts(with: "2. Expression Style"):
                currentSection = "expression"
                inKeyMomentsSection = false
            case trimmedLine.starts(with: "3. Social Landscape"):
                currentSection = "social"
                inKeyMomentsSection = false
            case trimmedLine.starts(with: "4. Next Steps"):
                currentSection = "nextSteps"
                inKeyMomentsSection = false
            case trimmedLine.starts(with: "5. Challenges"):
                currentSection = "challenges"
                inKeyMomentsSection = false
            case trimmedLine.starts(with: "6. Follow-up"):
                currentSection = "followUp"
                inKeyMomentsSection = false
            case trimmedLine.starts(with: "7. key_moments"):
                currentSection = "keyMoments"
                inKeyMomentsSection = true
                continue
            default:
                break
            }
            
            
            if inKeyMomentsSection && !trimmedLine.isEmpty {
                keyMomentsLines.append(trimmedLine)
                continue
            }
            
            if trimmedLine.starts(with: "-") {
                let content = extractContent(from: trimmedLine, prefix: "-")
                if let colonIndex = content.firstIndex(of: ":") {
                    let key = String(content[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                    let value = String(content[content.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                    
                    switch currentSection {
                    case "emotion":
                        emotionData[key] = value
                    case "expression":
                        expressionData[key] = value
                    case "social":
                        socialData[key] = value
                    case "followUp":
                        followUpData[key] = value
                    default:
                        break
                    }
                } else if currentSection == "nextSteps" && !trimmedLine.contains("If none") {
                    nextStepsData.append(content)
                } else if currentSection == "challenges" && !trimmedLine.contains("If none") {
                    challengesData.append(content)
                }
            }
        }
            
            
        guard let emotion = emotionData["emotion"],
              let emotionDesc = emotionData["description"] else {
            throw AnalysisError.missingFields(fields: ["emotion"])
        }
        
        // Create ExpressionStyle
        guard let fillerWords = expressionData["filler_words"],
              let pattern = expressionData["pattern"],
              let note = expressionData["note"] else {
            throw AnalysisError.missingFields(fields: ["expression"])
        }
        
        // Create SocialLandscape
        guard let focus = socialData["focus"],
              let context = socialData["context"],
              let connections = socialData["connections"] else {
            throw AnalysisError.missingFields(fields: ["social"])
        }
        
        // Create FollowUp
        guard let question = followUpData["question"],
              let purpose = followUpData["purpose"] else {
            throw AnalysisError.missingFields(fields: ["followUp"])
        }
    
        if !keyMomentsLines.isEmpty {
            if let keyMoments = parseKeyMoments(keyMomentsLines) {
                for moment in keyMoments {
                    KeyMomentManager.shared.saveKeyMoment(moment)
                }
            }
        }
                
        
        return AIAnalysisResult(
            emotion: EmotionAnalysis(
                emotion: emotion,
                description: emotionDesc
            ),
            expression: ExpressionStyle(
                fillerWords: fillerWords,
                pattern: pattern,
                note: note
            ),
            social: SocialLandscape(
                focus: focus,
                context: context,
                connections: connections
            ),
            nextSteps: NextSteps(
                actions: nextStepsData,
                hasActions: !nextStepsData.isEmpty
            ),
            challenges: Challenges(
                items: challengesData,
                hasChallenges: !challengesData.isEmpty
            ),
            followUp: FollowUp(
                question: question,
                purpose: purpose
            )
        )
    }
    
    private func parseKeyMoments(_ lines: [String]) -> [KeyMomentModel]? {
        var currentSection = ""
        var moments: [KeyMomentModel] = []
        var currentMoment: [String: String] = [:]
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine == "nil" {
                return nil
            }
            
            if trimmedLine.starts(with: "- prompt:") {
                if !currentMoment.isEmpty {
                    if let prompt = currentMoment["prompt"], let insight = currentMoment["insight"] {
                        moments.append(KeyMomentModel(prompt: prompt, insight: insight, date: Date()))
                    }
                    currentMoment = [:]
                }
                currentMoment["prompt"] = extractContent(from: trimmedLine, prefix: "- prompt:")
            } else if trimmedLine.starts(with: "- insight:") {
                currentMoment["insight"] = extractContent(from: trimmedLine, prefix: "- insight:")
            }
        }
        
        // Add last moment if exists
        if !currentMoment.isEmpty {
            if let prompt = currentMoment["prompt"], let insight = currentMoment["insight"] {
                moments.append(KeyMomentModel(prompt: prompt, insight: insight, date: Date()))
            }
        }
        
        return moments.isEmpty ? nil : moments
    }
    
    func extractContent(from line: String, prefix: String) -> String {
        if let range = line.range(of: prefix, options: .caseInsensitive) {
            return String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        }
        return line.trimmingCharacters(in: .whitespaces)
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
