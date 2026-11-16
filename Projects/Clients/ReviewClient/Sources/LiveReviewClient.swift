import ClientCore
import Foundation
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

    public func storeInitialRatings(_ ratings: [InitialRating]) async throws(TransportError) {
        let _: ServerResponse<EmptyResult> = try await client.send(Self.bulkEndpoint(ratings))
    }

    /// 레거시 `AnimeAPI.storedPreference`: JSON 배열 [{animeId, rating}]
    static func bulkEndpoint(_ ratings: [InitialRating]) -> Endpoint<EmptyResult> {
        return Endpoint(
            method: .post,
            path: "api/reviews/bulk",
            body: .json(ratings.map { RatingBody(animeId: $0.animeId, rating: $0.rating) }),
            requiresAuth: true
        )
    }

    public func deleteReview(id: Int) async throws(TransportError) {
        let _: ServerResponse<EmptyResult> = try await client.send(
            Self.deleteReviewEndpoint(id: id))
    }

    public func recentReviews(lastId: Int?) async throws(TransportError) -> RecentReviewPage? {
        let response = try await client.send(Self.recentEndpoint(lastId: lastId))
        guard let result = response.result, let reviews = result.reviews else {
            return nil
        }
        return RecentReviewPage(reviews: reviews.map(\.review), lastId: result.cursor?.lastId)
    }

    /// 레거시 `ReviewAPI.recentReview`: lastId만 (size 없음)
    static func recentEndpoint(lastId: Int?) -> Endpoint<RecentResult> {
        return Endpoint(
            method: .get,
            path: "api/reviews/recent",
            query: lastId.map { [URLQueryItem(name: "lastId", value: String($0))] } ?? [],
            requiresAuth: true
        )
    }

    public func setReviewLike(id: Int, liked: Bool) async throws(TransportError) -> Bool {
        let response: ServerResponse<EmptyResult> = try await client.send(
            Endpoint(
                method: liked ? .post : .delete, path: "api/reviews/\(id)/like", requiresAuth: true)
        )
        return response.code == 200
    }

    public func reportReview(id: Int, message: String) async throws(TransportError) {
        try await sendReadingBody(
            Endpoint(
                method: .post, path: "api/reviews/\(id)/report",
                body: .json(ReportBody(message: message)),
                requiresAuth: true))
    }

    public func blockUser(id: Int) async throws(TransportError) {
        try await sendReadingBody(
            Endpoint(method: .post, path: "api/\(id)/block-user", requiresAuth: true))
    }

    public func animeReviews(
        animeId: Int, sort: String, includesSpoiler: Bool, lastValue: String?, lastId: Int?
    )
        async throws(TransportError) -> AnimeReviewPage
    {
        let response = try await client.send(
            Self.animeReviewsEndpoint(
                animeId: animeId, sort: sort, includesSpoiler: includesSpoiler,
                lastValue: lastValue, lastId: lastId))
        return AnimeReviewPage(
            reviews: response.result?.reviews?.map(\.review),
            lastId: response.result?.cursor?.lastId,
            lastValue: response.result?.cursor?.lastValue)
    }

    /// 레거시 `AnimeAPI.reviewList`
    static func animeReviewsEndpoint(
        animeId: Int, sort: String, includesSpoiler: Bool, lastValue: String?, lastId: Int?
    ) -> Endpoint<RecentResult> {
        let parameters: [String: String?] = [
            "sort": sort, "isSpoiler": includesSpoiler ? "true" : "false", "lastValue": lastValue,
            "lastId": lastId.map(String.init), "size": "10",
        ]
        return Endpoint(
            method: .get,
            path: "api/animes/\(animeId)/reviews",
            query: parameters.compactMapValues { $0 }.sorted { $0.key < $1.key }
                .map { URLQueryItem(name: $0.key, value: $0.value) },
            requiresAuth: true
        )
    }

    public func myReview(animeId: Int) async throws(TransportError) -> MyReview? {
        let response = try await client.send(
            Endpoint<MyReviewResult>(
                method: .get, path: "api/animes/\(animeId)/my-review", requiresAuth: true))
        return response.result.map {
            MyReview(
                reviewId: $0.reviewId, rating: $0.rating, content: $0.content,
                createdAt: $0.createdAt,
                likeCount: $0.likeCount)
        }
    }

    public func registerRating(animeId: Int, rating: Double) async throws(TransportError) {
        try await sendReadingBody(
            Endpoint(
                method: .post, path: "api/rating/\(animeId)/animes",
                body: .json(RatingOnlyBody(rating: rating)),
                requiresAuth: true))
    }

    public func editRating(reviewId: Int, rating: Double) async throws(TransportError) {
        try await sendReadingBody(
            Endpoint(
                method: .patch, path: "api/rating/\(reviewId)/animes",
                body: .json(RatingOnlyBody(rating: rating)),
                requiresAuth: true))
    }

    /// 레거시는 `.validate()` 없이 `BaseResponse`로 읽기만 한다. HTTP 상태와 무관하게 {code, value}를 읽으면 성공이다
    private func sendReadingBody(_ endpoint: Endpoint<EmptyResult>) async throws(TransportError) {
        let data = try await client.sendRaw(endpoint)
        guard (try? JSONDecoder().decode(BodyEnvelope.self, from: data)) != nil else {
            throw .decoding
        }
    }

    /// 레거시 `ReviewAPI.deleteReview`
    static func deleteReviewEndpoint(id: Int) -> Endpoint<EmptyResult> {
        return Endpoint(method: .delete, path: "api/reviews/\(id)", requiresAuth: true)
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

struct RatingBody: Encodable, Sendable {
    let animeId: Int
    let rating: Double
}

struct ReportBody: Encodable, Sendable {
    let message: String
}

/// 레거시 `BaseResponse`의 필수 키
struct BodyEnvelope: Decodable {
    let code: Int
    let value: String
}

/// 레거시 `ReviewResult`
struct RecentResult: Decodable, Sendable {
    struct Cursor: Decodable, Sendable {
        let lastId: Int?
        let lastValue: String?
    }

    struct Item: Decodable, Sendable {
        let reviewId: Int?
        let userId: Int?
        let animeId: Int?
        let animeTitle: String?
        let animeCoverImageUrl: String?
        let rating: Double?
        let reviewContent: String?
        let nickname: String?
        let profileImageUrl: String?
        let createdAt: String?
        let likeCount: Int?
        let likedByCurrentUser: Bool?
        let content: String?
        let isMine: Bool?
        let isSpoiler: Bool?

        var review: RecentReview {
            return RecentReview(
                reviewId: reviewId, userId: userId, animeId: animeId, animeTitle: animeTitle,
                animeCoverImageUrl: animeCoverImageUrl, rating: rating,
                text: content ?? reviewContent ?? "--",
                nickname: nickname,
                profileImageId: profileImageUrl.map {
                    Int($0.components(separatedBy: "/").last ?? "") ?? 0
                },
                createdAt: createdAt, likeCount: likeCount, isLiked: likedByCurrentUser,
                isMine: isMine,
                isSpoiler: isSpoiler)
        }
    }

    let cursor: Cursor?
    let reviews: [Item]?
}

struct RatingOnlyBody: Encodable, Sendable {
    let rating: Double
}

/// 레거시 `MyReviewItem`
struct MyReviewResult: Decodable, Sendable {
    let reviewId: Int?
    let rating: Double?
    let content: String?
    let createdAt: String?
    let likeCount: Int?
}
