import ClientCore

/// 취향 선택 목록의 애니 (레거시 `AnimePreference`)
public struct OnboardingAnime: Hashable, Sendable {
    public let animeId: Int?
    public let title: String?
    public let coverImageUrl: String?
    public let genres: [String]?

    public init(animeId: Int?, title: String?, coverImageUrl: String?, genres: [String]?) {
        self.animeId = animeId
        self.title = title
        self.coverImageUrl = coverImageUrl
        self.genres = genres
    }
}

public struct OnboardingPage: Equatable, Sendable {
    public let animes: [OnboardingAnime]
    public let lastId: Int?

    public init(animes: [OnboardingAnime], lastId: Int?) {
        self.animes = animes
        self.lastId = lastId
    }
}

/// 작품 탐색 한 칸 (레거시 `Anime`)
public struct ExploreAnime: Hashable, Sendable {
    public let animeId: Int?
    public let title: String?
    public let coverImageUrl: String?

    public init(animeId: Int?, title: String?, coverImageUrl: String?) {
        self.animeId = animeId
        self.title = title
        self.coverImageUrl = coverImageUrl
    }
}

/// 작품 탐색 조건 (레거시 `ExploreRequestItem`)
public struct ExploreQuery: Equatable, Sendable {
    /// "popularity" · "rating"
    public var sort: String
    public var year: Int?
    public var season: Int?
    public var genreIds: [Int]?
    public var type: String?
    public var lastId: Int?
    /// "AND" · "OR"
    public var genreOp: String

    public init(
        sort: String, year: Int?, season: Int?, genreIds: [Int]?, type: String?, lastId: Int?,
        genreOp: String
    ) {
        self.sort = sort
        self.year = year
        self.season = season
        self.genreIds = genreIds
        self.type = type
        self.lastId = lastId
        self.genreOp = genreOp
    }
}

public struct ExplorePage: Equatable, Sendable {
    public let animes: [ExploreAnime]
    public let lastId: Int?

    public init(animes: [ExploreAnime], lastId: Int?) {
        self.animes = animes
        self.lastId = lastId
    }
}

public protocol ExploreClient: Sendable {
    /// 작품 탐색 (`GET api/explore/animes`, 18개씩). 결과·목록이 없으면 nil
    func exploreAnimes(_ query: ExploreQuery) async throws(TransportError) -> ExplorePage?

    /// `GET api/explore-search` (취향 선택). 값이 없는 조건은 보내지 않는다. 결과·목록이 없으면 nil
    func onboardingAnimes(query: String?, year: Int?, season: Int?, genreId: Int?, lastId: Int?)
        async throws(TransportError) -> OnboardingPage?
}
