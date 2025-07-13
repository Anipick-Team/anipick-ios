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
    let cursor: CursorId
    let animes: [RankedAnime]
}

struct RankedAnime: Decodable {
    let animeId: Int
    let title: String
    let coverImageUrl: String
    let rank: Int
    let change: Int
    let trend: Trend
    let genres: [String]
}

