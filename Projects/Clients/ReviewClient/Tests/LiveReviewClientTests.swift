import ClientCore
import Foundation
import Networking
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
}
