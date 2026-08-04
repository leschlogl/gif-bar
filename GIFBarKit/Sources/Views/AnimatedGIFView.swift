import DesignSystem
import ImageIO
import SwiftUI

/// Decodes and plays back a GIF's frames manually via `ImageIO`/`CGImageSource` — no
/// third-party GIF library is implied by the PRD (only the official Giphy SDK is
/// disallowed). Falls back to `StripedPlaceholder` while loading or on failure.
struct AnimatedGIFView: View {
    let url: URL
    let loadData: (URL) async throws -> Data

    @State private var frames: [GIFFrame] = []
    @State private var currentFrameIndex = 0

    var body: some View {
        ZStack {
            if let frame = frames[safe: currentFrameIndex] {
                Image(decorative: frame.image, scale: 1)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                StripedPlaceholder(cornerRadius: 0)
            }
        }
        .task(id: url) {
            await loadAndAnimate()
        }
    }

    private func loadAndAnimate() async {
        frames = []
        currentFrameIndex = 0
        guard let data = try? await loadData(url),
              let decoded = try? Self.decodeFrames(from: data),
              !decoded.isEmpty
        else { return }

        guard !Task.isCancelled else { return }
        frames = decoded

        guard decoded.count > 1 else { return }
        while !Task.isCancelled {
            for index in decoded.indices {
                guard !Task.isCancelled else { return }
                currentFrameIndex = index
                try? await Task.sleep(for: .seconds(decoded[index].duration))
            }
        }
    }

    private static func decodeFrames(from data: Data) throws -> [GIFFrame] {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw DecodingError.invalidData
        }
        let count = CGImageSourceGetCount(source)
        guard count > 0 else { throw DecodingError.invalidData }

        return (0..<count).compactMap { index -> GIFFrame? in
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else { return nil }
            return GIFFrame(image: cgImage, duration: frameDuration(source: source, index: index))
        }
    }

    /// GIF frame delays default to 0.1s per the format spec when unspecified, and some
    /// encoders emit implausibly small (near-zero) delays that would otherwise spin the
    /// animation far faster than intended.
    private static func frameDuration(source: CGImageSource, index: Int) -> Double {
        let minimumDuration = 0.02
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
              let gifProperties = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any]
        else {
            return 0.1
        }
        let duration = (gifProperties[kCGImagePropertyGIFUnclampedDelayTime] as? Double)
            ?? (gifProperties[kCGImagePropertyGIFDelayTime] as? Double)
            ?? 0.1
        return max(duration, minimumDuration)
    }

    private enum DecodingError: Error {
        case invalidData
    }
}

private struct GIFFrame {
    let image: CGImage
    let duration: Double
}

extension Array {
    fileprivate subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
