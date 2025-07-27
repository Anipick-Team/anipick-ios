//
//  AnimePreferenceResponse.swift
//  AniPick
//
//  Created by cho on 7/22/25.
//


import Foundation

struct AnimePreferenceResponse: Decodable {
    let code: Int
    let value: String
    let result: AnimePreferenceResult?
}

struct AnimePreferenceResult: Decodable {
    let count: Int
    let cursor: AnimeCursor?
    let animes: [AnimePreference]?
}

struct AnimeCursor: Decodable {
    let lastId: Int?
}

struct AnimePreference: Decodable, Hashable {
    let animeId: Int?
    let title: String?
    let coverImageUrl: String?
    let genres: [String]?
}
