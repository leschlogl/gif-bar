import Foundation

/// Fetches raw image/GIF bytes for a URL, fakeable for `ViewModels`/`Views` tests.
public protocol ImageLoading: Sendable {
    func data(for url: URL) async throws -> Data
}

/// Memory + disk cache keyed by rendition URL (see "Cache reuse" in
/// docs/decisions/gif-handling.md). Concurrent requests for the same URL share a single
/// in-flight download rather than issuing duplicate network calls — this is what makes
/// re-appearing cells during fast scroll-back free.
public actor ImageCache: ImageLoading {
    private let session: APIRequesting
    private let diskCache: DiskImageCaching?
    private let memoryCache = NSCache<NSURL, NSData>()
    private var inFlightTasks: [URL: Task<Data, Error>] = [:]

    public init(session: APIRequesting = URLSession.shared, diskCache: DiskImageCaching? = FileManagerDiskImageCache()) {
        self.session = session
        self.diskCache = diskCache
    }

    public func data(for url: URL) async throws -> Data {
        if let cached = memoryCache.object(forKey: url as NSURL) {
            return cached as Data
        }
        if let inFlight = inFlightTasks[url] {
            return try await inFlight.value
        }

        let task = Task<Data, Error> { [session, diskCache] in
            if let cached = await diskCache?.data(for: url) {
                return cached
            }
            let (data, response) = try await session.data(for: URLRequest(url: url))
            guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
                throw NetworkError.invalidResponse
            }
            await diskCache?.write(data, for: url)
            return data
        }
        inFlightTasks[url] = task
        defer { inFlightTasks[url] = nil }

        let data = try await task.value
        memoryCache.setObject(data as NSData, forKey: url as NSURL)
        return data
    }
}
