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

/// 공개 예정 한 칸 (레거시 `UpcomingAnime`)
public struct ComingSoonAnime: Hashable, Sendable {
    public let animeId: Int?
    public let title: String?
    public let coverImageUrl: String?
    public let releaseDate: String?

    public init(animeId: Int?, title: String?, coverImageUrl: String?, releaseDate: String?) {
        self.animeId = animeId
        self.title = title
        self.coverImageUrl = coverImageUrl
        self.releaseDate = releaseDate
    }
}

public struct ComingSoonPage: Equatable, Sendable {
    public let animes: [ComingSoonAnime]
    public let lastId: Int?

    public init(animes: [ComingSoonAnime], lastId: Int?) {
        self.animes = animes
        self.lastId = lastId
    }
}

/// 요일별 신작 한 페이지
public struct WeekdayAnimePage: Equatable, Sendable {
    public let animes: [HomeAnime]
    public let lastId: Int?

    public init(animes: [HomeAnime], lastId: Int?) {
        self.animes = animes
        self.lastId = lastId
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
    /// 공개 예정 (`GET api/animes/coming-soon`, 18개씩). sort는 latest·popularity·startDate. 결과나 목록이 없으면 nil
    func comingSoon(sort: String, lastId: Int?, includeAdult: Bool) async throws(TransportError)
        -> ComingSoonPage?
    /// 요일별 신작 (`GET api/animes`, 18개씩). day는 MON~SUN, sort는 popularity·latest. 결과가 없으면 빈 페이지
    func weekdayNewAnimes(day: String, sort: String, lastId: Int?) async throws(TransportError)
        -> WeekdayAnimePage
}
