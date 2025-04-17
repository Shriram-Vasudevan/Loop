//
//  AudioAnalyzer.swift
//  Loop
//
//  Created by Shriram Vasudevan on 12/23/24.
//

import Foundation
import Speech

class AudioAnalyzer {
    static let shared = AudioAnalyzer()
    
    private let apiKey: String
        
    init() {
        self.apiKey = ConfigurationKey.apiKey
    }
    
    func transcribeAudio(url: URL) async throws -> String {
        print("Starting transcription process...")

        do {
            print("Falling back to Whisper API...")
            return try await transcribeWithWhisper(url: url)
        } catch {
            print("Whisper Speech Recognition failed with error: \(error)")
            print("Attempting Apple Speech Recognition...")
            return try await transcribeWithApple(url: url)
        }
    }
    
    private func transcribeWithApple(url: URL) async throws -> String {
        let authStatus = try await withCheckedThrowingContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        
        print("Speech recognition authorization status after request: \(authStatus.rawValue)")
        
        guard authStatus == .authorized else {
            print("Speech recognition not authorized: \(authStatus)")
            throw AnalysisError.transcriptionFailed("Speech recognition not authorized: \(authStatus)")
        }
        
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) else {
            throw AnalysisError.transcriptionFailed("Failed to create speech recognizer - device may not support en-US locale")
        }
        
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        
        print("Starting transcription for audio at: \(url)")
        
        return try await withCheckedThrowingContinuation { continuation in
            let task = recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: AnalysisError.transcriptionFailed("Speech recognition failed: \(error.localizedDescription)"))
                } else if let result = result, result.isFinal {
                    continuation.resume(returning: result.bestTranscription.formattedString)
                }
            }
            
            if task == nil {
                continuation.resume(throwing: AnalysisError.transcriptionFailed("Failed to create recognition task"))
            }
        }
    }
    
    private func transcribeWithWhisper(url: URL) async throws -> String {
        print("Preparing Whisper API request for: \(url)")
        
        guard !apiKey.isEmpty else {
            throw AnalysisError.transcriptionFailed("Missing OpenAI API key")
        }
        
        let preferredLanguage = UserDefaults.standard.string(forKey: "preferredLanguage") ?? "English"
        let languageCode = mapLanguageToWhisperCode(language: preferredLanguage)
        
        print("Using language: \(preferredLanguage) (code: \(languageCode))")

        print("Reading audio file data...")
        let audioData = try Data(contentsOf: url)
        print("Audio data size: \(audioData.count) bytes")
        
        let boundary = UUID().uuidString
        print("Creating Whisper API request...")
        
        guard let apiUrl = URL(string: "https://api.openai.com/v1/audio/transcriptions") else {
            print("❌ Failed to create Whisper API URL")
            throw AnalysisError.transcriptionFailed("Failed to create Whisper API URL")
        }

        var request = URLRequest(url: apiUrl)
        
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        print("Creating multipart form data...")
        var body = Data()

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n")
        body.append("whisper-1\r\n")

        if languageCode != "auto" {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n")
            body.append("\(languageCode)\r\n")
        }

        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n")
        body.append("Content-Type: audio/m4a\r\n\r\n")
        body.append(audioData)
        body.append("\r\n")
        
        body.append("--\(boundary)--\r\n")
        request.httpBody = body
        
        print("Sending request to Whisper API...")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
           if let responseString = String(data: data, encoding: .utf8) {
               throw AnalysisError.transcriptionFailed("Whisper API error: Status \(httpResponse.statusCode), Response: \(responseString)")
           } else {
               throw AnalysisError.transcriptionFailed("Whisper API error: Status \(httpResponse.statusCode)")
           }
       }
        
        do {
            let result = try JSONDecoder().decode(WhisperResponse.self, from: data)
            return result.text
        } catch {
            if let responseString = String(data: data, encoding: .utf8) {
                throw AnalysisError.transcriptionFailed("Failed to decode Whisper response: \(error.localizedDescription), Raw response: \(responseString)")
            } else {
                throw AnalysisError.transcriptionFailed("Failed to decode Whisper response: \(error.localizedDescription)")
            }
        }
    }

    // Add this helper function to map user-friendly language names to Whisper codes
    private func mapLanguageToWhisperCode(language: String) -> String {
        // Map from the user-friendly language name to Whisper's language code
        let languageMap: [String: String] = [
            "Afrikaans": "af",
            "Albanian": "sq",
            "Amharic": "am",
            "Arabic": "ar",
            "Armenian": "hy",
            "Assamese": "as",
            "Azerbaijani": "az",
            "Bashkir": "ba",
            "Basque": "eu",
            "Belarusian": "be",
            "Bengali": "bn",
            "Bosnian": "bs",
            "Breton": "br",
            "Bulgarian": "bg",
            "Burmese": "my",
            "Catalan": "ca",
            "Chinese (Simplified)": "zh",
            "Chinese (Traditional)": "zh",
            "Croatian": "hr",
            "Czech": "cs",
            "Danish": "da",
            "Dutch": "nl",
            "English": "en",
            "Estonian": "et",
            "Faroese": "fo",
            "Finnish": "fi",
            "French": "fr",
            "Galician": "gl",
            "Georgian": "ka",
            "German": "de",
            "Greek": "el",
            "Gujarati": "gu",
            "Haitian Creole": "ht",
            "Hausa": "ha",
            "Hawaiian": "haw",
            "Hebrew": "iw",
            "Hindi": "hi",
            "Hungarian": "hu",
            "Icelandic": "is",
            "Indonesian": "id",
            "Italian": "it",
            "Japanese": "ja",
            "Javanese": "jw",
            "Kannada": "kn",
            "Kazakh": "kk",
            "Khmer": "km",
            "Korean": "ko",
            "Lao": "lo",
            "Latin": "la",
            "Latvian": "lv",
            "Lithuanian": "lt",
            "Luxembourgish": "lb",
            "Macedonian": "mk",
            "Malagasy": "mg",
            "Malay": "ms",
            "Malayalam": "ml",
            "Maltese": "mt",
            "Maori": "mi",
            "Marathi": "mr",
            "Mongolian": "mn",
            "Nepali": "ne",
            "Norwegian": "no",
            "Occitan": "oc",
            "Pashto": "ps",
            "Persian": "fa",
            "Polish": "pl",
            "Portuguese": "pt",
            "Punjabi": "pa",
            "Romanian": "ro",
            "Russian": "ru",
            "Sanskrit": "sa",
            "Serbian": "sr",
            "Shona": "sn",
            "Sindhi": "sd",
            "Sinhala": "si",
            "Slovak": "sk",
            "Slovenian": "sl",
            "Somali": "so",
            "Spanish": "es",
            "Sundanese": "su",
            "Swahili": "sw",
            "Swedish": "sv",
            "Tagalog": "tl",
            "Tajik": "tg",
            "Tamil": "ta",
            "Tatar": "tt",
            "Telugu": "te",
            "Thai": "th",
            "Tibetan": "bo",
            "Turkish": "tr",
            "Turkmen": "tk",
            "Ukrainian": "uk",
            "Urdu": "ur",
            "Uzbek": "uz",
            "Vietnamese": "vi",
            "Welsh": "cy",
            "Yiddish": "yi",
            "Yoruba": "yo"
        ]
        
        // Return the language code if found, otherwise use "auto" for auto-detection
        return languageMap[language] ?? "auto"
    }
    
    func getDuration(url: URL) -> TimeInterval {
        let asset = AVURLAsset(url: url)
        return CMTimeGetSeconds(asset.duration)
    }
}

struct WhisperResponse: Codable {
    let text: String
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

