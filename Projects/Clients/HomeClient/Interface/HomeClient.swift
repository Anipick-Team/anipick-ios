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

/// 검색 결과 작품 (레거시 `AnimeWithClickLog`). 로그 주소는 받는 대로 서버에 알린다
public struct SearchAnime: Hashable, Sendable {
    public let animeId: Int?
    public let title: String?
    public let coverImageUrl: String?
    public let clickLog: String?
    public let impressionLog: String?

    public init(
        animeId: Int?, title: String?, coverImageUrl: String?, clickLog: String?,
        impressionLog: String?
    ) {
        self.animeId = animeId
        self.title = title
        self.coverImageUrl = coverImageUrl
        self.clickLog = clickLog
        self.impressionLog = impressionLog
    }
}

/// 검색 결과 인물 (레거시 `Person`)
public struct SearchPerson: Hashable, Sendable {
    public let personId: Int?
    public let name: String?
    public let profileImage: String?

    public init(personId: Int?, name: String?, profileImage: String?) {
        self.personId = personId
        self.name = name
        self.profileImage = profileImage
    }
}

/// 검색 결과 제작사 (레거시 `Studio`)
public struct SearchStudio: Hashable, Sendable {
    public let studioId: Int?
    public let name: String?

    public init(studioId: Int?, name: String?) {
        self.studioId = studioId
        self.name = name
    }
}

/// 검색 한 페이지. count는 서버가 준 전체 개수 (없으면 0)
public struct SearchPage<Item: Hashable & Sendable>: Equatable, Sendable {
    public let items: [Item]
    public let count: Int
    public let lastId: Int?

    public init(items: [Item], count: Int, lastId: Int?) {
        self.items = items
        self.count = count
        self.lastId = lastId
    }
}

/// 실시간 인기 한 칸 (레거시 `TrendingAnimes`)
public struct TrendingAnime: Hashable, Sendable {
    public let animeId: Int?
    public let title: String?
    public let coverImageUrl: String?
    public let rank: Int?

    public init(animeId: Int?, title: String?, coverImageUrl: String?, rank: Int?) {
        self.animeId = animeId
        self.title = title
        self.coverImageUrl = coverImageUrl
        self.rank = rank
    }
}

/// 홈의 최근 리뷰 카드 (레거시 `Review`)
public struct HomeReview: Hashable, Sendable {
    public let reviewId: Int?
    public let animeTitle: String?
    public let reviewContent: String?
    public let nickname: String?
    public let createdAt: String?

    public init(
        reviewId: Int?, animeTitle: String?, reviewContent: String?, nickname: String?,
        createdAt: String?
    ) {
        self.reviewId = reviewId
        self.animeTitle = animeTitle
        self.reviewContent = reviewContent
        self.nickname = nickname
        self.createdAt = createdAt
    }
}

/// 다음 분기 방영 예정 (레거시 `AnimeSeasonResult`)
public struct UpcomingSeason: Equatable, Sendable {
    public let season: Int
    public let seasonYear: Int
    public let animes: [HomeAnime]

    public init(season: Int, seasonYear: Int, animes: [HomeAnime]) {
        self.season = season
        self.seasonYear = seasonYear
        self.animes = animes
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
    /// 요일별 신작 (`GET api/animes`). day는 MON~SUN, sort는 popularity·latest. 결과가 없으면 빈 페이지
    func weekdayNewAnimes(day: String, sort: String, lastId: Int?, size: Int)
        async throws(TransportError)
        -> WeekdayAnimePage

    /// 홈 실시간 인기 (`GET api/home/animes/trending`). 결과가 없으면 빈 목록
    func trending() async throws(TransportError) -> [TrendingAnime]
    /// 홈 취향 추천 (`GET api/home/recommendation/animes`). 결과나 목록이 없으면 nil
    func homeRecommendations() async throws(TransportError) -> RecommendationPage?
    /// 홈 비슷한 작품 (`GET api/home/recommendation/animes/{id}/recent`). 결과나 목록이 없으면 nil
    func homeRecentRecommendations(animeId: Int) async throws(TransportError) -> RecommendationPage?
    /// 홈 최근 리뷰 (`GET api/home/reviews/recent`). 결과가 없으면 `.decoding` (레거시 필수 값)
    func homeRecentReviews() async throws(TransportError) -> [HomeReview]
    /// 다음 분기 방영 예정 (`GET api/animes/upcoming-season`). 결과가 없으면 `.decoding`
    func upcomingSeason() async throws(TransportError) -> UpcomingSeason
    /// 홈 공개 예정 (`GET api/home/animes/coming-soon`). 결과가 없으면 `.decoding`
    func homeComingSoon() async throws(TransportError) -> [HomeAnime]
    /// 검색 첫 화면의 인기 작품 (`GET api/search/init`). 결과가 없으면 빈 목록
    func popularAnimes() async throws(TransportError) -> [HomeAnime]
    /// 작품 검색 (`GET api/search/animes?query&lastId`). 결과가 없으면 nil
    func searchAnimes(query: String, lastId: Int?) async throws(TransportError) -> SearchPage<
        SearchAnime
    >?
    /// 인물 검색 (`GET api/search/persons`). 결과가 없으면 nil
    func searchPersons(query: String, lastId: Int?) async throws(TransportError) -> SearchPage<
        SearchPerson
    >?
    /// 제작사 검색 (`GET api/search/studios`). 결과가 없으면 nil
    func searchStudios(query: String, lastId: Int?) async throws(TransportError) -> SearchPage<
        SearchStudio
    >?
    /// 검색 결과의 노출·클릭 로그 주소를 그대로 요청한다 (인증 없음, 결과는 보지 않는다)
    func sendTrackingLog(_ url: String) async

    /// 최근 검색어 (최신이 앞). 이 기기에 저장한다
    func recentKeywords() -> [String]
    /// 맨 앞에 넣는다 (같은 검색어는 앞으로 옮긴다)
    func saveRecentKeyword(_ keyword: String)
    func setRecentKeywords(_ keywords: [String])
    func clearRecentKeywords()
}
