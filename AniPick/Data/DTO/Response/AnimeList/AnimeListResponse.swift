//
//  AnimeSeriesListResponse.swift
//  AniPick
//
//  Created by cho on 7/13/25.
//


import Foundation

// MARK: - Top-Level Response
struct AnimeSeriesListResponse: Decodable {
    let code: Int
    let value: String
    let result: [AnimeSeriesItem]
}

// MARK: - Anime Item
struct AnimeSeriesItem: Decodable, Identifiable {
    let animeId: Int
    let title: String
    let coverImageUrl: String
    let airDate: String?

    var id: Int { animeId }
}
