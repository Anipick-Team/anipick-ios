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

    public func studio(id: Int, lastId: Int?, lastValue: String?) async throws(TransportError)
        -> StudioPage
    {
        let result = try await client.send(
            Self.query(
                "api/studios/\(id)/animes",
                ["lastId": lastId.map(String.init), "lastValue": lastValue, "size": "20"])
                as Endpoint<StudioResult>
        )
        .requireResult()
        return StudioPage(
            studioName: result.studioName,
            animes: result.animes.map {
                StudioAnime(
                    animeId: $0.animeId, title: $0.title, coverImageUrl: $0.coverImageUrl,
                    seasonYear: $0.seasonYear)
            },
            lastId: result.cursor.lastId, lastValue: result.cursor.lastValue)
    }

    public func characters(animeId: Int) async throws(TransportError) -> [CastMember] {
        let result = try await client.send(
            Self.query("api/animes/\(animeId)/characters", ["size": "20"])
                as Endpoint<CharactersResult>
        )
        .requireResult()
        return result.characters.map {
            CastMember(character: $0.character?.person, voiceActor: $0.voiceActor?.person)
        }
    }

    public func person(id: Int, lastId: Int?) async throws(TransportError) -> PersonPage {
        let result = try await client.send(
            Self.query("api/person/\(id)", ["lastId": lastId.map(String.init), "size": "20"])
                as Endpoint<PersonResult>
        )
        .requireResult()
        return PersonPage(
            name: result.name, profileImageUrl: result.profileImageUrl, isLiked: result.isLiked,
            count: result.count,
            lastId: result.cursor.lastId,
            works: result.works.map {
                PersonWork(
                    animeId: $0.animeId, animeTitle: $0.animeTitle, characterId: $0.characterId,
                    characterName: $0.characterName, characterImageUrl: $0.characterImageUrl)
            })
    }

    public func setPersonLike(id: Int, liked: Bool) async throws(TransportError) {
        let _: ServerResponse<EmptyResult> = try await client.send(
            Endpoint(
                method: liked ? .post : .delete, path: "api/persons/\(id)/like", requiresAuth: true)
        )
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

struct ValueCursor: Decodable, Sendable {
    let lastId: Int?
    let lastValue: String?
}

/// 레거시 `StudioDetailResult` (모두 필수 값)
struct StudioResult: Decodable, Sendable {
    struct Anime: Decodable, Sendable {
        let animeId: Int?
        let title: String?
        let coverImageUrl: String?
        let seasonYear: String
    }

    let studioName: String
    let cursor: ValueCursor
    let animes: [Anime]
}

/// 레거시 `CharacterAndVoiceActorPair`
struct CharactersResult: Decodable, Sendable {
    struct Person: Decodable, Sendable {
        let id: Int
        let name: String
        let imageUrl: String?

        var person: CastPerson {
            return CastPerson(id: id, name: name, imageUrl: imageUrl)
        }
    }

    struct Pair: Decodable, Sendable {
        let character: Person?
        let voiceActor: Person?
    }

    let cursor: ValueCursor
    let characters: [Pair]
}

/// 레거시 `PersonDetailResult` (모두 필수 값)
struct PersonResult: Decodable, Sendable {
    struct Cursor: Decodable, Sendable {
        let lastId: Int
    }

    struct Work: Decodable, Sendable {
        let animeId: Int
        let animeTitle: String
        let characterId: Int
        let characterName: String
        let characterImageUrl: String?
    }

    let name: String
    let profileImageUrl: String?
    let isLiked: Bool
    let count: Int
    let cursor: Cursor
    let works: [Work]
}
