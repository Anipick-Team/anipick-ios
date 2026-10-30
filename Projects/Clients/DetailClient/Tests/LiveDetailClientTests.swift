import ClientCore
import DetailClientInterface
import Foundation
import Networking
import Testing

@testable import DetailClientLive

@Suite("LiveDetailClient", .timeLimit(.minutes(1)))
struct LiveDetailClientTests {
    private func query(_ request: URLRequest) -> [String: String] {
        let items =
            URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
        return Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })
    }

    @Test("SD1. 관련 작품: GET api/animes/{id}/series, lastId·size=10. count는 필수 (없으면 실패), 결과가 없으면 nil")
    func series() async throws {
        let stub = ClientStub(
            .json(
                #"{"code":200,"value":"OK","result":{"count":12,"cursor":{"lastId":4},"animes":[{"animeId":4,"title":"A","airDate":"x"}]}}"#
            ))

        let page = try await LiveDetailClient(client: stub.client).series(animeId: 7, lastId: 3)

        let request = try #require(stub.requests.first)
        #expect(request.url?.path() == "/api/animes/7/series")
        #expect(query(request) == ["lastId": "3", "size": "10"])
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer T")
        #expect(
            page
                == SeriesPage(
                    animes: [DetailAnime(animeId: 4, title: "A", coverImageUrl: nil)], count: 12,
                    lastId: 4))

        let none = ClientStub(.json(#"{"code":200,"value":"OK","result":null}"#))
        #expect(
            try await LiveDetailClient(client: none.client).series(animeId: 7, lastId: nil) == nil)
        #expect(query(try #require(none.requests.first)) == ["size": "10"])
        let noCount = ClientStub(.json(#"{"code":200,"value":"OK","result":{"animes":[]}}"#))
        await #expect(throws: TransportError.decoding) {
            try await LiveDetailClient(client: noCount.client).series(animeId: 7, lastId: nil)
        }
    }

    @Test("RC1. 함께 볼만한 작품: GET api/animes/{id}/recommendations, size=10, 기준 제목. 목록이 없으면 nil")
    func recommendations() async throws {
        let stub = ClientStub(
            .json(
                #"{"code":200,"value":"OK","result":{"referenceAnimeTitle":"기준","cursor":{"lastId":2},"animes":[{"animeId":2}]}}"#
            ))

        let page = try await LiveDetailClient(client: stub.client).recommendations(
            animeId: 7, lastId: nil)

        #expect(try #require(stub.requests.first).url?.path() == "/api/animes/7/recommendations")
        #expect(
            page
                == AnimeRecommendationPage(
                    animes: [DetailAnime(animeId: 2, title: nil, coverImageUrl: nil)],
                    referenceAnimeTitle: "기준", lastId: 2))
        let noList = ClientStub(
            .json(#"{"code":200,"value":"OK","result":{"referenceAnimeTitle":"기준"}}"#))
        #expect(
            try await LiveDetailClient(client: noList.client).recommendations(animeId: 7, lastId: 1)
                == nil)
    }

    @Test("PR1. 제작사: GET api/studios/{id}/animes, lastId·lastValue·size=20. 이름·커서·목록·연도는 필수")
    func studio() async throws {
        let stub = ClientStub(
            .json(
                #"{"code":200,"value":"OK","result":{"studioName":"MAPPA","cursor":{"lastId":5,"lastValue":"v"},"animes":[{"animeId":5,"title":"A","seasonYear":"2024"}]}}"#
            ))

        let page = try await LiveDetailClient(client: stub.client).studio(
            id: 3, lastId: 2, lastValue: "x")

        let request = try #require(stub.requests.first)
        #expect(request.url?.path() == "/api/studios/3/animes")
        #expect(query(request) == ["lastId": "2", "lastValue": "x", "size": "20"])
        #expect(
            page
                == StudioPage(
                    studioName: "MAPPA",
                    animes: [
                        StudioAnime(animeId: 5, title: "A", coverImageUrl: nil, seasonYear: "2024")
                    ],
                    lastId: 5, lastValue: "v"))
        let noYear = ClientStub(
            .json(
                #"{"code":200,"value":"OK","result":{"studioName":"M","cursor":{},"animes":[{"animeId":1}]}}"#
            ))
        await #expect(throws: TransportError.decoding) {
            try await LiveDetailClient(client: noYear.client).studio(
                id: 3, lastId: nil, lastValue: nil)
        }
    }

    @Test("CV1. 캐릭터·성우진: GET api/animes/{id}/characters?size=20 (커서 없이 한 번)")
    func characters() async throws {
        let stub = ClientStub(
            .json(
                #"{"code":200,"value":"OK","result":{"cursor":{},"characters":[{"character":{"id":1,"name":"루피","imageUrl":"c"},"voiceActor":{"id":9,"name":"성우","imageUrl":null},"role":"MAIN"},{"character":null,"voiceActor":null}]}}"#
            ))

        let cast = try await LiveDetailClient(client: stub.client).characters(animeId: 7)

        let request = try #require(stub.requests.first)
        #expect(request.url?.path() == "/api/animes/7/characters")
        #expect(query(request) == ["size": "20"])
        #expect(
            cast
                == [
                    CastMember(
                        character: CastPerson(id: 1, name: "루피", imageUrl: "c"),
                        voiceActor: CastPerson(id: 9, name: "성우", imageUrl: nil)),
                    CastMember(character: nil, voiceActor: nil),
                ])
    }

    @Test(
        "VA1. 성우: GET api/person/{id}, lastId·size=20 (모든 값 필수). 좋아요는 POST·DELETE api/persons/{id}/like"
    )
    func person() async throws {
        let stub = ClientStub(
            .json(
                #"{"code":200,"value":"OK","result":{"personId":3,"name":"카지","profileImageUrl":null,"isLiked":true,"count":40,"cursor":{"lastId":8},"works":[{"animeId":1,"animeTitle":"A","characterId":8,"characterName":"C","characterImageUrl":"u"}]}}"#
            ))
        let client = LiveDetailClient(client: stub.client)

        let page = try await client.person(id: 3, lastId: 5)
        try await client.setPersonLike(id: 3, liked: true)
        try await client.setPersonLike(id: 3, liked: false)

        #expect(
            stub.requests.map { "\($0.httpMethod ?? "") \($0.url?.path() ?? "")" }
                == ["GET /api/person/3", "POST /api/persons/3/like", "DELETE /api/persons/3/like"])
        #expect(query(try #require(stub.requests.first)) == ["lastId": "5", "size": "20"])
        #expect(
            page
                == PersonPage(
                    name: "카지", profileImageUrl: nil, isLiked: true, count: 40, lastId: 8,
                    works: [
                        PersonWork(
                            animeId: 1, animeTitle: "A", characterId: 8, characterName: "C",
                            characterImageUrl: "u")
                    ]))
        let noCursor = ClientStub(
            .json(
                #"{"code":200,"value":"OK","result":{"name":"a","isLiked":false,"count":0,"cursor":{},"works":[]}}"#
            ))
        await #expect(throws: TransportError.decoding) {
            try await LiveDetailClient(client: noCursor.client).person(id: 3, lastId: nil)
        }
    }

    @Test("AD1. 애니 상세 요청 4개의 경로. 상세는 결과 필수, 장르는 이름만")
    func detailEndpoints() async throws {
        let info = ClientStub(
            .json(
                #"{"code":200,"value":"OK","result":{"animeId":7,"title":"T","genres":[{"id":1,"name":"액션"}],"studios":[{"studioId":3,"name":"S"}],"watchStatus":"WATCHING"}}"#
            ))
        let detail = try await LiveDetailClient(client: info.client).animeInfo(id: 7)
        #expect(try #require(info.requests.first).url?.path() == "/api/animes/7/detail/info")
        #expect(detail.genres == ["액션"])
        #expect(detail.studios == [AnimeInfo.Studio(studioId: 3, name: "S")])
        #expect(detail.watchStatus == "WATCHING")

        let list = ClientStub(
            .json(#"{"code":200,"value":"OK","result":[{"animeId":2,"title":"A"}]}"#))
        let client = LiveDetailClient(client: list.client)
        #expect(
            try await client.detailSeries(animeId: 7) == [
                DetailAnime(animeId: 2, title: "A", coverImageUrl: nil)
            ])
        #expect(try await client.detailRecommendations(animeId: 7).count == 1)
        let cast = ClientStub(
            .json(
                #"{"code":200,"value":"OK","result":[{"character":{"id":1,"name":"C"},"voiceActor":null}]}"#
            ))
        #expect(
            try await LiveDetailClient(client: cast.client).detailCast(animeId: 7)
                == [
                    CastMember(
                        character: CastPerson(id: 1, name: "C", imageUrl: nil), voiceActor: nil)
                ])
        #expect(
            (list.requests + cast.requests).map { $0.url?.path() ?? "" }
                == [
                    "/api/animes/7/detail/series", "/api/animes/7/detail/recommendation",
                    "/api/animes/7/detail/actor",
                ])

        let none = ClientStub(.json(#"{"code":200,"value":"OK","result":null}"#))
        await #expect(throws: TransportError.decoding) {
            try await LiveDetailClient(client: none.client).animeInfo(id: 7)
        }
    }

    @Test("AD2. 좋아요·시청 상태: 경로·메서드·JSON 본문. HTTP 상태와 무관하게 본문을 읽으면 성공, code를 돌려준다")
    func actions() async throws {
        let stub = ClientStub(.json(#"{"code":128,"value":"EXISTS"}"#))
        let client = LiveDetailClient(client: stub.client)

        try await client.setAnimeLike(id: 7, liked: true)
        try await client.setAnimeLike(id: 7, liked: false)
        let code = try await client.setWatchStatus(animeId: 7, status: "WATCHING")
        try await client.deleteWatchStatus(animeId: 7)

        #expect(code == 128)
        #expect(
            stub.requests.map { "\($0.httpMethod ?? "") \($0.url?.path() ?? "")" }
                == [
                    "POST /api/animes/7/like", "DELETE /api/animes/7/like",
                    "POST /api/users/7/status",
                    "DELETE /api/users/7/status",
                ])
        #expect(
            String(decoding: try JSONEncoder().encode(LikeBody(animeId: 7)), as: UTF8.self)
                == #"{"animeId":7}"#)
        #expect(
            String(
                decoding: try JSONEncoder().encode(StatusBody(status: "WATCHING")), as: UTF8.self)
                == #"{"status":"WATCHING"}"#)
        let broken = ClientStub(.json("<html>"))
        await #expect(throws: TransportError.decoding) {
            try await LiveDetailClient(client: broken.client).setAnimeLike(id: 7, liked: true)
        }
    }
}
