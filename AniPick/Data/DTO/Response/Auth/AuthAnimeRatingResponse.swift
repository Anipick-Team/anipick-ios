//
//  AuthAnimeRatingResponse.swift
//  AniPick
//
//  Created by cho on 6/11/25.
//

struct AuthAnimeRatingResponse: Decodable {
    let code: Int
    let value: String
    let result: String // TODO
    let count: Int
    let cursor: Cursor
}



