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
        
        Respond in exactly the following format; no other text should be provided:
        
        1. feeling: [use a specific adjective to describe the tone or emotion of the response]
        2. description: [explain the feeling in 2-3 short-medium sentences, addressing the user directly in the second person ("your response conveys..."). provide insight into the tone and its possible implications.]
        3. tense: [past/present/future]
        4. description: [in 1 sentence (under 15 words), explain how the tense influences the response's tone, focus, or narrative perspective.]
        5. self-references: [count the number of "I/me/my" to measure self-focus]
        6. action-reflection: [provide a clear and balanced ratio like 50/50, 40/60, or 60/40. avoid extremes like 70/30 unless strongly justified]
        7. description: [in 1 short sentence (under 15 words), explain if the response leans toward actions (doing things) or reflections (thinking about them) and why that balance matters.]
        8. solution-focus: [provide a balanced ratio like 50/50, 40/60, or 60/40, showing how much of the response focuses on problems vs solutions. avoid extreme ratios unless strongly justified]
        9. description: [in 1 short sentence (under 15 words), explain whether the response emphasizes solving problems or dwelling on them, and how this focus affects its tone or direction.]
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
            throw AnalysisError.aiAnalysisFailed("could not get ai message content")
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

        print("Raw AI Response:")
        print(response)
        
        var currentSection = ""
        
        for (index, line) in lines.enumerated() {
            print("Processing line \(index): \(line)")
            
            let lowercasedLine = line.lowercased().trimmingCharacters(in: .whitespaces)

            func extractContent(from line: String, prefix: String) -> String {
                if let range = line.range(of: prefix, options: .caseInsensitive) {
                    return String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                }
                return line.trimmingCharacters(in: .whitespaces)
            }
            
            switch true {
            case lowercasedLine.contains("1. feeling"):
                currentSection = "feeling"
                feeling = extractContent(from: line, prefix: "1. feeling:")
            case lowercasedLine.contains("2. description") && currentSection == "feeling":
                feelingDescription = extractContent(from: line, prefix: "2. description:")
            case lowercasedLine.contains("3. tense"):
                currentSection = "tense"
                tense = extractContent(from: line, prefix: "3. tense:")
            case lowercasedLine.contains("4. description") && currentSection == "tense":
                tenseDescription = extractContent(from: line, prefix: "4. description:")
            case lowercasedLine.contains("5. self-references"):
                let countString = extractContent(from: line, prefix: "5. self-references:")
                selfReferenceCount = Int(countString.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0
            case lowercasedLine.contains("6. action-reflection"):
                currentSection = "action"
                actionReflectionRatio = extractContent(from: line, prefix: "6. action-reflection:")
            case lowercasedLine.contains("7. description") && currentSection == "action":
                actionReflectionDescription = extractContent(from: line, prefix: "7. description:")
            case lowercasedLine.contains("8. solution-focus"):
                currentSection = "solution"
                solutionFocus = extractContent(from: line, prefix: "8. solution-focus:")
            case lowercasedLine.contains("9. description") && currentSection == "solution":
                solutionFocusDescription = extractContent(from: line, prefix: "9. description:")
            case lowercasedLine.contains("10. follow-up"):
                followUp = extractContent(from: line, prefix: "10. follow-up:")
            default:
                print("Unhandled line: \(line)")
                continue
            }
        }

        print("Parsed values:")
        print("Feeling: \(feeling ?? "nil")")
        print("Feeling Description: \(feelingDescription ?? "nil")")
        print("Tense: \(tense ?? "nil")")
        print("Tense Description: \(tenseDescription ?? "nil")")
        print("Self Reference Count: \(selfReferenceCount ?? -1)")
        print("Action Reflection Ratio: \(actionReflectionRatio ?? "nil")")
        print("Action Reflection Description: \(actionReflectionDescription ?? "nil")")
        print("Solution Focus: \(solutionFocus ?? "nil")")
        print("Solution Focus Description: \(solutionFocusDescription ?? "nil")")
        print("Follow Up: \(followUp ?? "nil")")
        
        var missingFields: [String] = []

        if feeling == nil { missingFields.append("feeling") }
        if feelingDescription == nil { missingFields.append("feelingDescription") }
        if tense == nil { missingFields.append("tense") }
        if tenseDescription == nil { missingFields.append("tenseDescription") }
        if selfReferenceCount == nil { missingFields.append("selfReferenceCount") }
        if actionReflectionRatio == nil { missingFields.append("actionReflectionRatio") }
        if actionReflectionDescription == nil { missingFields.append("actionReflectionDescription") }
        if solutionFocus == nil { missingFields.append("solutionFocus") }
        if solutionFocusDescription == nil { missingFields.append("solutionFocusDescription") }
        if followUp == nil { missingFields.append("followUp") }

        if !missingFields.isEmpty {
            throw AnalysisError.missingFields(fields: missingFields)
        }
        
        return AIAnalysisResult(
            feeling: feeling!,
            feelingDescription: feelingDescription!,
            tense: tense!,
            tenseDescription: tenseDescription!,
            selfReferenceCount: selfReferenceCount!,
            followUp: followUp!,
            actionReflectionRatio: actionReflectionRatio!,
            actionReflectionDescription: actionReflectionDescription!,
            solutionFocus: solutionFocus!,
            solutionFocusDescription: solutionFocusDescription!
        )
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
