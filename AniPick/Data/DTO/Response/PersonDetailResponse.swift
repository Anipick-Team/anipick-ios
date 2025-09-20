//
//  PersonDetailResponse.swift
//  AniPick
//
//  Created by cho on 9/7/25.
//


import Foundation

// MARK: - Top Level
struct PersonDetailResponse: Codable, Hashable {
    let code: Int
    let value: String
    let result: PersonDetailResult
}

// MARK: - Result
struct PersonDetailResult: Codable, Hashable {
    let personId: Int
    let name: String
    let profileImageUrl: String?
    let isLiked: Bool
    let count: Int
    let cursor: PersonCursor
    let works: [PersonWork]
}

// MARK: - Cursor
struct PersonCursor: Codable, Hashable {
    let lastId: Int
}

// MARK: - Work (작품)
struct PersonWork: Codable, Hashable {
    let animeId: Int
    let animeTitle: String
    let characterId: Int
    let characterName: String
    let characterImageUrl: String?

}
