import ClientCore
import Foundation
import HomeClientInterface
import Networking
import Storage
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

    @Test("HS1. 인기 작품: GET api/search/init (결과가 없으면 빈 목록)")
    func popular() async throws {
        let stub = ClientStub(
            .json(
                #"{"code":200,"value":"SUCCESS","result":{"popularAnimes":[{"animeId":1,"title":"A"}]}}"#
            ))

        let animes = try await LiveHomeClient(client: stub.client).popularAnimes()

        let request = try #require(stub.requests.first)
        #expect(request.url?.path() == "/api/search/init")
        #expect(query(request).isEmpty)
        #expect(animes == [HomeAnime(animeId: 1, title: "A", coverImageUrl: nil)])
        let empty = ClientStub(.json(#"{"code":200,"value":"SUCCESS","result":null}"#))
        #expect(try await LiveHomeClient(client: empty.client).popularAnimes().isEmpty)
    }

    @Test(
        "HS2. 검색 3종: GET api/search/{animes|persons|studios}?query&lastId, 전체 개수(없으면 0)와 커서. 결과가 없으면 nil"
    )
    func search() async throws {
        let animes = ClientStub(
            .json(
                #"{"code":200,"value":"OK","result":{"count":12,"personCount":3,"cursor":{"lastId":5},"animes":[{"animeId":5,"title":"A","clickLog":"https://log/c","impressionLogs":"https://log/i"}]}}"#
            ))
        let page = try await LiveHomeClient(client: animes.client).searchAnimes(
            query: "원피스", lastId: 2)
        #expect(try #require(animes.requests.first).url?.path() == "/api/search/animes")
        #expect(query(try #require(animes.requests.first)) == ["query": "원피스", "lastId": "2"])
        #expect(
            page
                == SearchPage(
                    items: [
                        SearchAnime(
                            animeId: 5, title: "A", coverImageUrl: nil, clickLog: "https://log/c",
                            impressionLog: "https://log/i")
                    ],
                    count: 12, lastId: 5))

        let persons = ClientStub(
            .json(
                #"{"code":200,"success":true,"result":{"cursor":null,"persons":[{"personId":7,"name":"P","profileImage":"u"}]}}"#
            ))
        let personPage = try await LiveHomeClient(client: persons.client).searchPersons(
            query: "a", lastId: nil)
        #expect(try #require(persons.requests.first).url?.path() == "/api/search/persons")
        #expect(query(try #require(persons.requests.first)) == ["query": "a"])
        #expect(
            personPage
                == SearchPage(
                    items: [SearchPerson(personId: 7, name: "P", profileImage: "u")], count: 0,
                    lastId: nil))

        let studios = ClientStub(
            .json(#"{"code":200,"result":{"count":1,"studios":[{"studioId":3,"name":"S"}]}}"#))
        let studioPage = try await LiveHomeClient(client: studios.client).searchStudios(
            query: "a", lastId: nil)
        #expect(try #require(studios.requests.first).url?.path() == "/api/search/studios")
        #expect(
            studioPage
                == SearchPage(items: [SearchStudio(studioId: 3, name: "S")], count: 1, lastId: nil))

        let none = ClientStub(.json(#"{"code":200,"value":"OK","result":null}"#))
        #expect(
            try await LiveHomeClient(client: none.client).searchAnimes(query: "a", lastId: nil)
                == nil)
    }

    @Test("HS3. 최근 검색어: 레거시 키(homeRecentKeyword)에 최신을 앞에, 같은 검색어는 앞으로 옮긴다")
    func keywords() throws {
        let defaults = try #require(UserDefaults(suiteName: "home-\(UUID().uuidString)"))
        let client = LiveHomeClient(
            client: ClientStub(.json("{}")).client, preferences: Preferences(defaults: defaults))

        client.saveRecentKeyword("a")
        client.saveRecentKeyword("b")
        client.saveRecentKeyword("a")
        #expect(defaults.stringArray(forKey: "homeRecentKeyword") == ["a", "b"])
        client.setRecentKeywords(["b"])
        #expect(client.recentKeywords() == ["b"])
        client.clearRecentKeywords()

        #expect(client.recentKeywords().isEmpty)
    }
}
