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
    /// Without this, `NSCache` only evicts under actual system memory pressure — a
    /// reactive, late backstop rather than a budget. A long scroll session through
    /// hundreds of grid thumbnails (plus the occasional full-resolution `original`
    /// rendition pulled in for Copy GIF, sharing this same cache) would otherwise grow
    /// this unbounded until the system intervenes. 150MB comfortably holds hundreds of
    /// thumbnails; `cost:` is passed as each entry's actual byte count so eviction is
    /// driven by real memory use, not entry count.
    public static let defaultMemoryCacheLimitBytes = 150 * 1024 * 1024

    private let session: APIRequesting
    private let diskCache: DiskImageCaching?
    private let memoryCache = NSCache<NSURL, NSData>()
    private var inFlightTasks: [URL: Task<Data, Error>] = [:]

    public init(
        session: APIRequesting = URLSession.shared,
        diskCache: DiskImageCaching? = FileManagerDiskImageCache(),
        memoryCacheLimitBytes: Int = ImageCache.defaultMemoryCacheLimitBytes
    ) {
        self.session = session
        self.diskCache = diskCache
        memoryCache.totalCostLimit = memoryCacheLimitBytes
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
        memoryCache.setObject(data as NSData, forKey: url as NSURL, cost: data.count)
        return data
    }
}
