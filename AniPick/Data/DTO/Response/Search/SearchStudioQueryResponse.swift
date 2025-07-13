//
//  SearchStudioQueryResponse.swift
//  AniPick
//
//  Created by cho on 6/17/25.
//

struct SearchStudioQueryResponse: Decodable {
    let code: Int
    let success: Bool?
    let result: SearchStudioResult?
}

struct SearchStudioResult: Decodable {
    let count: Int
    let animeCount: Int
    let personCount: Int
    let cursor: CursorId
    let studios: [Studio]
}

struct Studio: Decodable {
    let studioId: Int
    let name: String
}
