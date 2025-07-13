import Foundation

// MARK: - Top-Level Response
struct RatedReviewListResponse: Codable {
    let code: Int
    let value: String
    let result: RatedReviewListResult
}

// MARK: - Result
struct RatedReviewListResult: Codable {
    let count: Int
    let cursor: RatedReviewCursor
    let reviews: [RatedReview]
}

// MARK: - Cursor
struct RatedReviewCursor: Codable {
    let sort: String         // 예: "ratingDesc"
    let lastId: Int
    let lastValue: String    // "4.0" 등 (likeCount 또는 rating에 따라)
}

// MARK: - Review Item
struct RatedReview: Codable, Identifiable {
    let animeId: Int
    let title: String
    let coverImageUrl: String
    let rating: Double
    let reviewId: Int
    let reviewContent: String?  // nullable
    let createdAt: String       // "2025.04.05" 등
    let likeCount: Int
    let isLiked: Bool

    var id: Int { reviewId } // ForEach 등에서 사용하기 위함
}
