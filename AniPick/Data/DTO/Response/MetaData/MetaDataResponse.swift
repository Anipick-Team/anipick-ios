//
//  MetaDataResponse.swift
//  AniPick
//
//  Created by cho on 7/20/25.
//


import Foundation

struct MetaDataResponse: Decodable {
    let code: Int
    let value: String
    let result: MetaDataResult
}

struct MetaDataResult: Decodable {
    let seasonYear: [Int]
    let season: [Season]
    let genres: [Genre]
    let type: [String]
}

struct Season: Codable {
    let id: Int
    let name: String
}
