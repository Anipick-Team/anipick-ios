//
//  StudioDetailResponse.swift
//  AniPick
//
//  Created by cho on 9/5/25.
//

import Foundation

struct StudioDetailResponse: Decodable {
    let code: Int
    let value: String
    let result: StudioDetailResult
}

// result 안의 구조
struct StudioDetailResult: Decodable {
    let studioName: String
    let cursor: Cursor
    let animes: [AnimeWithSeasonYear]
}


// 애니메이션 정보
struct AnimeWithSeasonYear: Decodable, Hashable {
    let animeId: Int?
    let title: String?
    let coverImageUrl: String?
    let seasonYear: String
}
