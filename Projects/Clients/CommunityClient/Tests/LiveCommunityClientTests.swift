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

    @Test("CP1. 게시판 글: GET api/community/boards/{id}/posts, sort·커서·size=20. 비어 있는 값은 레거시 기본값으로")
    func posts() async throws {
        let stub = ClientStub(
            .json(
                #"{"code":200,"value":"SUCCESS","result":{"count":2,"cursor":{"sort":"latest","lastId":8,"lastValue":"v"},"posts":[{"postId":8,"title":"제목","content":"본문","thumbnailImageId":30,"imageCount":3,"isSpoiler":true,"likeCount":4,"commentCount":1,"createdAt":"10.30","nickname":"닉","profileImageUrl":"https://x/api/image/12"},{"postId":9,"thumbnailImageId":31,"profileImageUrl":"https://x/profile/abc"}]}}"#
            ))
        let client = LiveCommunityClient(client: stub.client, imageBaseURL: Self.imageBase)

        let page = try await client.posts(
            seriesId: 5, sort: "popularWeekly", lastValue: "3", lastId: 2)

        let request = try #require(stub.requests.first)
        #expect(request.url?.path() == "/api/community/boards/5/posts")
        #expect(
            query(request) == [
                "sort": "popularWeekly", "lastValue": "3", "lastId": "2", "size": "20",
            ])
        #expect(page.lastId == 8)
        #expect(page.lastValue == "v")
        #expect(
            page.posts
                == [
                    CommunityPost(
                        id: 8, authorName: "닉",
                        authorImageURL: URL(string: "https://img.test/api/image/12"),
                        date: "10.30", title: "제목", content: "본문",
                        thumbnailURL: URL(string: "https://img.test/api/image/30"), imageCount: 3,
                        likeCount: 4,
                        commentCount: 1, isSpoiler: true),
                    CommunityPost(
                        id: 9, authorName: "익명", authorImageURL: nil, date: "", title: "",
                        content: "",
                        thumbnailURL: URL(string: "https://img.test/api/image/31"), imageCount: 1,
                        likeCount: 0,
                        commentCount: 0, isSpoiler: false),
                ])
    }

    @Test("CP1. 결과가 없으면 빈 페이지, 비어 있는 커서는 보내지 않는다")
    func postsEmptyAndFailure() async throws {
        let stub = ClientStub(.json(#"{"code":200,"value":"SUCCESS","result":null}"#))
        let page = try await LiveCommunityClient(client: stub.client, imageBaseURL: Self.imageBase)
            .posts(seriesId: 1, sort: "latest", lastValue: nil, lastId: nil)

        #expect(page == CommunityPostPage(posts: [], lastId: nil, lastValue: nil))
        #expect(query(try #require(stub.requests.first)) == ["sort": "latest", "size": "20"])
    }

    @Test("CD1. 게시글 상세: GET api/community/posts/{id}. 빈 값은 레거시 기본값, 사진 id는 주소로도")
    func postDetail() async throws {
        let stub = ClientStub(
            .json(
                #"{"code":200,"value":"SUCCESS","result":{"postId":3,"seriesId":7,"animeTitle":"A","title":"T","content":"B","imageIds":[4,5],"isSpoiler":true,"viewCount":9,"likeCount":2,"commentCount":1,"createdAt":"d","nickname":"n","profileImageUrl":"/api/image/6","isMine":true,"likedByCurrentUser":true}}"#
            ))
        let client = LiveCommunityClient(client: stub.client, imageBaseURL: Self.imageBase)

        let detail = try await client.postDetail(id: 3)

        #expect(try #require(stub.requests.first).url?.path() == "/api/community/posts/3")
        #expect(
            detail
                == CommunityPostDetail(
                    postId: 3, seriesId: 7, animeTitle: "A", authorName: "n",
                    authorImageURL: URL(string: "https://img.test/api/image/6"), date: "d",
                    isSpoiler: true,
                    imageIds: [4, 5],
                    imageURLs: [
                        URL(string: "https://img.test/api/image/4")!,
                        URL(string: "https://img.test/api/image/5")!,
                    ],
                    title: "T", body: "B", viewCount: 9, likeCount: 2, commentCount: 1,
                    isLiked: true, isMine: true))

        let empty = ClientStub(.json(#"{"code":200,"value":"SUCCESS","result":{"postId":3}}"#))
        let fallback = try await LiveCommunityClient(
            client: empty.client, imageBaseURL: Self.imageBase
        )
        .postDetail(id: 3)
        #expect(fallback.seriesId == 0)
        #expect(fallback.animeTitle == "애니메이션")
        #expect(fallback.authorName == "익명")

        let none = ClientStub(.json(#"{"code":200,"value":"SUCCESS","result":null}"#))
        await #expect(throws: TransportError.decoding) {
            try await LiveCommunityClient(client: none.client, imageBaseURL: Self.imageBase)
                .postDetail(id: 3)
        }
    }

    @Test("CD2. 댓글: GET api/community/posts/{id}/comments, lastId·size=20. 지운 댓글은 문구로, 답글도 같은 규칙")
    func comments() async throws {
        let stub = ClientStub(
            .json(
                #"{"code":200,"value":"SUCCESS","result":{"cursor":{"lastId":11},"comments":[{"commentId":10,"content":"원래","isDeleted":true,"likeCount":1,"replies":[{"commentId":12,"content":"답","nickname":"r","isMine":true,"likedByCurrentUser":true}]}]}}"#
            ))
        let client = LiveCommunityClient(client: stub.client, imageBaseURL: Self.imageBase)

        let page = try await client.comments(postId: 3, lastId: 9)

        let request = try #require(stub.requests.first)
        #expect(request.url?.path() == "/api/community/posts/3/comments")
        #expect(query(request) == ["lastId": "9", "size": "20"])
        #expect(page.lastId == 11)
        #expect(
            page.comments
                == [
                    CommunityComment(
                        id: 10, authorName: "익명", authorImageURL: nil, date: "",
                        content: "삭제된 댓글입니다.",
                        likeCount: 1, isLiked: false, isMine: false,
                        replies: [
                            CommunityComment(
                                id: 12, authorName: "r", authorImageURL: nil, date: "",
                                content: "답", likeCount: 0,
                                isLiked: true, isMine: true, replies: [])
                        ])
                ])
    }

    @Test("CD3. 좋아요·댓글·삭제·신고의 경로와 메서드, JSON 본문")
    func actions() async throws {
        let stub = ClientStub(.json(#"{"code":200,"value":"SUCCESS"}"#))
        let client = LiveCommunityClient(client: stub.client, imageBaseURL: Self.imageBase)

        try await client.setPostLike(id: 1, liked: true)
        try await client.setPostLike(id: 1, liked: false)
        try await client.setCommentLike(id: 2, liked: true)
        try await client.setCommentLike(id: 2, liked: false)
        try await client.createComment(postId: 3, content: "c", parentCommentId: nil)
        try await client.updateComment(id: 4, content: "u")
        try await client.deletePost(id: 5)
        try await client.deleteComment(id: 6)
        try await client.report(target: .comment, targetId: 7, category: .spam)

        #expect(
            stub.requests.map { "\($0.httpMethod ?? "") \($0.url?.path() ?? "")" }
                == [
                    "POST /api/community/posts/1/like", "DELETE /api/community/posts/1/like",
                    "POST /api/community/comments/2/like", "DELETE /api/community/comments/2/like",
                    "POST /api/community/posts/3/comments", "PATCH /api/community/comments/4",
                    "DELETE /api/community/posts/5", "DELETE /api/community/comments/6",
                    "POST /api/community/reports",
                ])
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        #expect(
            String(
                decoding: try encoder.encode(CommentBody(content: "c", parentCommentId: nil)),
                as: UTF8.self)
                == #"{"content":"c"}"#)
        #expect(
            String(
                decoding: try encoder.encode(CommentBody(content: "c", parentCommentId: 8)),
                as: UTF8.self)
                == #"{"content":"c","parentCommentId":8}"#)
        #expect(
            String(
                decoding: try encoder.encode(
                    ReportBody(targetType: "COMMENT", targetId: 7, reportCategory: "SPAM")),
                as: UTF8.self)
                == #"{"reportCategory":"SPAM","targetId":7,"targetType":"COMMENT"}"#)
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
