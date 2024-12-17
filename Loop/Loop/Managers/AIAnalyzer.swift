//
//  AIAnalyzer.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/16/24.
//

import Foundation

class AIAnalyzer {
    static let shared = AIAnalyzer()
    
    private let apiKey: String
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    
    init(apiKey: String = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "") {
        self.apiKey = apiKey
    }
    
    func analyzeResponses(_ responses: [String]) async throws -> AIAnalysisResult {
        print("analyzing")
        
        let prompt = """
        analyze these 3 responses:

        response 1:
        \(responses[0])

        response 2:
        \(responses[1])

        response 3:
        \(responses[2])

        1. feeling: [use a specific adjective to describe the tone or emotion of the response]
        2. description: [explain the feeling in 2-3 short-medium sentences, addressing the user directly in the second person ("your response conveys..."). provide insight into the tone and its possible implications.]
        3. tense: [past/present/future]
        4. description: [in 1-2 sentences, explain how the tense influences the response's tone, focus, or narrative perspective.]
        5. self-references: [count the number of "I/me/my" to measure self-focus]
        6. action-reflection: [provide a clear and balanced ratio like 50/50, 40/60, or 60/40. avoid extremes like 70/30 unless strongly justified]
        7. description: [in 1-2 short sentences, explain if the response leans toward actions (doing things) or reflections (thinking about them) and why that balance matters.]
        8. solution-focus: [provide a balanced ratio like 50/50, 40/60, or 60/40, showing how much of the response focuses on problems vs solutions. avoid extreme ratios unless strongly justified]
        9. description: [in 1-2 short sentences, explain whether the response emphasizes solving problems or dwelling on them, and how this focus affects its tone or direction.]
        10. follow-up: [generate a thoughtful and specific question related to the feeling described in 1. avoid mentioning personal details directly but instead generalize the idea to encourage broader reflection (e.g., if the response mentions liking a specific person, ask about what they value in people overall).]
        """

        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": "You are an analyzer that responds in the exact format requested, no additional text."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.3,
            "max_tokens": 1000,
            "top_p": 0.1,
            "frequency_penalty": 0.0,
            "presence_penalty": 0.0
        ]
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        print("ai response \(data)")
        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        guard let content = response.choices.first?.message.content else {
            throw AnalysisError.aiAnalysisFailed
        }
        
        return try parseAIResponse(content)
    }
    
    private func parseAIResponse(_ response: String) throws -> AIAnalysisResult {
        let lines = response.components(separatedBy: .newlines)
        var feeling: String?
        var feelingDescription: String?
        var tense: String?
        var tenseDescription: String?
        var selfReferenceCount: Int?
        var followUp: String?
        var actionReflectionRatio: String?
        var actionReflectionDescription: String?
        var solutionFocus: String?
        var solutionFocusDescription: String?
        
        var currentSection = ""
        
        for line in lines {
            let lowercasedLine = line.lowercased()
            
            switch true {
            case lowercasedLine.starts(with: "1. feeling:"):
                currentSection = "feeling"
                feeling = line.replacing("1. feeling:", with: "").trimmingCharacters(in: .whitespaces)
            case lowercasedLine.starts(with: "2. description:") && currentSection == "feeling":
                feelingDescription = line.replacing("2. description:", with: "").trimmingCharacters(in: .whitespaces)
            case lowercasedLine.starts(with: "3. tense:"):
                currentSection = "tense"
                tense = line.replacing("3. tense:", with: "").trimmingCharacters(in: .whitespaces)
            case lowercasedLine.starts(with: "4. description:") && currentSection == "tense":
                tenseDescription = line.replacing("4. description:", with: "").trimmingCharacters(in: .whitespaces)
            case lowercasedLine.starts(with: "5. self-references:"):
                let countString = line.replacing("5. self-references:", with: "").trimmingCharacters(in: .whitespaces)
                selfReferenceCount = Int(countString) ?? 0
            case lowercasedLine.starts(with: "6. action-reflection:"):
                currentSection = "action"
                actionReflectionRatio = line.replacing("6. action-reflection:", with: "").trimmingCharacters(in: .whitespaces)
            case lowercasedLine.starts(with: "7. description:") && currentSection == "action":
                actionReflectionDescription = line.replacing("7. description:", with: "").trimmingCharacters(in: .whitespaces)
            case lowercasedLine.starts(with: "8. solution-focus:"):
                currentSection = "solution"
                solutionFocus = line.replacing("8. solution-focus:", with: "").trimmingCharacters(in: .whitespaces)
            case lowercasedLine.starts(with: "9. description:") && currentSection == "solution":
                solutionFocusDescription = line.replacing("9. description:", with: "").trimmingCharacters(in: .whitespaces)
            case lowercasedLine.starts(with: "10. follow-up:"):
                followUp = line.replacing("10. follow-up:", with: "").trimmingCharacters(in: .whitespaces)
            default:
                continue
            }
        }
        
        guard let feeling = feeling,
              let feelingDescription = feelingDescription,
              let tense = tense,
              let tenseDescription = tenseDescription,
              let selfReferenceCount = selfReferenceCount,
              let followUp = followUp,
              let actionReflectionRatio = actionReflectionRatio,
              let actionReflectionDescription = actionReflectionDescription,
              let solutionFocus = solutionFocus,
              let solutionFocusDescription = solutionFocusDescription else {
            throw AnalysisError.invalidAIResponse
        }
        
        return AIAnalysisResult(
            feeling: feeling,
            feelingDescription: feelingDescription,
            tense: tense,
            tenseDescription: tenseDescription,
            selfReferenceCount: selfReferenceCount,
            followUp: followUp,
            actionReflectionRatio: actionReflectionRatio,
            actionReflectionDescription: actionReflectionDescription,
            solutionFocus: solutionFocus,
            solutionFocusDescription: solutionFocusDescription
        )
    }
}

// Response models
private struct OpenAIResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let content: String
    }
}
