//
//  HomeSearchResponse.swift
//  AniPick
//
//  Created by cho on 7/16/25.
//
import Foundation

struct HomeSearchResponse: Decodable {
    let code: Int
    let success: Bool?
    let result: HomeSearchResult?
}

struct HomeSearchResult: Decodable, Hashable, Identifiable {
    let id = UUID()
    
    let count: Int
    let animeCount: Int?
    let nextPage: Int?
    let personCount: Int?
    let studioCount: Int?
    let cursor: CursorId
    let animes: [AnimeWithClickLog]?
    let persons: [Person]?
    let studios: [Studio]?
}

struct Studio: Decodable, Hashable {
    let studioId: Int
    let name: String
}

struct Person: Decodable, Hashable  {
    let personId: Int
    let name: String
    let profileImage: String
}

struct AnimeWithClickLog: Decodable, Hashable  {
    let animeId: Int
    let title: String
    let coverImageUrl: String
    let clickLog: String
    let impressionLogs: String?
}
