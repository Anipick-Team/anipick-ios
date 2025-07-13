//
//  ToWatchResponse.swift
//  AniPick
//
//  Created by cho on 7/13/25.
//

import Foundation

struct ToWatchResponse: Codable {
    let code: Int
    let value: String
    let result: ToWatchListResult
}

struct ToWatchListResult: Codable {
    let count: Int
    let cursor: ToWatchAnimeCursor
    let animes: [ToWatchAnime]
}

struct ToWatchAnimeCursor: Codable {
    let lastId: Int
}

struct ToWatchAnime: Codable, Identifiable {
    let animeId: Int
    let userAnimeStatusId: Int
    let title: String
    let coverImageUrl: String
    let myRating: Double?
    
    var id: Int { animeId } // For ForEach use
}

