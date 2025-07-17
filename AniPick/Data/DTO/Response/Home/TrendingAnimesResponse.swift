//
//  TrendingAnimesResponse.swift
//  AniPick
//
//  Created by cho on 6/11/25.
//

struct TrendingAnimesResponse: Decodable {
    let code: Int
    let value: String
    let result: [TrendingAnimes]?
    let errorReason: String?
    let errorValue: String?
}

struct TrendingAnimes: Hashable, Decodable {
    let animeId: Int?
    let title: String?
    let coverImageUrl: String?
    let rank: Int?
}
