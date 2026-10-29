import ClientCore

/// 상세 목록의 작품 한 칸 (레거시 `Anime`·`SeriesAnime`). 서버가 비워 보낼 수 있는 값은 모두 선택값이다
public struct DetailAnime: Hashable, Sendable {
    public let animeId: Int?
    public let title: String?
    public let coverImageUrl: String?

    public init(animeId: Int?, title: String?, coverImageUrl: String?) {
        self.animeId = animeId
        self.title = title
        self.coverImageUrl = coverImageUrl
    }
}

/// 관련 작품 한 페이지 (레거시 `SeriesAnimeResult`)
public struct SeriesPage: Equatable, Sendable {
    public let animes: [DetailAnime]
    /// 전체 개수
    public let count: Int
    public let lastId: Int?

    public init(animes: [DetailAnime], count: Int, lastId: Int?) {
        self.animes = animes
        self.count = count
        self.lastId = lastId
    }
}

/// 함께 볼만한 작품 한 페이지 (레거시 `RecommendationResult`)
public struct AnimeRecommendationPage: Equatable, Sendable {
    public let animes: [DetailAnime]
    public let referenceAnimeTitle: String?
    public let lastId: Int?

    public init(animes: [DetailAnime], referenceAnimeTitle: String?, lastId: Int?) {
        self.animes = animes
        self.referenceAnimeTitle = referenceAnimeTitle
        self.lastId = lastId
    }
}

public protocol DetailClient: Sendable {
    /// 관련 작품 (`GET api/animes/{id}/series`, size=10). 결과가 없으면 nil
    func series(animeId: Int, lastId: Int?) async throws(TransportError) -> SeriesPage?
    /// 함께 볼만한 작품 (`GET api/animes/{id}/recommendations`, size=10). 결과나 목록이 없으면 nil
    func recommendations(animeId: Int, lastId: Int?) async throws(TransportError)
        -> AnimeRecommendationPage?
}
