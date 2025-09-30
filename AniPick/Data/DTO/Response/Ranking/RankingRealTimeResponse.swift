//
//  RankingRealTimeResponse.swift
//  AniPick
//
//  Created by cho on 6/18/25.
//

struct RankingRealTimeResponse: Decodable {
    let code: Int
    let value: String
    let result: RankingResult
}

struct RankingResult: Decodable {
    let cursor: RankingCursor
    let animes: [RankedAnime]
}

struct RankingCursor: Decodable {
    let sort: String?
    let lastId: Int
    let lastValue: String?
}

struct RankedAnime: Decodable, Hashable {
    let animeId: Int?
    let title: String?
    let coverImageUrl: String?
    let rank: Int?
    let change: String?
    let trend: String?
    let genres: [String]?
    let popularity: Int?
    let trending: Int?
}

