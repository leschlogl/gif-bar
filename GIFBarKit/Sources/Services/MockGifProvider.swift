import Models

/// Stands in for a real `GiphyService` until the Networking milestone lands.
/// Backed by the same 18-item dataset used in the approved design prototype.
public struct MockGifProvider: GifProviding {
    private static let dataset: [Gif] = [
        Gif(id: "1", title: "Excited Cat", width: 200, height: 150),
        Gif(id: "2", title: "Thumbs Up", width: 200, height: 190),
        Gif(id: "3", title: "Confetti Burst", width: 200, height: 130),
        Gif(id: "4", title: "Dancing Robot", width: 200, height: 210),
        Gif(id: "5", title: "Happy Dance", width: 200, height: 170),
        Gif(id: "6", title: "Mind Blown", width: 200, height: 150),
        Gif(id: "7", title: "Clapping Hands", width: 200, height: 230),
        Gif(id: "8", title: "Slow Clap", width: 200, height: 140),
        Gif(id: "9", title: "Party Parrot", width: 200, height: 180),
        Gif(id: "10", title: "Facepalm", width: 200, height: 160),
        Gif(id: "11", title: "Eye Roll", width: 200, height: 200),
        Gif(id: "12", title: "Popcorn Time", width: 200, height: 150),
        Gif(id: "13", title: "High Five", width: 200, height: 170),
        Gif(id: "14", title: "Success Kid", width: 200, height: 190),
        Gif(id: "15", title: "Deal With It", width: 200, height: 140),
        Gif(id: "16", title: "Golf Clap", width: 200, height: 220),
        Gif(id: "17", title: "Fist Bump", width: 200, height: 160),
        Gif(id: "18", title: "Mic Drop", width: 200, height: 180),
    ]

    private let latency: Duration
    private let clock: any Clock<Duration>

    public init(latency: Duration = .milliseconds(700), clock: any Clock<Duration> = ContinuousClock()) {
        self.latency = latency
        self.clock = clock
    }

    public func trending(offset: Int, limit: Int) async throws -> GifPage {
        try await simulateLatency()
        return page(from: Self.dataset, offset: offset, limit: limit)
    }

    public func search(query: String, offset: Int, limit: Int) async throws -> GifPage {
        try await simulateLatency()
        let matches = query.isEmpty
            ? Self.dataset
            : Self.dataset.filter { $0.title.localizedCaseInsensitiveContains(query) }
        return page(from: matches, offset: offset, limit: limit)
    }

    public func fetch(ids: [String]) async throws -> [Gif] {
        try await simulateLatency()
        let byID = Dictionary(uniqueKeysWithValues: Self.dataset.map { ($0.id, $0) })
        return ids.compactMap { byID[$0] }
    }

    private func simulateLatency() async throws {
        guard latency > .zero else { return }
        try await clock.sleep(for: latency)
    }

    private func page(from source: [Gif], offset: Int, limit: Int) -> GifPage {
        guard offset < source.count else { return GifPage(gifs: [], hasMore: false) }
        let end = min(offset + limit, source.count)
        return GifPage(gifs: Array(source[offset..<end]), hasMore: end < source.count)
    }
}
