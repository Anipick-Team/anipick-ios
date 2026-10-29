import ClientCore
import Foundation
import HomeClientInterface
import Networking

public struct LiveHomeClient: HomeClient {
    private let client: HTTPClient

    /// - Parameter client: 인증 클라이언트
    public init(client: HTTPClient) {
        self.client = client
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

    public func weekdayNewAnimes(day: String, sort: String, lastId: Int?)
        async throws(TransportError)
        -> WeekdayAnimePage
    {
        let response = try await client.send(
            Self.query(
                "api/animes",
                ["day": day, "sort": sort, "lastId": lastId.map(String.init), "size": "18"])
                as Endpoint<WeekdayResult>)
        return WeekdayAnimePage(
            animes: (response.result?.animes ?? []).map(\.anime),
            lastId: response.result?.cursor?.lastId)
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
