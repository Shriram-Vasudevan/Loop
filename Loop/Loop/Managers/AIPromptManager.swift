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
        print("[AI Prompt] Starting AI prompt generation at \(Date())")

        let startTime = Date()
        let maxWaitTime: TimeInterval = 10.0  // Max wait time for loop/transcript saving

        print("[AI Prompt] Checking if a loop or transcript is still being saved...")
        
        while ReflectionSessionManager.shared.isSavingLoop || ReflectionSessionManager.shared.isSavingTranscript {
            let elapsedTime = Date().timeIntervalSince(startTime)
            if elapsedTime > maxWaitTime {
                print("[AI Prompt] WARNING: Timed out waiting for loop/transcript to finish saving after \(elapsedTime) seconds.")
                break
            }
            print("[AI Prompt] Waiting... Loop or transcript is still being saved (\(elapsedTime)s elapsed)")
            try? await Task.sleep(nanoseconds: 250_000_000)
        }

        print("[AI Prompt] Loop and transcript saving complete. Proceeding with response collection.")

        while Date().timeIntervalSince(startTime) < maxWaitTime {
            let responses = await getTodaysResponses()
            let significantResponses = responses.filter { !$0.question.contains("feeling today") }

            print("[AI Prompt] Retrieved \(responses.count) total responses, \(significantResponses.count) significant responses.")

            if significantResponses.count > 0 {
                let formattedResponses = significantResponses.enumerated().map { index, response in
                    "\(index + 1). \(response.question): \(response.answer)"
                }.joined(separator: "\n\n")

                print("[AI Prompt] Enough responses found. Generating AI prompt.")

                let prompt = """
                Based on these reflections:

                \(formattedResponses)

                Generate ONE follow-up question that helps the user explore broader patterns in their life. The question should build upon their shared experiences while encouraging deeper reflection.

                CORE PRINCIPLES:
                1. Move from specific experiences to broader patterns in their life
                2. Build on emotional themes or behaviors they've mentioned
                3. Use their own perspective as a foundation

                EXAMPLES:

                User shares: "Finally finished that big project at work. Felt great to complete it, even though it was stressful. The team really came together at the end."

                ✓ Good: How do challenging situations tend to affect your relationships with others?
                (Expands from specific project to broader pattern about challenges and connections)
                
                ✓ Good: What do you has helped you become better at overcoming challenges?
                (Asks them to go deeper with their relationship with challenge)
                

                ✗ Bad: What made the project stressful?
                (Too specific, focuses on past details they've already discussed)

                GUIDELINES:
                - Use simple, conversational language
                - Make questions easy to answer through reflection
                - Stay under 13 words
                - Focus on patterns and themes rather than specific events
                - Build on their perspective without contradicting it
                - Connect their experiences to broader life patterns
                - Don't default to: "how does [x] influence other areas of your life." Look for better questions first.

                AVOID:
                - Questions about details they've already shared
                - Multiple questions in one
                - Complex or abstract language
                - Yes/no questions
                - Questioning their experiences or feelings
                - Overly specific focus on single events

                Response format: Return only the question, nothing else. No quotes bookending response.
                """

                do {
                    let requestBody: [String: Any] = [
                        "model": "gpt-4o-mini",
                        "messages": [
                            ["role": "system", "content": """
                                You are an expert in creating simple, reflective follow-up questions.
                                Your goal is to encourage users to think deeply without overwhelming them.
                                Avoid direct references to mood ratings. Focus on actionable follow-ups based on their responses.
                                """],
                            ["role": "user", "content": prompt]
                        ],
                        "temperature": 0.7,
                        "max_tokens": 50
                    ]

                    var request = URLRequest(url: URL(string: endpoint)!)
                    request.httpMethod = "POST"
                    request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

                    print("[AI Prompt] Sending request to OpenAI...")

                    let (data, _) = try await URLSession.shared.data(for: request)
                    let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)

                    if let question = response.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) {
                        print("[AI Prompt] Success! Received AI-generated question: \(question)")
                        return question
                    } else {
                        print("[AI Prompt] ERROR: No valid AI response received.")
                    }
                } catch {
                    print("[AI Prompt] ERROR: Failed to generate AI prompt - \(error)")
                }
            }
            
            print("[AI Prompt] Not enough responses yet, retrying...")
            try? await Task.sleep(nanoseconds: 250_000_000)
        }

        let finalResponses = await getTodaysResponses()
        if !finalResponses.isEmpty {
            print("[AI Prompt] WARNING: Using a random pre-defined prompt due to missing AI response.")
            return ReflectionSessionManager.shared.getRandomPrompt(for: .emotionalWellbeing)?.text ?? "How are these experiences shaping your perspective today?"
        }

        print("[AI Prompt] ERROR: No cached responses found. Using fallback prompt.")
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

