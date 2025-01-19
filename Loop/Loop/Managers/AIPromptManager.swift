//
//  AIPromptManager.swift
//  Loop
//
//  Created by Shriram Vasudevan on 1/16/25.
//

import Foundation

class AIPromptManager {
    static let shared = AIPromptManager()
    
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    private let apiKey: String
        
    init() {
        self.apiKey = ConfigurationKey.apiKey
    }
    
    func generatePrompt() async -> String {
        let responses = await getTodaysResponses()
        
        guard !responses.isEmpty else {
            return ReflectionSessionManager.shared.getRandomPrompt(for: .emotionalWellbeing)?.text ?? getFallbackPrompt(for: .emotionalWellbeing)
        }
        
        let formattedResponses = responses.map { "\($0.question): \($0.answer)" }
            .joined(separator: "\n\n")
            
        let prompt = """
        Based on these responses:

        \(formattedResponses)

        Generate ONE reflective question about them:
        1. References themes/patterns from their responses
        2. Never mentions specific names, places, or events
        3. Generalizes personal details while keeping the core meaning
        4. Is one brief sentence with a question mark

        BAD: "How did your fight with Sarah affect you?"
        GOOD: "How do recent emotional conversations shape your responses?"

        Response: Only the question, no other text.
        """
        
        do {
            let requestBody: [String: Any] = [
                "model": "gpt-4",
                "messages": [
                    ["role": "system", "content": "You are an expert at creating thoughtful reflection prompts that encourage self-discovery while maintaining appropriate boundaries."],
                    ["role": "user", "content": prompt]
                ],
                "temperature": 0.7,
                "max_tokens": 200
            ]
            
            var request = URLRequest(url: URL(string: endpoint)!)
            request.httpMethod = "POST"
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            
            if let question = response.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) {
                return question
            }
        } catch {
            print("Error generating AI prompt: \(error)")
        }
        
        return ReflectionSessionManager.shared.getRandomPrompt(for: .emotionalWellbeing)?.text ?? getFallbackPrompt(for: .emotionalWellbeing)
    }
    
    private func getTodaysResponses() async -> [(question: String, answer: String)] {
        var responses: [(question: String, answer: String)] = []

        if let moodRating = DailyCheckinManager.shared.todaysCheckIn?.rating {
            responses.append((
                question: "How are you feeling today?",
                answer: "Rated mood as \(Int(moodRating)) out of 10"
            ))
        }
        
        // Get cached responses from today
        let cachedResponses = ReflectionSessionManager.shared.getTodaysCachedResponses()
        responses.append(contentsOf: cachedResponses.map { response in
            (question: response.prompt, answer: response.transcript)
        })
        
        return responses
    }
    
    private func getFallbackPrompt(for category: PromptCategory) -> String {
        // Using the same fallback logic as before
        switch category {
        case .emotionalWellbeing: return "How are your emotions evolving today?"
        case .challenges: return "What challenge are you facing right now?"
        case .growth: return "What are you learning about yourself lately?"
        case .connections: return "How are your relationships influencing you?"
        case .curiosity: return "What's capturing your attention these days?"
        case .freeform: return "What's on your mind right now?"
        case .extraPrompts: return "What would you like to explore further?"
        }
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

