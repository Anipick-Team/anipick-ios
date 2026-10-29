import ClientCore
import Networking
import ReviewClientInterface

/// `api/reviews/*` (레거시 `AnimeAPI`의 리뷰 요청).
public struct LiveReviewClient: ReviewClient {
    private let client: HTTPClient

    /// - Parameter client: 인증 클라이언트 (`tokenProvider`가 있는 것)
    public init(client: HTTPClient) {
        self.client = client
    }

    public func writeReview(
        animeId: Int,
        content: String,
        rating: Double,
        isSpoiler: Bool
    ) async throws(TransportError) {
        let _: ServerResponse<EmptyResult> = try await client.send(
            Self.writeReviewEndpoint(
                animeId: animeId,
                content: content,
                rating: rating,
                isSpoiler: isSpoiler
            )
        )
    }

    /// 레거시 `AnimeAPI.swift` — `PATCH api/reviews/{animeId}/animes`, JSON 본문
    static func writeReviewEndpoint(
        animeId: Int,
        content: String,
        rating: Double,
        isSpoiler: Bool
    ) -> Endpoint<EmptyResult> {
        return Endpoint(
            method: .patch,
            path: "api/reviews/\(animeId)/animes",
            body: .json(WriteReviewBody(rating: rating, isSpoiler: isSpoiler, content: content)),
            requiresAuth: true
        )
    }
}

struct WriteReviewBody: Encodable, Sendable {
    let rating: Double
    let isSpoiler: Bool
    let content: String
}
