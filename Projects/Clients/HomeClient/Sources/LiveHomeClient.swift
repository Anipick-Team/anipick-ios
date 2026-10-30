import ClientCore
import Foundation
import HomeClientInterface
import Networking
import Storage

public struct LiveHomeClient: HomeClient {
    /// 레거시 `UserDefaultKey.homeRecentKeyword`
    static let recentKeywordsKey = PreferenceKey("homeRecentKeyword", defaultValue: [String]())

    private let client: HTTPClient
    private let preferences: Preferences
    private let session: URLSession

    /// - Parameters:
    ///   - client: 인증 클라이언트
    ///   - session: 검색 로그 주소를 보낼 세션 (인증 없음)
    public init(
        client: HTTPClient, preferences: Preferences = Preferences(), session: URLSession = .shared
    ) {
        self.client = client
        self.preferences = preferences
        self.session = session
    }

    public func popularAnimes() async throws(TransportError) -> [HomeAnime] {
        let response = try await client.send(
            Self.query("api/search/init", [:]) as Endpoint<PopularResult>)
        return (response.result?.popularAnimes ?? []).map(\.anime)
    }

    public func searchAnimes(query: String, lastId: Int?) async throws(TransportError)
        -> SearchPage<SearchAnime>?
    {
        let response = try await client.send(
            Self.searchEndpoint("api/search/animes", query, lastId)
                as Endpoint<SearchResult<SearchAnimeDTO>>)
        return response.result.map { result in
            SearchPage(
                items: (result.animes ?? []).map(\.anime), count: result.count ?? 0,
                lastId: result.cursor?.lastId)
        }
    }

    public func searchPersons(query: String, lastId: Int?) async throws(TransportError)
        -> SearchPage<SearchPerson>?
    {
        let response = try await client.send(
            Self.searchEndpoint("api/search/persons", query, lastId)
                as Endpoint<SearchResult<PersonDTO>>)
        return response.result.map { result in
            SearchPage(
                items: (result.persons ?? []).map(\.person), count: result.count ?? 0,
                lastId: result.cursor?.lastId)
        }
    }

    public func searchStudios(query: String, lastId: Int?) async throws(TransportError)
        -> SearchPage<SearchStudio>?
    {
        let response = try await client.send(
            Self.searchEndpoint("api/search/studios", query, lastId)
                as Endpoint<SearchResult<StudioDTO>>)
        return response.result.map { result in
            SearchPage(
                items: (result.studios ?? []).map(\.studio), count: result.count ?? 0,
                lastId: result.cursor?.lastId)
        }
    }

    static func searchEndpoint<Result>(_ path: String, _ query: String, _ lastId: Int?) -> Endpoint<
        Result
    > {
        return Self.query(path, ["query": query, "lastId": lastId.map(String.init)])
    }

    public func sendTrackingLog(_ url: String) async {
        guard let url = URL(string: url) else {
            return
        }
        _ = try? await session.data(from: url)
    }

    public func recentKeywords() -> [String] {
        return preferences.value(for: Self.recentKeywordsKey)
    }

    public func saveRecentKeyword(_ keyword: String) {
        var keywords = recentKeywords()
        keywords.removeAll { $0 == keyword }
        keywords.insert(keyword, at: 0)
        preferences.set(keywords, for: Self.recentKeywordsKey)
    }

    public func setRecentKeywords(_ keywords: [String]) {
        preferences.set(keywords, for: Self.recentKeywordsKey)
    }

    public func clearRecentKeywords() {
        preferences.set([], for: Self.recentKeywordsKey)
    }

    public func recommendations(lastId: Int?, lastValue: String?) async throws(TransportError)
        -> RecommendationPage?
    {
        return Self.page(
            try await client.send(
                Self.endpoint("api/recommendation/animes", lastId: lastId, lastValue: lastValue)))
    }

    public func recentRecommendations(animeId: Int, lastId: Int?, lastValue: String?)
        async throws(TransportError) -> RecommendationPage?
    {
        return Self.page(
            try await client.send(
                Self.endpoint(
                    "api/recommendation/animes/\(animeId)/recent", lastId: lastId,
                    lastValue: lastValue)))
    }

    public func comingSoon(sort: String, lastId: Int?, includeAdult: Bool)
        async throws(TransportError)
        -> ComingSoonPage?
    {
        let response = try await client.send(
            Self.query(
                "api/animes/coming-soon",
                [
                    "sort": sort, "lastId": lastId.map(String.init), "size": "18",
                    "includeAdult": includeAdult ? "true" : "false",
                ]) as Endpoint<ComingSoonResult>)
        guard let result = response.result, let animes = result.animes else {
            return nil
        }
        return ComingSoonPage(
            animes: animes.map {
                ComingSoonAnime(
                    animeId: $0.animeId, title: $0.title, coverImageUrl: $0.coverImageUrl,
                    releaseDate: $0.releaseDate)
            },
            lastId: result.cursor?.lastId
        )
    }

    public func weekdayNewAnimes(day: String, sort: String, lastId: Int?, size: Int)
        async throws(TransportError)
        -> WeekdayAnimePage
    {
        let response = try await client.send(
            Self.query(
                "api/animes",
                ["day": day, "sort": sort, "lastId": lastId.map(String.init), "size": String(size)])
                as Endpoint<WeekdayResult>)
        return WeekdayAnimePage(
            animes: (response.result?.animes ?? []).map(\.anime),
            lastId: response.result?.cursor?.lastId)
    }

    public func trending() async throws(TransportError) -> [TrendingAnime] {
        let response = try await client.send(
            Self.query("api/home/animes/trending", [:]) as Endpoint<[TrendingDTO]>)
        return (response.result ?? []).map {
            TrendingAnime(
                animeId: $0.animeId, title: $0.title, coverImageUrl: $0.coverImageUrl, rank: $0.rank
            )
        }
    }

    public func homeRecommendations() async throws(TransportError) -> RecommendationPage? {
        return Self.page(try await client.send(Self.query("api/home/recommendation/animes", [:])))
    }

    public func homeRecentRecommendations(animeId: Int) async throws(TransportError)
        -> RecommendationPage?
    {
        return Self.page(
            try await client.send(
                Self.query("api/home/recommendation/animes/\(animeId)/recent", [:])))
    }

    public func homeRecentReviews() async throws(TransportError) -> [HomeReview] {
        let reviews = try await client.send(
            Self.query("api/home/reviews/recent", [:]) as Endpoint<[HomeReviewDTO]>
        )
        .requireResult()
        return reviews.map {
            HomeReview(
                reviewId: $0.reviewId, animeTitle: $0.animeTitle, reviewContent: $0.reviewContent,
                nickname: $0.nickname, createdAt: $0.createdAt)
        }
    }

    public func upcomingSeason() async throws(TransportError) -> UpcomingSeason {
        let result = try await client.send(
            Self.query("api/animes/upcoming-season", [:]) as Endpoint<SeasonResult>
        )
        .requireResult()
        return UpcomingSeason(
            season: result.season, seasonYear: result.seasonYear, animes: result.animes.map(\.anime)
        )
    }

    public func homeComingSoon() async throws(TransportError) -> [HomeAnime] {
        return try await client.send(
            Self.query("api/home/animes/coming-soon", [:]) as Endpoint<[AnimeDTO]>
        )
        .requireResult().map(\.anime)
    }

    static func query<Result>(_ path: String, _ parameters: [String: String?]) -> Endpoint<Result> {
        return Endpoint(
            method: .get,
            path: path,
            query: parameters.compactMapValues { $0 }.sorted { $0.key < $1.key }
                .map { URLQueryItem(name: $0.key, value: $0.value) },
            requiresAuth: true
        )
    }

    /// 레거시 `RecommendationAPI`: lastId·lastValue만 (size 없음)
    static func endpoint(_ path: String, lastId: Int?, lastValue: String?) -> Endpoint<
        RecommendationResult
    > {
        let parameters: [String: String?] = [
            "lastId": lastId.map(String.init), "lastValue": lastValue,
        ]
        return Endpoint(
            method: .get,
            path: path,
            query: parameters.compactMapValues { $0 }.sorted { $0.key < $1.key }
                .map { URLQueryItem(name: $0.key, value: $0.value) },
            requiresAuth: true
        )
    }

    private static func page(_ response: ServerResponse<RecommendationResult>)
        -> RecommendationPage?
    {
        guard let result = response.result, let animes = result.animes else {
            return nil
        }
        return RecommendationPage(
            animes: animes.map(\.anime),
            referenceAnimeTitle: result.referenceAnimeTitle,
            lastId: result.cursor?.lastId,
            lastValue: result.cursor?.lastValue
        )
    }
}

/// 레거시 `Anime`
struct AnimeDTO: Decodable, Sendable {
    let animeId: Int?
    let title: String?
    let coverImageUrl: String?

    var anime: HomeAnime {
        return HomeAnime(animeId: animeId, title: title, coverImageUrl: coverImageUrl)
    }
}

/// 레거시 `RecommendationResult`
struct RecommendationResult: Decodable, Sendable {
    struct Cursor: Decodable, Sendable {
        let lastId: Int?
        let lastValue: String?
    }

    let referenceAnimeTitle: String?
    let cursor: Cursor?
    let animes: [AnimeDTO]?
}

struct PageCursor: Decodable, Sendable {
    let lastId: Int?
}

/// 레거시 `UpcomingAnimeResult`
struct ComingSoonResult: Decodable, Sendable {
    struct Anime: Decodable, Sendable {
        let animeId: Int?
        let title: String?
        let coverImageUrl: String?
        let releaseDate: String?
    }

    let cursor: PageCursor?
    let animes: [Anime]?
}

/// 레거시 `WeekdayAnimeResult`
struct WeekdayResult: Decodable, Sendable {
    let cursor: PageCursor?
    let animes: [AnimeDTO]?
}

/// 레거시 `PopularAnimes`
struct PopularResult: Decodable, Sendable {
    let popularAnimes: [AnimeDTO]?
}

/// 레거시 `AnimeResult`·`SearchPersonResult`·`SearchStudioResult`
struct SearchResult<Item: Decodable & Sendable>: Decodable, Sendable {
    let count: Int?
    let cursor: PageCursor?
    let animes: [Item]?
    let persons: [Item]?
    let studios: [Item]?
}

struct SearchAnimeDTO: Decodable, Sendable {
    let animeId: Int?
    let title: String?
    let coverImageUrl: String?
    let clickLog: String?
    let impressionLogs: String?

    var anime: SearchAnime {
        return SearchAnime(
            animeId: animeId, title: title, coverImageUrl: coverImageUrl, clickLog: clickLog,
            impressionLog: impressionLogs)
    }
}

struct PersonDTO: Decodable, Sendable {
    let personId: Int?
    let name: String?
    let profileImage: String?

    var person: SearchPerson {
        return SearchPerson(personId: personId, name: name, profileImage: profileImage)
    }
}

struct StudioDTO: Decodable, Sendable {
    let studioId: Int?
    let name: String?

    var studio: SearchStudio {
        return SearchStudio(studioId: studioId, name: name)
    }
}

/// 레거시 `TrendingAnimes`
struct TrendingDTO: Decodable, Sendable {
    let animeId: Int?
    let title: String?
    let coverImageUrl: String?
    let rank: Int?
}

/// 레거시 `Review` (홈 최근 리뷰)
struct HomeReviewDTO: Decodable, Sendable {
    let reviewId: Int?
    let animeTitle: String?
    let reviewContent: String?
    let nickname: String?
    let createdAt: String?
}

/// 레거시 `AnimeSeasonResult` (모두 필수 값)
struct SeasonResult: Decodable, Sendable {
    let season: Int
    let seasonYear: Int
    let animes: [AnimeDTO]
}
