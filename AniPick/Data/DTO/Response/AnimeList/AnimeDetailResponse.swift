//
//  AnimeDetailResponse.swift
//  AniPick
//
//  Created by cho on 7/13/25.
//

import Foundation

struct AnimeDetailResponse: Decodable {
    let code: Int
    let value: String
    let result: AnimeDetail
}

struct AnimeDetail: Decodable {
    let animeId: Int
    let title: String?
    let coverImageUrl: String?
    let bannerImageUrl: String?
    let description: String?
    let averageRating: String?         // null 가능
    let isLiked: Bool?
    let watchStatus: String?           // WATCHLIST, WATCHING, FINISHED or null
    let type: String?                   // e.g., "TVA"
    let reviewCount: Int?
    let genres: [Genre]?
    let episode: Int?
    let airDate: String?         // "2025년 3분기"
    let status: String?               // "방영 중", "방영 예정" 등
    let age: String?                    // 현재는 "-" 고정
    let studios: [Studio]? // SearchStudioQueryResponse에 위치
}

struct Genre: Codable, Identifiable {
    let id: Int
    let name: String
}


