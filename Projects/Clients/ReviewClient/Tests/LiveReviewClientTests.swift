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
}
