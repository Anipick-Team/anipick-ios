//
//  RecentReviewsResponse.swift
//  AniPick
//
//  Created by cho on 6/12/25.
//

struct RecentReviewInHomeResponse: Codable {
    let code: Int
    let value: String
    let result: [Review]
}

struct Review: Hashable, Codable {
    let reviewId: Int?
    let animeId: Int?
    let animeTitle: String?
    let reviewContent: String?
    let nickname: String?
    let createdAt: String?
}

