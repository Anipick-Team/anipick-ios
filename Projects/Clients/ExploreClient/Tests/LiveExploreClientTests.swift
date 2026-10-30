import ClientCore
import ExploreClientInterface
import Foundation
import Networking
import Testing

@testable import ExploreClientLive

@Suite("LiveExploreClient", .timeLimit(.minutes(1)))
struct LiveExploreClientTests {
    private func query(_ request: URLRequest) -> [String: String] {
        let items =
            URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
        return Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })
    }

    @Test("PS1. 취향 선택 목록: GET api/explore-search, 값이 있는 조건만(장르는 genres=id), size 없음, 토큰")
    func onboarding() async throws {
        let stub = ClientStub(
            .json(
                #"{"code":200,"value":"SUCCESS","result":{"count":1,"cursor":{"lastId":7},"animes":[{"animeId":7,"title":"A","coverImageUrl":null,"genres":["액션"]}]}}"#
            ))

        let page = try await LiveExploreClient(client: stub.client)
            .onboardingAnimes(query: "나루토", year: 2025, season: nil, genreId: 3, lastId: 5)

        let request = try #require(stub.requests.first)
        #expect(request.url?.path() == "/api/explore-search")
        #expect(query(request) == ["query": "나루토", "year": "2025", "genres": "3", "lastId": "5"])
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer T")
        #expect(
            page
                == OnboardingPage(
                    animes: [
                        OnboardingAnime(animeId: 7, title: "A", coverImageUrl: nil, genres: ["액션"])
                    ],
                    lastId: 7))
    }

    @Test("PS1. 결과나 목록이 없으면 nil (레거시는 아무것도 하지 않는다)")
    func missing() async throws {
        let stub = ClientStub(
            .json(#"{"code":200,"value":"SUCCESS","result":{"count":0,"cursor":null}}"#))

        let page = try await LiveExploreClient(client: stub.client)
            .onboardingAnimes(query: nil, year: nil, season: nil, genreId: nil, lastId: nil)

        #expect(page == nil)
        #expect(query(try #require(stub.requests.first)).isEmpty)
    }

    @Test("EX1. 작품 탐색: GET api/explore/animes, 장르는 genres[] 반복, size=18, lastValue 없음")
    func exploreAnimes() async throws {
        let stub = ClientStub(
            .json(
                #"{"code":200,"value":"SUCCESS","result":{"count":2,"cursor":{"sort":"popularity","lastId":9,"lastValue":null},"animes":[{"animeId":9,"title":"A","coverImageUrl":null,"releaseDate":null}]}}"#
            ))

        let page = try await LiveExploreClient(client: stub.client).exploreAnimes(
            ExploreQuery(
                sort: "rating", year: 2025, season: nil, genreIds: [3, 5], type: "TV", lastId: 4,
                genreOp: "AND"))

        let request = try #require(stub.requests.first)
        #expect(request.url?.path() == "/api/explore/animes")
        let items =
            URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(items.filter { $0.name == "genres[]" }.map(\.value) == ["3", "5"])
        #expect(
            Dictionary(items.filter { $0.name != "genres[]" }.map { ($0.name, $0.value ?? "") }) {
                a, _ in a
            }
                == [
                    "sort": "rating", "year": "2025", "type": "TV", "lastId": "4", "size": "18",
                    "genreOp": "AND",
                ])
        #expect(
            page
                == ExplorePage(
                    animes: [ExploreAnime(animeId: 9, title: "A", coverImageUrl: nil)], lastId: 9))
    }
}
