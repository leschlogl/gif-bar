import XCTest
@testable import Networking

private actor CallCounter {
    private(set) var count = 0
    func increment() -> Int {
        count += 1
        return count
    }
}

private struct FakeAPIRequesting: APIRequesting {
    let counter: CallCounter
    let responseData: Data
    let statusCode: Int
    /// Lets a test hold the response open until a signal fires, to force overlap
    /// between two concurrent callers.
    let gate: Gate?

    init(responseData: Data = Data("gif-bytes".utf8), statusCode: Int = 200, counter: CallCounter = CallCounter(), gate: Gate? = nil) {
        self.responseData = responseData
        self.statusCode = statusCode
        self.counter = counter
        self.gate = gate
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        _ = await counter.increment()
        if let gate {
            await gate.waitUntilOpen()
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        return (responseData, response)
    }
}

private actor Gate {
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func open() {
        isOpen = true
        waiters.forEach { $0.resume() }
        waiters.removeAll()
    }

    func waitUntilOpen() async {
        if isOpen { return }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }
}

private actor FakeDiskImageCache: DiskImageCaching {
    private var storage: [URL: Data] = [:]
    private(set) var writeCount = 0

    func seed(_ data: Data, for url: URL) {
        storage[url] = data
    }

    func data(for url: URL) -> Data? {
        storage[url]
    }

    func write(_ data: Data, for url: URL) {
        writeCount += 1
        storage[url] = data
    }
}

final class ImageCacheTests: XCTestCase {
    private let url = URL(string: "https://media.giphy.com/some.gif")!

    func testSecondFetchOfSameURLUsesMemoryCacheNotNetwork() async throws {
        let counter = CallCounter()
        let cache = ImageCache(session: FakeAPIRequesting(counter: counter), diskCache: nil)

        _ = try await cache.data(for: url)
        _ = try await cache.data(for: url)

        let callCount = await counter.count
        XCTAssertEqual(callCount, 1)
    }

    func testMemoryCacheEvictsOnceTotalCostLimitIsExceeded() async throws {
        let counter = CallCounter()
        let responseData = Data(repeating: 0, count: 1_000)
        let cache = ImageCache(
            session: FakeAPIRequesting(responseData: responseData, counter: counter),
            diskCache: nil,
            // Smaller than a single response, so every insert immediately exceeds budget.
            memoryCacheLimitBytes: 10
        )

        _ = try await cache.data(for: url)
        _ = try await cache.data(for: url)

        let callCount = await counter.count
        XCTAssertEqual(callCount, 2, "an entry over the memory cache's cost limit should be evicted, forcing a re-fetch")
    }

    func testConcurrentRequestsForSameURLShareOneDownload() async throws {
        let counter = CallCounter()
        let gate = Gate()
        let cache = ImageCache(session: FakeAPIRequesting(counter: counter, gate: gate), diskCache: nil)
        let url = self.url

        async let first = cache.data(for: url)
        async let second = cache.data(for: url)

        // Give both callers a chance to register as in-flight before releasing the response.
        try await Task.sleep(for: .milliseconds(50))
        await gate.open()

        _ = try await (first, second)
        let callCount = await counter.count
        XCTAssertEqual(callCount, 1, "two concurrent requests for the same URL should share one download")
    }

    func testDiskCacheHitAvoidsNetworkCall() async throws {
        let counter = CallCounter()
        let diskCache = FakeDiskImageCache()
        await diskCache.seed(Data("cached-bytes".utf8), for: url)
        let cache = ImageCache(session: FakeAPIRequesting(counter: counter), diskCache: diskCache)

        let data = try await cache.data(for: url)

        XCTAssertEqual(data, Data("cached-bytes".utf8))
        let callCount = await counter.count
        XCTAssertEqual(callCount, 0)
    }

    func testSuccessfulFetchWritesThroughToDiskCache() async throws {
        let diskCache = FakeDiskImageCache()
        let cache = ImageCache(session: FakeAPIRequesting(), diskCache: diskCache)

        _ = try await cache.data(for: url)

        let writeCount = await diskCache.writeCount
        XCTAssertEqual(writeCount, 1)
    }

    func testFailedFetchThrowsAndDoesNotCache() async throws {
        let counter = CallCounter()
        let cache = ImageCache(session: FakeAPIRequesting(statusCode: 404, counter: counter), diskCache: nil)

        do {
            _ = try await cache.data(for: url)
            XCTFail("expected an error for a 404 response")
        } catch NetworkError.invalidResponse {
            // expected
        }

        // A retry after a failure should hit the network again, not serve a cached failure.
        _ = try? await cache.data(for: url)
        let callCount = await counter.count
        XCTAssertEqual(callCount, 2)
    }
}
