//
//  TrendingAnimesResponse.swift
//  AniPick
//
//  Created by cho on 6/11/25.
//

struct TrendingAnimesResponse: Decodable {
    let code: Int
    let value: String
    let result: [TrendingAnimes]
}

struct TrendingAnimes: Decodable {
    let animeId: Int
    let title: String
    let coverImageUrl: String
}
