import CoreGraphics

/// Greedy shortest-column layout: each item is appended to whichever column
/// currently has the smallest cumulative height. Deterministic and stable
/// under append — items already placed never move when more items are added
/// to the end of `items`, which matters for infinite-scroll pagination.
public enum MasonryBalancer {
    public static func distribute<T>(_ items: [T], columns: Int, height: (T) -> CGFloat) -> [[T]] {
        guard columns > 0 else { return [items] }

        var buckets: [[T]] = Array(repeating: [], count: columns)
        var bucketHeights = Array(repeating: CGFloat.zero, count: columns)

        for item in items {
            let shortest = bucketHeights.indices.min { bucketHeights[$0] < bucketHeights[$1] } ?? 0
            buckets[shortest].append(item)
            bucketHeights[shortest] += height(item)
        }

        return buckets
    }
}
