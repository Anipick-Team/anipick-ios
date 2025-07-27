//
//  SeriesAnimeResponse.swift
//  AniPick
//
//  Created by cho on 7/22/25.
//


import Foundation

struct SeriesAnimeResponse: Decodable {
    let code: Int
    let value: String
    let result: SeriesAnimeResult?
}

struct SeriesAnimeResult: Decodable {
    let count: Int
    let cursor: AnimeCursor?
    let animes: [SeriesAnime]?
}


struct SeriesAnime: Decodable, Hashable {
    let animeId: Int?
    let title: String?
    let coverImageUrl: String?
    let airDate: String?
}
