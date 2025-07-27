//
//  UpcomingAnimeListResponse.swift
//  AniPick
//
//  Created by cho on 7/22/25.
//


import Foundation

struct UpcomingAnimeListResponse: Decodable {
    let code: Int
    let value: String
    let result: UpcomingAnimeResult?
}

struct UpcomingAnimeResult: Decodable {
    let count: Int?
    let cursor: Cursor?
    let animes: [UpcomingAnime]?
}


struct UpcomingAnime: Decodable, Hashable {
    let animeId: Int?
    let title: String?
    let coverImageUrl: String?
    let releaseDate: String?
    let isAdult: Bool?
}
