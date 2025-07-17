//
//  UpcomingSeasonResponse.swift
//  AniPick
//
//  Created by cho on 6/12/25.
//

struct AnimeSeasonResponse: Codable {
    let code: Int
    let value: String
    let result: AnimeSeasonResult
}

struct AnimeSeasonResult: Codable {
    let season: Int
    let seasonYear: Int
    let animes: [Anime]
}

struct Anime: Hashable, Codable {
    let animeId: Int?
    let title: String?
    let coverImageUrl: String?
}
