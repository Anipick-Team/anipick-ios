//
//  RecommendedAnimeResponse.swift
//  AniPick
//
//  Created by cho on 9/7/25.
//

import Foundation

struct RecommendedAnimeResponse: Decodable {
    let code: Int
    let value: String
    let result: [Anime]
}
