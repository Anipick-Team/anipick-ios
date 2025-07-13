//
//  RankingYearSeasonResponse.swift
//  AniPick
//
//  Created by cho on 6/18/25.
//

struct RankingYearSeasonResponse: Decodable {
    let code: Int
    let value: String
    let result: RankingResult
}
