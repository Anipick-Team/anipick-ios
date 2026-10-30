import ClientCore
import Foundation
import Networking
import RankingClientInterface
import Testing

@testable import RankingClientLive

@Suite("LiveRankingClient", .timeLimit(.minutes(1)))
struct LiveRankingClientTests {
    private let page = #"""
        {"code":200,"value":"SUCCESS","errorValue":null,"result":{
          "cursor":{"sort":null,"lastId":55,"lastValue":"9.5"},
          "animes":[{"animeId":1,"title":"A","coverImageUrl":null,"rank":1,"change":"-2",
                     "trend":"down","genres":["액션"],"popularity":3,"trending":1}]}}
        """#

    private func query(_ request: URLRequest) -> [String: String] {
        let items =
            URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
        return Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })
    }

    @Test("R5. 실시간: GET api/rankings/real-time, 값이 있는 파라미터와 size=20, 토큰")
    func realTime() async throws {
        let stub = ClientStub(.json(page))

        let result = try await LiveRankingClient(client: stub.client)
            .realTime(genre: "액션", lastId: 10, lastValue: nil)

        let request = try #require(stub.requests.first)
        #expect(request.httpMethod == "GET")
        #expect(request.url?.path() == "/api/rankings/real-time")
        #expect(query(request) == ["genre": "액션", "lastId": "10", "size": "20"])
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer T")
        #expect(
            result
                == RankingPage(
                    animes: [
                        RankedAnime(
                            animeId: 1, title: "A", coverImageUrl: nil, rank: 1, change: "-2",
                            trend: "down", genres: ["액션"])
                    ],
                    lastId: 55,
                    lastValue: "9.5"
                ))
    }

    @Test("R6. 연도/분기: year·season·lastRank를 보낸다. 분기가 없으면 뺀다")
    func yearSeason() async throws {
        let stub = ClientStub(.json(page))
        let client = LiveRankingClient(client: stub.client)

        _ = try await client.yearSeason(
            year: 2025, season: 3, genre: nil, lastId: nil, lastRank: nil)
        _ = try await client.yearSeason(
            year: 2024, season: nil, genre: "SF", lastId: 5, lastRank: 20)

        #expect(
            stub.requests.map { $0.url?.path() } == [
                "/api/rankings/year-season", "/api/rankings/year-season",
            ])
        #expect(query(stub.requests[0]) == ["year": "2025", "season": "3", "size": "20"])
        #expect(
            query(stub.requests[1])
                == ["year": "2024", "genre": "SF", "lastId": "5", "lastRank": "20", "size": "20"])
    }

    @Test("R7. 역대: GET api/rankings/all-time")
    func allTime() async throws {
        let stub = ClientStub(.json(page))

        _ = try await LiveRankingClient(client: stub.client).allTime(
            genre: nil, lastId: 3, lastRank: 7)

        let request = try #require(stub.requests.first)
        #expect(request.url?.path() == "/api/rankings/all-time")
        #expect(query(request) == ["lastId": "3", "lastRank": "7", "size": "20"])
    }

    @Test("결과가 없는 응답(업무 오류)은 실패로 본다 — 레거시도 디코딩에 실패해 아무것도 하지 않는다")
    func missingResultFails() async {
        let stub = ClientStub(.json(#"{"code":500,"value":"FAIL","errorValue":"x","result":null}"#))

        await #expect(throws: TransportError.decoding) {
            _ = try await LiveRankingClient(client: stub.client)
                .realTime(genre: nil, lastId: nil, lastValue: nil)
        }
    }
}
