import ClientCore
import Foundation
import HomeClientInterface
import Networking
import Testing

@testable import HomeClientLive

@Suite("LiveHomeClient", .timeLimit(.minutes(1)))
struct LiveHomeClientTests {
    private func query(_ request: URLRequest) -> [String: String] {
        let items =
            URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
        return Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })
    }

    @Test("RC1. 취향 추천: GET api/recommendation/animes, lastId·lastValue만 (없으면 빼고)")
    func recommendations() async throws {
        let stub = ClientStub(
            .json(
                #"{"code":200,"value":"SUCCESS","result":{"referenceAnimeTitle":null,"cursor":{"lastId":5,"lastValue":"v"},"animes":[{"animeId":5,"title":"A","coverImageUrl":"u","releaseDate":"r"}]}}"#
            ))
        let client = LiveHomeClient(client: stub.client)

        let page = try await client.recommendations(lastId: 2, lastValue: "x")

        let request = try #require(stub.requests.first)
        #expect(request.url?.path() == "/api/recommendation/animes")
        #expect(query(request) == ["lastId": "2", "lastValue": "x"])
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer T")
        #expect(
            page
                == RecommendationPage(
                    animes: [HomeAnime(animeId: 5, title: "A", coverImageUrl: "u")],
                    referenceAnimeTitle: nil,
                    lastId: 5, lastValue: "v"))

        let empty = ClientStub(.json(#"{"code":200,"value":"SUCCESS","result":null}"#))
        #expect(
            try await LiveHomeClient(client: empty.client).recommendations(
                lastId: nil, lastValue: nil) == nil)
        #expect(query(try #require(empty.requests.first)).isEmpty)
    }

    @Test("RC2. 비슷한 작품: GET api/recommendation/animes/{id}/recent, 기준 제목. 목록이 없으면 nil")
    func recentRecommendations() async throws {
        let stub = ClientStub(
            .json(
                #"{"code":200,"value":"SUCCESS","result":{"referenceAnimeTitle":"기준","cursor":null,"animes":[]}}"#
            ))

        let page = try await LiveHomeClient(client: stub.client)
            .recentRecommendations(animeId: 9, lastId: nil, lastValue: nil)

        #expect(
            try #require(stub.requests.first).url?.path() == "/api/recommendation/animes/9/recent")
        #expect(
            page
                == RecommendationPage(
                    animes: [], referenceAnimeTitle: "기준", lastId: nil, lastValue: nil))

        let noList = ClientStub(
            .json(#"{"code":200,"value":"SUCCESS","result":{"referenceAnimeTitle":"기준"}}"#))
        #expect(
            try await LiveHomeClient(client: noList.client).recentRecommendations(
                animeId: 9, lastId: 1, lastValue: "a")
                == nil)
    }

    @Test(
        "CS1. 공개 예정: GET api/animes/coming-soon, sort·lastId·size=18·includeAdult(true/false). 목록이 없으면 nil"
    )
    func comingSoon() async throws {
        let stub = ClientStub(
            .json(
                #"{"code":200,"value":"SUCCESS","result":{"count":1,"cursor":{"lastId":4},"animes":[{"animeId":4,"title":"A","coverImageUrl":null,"releaseDate":"11.01","isAdult":false}]}}"#
            ))

        let page = try await LiveHomeClient(client: stub.client).comingSoon(
            sort: "startDate", lastId: 3, includeAdult: false)

        let request = try #require(stub.requests.first)
        #expect(request.url?.path() == "/api/animes/coming-soon")
        #expect(
            query(request) == [
                "sort": "startDate", "lastId": "3", "size": "18", "includeAdult": "false",
            ])
        #expect(
            page
                == ComingSoonPage(
                    animes: [
                        ComingSoonAnime(
                            animeId: 4, title: "A", coverImageUrl: nil, releaseDate: "11.01")
                    ], lastId: 4))

        let empty = ClientStub(.json(#"{"code":200,"value":"SUCCESS","result":{"cursor":null}}"#))
        #expect(
            try await LiveHomeClient(client: empty.client).comingSoon(
                sort: "latest", lastId: nil, includeAdult: true) == nil)
        #expect(query(try #require(empty.requests.first))["includeAdult"] == "true")
    }

    @Test("WN1. 요일별 신작: GET api/animes, day·sort·lastId·size=18. 결과가 없으면 빈 페이지")
    func weekday() async throws {
        let stub = ClientStub(
            .json(
                #"{"code":200,"value":"SUCCESS","result":{"cursor":{"lastId":7},"animes":[{"animeId":7,"title":"B"}]}}"#
            ))

        let page = try await LiveHomeClient(client: stub.client).weekdayNewAnimes(
            day: "TUE", sort: "popularity", lastId: nil)

        let request = try #require(stub.requests.first)
        #expect(request.url?.path() == "/api/animes")
        #expect(query(request) == ["day": "TUE", "sort": "popularity", "size": "18"])
        #expect(
            page
                == WeekdayAnimePage(
                    animes: [HomeAnime(animeId: 7, title: "B", coverImageUrl: nil)], lastId: 7))

        let empty = ClientStub(.json(#"{"code":200,"value":"SUCCESS","result":null}"#))
        #expect(
            try await LiveHomeClient(client: empty.client).weekdayNewAnimes(
                day: "MON", sort: "latest", lastId: 2)
                == WeekdayAnimePage(animes: [], lastId: nil))
    }
}
