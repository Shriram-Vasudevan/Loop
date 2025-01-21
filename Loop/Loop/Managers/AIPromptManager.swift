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
        
        // If no significant responses, use fallback prompts
        if responses.isEmpty || responses.allSatisfy({ $0.question.contains("feeling today") }) {
            return ReflectionSessionManager.shared.getRandomPrompt(for: .emotionalWellbeing)?.text ?? getFallbackPrompt(for: .emotionalWellbeing)
        }
        
        // Filter significant responses, ignoring basic mood questions
        let significantResponses = responses.filter { !$0.question.contains("feeling today") }
        
        // Format the responses for the AI
        let formattedResponses = significantResponses.enumerated().map { index, response in
            "\(index + 1). \(response.question): \(response.answer)"
        }.joined(separator: "\n\n")
        
        let prompt = """
        Based on these reflections:

        \(formattedResponses)

        Generate ONE follow-up question that helps the user explore broader patterns in their life. The question should build upon their shared experiences while encouraging deeper reflection.

        CORE PRINCIPLES:
        1. Move from specific experiences to broader patterns in their life
        2. Build on emotional themes or behaviors they've mentioned
        3. Help them discover connections between different aspects of their life
        4. Use their own perspective as a foundation

        EXAMPLES:

        User shares: "Finally finished that big project at work. Felt great to complete it, even though it was stressful. The team really came together at the end."

        ✓ Good: "How do challenging situations tend to affect your relationships with others?"
        (Expands from specific project to broader pattern about challenges and connections)

        ✗ Bad: "What made the project stressful?"
        (Too specific, focuses on past details they've already discussed)

        GUIDELINES:
        - Use simple, conversational language
        - Make questions easy to answer through reflection
        - Stay under 15 words
        - Focus on patterns and themes rather than specific events
        - Build on their perspective without contradicting it
        - Connect their experiences to broader life patterns

        AVOID:
        - Questions about details they've already shared
        - Multiple questions in one
        - Complex or abstract language
        - Yes/no questions
        - Questioning their experiences or feelings
        - Overly specific focus on single events

        Response format: Return only the question, nothing else.
        """
        
        do {
            let requestBody: [String: Any] = [
                "model": "gpt-4",
                "messages": [
                    ["role": "system", "content": """
                        You are an expert in creating simple, reflective follow-up questions.
                        Your goal is to encourage users to think deeply without overwhelming them.
                        Avoid direct references to mood ratings. Focus on actionable follow-ups based on their responses.
                        """],
                    ["role": "user", "content": prompt]
                ],
                "temperature": 0.6,
                "max_tokens": 50 // Ensures short, concise questions
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

