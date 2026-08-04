import Foundation

/// A single entry from a Giphy GIF object's `images` dictionary (e.g. `fixed_width`,
/// `original`). Giphy's API returns `width`/`height` as JSON strings, not numbers, hence
/// the custom decoding below.
public struct RenditionDTO: Decodable, Sendable, Equatable {
    public let url: URL
    public let width: Int
    public let height: Int

    private enum CodingKeys: String, CodingKey {
        case url, width, height
    }

    public init(url: URL, width: Int, height: Int) {
        self.url = url
        self.width = width
        self.height = height
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = try container.decode(URL.self, forKey: .url)
        width = try container.decodeIntFromStringOrNumber(forKey: .width)
        height = try container.decodeIntFromStringOrNumber(forKey: .height)
    }
}

extension KeyedDecodingContainer {
    /// Giphy's rendition objects encode numeric fields (`width`, `height`, `size`) as
    /// JSON strings. Falls back to a plain `Int` in case that ever changes upstream.
    func decodeIntFromStringOrNumber(forKey key: Key) throws -> Int {
        if let intValue = try? decode(Int.self, forKey: key) {
            return intValue
        }
        let stringValue = try decode(String.self, forKey: key)
        guard let intValue = Int(stringValue) else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: self,
                debugDescription: "Expected an integer or integer string, got \"\(stringValue)\""
            )
        }
        return intValue
    }
}
