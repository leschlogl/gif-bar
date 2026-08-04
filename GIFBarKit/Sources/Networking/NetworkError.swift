public enum NetworkError: Error, Sendable, Equatable {
    case invalidURL
    case missingAPIKey
    case requestFailed(String)
    case invalidResponse
    case httpStatus(Int)
    case decodingFailed(String)
}
