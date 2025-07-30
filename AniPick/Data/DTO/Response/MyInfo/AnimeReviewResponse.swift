//
//  AnimeReviewResponse.swift
//  AniPick
//
//  Created by cho on 7/27/25.
//


import Foundation

// MARK: - Top-level Response
struct AnimeReviewResponse: Codable {
    let code: Int
    let value: String
    let result: AnimeReviewResult?
}

// MARK: - Result
struct AnimeReviewResult: Codable {
    let count: Int
    let cursor: AnimeReviewCursor?
    let reviews: [AnimeReview]
}

// MARK: - Cursor
struct AnimeReviewCursor: Codable {
    let sort: String
    let lastId: Int
    let lastValue: String
}

// MARK: - Review
struct AnimeReview: Codable, Hashable {
    let animeId: Int
    let title: String
    let coverImageUrl: String
    let rating: Double
    let reviewId: Int
    let reviewContent: String?
    let createdAt: String
    let likeCount: Int
    let isLiked: Bool
}
