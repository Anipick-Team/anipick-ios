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

public protocol ExploreClient: Sendable {
    /// `GET api/explore-search` (취향 선택). 값이 없는 조건은 보내지 않는다. 결과·목록이 없으면 nil
    func onboardingAnimes(query: String?, year: Int?, season: Int?, genreId: Int?, lastId: Int?)
        async throws(TransportError) -> OnboardingPage?
}
