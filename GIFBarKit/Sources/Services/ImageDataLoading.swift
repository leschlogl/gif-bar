import Foundation
import Networking

/// Fetches raw image/GIF bytes for a URL — same shape as `Networking.ImageLoading`,
/// redeclared here so `ViewModels` (which cannot import `Networking`) can depend on it.
/// Same pattern as `FavoritesManaging` wrapping `Persistence.FavoritesStore`.
public protocol ImageDataLoading: Sendable {
    func data(for url: URL) async throws -> Data
}

extension ImageCache: ImageDataLoading {}
