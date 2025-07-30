//
//  ReviewResponse.swift
//  AniPick
//
//  Created by cho on 7/28/25.
//


import Foundation

struct ReviewResponse: Decodable {
    let code: Int
    let value: String
    let result: MyReviewItem?
}

struct MyReviewItem: Decodable {
    let reviewId: Int?
    let rating: Double?
    let content: String?
    let createdAt: String?  // 또는 Date 타입으로 바꿀 수도 있음
    let likeCount: Int?
}
