//
//  AuthAnimeRatingRequest.swift
//  AniPick
//
//  Created by cho on 6/11/25.
//

struct AuthAnimeRatingRequest: Encodable {
    let animeId: Int
    let rating: Double
}
