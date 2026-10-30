import ClientCore
import Foundation
import Networking
import ReviewClientInterface
import Testing

@testable import ReviewClientLive

@Suite("LiveReviewClient", .timeLimit(.minutes(1)))
struct LiveReviewClientTests {
    @Test("V8. PATCH api/reviews/{animeId}/animes에 별점·스포일러·내용을 JSON으로, 토큰과 함께 보낸다")
    func sendsReview() async throws {
        let stub = ClientStub(.json(#"{"code":200,"value":"SUCCESS","errorValue":null}"#))

        try await LiveReviewClient(client: stub.client)
            .writeReview(animeId: 42, content: "재밌다", rating: 4.5, isSpoiler: true)

        let request = try #require(stub.requests.first)
        #expect(request.httpMethod == "PATCH")
        #expect(request.url?.path() == "/api/reviews/42/animes")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer T")

        // URLProtocol에는 본문이 스트림으로 와서 요청 정의의 본문을 인코딩해 확인한다
        let endpoint = LiveReviewClient.writeReviewEndpoint(
            animeId: 42, content: "재밌다", rating: 4.5, isSpoiler: true)
        #expect(endpoint.requiresAuth)
        guard case .json(let body) = endpoint.body else {
            Issue.record("JSON 본문이 아니다")
            return
        }
        let encoded = try JSONEncoder().encode(body)
        let json = try #require(try JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        #expect(json.count == 3)
        #expect(json["rating"] as? Double == 4.5)
        #expect(json["isSpoiler"] as? Bool == true)
        #expect(json["content"] as? String == "재밌다")
    }

    @Test("V9. 레거시처럼 응답 code가 200이 아니어도 성공으로 본다")
    func ignoresBusinessCode() async throws {
        let stub = ClientStub(.json(#"{"code":500,"value":"FAIL","errorValue":"x"}"#))

        try await LiveReviewClient(client: stub.client)
            .writeReview(animeId: 1, content: "", rating: 0, isSpoiler: false)
    }

    @Test("V10. 전송에 실패하면 던진다")
    func throwsOnTransportFailure() async {
        let stub = ClientStub(.failure(.notConnectedToInternet))

        await #expect(throws: TransportError.offline) {
            try await LiveReviewClient(client: stub.client)
                .writeReview(animeId: 1, content: "", rating: 0, isSpoiler: false)
        }
    }

    @Test("내 리뷰 삭제: DELETE api/reviews/{id}, 토큰")
    func deletesReview() async throws {
        let stub = ClientStub(.json(#"{"code":200,"value":"SUCCESS","errorValue":null}"#))

        try await LiveReviewClient(client: stub.client).deleteReview(id: 77)

        let request = try #require(stub.requests.first)
        #expect(request.httpMethod == "DELETE")
        #expect(request.url?.path() == "/api/reviews/77")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer T")
    }

    @Test("PS8. 취향 선택 별점: POST api/reviews/bulk, JSON 배열 [{animeId, rating}], 토큰")
    func storesInitialRatings() async throws {
        let stub = ClientStub(.json(#"{"code":200,"value":"SUCCESS","errorValue":null}"#))

        try await LiveReviewClient(client: stub.client)
            .storeInitialRatings([
                InitialRating(animeId: 1, rating: 4.5), InitialRating(animeId: 2, rating: 3),
            ])

        let request = try #require(stub.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path() == "/api/reviews/bulk")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer T")
        guard
            case .json(let body) = LiveReviewClient.bulkEndpoint([
                InitialRating(animeId: 1, rating: 4.5)
            ]).body
        else {
            Issue.record("JSON 본문이 아니다")
            return
        }
        let json =
            try JSONSerialization.jsonObject(with: try JSONEncoder().encode(body))
            as? [[String: Any]]
        #expect(json?.count == 1)
        #expect(json?.first?["animeId"] as? Int == 1)
        #expect(json?.first?["rating"] as? Double == 4.5)
    }

    @Test(
        "RR1. 최근 리뷰: GET api/reviews/recent?lastId. 내용은 content → reviewContent → \"--\", 프로필은 마지막 경로를 id로 (숫자가 아니면 0)"
    )
    func recentReviews() async throws {
        let stub = ClientStub(
            .json(
                #"{"code":200,"value":"SUCCESS","result":{"cursor":{"lastId":3},"reviews":[{"reviewId":1,"userId":9,"animeId":5,"rating":4.5,"reviewContent":"옛 내용","content":"새 내용","profileImageUrl":"https://x/api/image/77","likeCount":2,"likedByCurrentUser":true},{"reviewId":2,"reviewContent":"옛 내용만","profileImageUrl":"https://x/profile/abc"},{"reviewId":3}]}}"#
            ))

        let page = try #require(
            try await LiveReviewClient(client: stub.client).recentReviews(lastId: 8))

        let request = try #require(stub.requests.first)
        #expect(request.url?.path() == "/api/reviews/recent")
        #expect(request.url?.query() == "lastId=8")
        #expect(page.lastId == 3)
        #expect(page.reviews.map(\.text) == ["새 내용", "옛 내용만", "--"])
        #expect(page.reviews.map(\.profileImageId) == [77, 0, nil])
        #expect(page.reviews[0].isLiked == true)
        #expect(page.reviews[0].likeCount == 2)

        let empty = ClientStub(.json(#"{"code":200,"value":"SUCCESS","result":null}"#))
        #expect(try await LiveReviewClient(client: empty.client).recentReviews(lastId: nil) == nil)
        #expect(try #require(empty.requests.first).url?.query() == nil)
    }

    @Test("RR2. 리뷰 좋아요: POST·DELETE api/reviews/{id}/like, 본문 code가 200일 때만 성공")
    func like() async throws {
        let ok = ClientStub(.json(#"{"code":200,"value":"SUCCESS"}"#))
        #expect(try await LiveReviewClient(client: ok.client).setReviewLike(id: 4, liked: true))
        #expect(try await LiveReviewClient(client: ok.client).setReviewLike(id: 4, liked: false))
        #expect(
            ok.requests.map { "\($0.httpMethod ?? "") \($0.url?.path() ?? "")" } == [
                "POST /api/reviews/4/like", "DELETE /api/reviews/4/like",
            ])

        let rejected = ClientStub(.json(#"{"code":400,"value":"FAIL"}"#))
        #expect(
            try await LiveReviewClient(client: rejected.client).setReviewLike(id: 4, liked: true)
                == false)
    }

    @Test("RR3. 신고·차단: 경로와 본문. HTTP 상태와 무관하게 {code, value}를 읽으면 성공, 못 읽으면 실패")
    func reportAndBlock() async throws {
        let stub = ClientStub(.status(400, #"{"code":400,"value":"FAIL"}"#))
        let client = LiveReviewClient(client: stub.client)

        try await client.reportReview(id: 6, message: "개인정보 노출")
        try await client.blockUser(id: 9)

        #expect(
            stub.requests.map { "\($0.httpMethod ?? "") \($0.url?.path() ?? "")" } == [
                "POST /api/reviews/6/report", "POST /api/9/block-user",
            ])
        #expect(
            String(
                decoding: try JSONEncoder().encode(ReportBody(message: "개인정보 노출")), as: UTF8.self)
                == #"{"message":"개인정보 노출"}"#)

        let broken = ClientStub(.status(500, "<html>"))
        await #expect(throws: TransportError.decoding) {
            try await LiveReviewClient(client: broken.client).blockUser(id: 9)
        }
    }

    @Test(
        "RT1. 애니 리뷰: GET api/animes/{id}/reviews, sort·isSpoiler(true/false)·lastValue·lastId·size=10. 결과가 없으면 목록·커서 nil"
    )
    func animeReviews() async throws {
        let stub = ClientStub(
            .json(
                #"{"code":200,"value":"OK","result":{"cursor":{"lastId":4,"lastValue":"v"},"reviews":[{"reviewId":4,"isMine":true,"isSpoiler":true,"content":"c"}]}}"#
            ))

        let page = try await LiveReviewClient(client: stub.client)
            .animeReviews(
                animeId: 7, sort: "likes", includesSpoiler: false, lastValue: "x", lastId: 3)

        let request = try #require(stub.requests.first)
        #expect(request.url?.path() == "/api/animes/7/reviews")
        let items =
            URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(
            Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })
                == [
                    "sort": "likes", "isSpoiler": "false", "lastValue": "x", "lastId": "3",
                    "size": "10",
                ])
        #expect(page.lastId == 4)
        #expect(page.lastValue == "v")
        #expect(page.reviews?.first?.isMine == true)
        #expect(page.reviews?.first?.isSpoiler == true)

        let none = ClientStub(.json(#"{"code":200,"value":"OK","result":null}"#))
        #expect(
            try await LiveReviewClient(client: none.client)
                .animeReviews(
                    animeId: 7, sort: "latest", includesSpoiler: true, lastValue: nil, lastId: nil)
                == AnimeReviewPage(reviews: nil, lastId: nil, lastValue: nil))
    }

    @Test(
        "RT2. 내 리뷰: GET api/animes/{id}/my-review (없으면 nil). 별점 등록 POST·수정 PATCH api/rating/{id}/animes {rating}"
    )
    func myReviewAndRating() async throws {
        let stub = ClientStub(
            .json(
                #"{"code":200,"value":"OK","result":{"reviewId":9,"rating":3.5,"content":"c","createdAt":"d","likeCount":2}}"#
            ))
        let client = LiveReviewClient(client: stub.client)

        let mine = try await client.myReview(animeId: 7)
        try await client.registerRating(animeId: 7, rating: 4)
        try await client.editRating(reviewId: 9, rating: 2.5)

        #expect(
            mine == MyReview(reviewId: 9, rating: 3.5, content: "c", createdAt: "d", likeCount: 2))
        #expect(
            stub.requests.map { "\($0.httpMethod ?? "") \($0.url?.path() ?? "")" }
                == [
                    "GET /api/animes/7/my-review", "POST /api/rating/7/animes",
                    "PATCH /api/rating/9/animes",
                ])
        #expect(
            String(decoding: try JSONEncoder().encode(RatingOnlyBody(rating: 4)), as: UTF8.self)
                == #"{"rating":4}"#)
        let none = ClientStub(.json(#"{"code":200,"value":"OK","result":null}"#))
        #expect(try await LiveReviewClient(client: none.client).myReview(animeId: 7) == nil)
    }
}
