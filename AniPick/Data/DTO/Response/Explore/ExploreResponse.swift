//
//  ExplorePopularityResponse.swift
//  AniPick
//
//  Created by cho on 6/12/25.
//

struct ExploreResponse: Decodable {
    let code: Int
    let value: String
    let result: ExploreResult?
}

struct ExploreResult: Decodable {
    let count: Int?
    let cursor: Cursor?
    let animes: [Anime]?
    
}

struct Cursor: Decodable {
    let sort: String?
    let lastId: Int?
    let lastValue: String? // 탐색 - 평점 순일 경우에만 있음
}
