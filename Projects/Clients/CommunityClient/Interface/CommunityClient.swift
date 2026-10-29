import ClientCore

/// 커뮤니티 게시판(애니 시리즈) 한 칸 (레거시 `CommunityBoard`)
public struct CommunityBoard: Hashable, Sendable {
    public let seriesId: Int
    public let title: String?
    public let coverImageUrl: String?
    public let genres: [String]

    public init(seriesId: Int, title: String?, coverImageUrl: String?, genres: [String]) {
        self.seriesId = seriesId
        self.title = title
        self.coverImageUrl = coverImageUrl
        self.genres = genres
    }
}

public struct CommunityBoardPage: Equatable, Sendable {
    public let boards: [CommunityBoard]
    public let lastId: Int?
    public let lastValue: String?

    public init(boards: [CommunityBoard], lastId: Int?, lastValue: String?) {
        self.boards = boards
        self.lastId = lastId
        self.lastValue = lastValue
    }
}

public protocol CommunityClient: Sendable {
    /// 커뮤니티 게시판 탐색 (`GET api/community/explore/boards`, 20개씩). sort는 "popular"·"latest"
    func exploreBoards(sort: String, keyword: String?, lastValue: String?, lastId: Int?)
        async throws(TransportError) -> CommunityBoardPage
}
