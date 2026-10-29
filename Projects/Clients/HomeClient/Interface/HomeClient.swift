import ClientCore

/// 홈 목록의 작품 한 칸 (레거시 `Anime`). 서버가 비워 보낼 수 있는 값은 모두 선택값이다
public struct HomeAnime: Hashable, Sendable {
    public let animeId: Int?
    public let title: String?
    public let coverImageUrl: String?

    public init(animeId: Int?, title: String?, coverImageUrl: String?) {
        self.animeId = animeId
        self.title = title
        self.coverImageUrl = coverImageUrl
    }
}

/// 추천 한 페이지 (레거시 `RecommendationResult`)
public struct RecommendationPage: Equatable, Sendable {
    public let animes: [HomeAnime]
    /// 비슷한 작품 추천의 기준 작품 제목
    public let referenceAnimeTitle: String?
    public let lastId: Int?
    public let lastValue: String?

    public init(animes: [HomeAnime], referenceAnimeTitle: String?, lastId: Int?, lastValue: String?)
    {
        self.animes = animes
        self.referenceAnimeTitle = referenceAnimeTitle
        self.lastId = lastId
        self.lastValue = lastValue
    }
}

public protocol HomeClient: Sendable {
    /// 취향 추천 (`GET api/recommendation/animes`). 결과나 목록이 없으면 nil
    func recommendations(lastId: Int?, lastValue: String?) async throws(TransportError)
        -> RecommendationPage?
    /// 최근 본 작품과 비슷한 작품 (`GET api/recommendation/animes/{id}/recent`). 결과나 목록이 없으면 nil
    func recentRecommendations(animeId: Int, lastId: Int?, lastValue: String?)
        async throws(TransportError)
        -> RecommendationPage?
}
