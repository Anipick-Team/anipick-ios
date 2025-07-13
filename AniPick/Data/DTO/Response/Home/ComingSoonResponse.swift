//
//  ComingSoonResponse.swift
//  AniPick
//
//  Created by cho on 6/12/25.
//

struct ComingSoonResponse: Decodable {
    let code: Int
    let value: String
    let result: [Anime]
}



