import Foundation

enum GeminiServiceError: Error, LocalizedError {
    case invalidResponseType // 响应不是 HTTPURLResponse
    case httpError(statusCode: Int) // HTTP 状态码非 200，附带状态码
    case apiError(message: String) // API 返回的错误信息
    case invalidAPIKey // API Key 无效或未设置
    case emptyResponse // API 返回空内容
    case unknown(Error) // 其他未知错误
    case networkError(String) // Network error with description
    case jsonConversionError(String) // 新增：JSON转换错误

    var errorDescription: String? {
        switch self {
        case .invalidResponseType: return "Gemini API 返回了无效的响应类型。"
        case .httpError(let statusCode): return "Gemini API HTTP 错误: 状态码 \(statusCode)。"
        case .apiError(let message): return "Gemini API 错误: \(message)"
        case .invalidAPIKey: return "Gemini API Key 无效或未设置。请在设置中填写。"
        case .emptyResponse: return "Gemini API 返回了空内容或无法解析的响应。"
        case .unknown(let error): return "发生未知错误: \(error.localizedDescription)"
        case .networkError(let description): return "网络错误: \(description)"
        case .jsonConversionError(let description): return "JSON 转换错误: \(description)"
        }
    }
}

// 用于解析 Gemini API 响应的结构体
struct GeminiWordData: Decodable {
    let word: String
    let definition: String
    let originalSentence: String
    let translatedSentence: String
}

class GeminiService {

    private let apiUrl = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent")! // Using gemini-pro for general content generation

    /// 批量获取单词的释义和例句翻译
    /// - Parameters:
    ///   - words: 需要查询的单词列表
    ///   - subtitleText: 视频的完整字幕文本，用于提取例句
    /// - Returns: 包含每个单词释义和例句翻译的数组
    func fetchDefinitionsAndExamples(words: [String], subtitleText: String) async throws -> [GeminiWordData] {
        guard let apiKey = UserSettings.geminiAPIKey, !apiKey.isEmpty else {
            throw GeminiServiceError.invalidAPIKey
        }
        
        var request = URLRequest(url: apiUrl.appending(queryItems: [URLQueryItem(name: "key", value: apiKey)]))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let prompt = """
Given the following list of English words: \(words.joined(separator: ", "))
        And the full video subtitle text:
        \(subtitleText)
        
        For each word in the list, provide:
        1. A concise Chinese definition.
        2. One original English sentence from the provided subtitle text where the word appears.
        3. The Chinese translation of that original English sentence.
        
        Return the results as a JSON array of objects. Each object should have 'word', 'definition', 'original_sentence', and 'translated_sentence' keys. Ensure the JSON is valid and only contains the array.
"""

        let requestBody = ChatCompletionRequestBody(
            contents: [
                Content(
                    role: "user",
                    parts: [
                        Part(text: prompt)
                    ]
                )
            ],
            generationConfig: GenerationConfig(
                temperature: 0.3, // Adjust as needed
                topK: 30,
                topP: 0.7
            ),
            safetySettings: [ // Example safety settings, adjust as needed
                SafetySetting(category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_NONE"),
                SafetySetting(category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_NONE"),
                SafetySetting(category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold: "BLOCK_NONE"),
                SafetySetting(category: "HARM_CATEGORY_DANGEROUS_CONTENT", threshold: "BLOCK_NONE")
            ]
        )

        do {
            let httpBody = try JSONEncoder().encode(requestBody)
            request.httpBody = httpBody

            // Print the request body for debugging
            if let jsonString = String(data: httpBody, encoding: .utf8) {
                print("Gemini API Request Body:\n\(jsonString)")
            }

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw GeminiServiceError.invalidResponseType
            }

            guard httpResponse.statusCode == 200 else {
                if let errorBodyString = String(data: data, encoding: .utf8) {
                    if let decodedError = try? JSONDecoder().decode(GeminiAPIErrorResponse.self, from: data) {
                        print("Gemini API Error: Status Code \(httpResponse.statusCode), Message: \(decodedError.error.message)")
                        throw GeminiServiceError.apiError(message: decodedError.error.message)
                    } else {
                        print("HTTP Error: Status Code \(httpResponse.statusCode), Body: \(errorBodyString)")
                        throw GeminiServiceError.apiError(message: "HTTP Status Code: \(httpResponse.statusCode), Body: \(errorBodyString)")
                    }
                } else {
                    throw GeminiServiceError.httpError(statusCode: httpResponse.statusCode)
                }
            }

            // Parse the response
            let jsonResponse = try JSONDecoder().decode(GeminiGenerateContentResponse.self, from: data)

            guard let firstCandidate = jsonResponse.candidates?.first,
                  let text = firstCandidate.content?.parts?.first?.text else {
                throw GeminiServiceError.emptyResponse
            }

            // Gemini sometimes adds markdown code block, remove it
            let cleanedText = text.replacingOccurrences(of: "```json\n", with: "")
                                  .replacingOccurrences(of: "\n```", with: "")

            guard let jsonData = cleanedText.data(using: .utf8) else {
                throw GeminiServiceError.jsonConversionError("Failed to convert cleaned text to Data")
            }

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase // <-- 核心是增加这一行
            return try decoder.decode([GeminiWordData].self, from: jsonData)

        } catch let error as URLError {
            throw GeminiServiceError.networkError(error.localizedDescription)
        } catch let error as DecodingError {
            throw GeminiServiceError.jsonConversionError(error.localizedDescription)
        } catch {
            throw GeminiServiceError.unknown(error)
        }
    }
}

// MARK: - Helper Structs for Gemini API Request/Response

// Request Body Structs (reusing from user's example)
struct ChatCompletionRequestBody: Encodable {
    let contents: [Content]
    let generationConfig: GenerationConfig?
    let safetySettings: [SafetySetting]?
}

struct Content: Encodable {
    let role: String
    let parts: [Part]
}

struct Part: Encodable {
    let text: String
}

struct GenerationConfig: Encodable {
    let temperature: Double?
    let topK: Int?
    let topP: Double?
}

struct SafetySetting: Encodable {
    let category: String
    let threshold: String
}

// Response Body Structs (adapted for Gemini generateContent)
struct GeminiGenerateContentResponse: Decodable {
    let candidates: [GeminiCandidate]?
    let promptFeedback: PromptFeedback?
}

struct GeminiCandidate: Decodable {
    let content: GeminiContent?
    let finishReason: String? // e.g., "STOP"
    let safetyRatings: [SafetyRating]?
}

struct GeminiContent: Decodable {
    let parts: [GeminiPart]?
    let role: String? // Role might be present in content too
}

struct GeminiPart: Decodable {
    let text: String?
}

struct PromptFeedback: Decodable {
    let safetyRatings: [SafetyRating]?
    let blockReason: String?
}

struct SafetyRating: Decodable {
    let category: String?
    let probability: String?
}

// Error Response Struct (reusing from user's example)
struct GeminiAPIErrorResponse: Decodable {
    let error: APIError
}

struct APIError: Decodable {
    let code: Int
    let message: String
    let status: String
}
