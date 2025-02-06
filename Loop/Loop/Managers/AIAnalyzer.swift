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
            Analyze these daily reflection responses while maintaining privacy. Focus on identifying topics discussed and core patterns.

            \(formattedResponses)

            ### MOOD & SLEEP DATA:
            mood_data:
            [FROM "How are you feeling today?"]
            exists: YES/NO
            rating: (number 1-10)

            sleep_data:
            [FROM "How many hours did you sleep?"]
            exists: YES/NO
            hours: (number)

            ### STANDOUT MOMENT ANALYSIS:
            standout_analysis:
            [FROM "What moment from today stands out most to you?"]
            category: (work/relationships/health/learning/creativity/purpose/relaxation/finances/growth)
            sentiment: (positive/neutral/negative)
            key_moment: [Direct quote edited for impact and grammar: use ellipses (...) to skip unnecessary parts, while keeping authenticity.]

            ### ADDITIONAL KEY MOMENTS:
            additional_key_moments:
            [FROM ALL OTHER RESPONSES, EXCLUDING STANDOUT MOMENT]
            exists: YES/NO
            moments:
              key_moment: [Direct quote edited for clarity while preserving personal voice.]
              category: (realization/learning/success/challenge/connection/decision/plan)
              source_type: (summary/freeform)

            ### TOPIC SENTIMENT ANALYSIS:
            topic_sentiments:
            [IDENTIFY CORE THEMES FROM ALL RESPONSES. LOOK FOR NATURALLY MENTIONED TOPICS, NOT WHEN DIRECTLY ASKED. ABSTRACT TO MEANINGFUL LIFE AREAS.]
            exists: YES/NO
            topics:
              topic: [USE CONSISTENT PLURAL FORMS FROM: relationships/work/sports/health/hobbies/finances/learning/community/wellness]
              sentiment: (number between -1.0 and 1.0)
              [USE EXACT FORMAT: single topic per entry, 2-space indentation]
              // More negative numbers (-1.0 to -0.1) indicate more negative sentiment
              // 0.0 indicates neutral sentiment
              // More positive numbers (0.1 to 1.0) indicate more positive sentiment

            TOPIC ABSTRACTION RULES:
            - Extract core life areas, not specific activities or objects
            - Always use plural form (relationships not relationship)
            - Map to closest meaningful category:
              * Personal interactions/fights/dating → relationships
              * Job/career/workplace/tasks → work
              * Exercise/games/physical activities → sports
              * Diet/sleep/medical → health
              * Creative/recreational activities → hobbies
              * Money/investments/spending → finances
              * Education/skills/development → learning
              * Volunteering/social causes → community
              * Mental health/spirituality/self-care → wellness
            - Do not force topics - only include if naturally discussed

            ### DAILY SUMMARY:
            daily_summary:
            [SYNTHESIZE FROM ALL RESPONSES]
            exists: YES/NO
            summary: (2-3 sentence overview in the second-person capturing key themes, mood, and notable events from the day's reflections. Be personable and thoughtful. Don't provide advice, but identify potential patterns and other things you noticed if possible. Don't force anything.)

            CRITICAL FORMAT RULES:
            1. The topic_sentiments: field name must be exact
            2. Use 2-space indentation under topics:
            3. Each topic must be on its own line with 2-space indent
            4. No markdown bullets or special characters
            5. Include exact field names with colons
            6. Follow number formats exactly
        """
        

            let requestBody: [String: Any] = [
                "model": "gpt-4o-mini",
                "messages": [
                    ["role": "system", "content": "You are an expert at analyzing personal reflections while maintaining privacy. Focus on finding clear elements rather than forcing insights. For key moments, never repeat content or topics between standout and additional moments. Ensure recurring themes are genuinely mentioned multiple times."],
                    ["role": "user", "content": prompt]
                ],
                "temperature": 0.3,
                "max_tokens": 1000
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
        print("\n=== Starting AI Response Parsing ===")
        print("Raw response:", response)
        
        let sections = response.components(separatedBy: "\n\n")
        print("\nFound \(sections.count) sections:")
        sections.enumerated().forEach { index, section in
            print("\n--- Section \(index) ---")
            print(section)
        }
        
        print("\n=== Parsing Individual Sections ===")
        
        let moodData = try parseMoodData(from: sections)
        let sleepData = try parseSleepData(from: sections)
        let standoutAnalysis = try parseStandoutAnalysis(from: sections)
        let additionalKeyMoments = try parseAdditionalKeyMoments(from: sections)
        let topicSentiments = try parseTopicSentiments(from: sections)
        let dailySummary = try parseDailySummary(from: sections)
        
        let result = DailyAIAnalysisResult(
            date: Date(),
            moodData: moodData,
            sleepData: sleepData,
            standoutAnalysis: standoutAnalysis,
            additionalKeyMoments: additionalKeyMoments,
            topicSentiments: topicSentiments,
            dailySummary: dailySummary
        )
        print("\nFinal Result:", result)
        return result
    }
    
    private static func parseMoodData(from sections: [String]) throws -> MoodData? {
        guard let section = sections.first(where: { $0.contains("mood_data:") }) else {
            return nil
        }
        
        let exists = section.contains("exists: YES")
        let rating = try? extractDouble(from: section, field: "rating:")
        
        return MoodData(exists: exists, rating: rating)
    }
    
    private static func parseSleepData(from sections: [String]) throws -> SleepData? {
        guard let section = sections.first(where: { $0.contains("sleep_data:") }) else {
            return nil
        }
        
        let exists = section.contains("exists: YES")
        let hours = try? extractDouble(from: section, field: "hours:")
        
        return SleepData(exists: exists, hours: hours)
    }
    
    private static func parseDailySummary(from sections: [String]) throws -> DailySummary? {
        guard let section = sections.first(where: { $0.contains("daily_summary:") }) else {
            return nil
        }
        
        let exists = section.contains("exists: YES")
        let summary = try? extractString(from: section, field: "summary:")
        
        return DailySummary(exists: exists, summary: summary)
    }
    
    private static func parseTopicSentiments(from sections: [String]) throws -> [TopicSentiment]? {
        guard let section = sections.first(where: { $0.contains("topic_sentiments:") }) else {
            return nil
        }

        var extractedTopics: [TopicSentiment] = []
        let lines = section.components(separatedBy: .newlines)
        
        var currentTopic: String?
        var currentSentiment: Double?
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("topic:") {
                if let topic = currentTopic, let sentiment = currentSentiment {
                    extractedTopics.append(TopicSentiment(topic: topic, sentiment: sentiment))
                }
                if let value = try? extractString(from: line, field: "topic:")?.lowercased() {
                    currentTopic = value
                    currentSentiment = nil
                }
            } else if trimmed.hasPrefix("sentiment:") {
                if let value = try? extractString(from: line, field: "sentiment:"),
                   let sentiment = Double(value) {
                    currentSentiment = sentiment
                }
            }
        }

        if let topic = currentTopic, let sentiment = currentSentiment {
            extractedTopics.append(TopicSentiment(topic: topic, sentiment: sentiment))
            print("the topic \(topic) and sentiment: \(sentiment)")
        }

        return extractedTopics.isEmpty ? nil : extractedTopics
    }


    
    private static func parseStandoutAnalysis(from sections: [String]) throws -> StandoutAnalysis? {
        guard let section = sections.first(where: { $0.contains("standout_analysis:") }) else {
            return nil
        }
        
        let topic = try? extractTopic(from: section, field: "category:")

        let sentimentStr = try? extractString(from: section, field: "sentiment:")
        let sentiment = sentimentStr.flatMap { Double($0) }
        
        let keyMoment = try? extractString(from: section, field: "key_moment:")
        let finalKeyMoment = keyMoment == "NONE" ? nil : keyMoment
        
        return StandoutAnalysis(
            exists: true,
            primaryTopic: topic,
            category: nil,
            sentiment: sentiment,
            keyMoment: finalKeyMoment
        )
    }
    
    private static func parseAdditionalKeyMoments(from sections: [String]) throws -> AdditionalKeyMoments? {
        guard let section = sections.first(where: { $0.contains("additional_key_moments:") }) else {
            return nil
        }
        
        let exists = section.contains("exists: YES")
        if !exists {
            return AdditionalKeyMoments(exists: false, moments: nil)
        }
        

        var moments: [KeyMomentModel] = []
        if let momentsText = try? extractString(from: section, field: "moments:") {
            let momentEntries = momentsText.components(separatedBy: "- key_moment:")
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            
            for entry in momentEntries {
                if let keyMoment = try? extractString(from: entry, field: ""),
                   let category = try? extractMomentCategory(from: entry, field: "category:"),
                   let sourceType = try? extractSourceType(from: entry, field: "source_type:") {
                    
                    let moment = KeyMomentModel(
                        keyMoment: keyMoment.trimmingCharacters(in: .whitespaces),
                        category: category,
                        sourceType: sourceType
                    )
                    moments.append(moment)
                }
            }
        }
        
        return AdditionalKeyMoments(exists: true, moments: moments.isEmpty ? nil : moments)
    }
    
    private static func parseRecurringThemes(from sections: [String]) throws -> RecurringThemes? {
        guard let section = sections.first(where: { $0.contains("recurring_themes:") }) else {
            return nil
        }
        
        let exists = section.contains("exists: YES")
        if !exists {
            return RecurringThemes(exists: false, themes: nil)
        }
        
        var themes: [String] = []
        if let themesText = try? extractString(from: section, field: "themes:") {
            themes = themesText
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }
        
        return RecurringThemes(exists: true, themes: themes.isEmpty ? nil : themes)
    }
    
    private static func parseFillerAnalysis(from sections: [String]) throws -> FillerAnalysis {
        guard let section = sections.first(where: { $0.contains("filler_analysis:") }) else {
            return FillerAnalysis(totalCount: 0)
        }
        
        let totalCount = try extractInt(from: section, field: "total_count:") ?? 0
        return FillerAnalysis(totalCount: totalCount)
    }
    
    private static func parseFollowUpSuggestion(from sections: [String]) throws -> FollowUpSuggestion {
        guard let section = sections.first(where: { $0.contains("follow_up_suggestion:") }) else {
            return FollowUpSuggestion(exists: false, suggestion: nil)
        }
        
        let suggestion = try? extractString(from: section, field: "suggestion:")
        
        return FollowUpSuggestion(exists: true, suggestion: suggestion)
    }
    

    private static func extractDouble(from text: String, field: String) throws -> Double? {
        guard let value = try extractString(from: text, field: field) else { return nil }
        return Double(value.trimmingCharacters(in: .whitespaces))
    }
    
    private static func extractInt(from text: String, field: String) throws -> Int? {
        guard let value = try extractString(from: text, field: field) else { return nil }
        return Int(value.trimmingCharacters(in: .whitespaces))
    }
    
    private static func extractString(from text: String, field: String) throws -> String? {
        let searchText = field.isEmpty ? text : field
        guard let range = text.range(of: searchText) else { return nil }
        
        let afterField = String(text[range.upperBound...])
        let lines = afterField.components(separatedBy: .newlines)
        let value = lines[0].trimmingCharacters(in: .whitespaces)
        
        return value.isEmpty ? nil : value
    }
    
    private static func extractTopic(from text: String, field: String) throws -> TopicCategory? {
        guard let value = try extractString(from: text, field: field)?.lowercased() else { return nil }
        return TopicCategory(rawValue: value)
    }
    
    private static func extractMomentCategory(from text: String, field: String) throws -> MomentCategory? {
        print("Trying to extract category from:", text)
        
        guard let value = try extractString(from: text, field: field)?.lowercased() else {
            print("No category value found")
            return nil
        }
        
        print("Found category value:", value)
        
        let category = MomentCategory(rawValue: value)
        print("Parsed category:", category ?? "nil")
        return category
    }
    
    private static func extractSourceType(from text: String, field: String) throws -> SourceType? {
        guard let value = try extractString(from: text, field: field)?.lowercased() else { return nil }
        return SourceType(rawValue: value)
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
