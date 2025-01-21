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
            Analyze these daily reflection responses while maintaining privacy. Group analysis by question type.
            
            [Format: Each response has "question" and "answer" fields]
            
            1. Core Metrics
            [FROM "How are you feeling today?"]
            mood_data: {
                exists: [YES/NO],
                rating: [EXTRACT NUMBER 1-10 if exists]
            }
            
            [FROM "How many hours did you sleep?"]
            sleep_data: {
                exists: [YES/NO],
                hours: [EXTRACT NUMBER if exists]
            }
            
            2. Topic & Content Analysis
            [FROM "What moment from today stands out"]
            standout_analysis: {
                exists: [YES/NO],
                primary_topic: [IF EXISTS: work, relationships, health, growth, creativity, purpose],
                sentiment: [positive/neutral/negative],
                key_moment: [IF contains a meaningful realization, important event, or significant insight, extract it cleanly. Use ellipses for brevity. Limit to 1-2 sentences. If no truly significant moment, output NONE]
            }
            
            [FROM "Give a short summary"]
            summary_analysis: {
                exists: [YES/NO],
                primary_topic: [IF EXISTS and no standout: same topic categories as above],
                sentiment: [positive/neutral/negative]
            }
            
            [FROM "Share anything on your mind"]
            freeform_analysis: {
                exists: [YES/NO],
                primary_topic: [IF EXISTS and no standout: same topic categories as above],
                sentiment: [positive/neutral/negative]
            }
            
            3. Language Analysis
            [ANALYZE ALL RESPONSES]
            filler_analysis: {
                total_count: [COUNT of: um, uh, like, you know, kind of, sort of]
            }
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
        
        return try AIAnalyzer.parseFromAIResponse(content)
    }

    
    static func parseFromAIResponse(_ response: String) throws -> DailyAIAnalysisResult {
        // Split response into sections
        let sections = response.components(separatedBy: "\n\n")
        
        // Extract each analysis section
        let moodData = try parseMoodData(from: sections)
        let sleepData = try parseSleepData(from: sections)
        let standoutAnalysis = try parseStandoutAnalysis(from: sections)
        let summaryAnalysis = try parseSummaryAnalysis(from: sections)
        let freeformAnalysis = try parseFreeformAnalysis(from: sections)
        let fillerAnalysis = try parseFillerAnalysis(from: sections)
        
        return DailyAIAnalysisResult(
            date: Date(),
            moodData: moodData,
            sleepData: sleepData,
            standoutAnalysis: standoutAnalysis,
            summaryAnalysis: summaryAnalysis,
            freeformAnalysis: freeformAnalysis,
            fillerAnalysis: fillerAnalysis
        )
    }
    
    private static func parseMoodData(from sections: [String]) throws -> MoodData? {
        guard let moodSection = sections.first(where: { $0.contains("mood_data:") }) else {
            return nil
        }
        
        let exists = moodSection.contains("exists: YES")
        let rating = try? extractDouble(from: moodSection, field: "rating:")
        
        return MoodData(exists: exists, rating: rating)
    }
    
    private static func parseSleepData(from sections: [String]) throws -> SleepData? {
        guard let sleepSection = sections.first(where: { $0.contains("sleep_data:") }) else {
            return nil
        }
        
        let exists = sleepSection.contains("exists: YES")
        let hours = try? extractDouble(from: sleepSection, field: "hours:")
        
        return SleepData(exists: exists, hours: hours)
    }
    
    private static func parseStandoutAnalysis(from sections: [String]) throws -> StandoutAnalysis? {
        guard let standoutSection = sections.first(where: { $0.contains("standout_analysis:") }) else {
            return nil
        }
        
        let exists = standoutSection.contains("exists: YES")
        let topic = try? extractTopic(from: standoutSection, field: "primary_topic:")
        let sentiment = try? extractSentiment(from: standoutSection, field: "sentiment:")
        let keyMoment = try? extractString(from: standoutSection, field: "key_moment:")
        
        // If key_moment is "NONE", set to nil
        let finalKeyMoment = keyMoment == "NONE" ? nil : keyMoment
        
        return StandoutAnalysis(
            exists: exists,
            primaryTopic: topic,
            sentiment: sentiment,
            keyMoment: finalKeyMoment
        )
    }
    
    private static func parseSummaryAnalysis(from sections: [String]) throws -> SummaryAnalysis? {
        guard let summarySection = sections.first(where: { $0.contains("summary_analysis:") }) else {
            return nil
        }
        
        let exists = summarySection.contains("exists: YES")
        let topic = try? extractTopic(from: summarySection, field: "primary_topic:")
        let sentiment = try? extractSentiment(from: summarySection, field: "sentiment:")
        
        return SummaryAnalysis(
            exists: exists,
            primaryTopic: topic,
            sentiment: sentiment
        )
    }
    
    private static func parseFreeformAnalysis(from sections: [String]) throws -> FreeformAnalysis? {
        guard let freeformSection = sections.first(where: { $0.contains("freeform_analysis:") }) else {
            return nil
        }
        
        let exists = freeformSection.contains("exists: YES")
        let topic = try? extractTopic(from: freeformSection, field: "primary_topic:")
        let sentiment = try? extractSentiment(from: freeformSection, field: "sentiment:")
        
        return FreeformAnalysis(
            exists: exists,
            primaryTopic: topic,
            sentiment: sentiment
        )
    }
    
    private static func parseFillerAnalysis(from sections: [String]) throws -> FillerAnalysis {
        guard let fillerSection = sections.first(where: { $0.contains("filler_analysis:") }) else {
            return FillerAnalysis(totalCount: 0)
        }
        
        let totalCount = try extractInt(from: fillerSection, field: "total_count:") ?? 0
        return FillerAnalysis(totalCount: totalCount)
    }
    
    // Helper Extraction Methods
    private static func extractDouble(from text: String, field: String) throws -> Double? {
        guard let value = try extractString(from: text, field: field) else { return nil }
        return Double(value.trimmingCharacters(in: .whitespaces))
    }
    
    private static func extractInt(from text: String, field: String) throws -> Int? {
        guard let value = try extractString(from: text, field: field) else { return nil }
        return Int(value.trimmingCharacters(in: .whitespaces))
    }
    
    private static func extractString(from text: String, field: String) throws -> String? {
        guard let range = text.range(of: field) else { return nil }
        let afterField = String(text[range.upperBound...])
        let lines = afterField.components(separatedBy: .newlines)
        let value = lines[0].trimmingCharacters(in: .whitespaces)
        return value.isEmpty ? nil : value
    }
    
    private static func extractTopic(from text: String, field: String) throws -> TopicCategory? {
        guard let value = try extractString(from: text, field: field)?.lowercased() else { return nil }
        return TopicCategory(rawValue: value)
    }
    
    private static func extractSentiment(from text: String, field: String) throws -> SentimentCategory? {
        guard let value = try extractString(from: text, field: field)?.lowercased() else { return nil }
        return SentimentCategory(rawValue: value)
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
        
        if let sleepRating = SleepCheckinManager.shared.todaysSleep?.hours {
            responses.append((
                question: "How much did you sleep today?",
                answer: "Slept for \(Double(sleepRating)) hours"
            ))
            
            print("the sleep rating: \(sleepRating)")
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
