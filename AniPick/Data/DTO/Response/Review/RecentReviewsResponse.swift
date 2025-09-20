//
//  RecentReviewsResponse.swift
//  AniPick
//
//  Created by cho on 6/17/25.
//

struct RecentReviewsResponse: Decodable {
    let code: Int
    let value: String
    let result: ReviewResult?
}

struct ReviewResult: Decodable {
    let count: Int?
    let cursor: ReviewCursor?
    let reviews: [ReviewItem]?
}

struct ReviewCursor: Decodable {
    let sort: String?
    let lastId: Int?
    let lastValue: String?
}

struct ReviewItem: Decodable, Hashable {
    let reviewId: Int?
    let userId: Int?
    let animeId: Int?
    let animeTitle: String?
    let animeCoverImageUrl: String?
    let rating: Double?
    let reviewContent: String?
    let nickname: String?
    let profileImageUrl: String?
    let createdAt: String? // 또는 Date로 변환도 가능
    let likeCount: Int?
    let likedByCurrentUser: Bool?
    let isMine: Bool?
    let content: String?
}

