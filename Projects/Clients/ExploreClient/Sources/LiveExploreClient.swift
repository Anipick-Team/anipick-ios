import ClientCore
import ExploreClientInterface
import Foundation
import Networking

public struct LiveExploreClient: ExploreClient {
    private let client: HTTPClient

    /// - Parameter client: 인증 클라이언트
    public init(client: HTTPClient) {
        self.client = client
    }

    public func onboardingAnimes(
        query: String?,
        year: Int?,
        season: Int?,
        genreId: Int?,
        lastId: Int?
    ) async throws(TransportError) -> OnboardingPage? {
        let response = try await client.send(
            Self.onboardingEndpoint(
                query: query, year: year, season: season, genreId: genreId, lastId: lastId))
        guard let result = response.result, let animes = result.animes else {
            return nil
        }
        return OnboardingPage(
            animes: animes.map {
                OnboardingAnime(
                    animeId: $0.animeId, title: $0.title, coverImageUrl: $0.coverImageUrl,
                    genres: $0.genres)
            },
            lastId: result.cursor?.lastId
        )
    }

    public func exploreAnimes(_ query: ExploreQuery) async throws(TransportError) -> ExplorePage? {
        let response = try await client.send(Self.exploreEndpoint(query))
        guard let result = response.result, let animes = result.animes else {
            return nil
        }
        return ExplorePage(
            animes: animes.map {
                ExploreAnime(animeId: $0.animeId, title: $0.title, coverImageUrl: $0.coverImageUrl)
            },
            lastId: result.cursor?.lastId
        )
    }

    /// 레거시 `ExploreAPI.exploreAnime`: Alamofire URLEncoding 기본값처럼 배열은 `genres[]`를 반복한다.
    /// size는 18, lastValue는 보내지 않는다(레거시가 늘 nil)
    static func exploreEndpoint(_ query: ExploreQuery) -> Endpoint<ExploreResult> {
        var items: [URLQueryItem] = []
        func add(_ name: String, _ value: String?) {
            if let value {
                items.append(URLQueryItem(name: name, value: value))
            }
        }
        // 이름순 (Alamofire URLEncoding 기본 동작)
        for genreId in query.genreIds ?? [] {
            add("genres[]", String(genreId))
        }
        add("genreOp", query.genreOp)
        add("lastId", query.lastId.map(String.init))
        add("season", query.season.map(String.init))
        add("size", "18")
        add("sort", query.sort)
        add("type", query.type)
        add("year", query.year.map(String.init))
        return Endpoint(method: .get, path: "api/explore/animes", query: items, requiresAuth: true)
    }

    /// 레거시 `AnimeAPI.preference`: 장르는 `genres` 이름으로 id를 보낸다. size는 보내지 않는다
    static func onboardingEndpoint(
        query: String?,
        year: Int?,
        season: Int?,
        genreId: Int?,
        lastId: Int?
    ) -> Endpoint<OnboardingResult> {
        let parameters: [String: String?] = [
            "query": query, "year": year.map(String.init), "season": season.map(String.init),
            "genres": genreId.map(String.init), "lastId": lastId.map(String.init),
        ]
        return Endpoint(
            method: .get,
            path: "api/explore-search",
            query: parameters.compactMapValues { $0 }.sorted { $0.key < $1.key }
                .map { URLQueryItem(name: $0.key, value: $0.value) },
            requiresAuth: true
        )
    }
}

struct OnboardingResult: Decodable, Sendable {
    struct Cursor: Decodable, Sendable {
        let lastId: Int?
    }

    struct Anime: Decodable, Sendable {
        let animeId: Int?
        let title: String?
        let coverImageUrl: String?
        let genres: [String]?
    }

    let cursor: Cursor?
    let animes: [Anime]?
}

/// 레거시 `ExploreResult`
struct ExploreResult: Decodable, Sendable {
    struct Cursor: Decodable, Sendable {
        let lastId: Int?
    }

    struct Anime: Decodable, Sendable {
        let animeId: Int?
        let title: String?
        let coverImageUrl: String?
    }

    let cursor: Cursor?
    let animes: [Anime]?
}
