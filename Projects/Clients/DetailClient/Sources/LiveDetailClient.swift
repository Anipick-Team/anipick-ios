import ClientCore
import DetailClientInterface
import Foundation
import Networking

public struct LiveDetailClient: DetailClient {
    private let client: HTTPClient

    /// - Parameter client: 인증 클라이언트
    public init(client: HTTPClient) {
        self.client = client
    }

    public func series(animeId: Int, lastId: Int?) async throws(TransportError) -> SeriesPage? {
        let response = try await client.send(
            Self.pageEndpoint("api/animes/\(animeId)/series", lastId: lastId)
                as Endpoint<SeriesResult>)
        return response.result.map {
            SeriesPage(
                animes: ($0.animes ?? []).map(\.anime), count: $0.count, lastId: $0.cursor?.lastId)
        }
    }

    public func recommendations(animeId: Int, lastId: Int?) async throws(TransportError)
        -> AnimeRecommendationPage?
    {
        let response = try await client.send(
            Self.pageEndpoint("api/animes/\(animeId)/recommendations", lastId: lastId)
                as Endpoint<RecommendationResult>)
        guard let result = response.result, let animes = result.animes else {
            return nil
        }
        return AnimeRecommendationPage(
            animes: animes.map(\.anime), referenceAnimeTitle: result.referenceAnimeTitle,
            lastId: result.cursor?.lastId)
    }

    /// 레거시 `AnimeAPI`: 넘긴 size와 상관없이 늘 10을 보낸다
    static func pageEndpoint<Result>(_ path: String, lastId: Int?) -> Endpoint<Result> {
        let parameters: [String: String?] = ["lastId": lastId.map(String.init), "size": "10"]
        return Endpoint(
            method: .get,
            path: path,
            query: parameters.compactMapValues { $0 }.sorted { $0.key < $1.key }
                .map { URLQueryItem(name: $0.key, value: $0.value) },
            requiresAuth: true
        )
    }
}

struct PageCursor: Decodable, Sendable {
    let lastId: Int?
}

struct AnimeDTO: Decodable, Sendable {
    let animeId: Int?
    let title: String?
    let coverImageUrl: String?

    var anime: DetailAnime {
        return DetailAnime(animeId: animeId, title: title, coverImageUrl: coverImageUrl)
    }
}

/// 레거시 `SeriesAnimeResult` (count는 필수 값)
struct SeriesResult: Decodable, Sendable {
    let count: Int
    let cursor: PageCursor?
    let animes: [AnimeDTO]?
}

/// 레거시 `RecommendationResult`
struct RecommendationResult: Decodable, Sendable {
    let referenceAnimeTitle: String?
    let cursor: PageCursor?
    let animes: [AnimeDTO]?
}
