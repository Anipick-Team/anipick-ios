import ClientCore
import Foundation
import Networking
import RankingClientInterface

public struct LiveRankingClient: RankingClient {
    static let pageSize = 20

    private let client: HTTPClient

    /// - Parameter client: 인증 클라이언트 (레거시가 토큰을 붙여 보낸다)
    public init(client: HTTPClient) {
        self.client = client
    }

    public func realTime(
        genre: String?,
        lastId: Int?,
        lastValue: String?
    ) async throws(TransportError) -> RankingPage {
        return try await page(
            Self.realTimeEndpoint(genre: genre, lastId: lastId, lastValue: lastValue))
    }

    public func yearSeason(
        year: Int,
        season: Int?,
        genre: String?,
        lastId: Int?,
        lastRank: Int?
    ) async throws(TransportError) -> RankingPage {
        return try await page(
            Self.yearSeasonEndpoint(
                year: year, season: season, genre: genre, lastId: lastId, lastRank: lastRank)
        )
    }

    public func allTime(
        genre: String?,
        lastId: Int?,
        lastRank: Int?
    ) async throws(TransportError) -> RankingPage {
        return try await page(
            Self.allTimeEndpoint(genre: genre, lastId: lastId, lastRank: lastRank))
    }

    private func page(_ endpoint: Endpoint<RankingResult>) async throws(TransportError)
        -> RankingPage
    {
        let result = try await client.send(endpoint).requireResult()
        return RankingPage(
            animes: result.animes,
            lastId: result.cursor.lastId,
            lastValue: result.cursor.lastValue
        )
    }

    static func realTimeEndpoint(genre: String?, lastId: Int?, lastValue: String?) -> Endpoint<
        RankingResult
    > {
        return endpoint(
            "api/rankings/real-time",
            ["genre": genre, "lastId": lastId.map(String.init), "lastValue": lastValue]
        )
    }

    static func yearSeasonEndpoint(
        year: Int,
        season: Int?,
        genre: String?,
        lastId: Int?,
        lastRank: Int?
    ) -> Endpoint<RankingResult> {
        return endpoint(
            "api/rankings/year-season",
            [
                "year": String(year), "season": season.map(String.init), "genre": genre,
                "lastId": lastId.map(String.init), "lastRank": lastRank.map(String.init),
            ]
        )
    }

    static func allTimeEndpoint(genre: String?, lastId: Int?, lastRank: Int?) -> Endpoint<
        RankingResult
    > {
        return endpoint(
            "api/rankings/all-time",
            [
                "genre": genre, "lastId": lastId.map(String.init),
                "lastRank": lastRank.map(String.init),
            ]
        )
    }

    /// 레거시처럼 값이 없는 파라미터는 빼고, 이름순으로 보낸다 (Alamofire `URLEncoding` 기본 동작)
    private static func endpoint(_ path: String, _ parameters: [String: String?]) -> Endpoint<
        RankingResult
    > {
        var values = parameters.compactMapValues { $0 }
        values["size"] = String(pageSize)
        return Endpoint(
            method: .get,
            path: path,
            query: values.sorted { $0.key < $1.key }.map {
                URLQueryItem(name: $0.key, value: $0.value)
            },
            requiresAuth: true
        )
    }
}

struct RankingResult: Decodable, Sendable {
    struct Cursor: Decodable, Sendable {
        let lastId: Int
        let lastValue: String?
    }

    let cursor: Cursor
    let animes: [RankedAnime]
}
