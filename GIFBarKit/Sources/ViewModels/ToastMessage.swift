import Foundation

public struct ToastMessage: Equatable, Sendable, Identifiable {
    public enum Kind: Sendable, Equatable {
        case gifCopied
        case linkCopied
        case addedToFavorites
        case removedFromFavorites
    }

    public let id = UUID()
    public let kind: Kind

    public init(kind: Kind) {
        self.kind = kind
    }
}
