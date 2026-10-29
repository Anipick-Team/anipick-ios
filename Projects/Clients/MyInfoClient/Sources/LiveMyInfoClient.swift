import ClientCore
import Foundation
import MyInfoClientInterface
import Networking

public struct LiveMyInfoClient: MyInfoClient {
    private let client: HTTPClient

    /// - Parameter client: 인증 클라이언트
    public init(client: HTTPClient) {
        self.client = client
    }

    public func watchList(
        _ status: WatchStatus,
        lastId: Int?
    ) async throws(TransportError) -> MyPage<MyAnime> {
        let result = try await client.send(Self.watchListEndpoint(status, lastId: lastId))
            .requireResult()
        return MyPage(
            count: result.count,
            items: (result.animes ?? []).map(\.anime),
            lastId: result.cursor.lastId
        )
    }

    public func likedAnimes(lastId: Int?) async throws(TransportError) -> MyPage<MyAnime> {
        let result = try await client.send(Self.likedAnimesEndpoint(lastId: lastId)).requireResult()
        return MyPage(
            count: result.count,
            items: (result.animes ?? []).map(\.anime),
            lastId: result.cursor?.lastId
        )
    }

    public func likedPersons(lastId: Int?) async throws(TransportError) -> MyPage<MyPerson> {
        let result = try await client.send(Self.likedPersonsEndpoint(lastId: lastId))
            .requireResult()
        return MyPage(
            count: result.count,
            items: result.persons.map(\.person),
            lastId: result.cursor.lastId
        )
    }

    /// 레거시 경로: 상태마다 다른 경로에 같은 `status`를 함께 보낸다
    static func watchListEndpoint(_ status: WatchStatus, lastId: Int?) -> Endpoint<WatchListResult>
    {
        let path: String
        switch status {
        case .watchList:
            path = "api/mypage/animes/watchlist"
        case .watching:
            path = "api/mypage/animes/watching"
        case .finished:
            path = "api/mypage/animes/finished"
        }
        return endpoint(
            path, ["status": status.rawValue, "lastId": lastId.map(String.init), "size": "20"])
    }

    static func likedAnimesEndpoint(lastId: Int?) -> Endpoint<LikedAnimesResult> {
        return endpoint(
            "api/mypage/animes/like", ["lastId": lastId.map(String.init), "size": "20"])
    }

    static func likedPersonsEndpoint(lastId: Int?) -> Endpoint<LikedPersonsResult> {
        return endpoint(
            "api/mypage/persons/like", ["lastId": lastId.map(String.init), "size": "30"])
    }

    /// 값이 없는 파라미터는 빼고 이름순으로 (Alamofire `URLEncoding` 기본 동작)
    private static func endpoint<Result>(_ path: String, _ parameters: [String: String?])
        -> Endpoint<Result>
    {
        return Endpoint(
            method: .get,
            path: path,
            query: parameters.compactMapValues { $0 }.sorted { $0.key < $1.key }
                .map { URLQueryItem(name: $0.key, value: $0.value) },
            requiresAuth: true
        )
    }
}

struct AnimeDTO: Decodable, Sendable {
    let animeId: Int?
    let title: String?
    let coverImageUrl: String?
    let myRating: Double?

    var anime: MyAnime {
        return MyAnime(
            animeId: animeId, title: title, coverImageUrl: coverImageUrl, myRating: myRating)
    }
}

struct PersonDTO: Decodable, Sendable {
    let personId: Int?
    let name: String?
    let profileImageUrl: String?

    var person: MyPerson {
        return MyPerson(personId: personId, name: name, profileImageUrl: profileImageUrl)
    }
}

/// 레거시 `ToWatchListResult`: 커서는 반드시 온다
struct WatchListResult: Decodable, Sendable {
    struct Cursor: Decodable, Sendable {
        let lastId: Int
    }

    let count: Int
    let cursor: Cursor
    let animes: [AnimeDTO]?
}

/// 레거시 `MyInfoLikedAnimeResult`
struct LikedAnimesResult: Decodable, Sendable {
    struct Cursor: Decodable, Sendable {
        let lastId: Int?
    }

    let count: Int
    let cursor: Cursor?
    let animes: [AnimeDTO]?
}

/// 레거시 `LikedPersonListResult`
struct LikedPersonsResult: Decodable, Sendable {
    struct Cursor: Decodable, Sendable {
        let lastId: Int?
    }

    let count: Int
    let cursor: Cursor
    let persons: [PersonDTO]
}
