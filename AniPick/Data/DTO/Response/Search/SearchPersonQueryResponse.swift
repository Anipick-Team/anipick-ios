//
//  SearchPersonQueryResponse.swift
//  AniPick
//
//  Created by cho on 6/17/25.
//

struct SearchPersonQueryResponse: Decodable {
    let code: Int
    let success: Bool?
    let result: SearchPersonResult
}

struct SearchPersonResult: Decodable {
    let count: Int
    let animeCount: Int
    let studioCount: Int
    let cursor: CursorId
    let persons: [Person]
}

struct Person: Decodable {
    let personId: Int
    let name: String
    let profileImage: String
}
