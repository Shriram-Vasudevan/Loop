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
        
        if responses.isEmpty || (responses.count == 1 && responses[0].question.contains("feeling today")) {
            return ReflectionSessionManager.shared.getRandomPrompt(for: .emotionalWellbeing)?.text ?? getFallbackPrompt(for: .emotionalWellbeing)
        }
        
        let significantResponses = responses.filter { !$0.question.contains("feeling today") }
        
        let formattedResponses = significantResponses.map { "\($0.question): \($0.answer)" }
            .joined(separator: "\n\n")
            
        let moodContext = responses.first { $0.question.contains("feeling today") }
       
        let prompt = """
        Based on these responses:

        \(formattedResponses)

        \(moodContext != nil ? "Context: User rated their mood as \(moodContext!.answer)" : "")

        Generate ONE reflective question that:
        1. Directly references themes or ideas from their specific responses
        2. Shows you've understood and analyzed their unique situation
        3. Makes connections between different points they've mentioned
        4. Avoids generic questions that could apply to any response
        5. Remains specific while protecting privacy (no names/places)

        Examples based on sample responses:
        BAD: "What patterns do you notice in your life?" (too generic)
        BAD: "How do you feel about your situation?" (could apply to anything)
        GOOD: If they discussed work-life balance: "How does your approach to managing deadlines reflect your broader life priorities?"
        GOOD: If they mentioned learning new skills: "What similarities do you notice between how you tackle new challenges now versus earlier attempts?"

        Response: Only the question, no other text.
        """
        
        do {
            let requestBody: [String: Any] = [
                "model": "gpt-4",
                "messages": [
                    ["role": "system", "content": """
                        You are an expert at creating varied, insightful reflection prompts.
                        You excel at identifying subtle patterns and asking questions that encourage deep self-discovery.
                        Never default to simple cause-and-effect questions about mood or emotions.
                        Focus on generating diverse question structures that explore different aspects of self-reflection.
                        """],
                    ["role": "user", "content": prompt]
                ],
                "temperature": 0.8,
                "max_tokens": 100
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

