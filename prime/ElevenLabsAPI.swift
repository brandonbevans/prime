import Foundation

struct ElevenLabsAPI {
  struct DownloadedAudio {
    let data: Data
    let mimeType: String?
  }

  enum APIError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse(statusCode: Int)

    var errorDescription: String? {
      switch self {
      case .missingAPIKey:
        return "ElevenLabs API key is not configured."
      case .invalidURL:
        return "Failed to build ElevenLabs audio download URL."
      case let .invalidResponse(statusCode):
        return "ElevenLabs returned HTTP \(statusCode) while downloading audio."
      }
    }
  }

  /// Download the full conversation audio for a completed session.
  static func downloadConversationAudio(conversationId: String) async throws -> DownloadedAudio {
    let apiKey = Config.elevenLabsApiKey
    guard !apiKey.isEmpty else {
      throw APIError.missingAPIKey
    }

    guard
      let url = URL(string: "https://api.elevenlabs.io/v1/convai/conversations/\(conversationId)/audio")
    else {
      throw APIError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
    request.setValue("application/octet-stream", forHTTPHeaderField: "Accept")

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse,
      (200 ..< 300).contains(httpResponse.statusCode)
    else {
      let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
      throw APIError.invalidResponse(statusCode: statusCode)
    }

    let mimeType = httpResponse.value(forHTTPHeaderField: "Content-Type")
    return DownloadedAudio(data: data, mimeType: mimeType)
  }

  struct ConversationSummary: Decodable {
    let id: String
    let name: String?
    private let createdAtRaw: String?
    private let updatedAtRaw: String?
    private let lastInteractionAtRaw: String?

    private enum CodingKeys: String, CodingKey {
      case id
      case conversationId = "conversation_id"
      case name
      case createdAtRaw = "created_at"
      case updatedAtRaw = "updated_at"
      case lastInteractionAtRaw = "last_interaction_at"
    }

    init(id: String, name: String?, createdAtRaw: String?, updatedAtRaw: String?, lastInteractionAtRaw: String?) {
      self.id = id
      self.name = name
      self.createdAtRaw = createdAtRaw
      self.updatedAtRaw = updatedAtRaw
      self.lastInteractionAtRaw = lastInteractionAtRaw
    }

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      if let explicitId = try container.decodeIfPresent(String.self, forKey: .id) {
        id = explicitId
      } else if let alternateId = try container.decodeIfPresent(String.self, forKey: .conversationId) {
        id = alternateId
      } else {
        throw DecodingError.keyNotFound(
          CodingKeys.id,
          .init(
            codingPath: decoder.codingPath,
            debugDescription: "Conversation summary missing both id and conversation_id"
          )
        )
      }
      name = try container.decodeIfPresent(String.self, forKey: .name)
      createdAtRaw = try container.decodeIfPresent(String.self, forKey: .createdAtRaw)
      updatedAtRaw = try container.decodeIfPresent(String.self, forKey: .updatedAtRaw)
      lastInteractionAtRaw = try container.decodeIfPresent(String.self, forKey: .lastInteractionAtRaw)
    }

    var createdAt: Date? {
      ElevenLabsAPI.parseISODate(createdAtRaw)
    }

    var updatedAt: Date? {
      ElevenLabsAPI.parseISODate(updatedAtRaw)
    }

    var lastInteractionAt: Date? {
      ElevenLabsAPI.parseISODate(lastInteractionAtRaw)
    }

    var sortDate: Date {
      lastInteractionAt ?? updatedAt ?? createdAt ?? Date.distantPast
    }
  }

  private struct ConversationListResponse: Decodable {
    let conversations: [ConversationSummary]
  }

  static func fetchConversationSummaries() async throws -> [ConversationSummary] {
    let apiKey = Config.elevenLabsApiKey
    guard !apiKey.isEmpty else {
      throw APIError.missingAPIKey
    }

    guard let url = URL(string: "https://api.elevenlabs.io/v1/convai/conversations") else {
      throw APIError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse,
      (200 ..< 300).contains(httpResponse.statusCode)
    else {
      let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
      throw APIError.invalidResponse(statusCode: statusCode)
    }

    let decoder = JSONDecoder()
    return try decoder.decode(ConversationListResponse.self, from: data).conversations
  }

  private static let iso8601WithFractional: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()

  private static let iso8601Basic = ISO8601DateFormatter()

  private static func parseISODate(_ value: String?) -> Date? {
    guard let value else { return nil }
    if let date = iso8601WithFractional.date(from: value) {
      return date
    }
    return iso8601Basic.date(from: value)
  }
}

