//
//  ComingSoonResponse.swift
//  AniPick
//
//  Created by cho on 6/12/25.
//

struct ComingSoonResponse: Decodable {
    let code: Int
    let value: String
    let result: [Amine]
}

struct Amine: Decodable {
    let animeId: Int
    let title: String
    let coverImageUrl: String
    let releaseDate: String
}


