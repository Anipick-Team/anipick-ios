//
//  SearchResultResponse.swift
//  AniPick
//
//  Created by cho on 6/12/25.
//

struct SearchInitResponse: Decodable {
    let code: Int
    let value: String
    let result: PopularAnimes
}

struct PopularAnimes: Decodable {
    let popularAnimes: [Anime]
}
