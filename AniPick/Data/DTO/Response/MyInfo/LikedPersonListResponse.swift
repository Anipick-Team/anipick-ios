//
//  LikedPersonListResponse.swift
//  AniPick
//
//  Created by cho on 7/13/25.
//

import Foundation

struct LikedPersonListResponse: Decodable {
    let code: Int
    let value: String
    let result: LikedPersonListResult
}

struct LikedPersonListResult: Decodable {
    let count: Int
    let cursor: LikedPersonCursor
    let persons: [LikedRatedPerson]
}

struct LikedPersonCursor: Decodable {
    let lastId: Int?
}

struct LikedRatedPerson: Decodable, Hashable {
    let personId: Int?
    let userLikedVoiceActorId: Int?
    let name: String?
    let profileImageUrl: String?

}
