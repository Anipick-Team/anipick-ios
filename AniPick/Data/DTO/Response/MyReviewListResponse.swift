//
//  MyReviewListResponse.swift
//  AniPick
//
//  Created by cho on 9/7/25.
//

import Foundation

struct MyReviewListResponse: Codable {
    let code: Int
    let value: String
    let result: MyReviewListResult
}

struct MyReviewListResult: Codable, Hashable {
    let count: Int?
    let cursor: MyReviewCursor?
    let reviews: [MyReview]?
}

struct MyReviewCursor: Codable, Hashable {
    let sort: String?
    let lastId: Int?
   // let lastValue: Double?
}

struct MyReview: Codable, Hashable {
    let animeId: Int?
    let title: String?
    let coverImageUrl: String?
    let rating: Double?
    let reviewId: Int?
    let reviewContent: String?
    let createdAt: String?
    let likeCount: Int?
    let isLiked: Bool?
}
