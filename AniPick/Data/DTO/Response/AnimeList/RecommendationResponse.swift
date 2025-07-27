//
//  RecommendationResponse.swift
//  AniPick
//
//  Created by cho on 7/20/25.
//
import Foundation

struct RecommendationResponse: Decodable {
    let code: Int
    let value: String
    let result: RecommendationResult?
}

struct RecommendationResult: Decodable {
    let referenceAnimeTitle: String?
    let cursor: Cursor?
    let animes: [Anime]?
}
