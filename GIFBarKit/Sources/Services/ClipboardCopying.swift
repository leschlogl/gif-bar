public protocol ClipboardCopying: Sendable {
    func copyURL(gifID: String) async throws
    func copyBinary(gifID: String) async throws
}

public enum ClipboardServiceError: Error, Sendable, Equatable {
    case gifNotFound(String)
}
