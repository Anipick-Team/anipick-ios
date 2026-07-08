//
//  ComingSoonAnimeResponse.swift
//  AniPick
//
//  Created by cho on 6/18/25.
//

struct ComingSoonAnimeResponse: Decodable {
    let code: Int
    let value: String
    let result: ComingSoonResult
}

struct ComingSoonResult: Decodable {
    let count: Int
    let cursor: CursorWithSorted
    let animes: [ComingSoonAnime]
}

struct CursorWithSorted: Codable {
    let sort: String
    let lastId: Int
}

struct ComingSoonAnime: Decodable {
    let animeId: Int
    let title: String
    let coverImageUrl: String
    let releaseDate: String
    let isAdult: Bool? // 기본적으로 false, true인 경우에만 값이 옴
}
