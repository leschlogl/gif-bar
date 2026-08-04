import Foundation

/// Abstracts `URLSession` so networking code is unit-testable without live network calls.
/// Method signature mirrors `URLSession`'s own exactly, so `URLSession` already satisfies
/// this protocol with no extra code (same pattern as `Services.PasteboardWriting`).
public protocol APIRequesting: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: APIRequesting {}
