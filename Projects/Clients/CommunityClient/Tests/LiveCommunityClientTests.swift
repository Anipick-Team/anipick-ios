import ClientCore
import CommunityClientInterface
import Foundation
import Networking
import Testing

@testable import CommunityClientLive

@Suite("LiveCommunityClient", .timeLimit(.minutes(1)))
struct LiveCommunityClientTests {
    private static let imageBase = URL(string: "https://img.test/")!

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

        let page = try await LiveCommunityClient(client: stub.client, imageBaseURL: Self.imageBase)
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

        let page = try await LiveCommunityClient(client: stub.client, imageBaseURL: Self.imageBase)
            .exploreBoards(sort: "popular", keyword: nil, lastValue: nil, lastId: nil)

        #expect(page == CommunityBoardPage(boards: [], lastId: nil, lastValue: nil))
        #expect(query(try #require(stub.requests.first)) == ["sort": "popular", "size": "20"])
    }

    private func json(_ endpoint: Endpoint<EmptyResult>) throws -> String {
        guard case .json(let body) = endpoint.body else {
            Issue.record("JSON 본문이 아니다")
            return ""
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return String(decoding: try encoder.encode(body), as: UTF8.self)
    }

    @Test("CW1. 사진 올리기: POST api/image/community-post-image, multipart postImageFile, id가 없으면 nil")
    func upload() async throws {
        let stub = ClientStub(.json(#"{"code":200,"value":"SUCCESS","result":{"imageId":9}}"#))
        let client = LiveCommunityClient(client: stub.client, imageBaseURL: Self.imageBase)

        let id = try await client.uploadPostImage(
            jpeg: Data([1, 2]), fileName: "community-post-2.jpg")

        let request = try #require(stub.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path() == "/api/image/community-post-image")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer T")
        #expect(id == 9)
        let body = String(
            decoding: LiveCommunityClient.uploadEndpoint(jpeg: Data([1]), fileName: "a.jpg")
                .multipartBody, as: UTF8.self)
        #expect(body.contains(#"name="postImageFile"; filename="a.jpg""#))
        #expect(body.contains("Content-Type: image/jpeg"))

        let empty = ClientStub(.json(#"{"code":200,"value":"SUCCESS","result":{}}"#))
        #expect(
            try await LiveCommunityClient(client: empty.client, imageBaseURL: Self.imageBase)
                .uploadPostImage(jpeg: Data(), fileName: "a.jpg") == nil)
    }

    @Test("CW2. 글 작성: POST api/community/posts JSON, 사진이 없으면 imageIds를 빼고 보낸다")
    func create() async throws {
        let stub = ClientStub(.json(#"{"code":200,"value":"SUCCESS","result":null}"#))
        let client = LiveCommunityClient(client: stub.client, imageBaseURL: Self.imageBase)
        let draft = PostDraft(title: "제목", content: "", isSpoiler: true, imageIds: [3, 1])

        let outcome = try await client.createPost(seriesId: 7, draft)

        let request = try #require(stub.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path() == "/api/community/posts")
        #expect(outcome == .saved)
        #expect(
            try json(LiveCommunityClient.createEndpoint(seriesId: 7, draft))
                == #"{"content":"","imageIds":[3,1],"isSpoiler":true,"seriesId":7,"title":"제목"}"#)
        #expect(
            try json(
                LiveCommunityClient.createEndpoint(
                    seriesId: 7, PostDraft(title: "t", content: "c", isSpoiler: false, imageIds: [])
                ))
                == #"{"content":"c","isSpoiler":false,"seriesId":7,"title":"t"}"#)
    }

    @Test("CW3. 글 수정: PATCH api/community/posts/{id}, 사진이 없어도 빈 배열")
    func update() async throws {
        let stub = ClientStub(.json(#"{"code":200,"value":"SUCCESS"}"#))
        let client = LiveCommunityClient(client: stub.client, imageBaseURL: Self.imageBase)
        let draft = PostDraft(title: "t", content: "c", isSpoiler: false, imageIds: [])

        let outcome = try await client.updatePost(id: 12, draft)

        let request = try #require(stub.requests.first)
        #expect(request.httpMethod == "PATCH")
        #expect(request.url?.path() == "/api/community/posts/12")
        #expect(outcome == .saved)
        #expect(
            try json(LiveCommunityClient.updateEndpoint(id: 12, draft))
                == #"{"content":"c","imageIds":[],"isSpoiler":false,"title":"t"}"#)
    }

    @Test("CW4. 업무 오류는 HTTP 200 + code로 온다: code가 200이 아니면 안내 문구와 함께 거절")
    func rejected() async throws {
        let stub = ClientStub(
            .json(#"{"code":400,"value":"BAD","errorValue":"금지어가 있어요.","result":null}"#))

        let outcome = try await LiveCommunityClient(
            client: stub.client, imageBaseURL: Self.imageBase
        )
        .createPost(seriesId: 1, PostDraft(title: "t", content: "", isSpoiler: false, imageIds: []))

        #expect(outcome == .rejected(message: "금지어가 있어요."))
    }

    @Test("CW5. 첨부 사진 주소는 {서버}api/image/{id}")
    func imageURL() {
        let client = LiveCommunityClient(
            client: ClientStub(.json("{}")).client, imageBaseURL: Self.imageBase)

        #expect(client.imageURL(id: 5).absoluteString == "https://img.test/api/image/5")
    }
}

extension Endpoint {
    fileprivate var multipartBody: Data {
        guard case .multipart(let form) = body else {
            return Data()
        }
        return form.encoded()
    }
}
