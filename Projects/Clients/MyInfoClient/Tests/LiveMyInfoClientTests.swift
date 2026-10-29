import ClientCore
import Foundation
import MyInfoClientInterface
import Networking
import Testing

@testable import MyInfoClientLive

@Suite("LiveMyInfoClient", .timeLimit(.minutes(1)))
struct LiveMyInfoClientTests {
    private func query(_ request: URLRequest) -> [String: String] {
        let items =
            URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
        return Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })
    }

    @Test(
        "L1. 볼·보는 중·다 본 애니: 상태별 경로에 status·lastId·size=20을 보낸다",
        arguments: [
            (WatchStatus.watchList, "/api/mypage/animes/watchlist"),
            (.watching, "/api/mypage/animes/watching"), (.finished, "/api/mypage/animes/finished"),
        ]
    )
    func watchList(status: WatchStatus, path: String) async throws {
        let stub = ClientStub(
            .json(
                #"{"code":200,"value":"SUCCESS","result":{"count":42,"cursor":{"lastId":9},"animes":[{"animeId":1,"userAnimeStatusId":3,"title":"A","coverImageUrl":"u","myRating":4.5}]}}"#
            ))

        let page = try await LiveMyInfoClient(client: stub.client).watchList(status, lastId: 7)

        let request = try #require(stub.requests.first)
        #expect(request.httpMethod == "GET")
        #expect(request.url?.path() == path)
        #expect(query(request) == ["status": status.rawValue, "lastId": "7", "size": "20"])
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer T")
        #expect(
            page
                == MyPage(
                    count: 42,
                    items: [MyAnime(animeId: 1, title: "A", coverImageUrl: "u", myRating: 4.5)],
                    lastId: 9))
    }

    @Test("L1. 첫 페이지는 lastId를 보내지 않는다. animes가 없으면 빈 목록")
    func watchListFirstPage() async throws {
        let stub = ClientStub(
            .json(#"{"code":200,"value":"SUCCESS","result":{"count":0,"cursor":{"lastId":0}}}"#))

        let page = try await LiveMyInfoClient(client: stub.client).watchList(.watching, lastId: nil)

        #expect(query(try #require(stub.requests.first)) == ["status": "WATCHING", "size": "20"])
        #expect(page == MyPage(count: 0, items: [], lastId: 0))
    }

    @Test("L4. 좋아요한 작품: api/mypage/animes/like, size=20, 커서가 없어도 된다")
    func likedAnimes() async throws {
        let stub = ClientStub(
            .json(
                #"{"code":200,"value":"SUCCESS","result":{"count":3,"cursor":null,"animes":[{"animeId":5,"animeLikeId":1,"title":"B","coverImageUrl":null}]}}"#
            ))

        let page = try await LiveMyInfoClient(client: stub.client).likedAnimes(lastId: nil)

        let request = try #require(stub.requests.first)
        #expect(request.url?.path() == "/api/mypage/animes/like")
        #expect(query(request) == ["size": "20"])
        #expect(
            page
                == MyPage(
                    count: 3, items: [MyAnime(animeId: 5, title: "B", coverImageUrl: nil)],
                    lastId: nil))
    }

    @Test("L5. 좋아요한 인물: api/mypage/persons/like, size=30")
    func likedPersons() async throws {
        let stub = ClientStub(
            .json(
                #"{"code":200,"value":"SUCCESS","result":{"count":1,"cursor":{"lastId":4},"persons":[{"personId":8,"userLikedVoiceActorId":2,"name":"성우","profileImageUrl":"p"}]}}"#
            ))

        let page = try await LiveMyInfoClient(client: stub.client).likedPersons(lastId: 2)

        let request = try #require(stub.requests.first)
        #expect(request.url?.path() == "/api/mypage/persons/like")
        #expect(query(request) == ["lastId": "2", "size": "30"])
        #expect(
            page
                == MyPage(
                    count: 1, items: [MyPerson(personId: 8, name: "성우", profileImageUrl: "p")],
                    lastId: 4))
    }

    @Test("결과가 없는 응답은 실패 (레거시도 디코딩 실패로 아무것도 하지 않는다)")
    func missingResultFails() async {
        let stub = ClientStub(.json(#"{"code":500,"value":"FAIL","result":null}"#))

        await #expect(throws: TransportError.decoding) {
            _ = try await LiveMyInfoClient(client: stub.client).likedPersons(lastId: nil)
        }
    }
}
