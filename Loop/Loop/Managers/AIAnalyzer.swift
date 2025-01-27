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
            Analyze these daily reflection responses while maintaining privacy. Look for responses to specific questions:

            \(formattedResponses)
        
            mood_data:
            [FROM "How are you feeling today?"]
            exists: YES/NO
            rating: (number 1-10)

            sleep_data:
            [FROM "How many hours did you sleep?"]
            exists: YES/NO
            hours: (number)

           standout_analysis:
               [FROM "What moment from today stands out most to you?"]
               category: (work/relationships/health/learning/creativity/purpose/relaxation/leisure)
               sentiment: (positive/neutral/negative)
               key_moment: [Direct quote edited for impact: use ellipses (...) to skip sentences/parts that break flow, light paraphrasing allowed to improve clarity, preserve personal voice and emotional weight, maintain key realizations, edit grammar while keeping authenticity.
               Example:
               Original: "I realized today that I'm actually really good at leading and even though sometimes I doubt myself and get nervous about presentations which happens a lot especially with new clients, I can actually handle it really well and people seem to respond positively to my style."
               Edited: "I realized today that I'm actually really good at leading... I can handle it really well and people respond positively to my style."]

           additional_key_moments:
               [FROM ALL OTHER RESPONSES, EXCLUDING CONTENT FROM STANDOUT]
               exists: YES/NO
               moments:
                 - key_moment: [Direct quote edited for impact: use ellipses (...) to skip sentences/parts that break flow, light paraphrasing allowed to improve clarity, preserve personal voice and emotional weight, maintain key realizations, edit grammar while keeping authenticity.
                   Example:
                   Original: "I realized today that I'm actually really good at this stuff and even though sometimes I doubt myself and get nervous about presentations which happens a lot especially with new clients, I can actually handle it really well and people seem to respond positively to my style."
                   Edited: "I realized today that I'm actually really good at this... I can handle it really well and people respond positively to my style."]
                   category: (realization/learning/success/challenge/connection/decision/plan)
                   source_type: (summary/freeform)
        
            recurring_themes:
            [ANALYZE ALL RESPONSES]
            exists: YES/NO
            themes: (comma-separated list)

            summary_analysis:
            [FROM "Give a short summary"]
            exists: YES/NO
            primary_topic: (work/relationships/health/growth/creativity/purpose)
            sentiment: (positive/neutral/negative)

            freeform_analysis:
            [FROM "Share anything on your mind"]
            exists: YES/NO
            primary_topic: (work/relationships/health/growth/creativity/purpose)
            sentiment: (positive/neutral/negative)

            filler_analysis:
            total_count: (number)
        
            follow_up_suggestion:
            [ANALYZE ALL RESPONSES]
            exists: YES/NO
            suggestion: (A gentle, open-ended follow-up based on recurring themes or emotional undertones. Should be encouraging and exploratory without directly referencing specific responses. Maximum 2 sentences. Example: "What helps you stay calm during times of transition?")
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
            
            // Rest of the API call code remains the same
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
        
        print("\n--- Parsing Mood Data ---")
        let moodData = try parseMoodData(from: sections)
        print("Mood Data Result:", moodData ?? "nil")
        
        print("\n--- Parsing Sleep Data ---")
        let sleepData = try parseSleepData(from: sections)
        print("Sleep Data Result:", sleepData ?? "nil")
        
        print("\n--- Parsing Standout Analysis ---")
        let standoutAnalysis = try parseStandoutAnalysis(from: sections)
        print("Standout Analysis Result:", standoutAnalysis ?? "nil")
        
        print("\n--- Parsing Additional Key Moments ---")
        let additionalKeyMoments = try parseAdditionalKeyMoments(from: sections)
        print("Additional Key Moments Result:", additionalKeyMoments ?? "nil")
        
        print("\n--- Parsing Recurring Themes ---")
        let recurringThemes = try parseRecurringThemes(from: sections)
        print("Recurring Themes Result:", recurringThemes ?? "nil")
        
        print("\n--- Parsing Summary Analysis ---")
        let summaryAnalysis = try parseSummaryAnalysis(from: sections)
        print("Summary Analysis Result:", summaryAnalysis ?? "nil")
        
        print("\n--- Parsing Freeform Analysis ---")
        let freeformAnalysis = try parseFreeformAnalysis(from: sections)
        print("Freeform Analysis Result:", freeformAnalysis ?? "nil")
        
        print("\n--- Parsing Filler Analysis ---")
        let fillerAnalysis = try parseFillerAnalysis(from: sections)
        print("Filler Analysis Result:", fillerAnalysis)
        
        print("\n--- Parsing Follow-up Suggestion ---")
            let followUpSuggestion = try parseFollowUpSuggestion(from: sections)
            print("Follow-up Suggestion Result:", followUpSuggestion)
        
        print("\n=== Parsing Complete ===")
        
        let result = DailyAIAnalysisResult(
            date: Date(),
            moodData: moodData,
            sleepData: sleepData,
            standoutAnalysis: standoutAnalysis,
            additionalKeyMoments: additionalKeyMoments,
            recurringThemes: recurringThemes,
            summaryAnalysis: summaryAnalysis,
            freeformAnalysis: freeformAnalysis,
            fillerAnalysis: fillerAnalysis, followUpSuggestion: followUpSuggestion
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
    
    private static func parseStandoutAnalysis(from sections: [String]) throws -> StandoutAnalysis? {
        print("--- Debug: Standout Analysis ---")
        
        guard let section = sections.first(where: { $0.contains("standout_analysis:") }) else {
            print("No standout section found")
            return nil
        }
        
        print("Found section:", section)
        

        let topic = try? extractTopic(from: section, field: "category:")
        print("Topic:", topic ?? "nil")
        
        let sentiment = try? extractSentiment(from: section, field: "sentiment:")
        print("Sentiment:", sentiment ?? "nil")
        
        let keyMoment = try? extractString(from: section, field: "key_moment:")
        print("Key moment:", keyMoment ?? "nil")
        
        let finalKeyMoment = keyMoment == "NONE" ? nil : keyMoment
        print("Final key moment:", finalKeyMoment ?? "nil")
        
        let result = StandoutAnalysis(
            exists: true,
            primaryTopic: topic,
            category: nil,
            sentiment: sentiment,
            keyMoment: finalKeyMoment
        )
        
        print("Final result:", result)
        print("-------------------------")
        
        return result
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
    
    private static func parseSummaryAnalysis(from sections: [String]) throws -> SummaryAnalysis? {
        guard let section = sections.first(where: { $0.contains("summary_analysis:") }) else {
            return nil
        }
        
        let exists = section.contains("exists: YES")
        let topic = try? extractTopic(from: section, field: "primary_topic:")
        let sentiment = try? extractSentiment(from: section, field: "sentiment:")
        
        return SummaryAnalysis(exists: exists, primaryTopic: topic, sentiment: sentiment)
    }
    
    private static func parseFreeformAnalysis(from sections: [String]) throws -> FreeformAnalysis? {
        guard let section = sections.first(where: { $0.contains("freeform_analysis:") }) else {
            return nil
        }
        
        let exists = section.contains("exists: YES")
        let topic = try? extractTopic(from: section, field: "primary_topic:")
        let sentiment = try? extractSentiment(from: section, field: "sentiment:")
        
        return FreeformAnalysis(exists: exists, primaryTopic: topic, sentiment: sentiment)
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
        
        let exists = section.contains("exists: YES")
        let suggestion = try? extractString(from: section, field: "suggestion:")
        
        return FollowUpSuggestion(exists: exists, suggestion: suggestion)
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
