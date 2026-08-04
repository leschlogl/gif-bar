import CryptoKit
import Foundation

/// Persists downloaded image bytes to disk, keyed by URL. Protocol-wrapped so
/// `ImageCache` stays unit-testable without touching the filesystem.
public protocol DiskImageCaching: Sendable {
    func data(for url: URL) async -> Data?
    func write(_ data: Data, for url: URL) async
}

/// Hashes each URL to a filename (`SHA256`, since URLs can contain characters that
/// aren't safe as path components) inside `Caches/GIFBar/ImageCache`.
public actor FileManagerDiskImageCache: DiskImageCaching {
    private let directory: URL
    private let fileManager: FileManager

    public init(directory: URL = FileManagerDiskImageCache.defaultDirectory(), fileManager: FileManager = .default) {
        self.directory = directory
        self.fileManager = fileManager
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    public static func defaultDirectory() -> URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return caches.appendingPathComponent("GIFBar/ImageCache", isDirectory: true)
    }

    public func data(for url: URL) -> Data? {
        fileManager.contents(atPath: path(for: url).path)
    }

    public func write(_ data: Data, for url: URL) {
        try? data.write(to: path(for: url))
    }

    private func path(for url: URL) -> URL {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        let filename = digest.map { String(format: "%02x", $0) }.joined()
        return directory.appendingPathComponent(filename)
    }
}
