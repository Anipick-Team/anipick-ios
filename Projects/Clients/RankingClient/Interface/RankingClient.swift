import ClientCore

/// 랭킹 한 줄. 서버가 비워 보낼 수 있는 값은 모두 선택값이다 (레거시 `RankedAnime`)
public struct RankedAnime: Hashable, Sendable, Decodable {
    public let animeId: Int?
    public let title: String?
    public let coverImageUrl: String?
    public let rank: Int?
    /// 순위 변화량. 서버가 문자열로 보낸다 (예: "-3")
    public let change: String?
    /// "up" / "down" / 그 밖(변화 없음)
    public let trend: String?
    public let genres: [String]?

    public init(
        animeId: Int?,
        title: String?,
        coverImageUrl: String?,
        rank: Int?,
        change: String?,
        trend: String?,
        genres: [String]?
    ) {
        self.animeId = animeId
        self.title = title
        self.coverImageUrl = coverImageUrl
        self.rank = rank
        self.change = change
        self.trend = trend
        self.genres = genres
    }
}

/// 한 페이지와 다음 페이지 커서
public struct RankingPage: Equatable, Sendable {
    public let animes: [RankedAnime]
    public let lastId: Int
    /// 실시간 랭킹만 쓴다
    public let lastValue: String?

    public init(animes: [RankedAnime], lastId: Int, lastValue: String?) {
        self.animes = animes
        self.lastId = lastId
        self.lastValue = lastValue
    }
}

/// 랭킹 목록 (레거시 `RankingAPI`). 모두 20개씩 받는다. `genre`는 장르 **이름**이다(서버 요구).
public protocol RankingClient: Sendable {
    func realTime(genre: String?, lastId: Int?, lastValue: String?) async throws(TransportError)
        -> RankingPage
    func yearSeason(year: Int, season: Int?, genre: String?, lastId: Int?, lastRank: Int?)
        async throws(TransportError) -> RankingPage
    func allTime(genre: String?, lastId: Int?, lastRank: Int?) async throws(TransportError)
        -> RankingPage
}
