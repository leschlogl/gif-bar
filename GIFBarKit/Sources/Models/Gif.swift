public struct Gif: Identifiable, Hashable, Sendable, Codable {
    public let id: String
    public let title: String
    public let width: Int
    public let height: Int

    public init(id: String, title: String, width: Int, height: Int) {
        self.id = id
        self.title = title
        self.width = width
        self.height = height
    }
}
