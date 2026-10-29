import ClientCore
import CommunityClientInterface
import Foundation
import Networking
import Testing

@testable import CommunityClientLive

@Suite("LiveCommunityClient", .timeLimit(.minutes(1)))
struct LiveCommunityClientTests {
    private func query(_ request: URLRequest) -> [String: String] {
        let items =
            URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
        return Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })
    }

    @Test("CB1. 게시판 탐색: GET api/community/explore/boards, sort·keyword·커서·size=20, 장르 이름만")
    func exploreBoards() async throws {
        let stub = ClientStub(
            .json(
                #"{"code":200,"value":"SUCCESS","result":{"count":1,"cursor":{"sort":"popular","lastId":4,"lastValue":"99"},"boards":[{"seriesId":4,"title":"A","coverImageUrl":null,"genres":[{"id":1,"name":"액션"},{"id":2,"name":null}]}]}}"#
            ))

        let page = try await LiveCommunityClient(client: stub.client)
            .exploreBoards(sort: "latest", keyword: "나루토", lastValue: "10", lastId: 3)

        let request = try #require(stub.requests.first)
        #expect(request.url?.path() == "/api/community/explore/boards")
        #expect(
            query(request)
                == [
                    "sort": "latest", "keyword": "나루토", "lastValue": "10", "lastId": "3",
                    "size": "20",
                ])
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer T")
        #expect(
            page
                == CommunityBoardPage(
                    boards: [
                        CommunityBoard(seriesId: 4, title: "A", coverImageUrl: nil, genres: ["액션"])
                    ],
                    lastId: 4, lastValue: "99"))
    }

    @Test("CB1. 결과가 없어도 빈 페이지 (레거시: result가 없으면 빈 목록)")
    func emptyResult() async throws {
        let stub = ClientStub(.json(#"{"code":200,"value":"SUCCESS","result":null}"#))

        let page = try await LiveCommunityClient(client: stub.client)
            .exploreBoards(sort: "popular", keyword: nil, lastValue: nil, lastId: nil)

        #expect(page == CommunityBoardPage(boards: [], lastId: nil, lastValue: nil))
        #expect(query(try #require(stub.requests.first)) == ["sort": "popular", "size": "20"])
    }
}
