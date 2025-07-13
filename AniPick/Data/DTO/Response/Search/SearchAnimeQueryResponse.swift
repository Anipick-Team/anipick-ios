//
//  SearchQueryResponse.swift
//  AniPick
//
//  Created by cho on 6/17/25.
//

struct SearchAnimeQueryResponse: Decodable {
    let code: Int
    let value: String
    let result: AnimeResult
}

struct AnimeResult: Decodable {
    let count: Int
    let personCount: Int
    let studioCount: Int
    let cursor: CursorId
    let impressionLogs: [ImpressionLog]
    let animes: [AnimeWithClickLog]
}

struct CursorId: Decodable {
    let lastId: Int
}

struct ImpressionLog: Decodable {
  // TODO: 어떤게,,,들어오나요,,?
    let logs: String
}

struct AnimeWithClickLog: Decodable {
    let animeId: Int
    let title: String
    let coverImageUrl: String
    let clickLog: String
}
