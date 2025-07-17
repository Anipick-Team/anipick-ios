//
//  SearchQueryResponse.swift
//  AniPick
//
//  Created by cho on 6/17/25.
//

// HomeSearchResponse로 통일
struct SearchAnimeQueryResponse: Decodable {
    let code: Int
    let value: String
    let result: AnimeResult?
    
}

struct AnimeResult: Decodable {
    let count: Int
    let personCount: Int
    let studioCount: Int
    let cursor: CursorId
    let animes: [AnimeWithClickLog]
}

struct CursorId: Decodable, Hashable {
    let lastId: Int
}

