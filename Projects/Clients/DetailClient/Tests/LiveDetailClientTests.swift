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
}
